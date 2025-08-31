import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/env_config.dart';

/// Service for handling Firebase Cloud Messaging (FCM)
///
/// This service manages:
/// - FCM token retrieval and storage
/// - Permission requests
/// - Message handling (foreground/background)
/// - Test notification sending
/// - Token synchronization with Supabase
class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;

  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  SupabaseClient? _supabase;

  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Initializing FCM Service...');

      // Request notification permissions
      try {
        await requestPermissions();
        debugPrint('✅ FCM permissions requested');
      } catch (e) {
        debugPrint('⚠️ FCM permission request failed: $e');
      }

      // Get and store FCM token
      try {
        await _initializeToken();
        debugPrint('✅ FCM token initialized');
      } catch (e) {
        debugPrint('⚠️ FCM token initialization failed: $e');
      }

      // Set up message handlers
      try {
        _setupMessageHandlers();
        debugPrint('✅ FCM message handlers set up');
      } catch (e) {
        debugPrint('⚠️ FCM message handlers setup failed: $e');
      }

      // Listen for token refresh
      try {
        _setupTokenRefreshListener();
        debugPrint('✅ FCM token refresh listener set up');
      } catch (e) {
        debugPrint('⚠️ FCM token refresh listener setup failed: $e');
      }

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize FCM service: $e');
      // Don't rethrow - let the app continue with limited functionality
    }
  }

  /// Request notification permissions from user
  Future<bool> requestPermissions() async {
    try {
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      final bool isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      if (isAuthorized) {
        debugPrint('✅ User granted notification permissions');
      } else {
        debugPrint('❌ User denied notification permissions');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      _currentToken = await _fcm.getToken();
      debugPrint('FCM Token: $_currentToken');
      return _currentToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Store FCM token in Supabase linked to user ID
  Future<void> storeTokenInSupabase(String? userId) async {
    if (_currentToken == null || userId == null) {
      debugPrint('Cannot store token: token=$_currentToken, userId=$userId');
      return;
    }

    try {
      // Initialize Supabase client if not already done
      _supabase ??= Supabase.instance.client;

      // Check if user already has a token record
      final existingRecord = await _supabase!
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        await _supabase!
            .from('user_fcm_tokens')
            .update({
              'fcm_token': _currentToken,
              'updated_at': DateTime.now().toIso8601String(),
              'platform': defaultTargetPlatform.name,
            })
            .eq('user_id', userId);

        debugPrint('✅ Updated FCM token in Supabase for user: $userId');
      } else {
        // Insert new record
        await _supabase!.from('user_fcm_tokens').insert({
          'user_id': userId,
          'fcm_token': _currentToken,
          'platform': defaultTargetPlatform.name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ Stored new FCM token in Supabase for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error storing FCM token in Supabase: $e');
    }
  }

  /// Send test notification using Firebase Web API
  Future<bool> sendTestNotification({
    required String item,
    required String daysLeft,
    String? customUserId,
  }) async {
    try {
      // Get Firebase Web API key using EnvConfig
      final webApiKey = EnvConfig.firebaseWebApiKey;

      if (webApiKey == 'YOUR_FIREBASE_WEB_API_KEY' || webApiKey.isEmpty) {
        debugPrint('❌ Firebase Web API key not configured');
        return false;
      }

      // Get target FCM token
      String? targetToken = _currentToken;

      if (customUserId != null) {
        try {
          // Initialize Supabase client if not already done
          _supabase ??= Supabase.instance.client;

          // Get token for specific user from Supabase
          final userTokenRecord = await _supabase!
              .from('user_fcm_tokens')
              .select('fcm_token')
              .eq('user_id', customUserId)
              .maybeSingle();

          targetToken = userTokenRecord?['fcm_token'];
        } catch (e) {
          debugPrint('⚠️ Could not access Supabase for custom user token: $e');
        }
      }

      if (targetToken == null) {
        debugPrint('❌ No FCM token available for notification');
        return false;
      }

      // Prepare notification payload for FCM HTTP v1 API
      final Map<String, dynamic> message = {
        'message': {
          'token': targetToken,
          'notification': {
            'title': 'Your $item is expiring soon!',
            'body': 'Only $daysLeft days left. Use it before it spoils.',
          },
          'data': {
            'item': item,
            'days_left': daysLeft,
            'type': 'expiry_alert',
            'timestamp': DateTime.now().toIso8601String(),
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'expiry_reminders',
            },
          },
        },
      };

      debugPrint(
        '📱 Sending notification to: ${targetToken.substring(0, 20)}...',
      );
      debugPrint('📝 Notification: Your $item is expiring soon!');

      // Get Firebase project ID using EnvConfig
      final projectId = EnvConfig.firebaseProjectId;

      // Send notification via FCM HTTP v1 API
      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $webApiKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Test notification sent successfully: $responseData');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.statusCode}');
        debugPrint('Response: ${response.body}');

        // If it's an authentication error, try the legacy API as fallback
        if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('🔄 Trying legacy FCM API as fallback...');
          return await _sendNotificationLegacyAPI(
            targetToken,
            item,
            daysLeft,
            webApiKey,
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  /// Fallback method using legacy FCM API
  Future<bool> _sendNotificationLegacyAPI(
    String token,
    String item,
    String daysLeft,
    String apiKey,
  ) async {
    try {
      final Map<String, dynamic> notification = {
        'to': token,
        'notification': {
          'title': 'Your $item is expiring soon!',
          'body': 'Only $daysLeft days left. Use it before it spoils.',
          'sound': 'default',
        },
        'data': {
          'item': item,
          'days_left': daysLeft,
          'type': 'expiry_alert',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'priority': 'high',
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$apiKey',
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent via legacy API');
        return true;
      } else {
        debugPrint('❌ Legacy API also failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Legacy API error: $e');
      return false;
    }
  }

  /// Initialize token and store in Supabase
  Future<void> _initializeToken() async {
    await getToken();

    try {
      // Initialize Supabase client if not already done
      _supabase ??= Supabase.instance.client;

      // Get current user ID (you might need to adjust this based on your auth implementation)
      final currentUser = _supabase?.auth.currentUser;
      if (currentUser != null) {
        await storeTokenInSupabase(currentUser.id);
      }
    } catch (e) {
      debugPrint('⚠️ Could not access Supabase for token storage: $e');
    }
  }

  /// Set up message handlers for foreground and background
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Received foreground message: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      _handleMessage(message, isBackground: false);
    });

    // Handle background message taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '📱 App opened from background notification: ${message.messageId}',
      );
      debugPrint('Data: ${message.data}');

      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _handleInitialMessage();
  }

  /// Set up token refresh listener
  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((String newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _currentToken = newToken;

      try {
        // Initialize Supabase client if not already done
        _supabase ??= Supabase.instance.client;

        // Update token in Supabase
        final currentUser = _supabase?.auth.currentUser;
        if (currentUser != null) {
          storeTokenInSupabase(currentUser.id);
        }
      } catch (e) {
        debugPrint('⚠️ Could not access Supabase for token refresh: $e');
      }
    });
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message, {required bool isBackground}) {
    final data = message.data;
    final notification = message.notification;

    if (data.isNotEmpty) {
      final messageType = data['type'] ?? 'unknown';

      switch (messageType) {
        case 'expiry_alert':
          _handleExpiryAlert(data, notification);
          break;
        case 'general':
          _handleGeneralNotification(data, notification);
          break;
        default:
          debugPrint('Unknown message type: $messageType');
      }
    }
  }

  /// Handle expiry alert notifications
  void _handleExpiryAlert(
    Map<String, dynamic> data,
    RemoteNotification? notification,
  ) {
    final item = data['item'] ?? 'Unknown item';
    final daysLeft = data['days_left'] ?? '0';

    debugPrint('🍅 Expiry Alert: $item expires in $daysLeft days');

    // You can add custom logic here, such as:
    // - Update local database
    // - Show custom UI
    // - Navigate to specific screen
  }

  /// Handle general notifications
  void _handleGeneralNotification(
    Map<String, dynamic> data,
    RemoteNotification? notification,
  ) {
    debugPrint('📢 General notification received');
    // Handle general notifications
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    if (data.isNotEmpty) {
      final messageType = data['type'] ?? 'unknown';

      switch (messageType) {
        case 'expiry_alert':
          // Navigate to item details or home screen
          debugPrint('🔗 Navigate to expiry alert for item: ${data['item']}');
          break;
        case 'general':
          // Navigate to appropriate screen
          debugPrint('🔗 Navigate to general notification');
          break;
        default:
          debugPrint('🔗 Unknown notification tap: $messageType');
      }
    }
  }

  /// Handle initial message when app is opened from terminated state
  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        '📱 App opened from terminated state via notification: ${initialMessage.messageId}',
      );
      _handleNotificationTap(initialMessage);
    }
  }

  /// Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get current token (cached)
  String? get currentToken => _currentToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  // Handle background message processing here
  // Note: You have limited processing time in background
}
