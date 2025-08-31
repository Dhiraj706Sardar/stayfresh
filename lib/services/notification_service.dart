import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/grocery_item.dart';
import '../utils/constants.dart';

/// Service for handling push notifications and local notifications
///
/// This service manages:
/// - Firebase Cloud Messaging (FCM) for push notifications
/// - Local notifications for expiry reminders
/// - Notification scheduling and management
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data safely
      try {
        tz.initializeTimeZones();
        debugPrint('✅ Timezone data initialized');
      } catch (e) {
        debugPrint('⚠️ Timezone initialization failed: $e');
        // Continue without timezone - local notifications will still work
      }

      // Initialize local notifications
      await _initializeLocalNotifications();
      debugPrint('✅ Local notifications initialized');

      // Initialize FCM
      await _initializeFCM();
      debugPrint('✅ FCM initialized');

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
      // Don't rethrow - let the app continue with limited functionality
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Request permission for notifications
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
    } else {
      debugPrint(
        'User declined or has not accepted permission for notifications',
      );
    }

    // Get FCM token
    final String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel expiryChannel = AndroidNotificationChannel(
      'expiry_reminders',
      'Expiry Reminders',
      description: 'Notifications for items expiring soon',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          'general',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(expiryChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  /// Schedule expiry reminder notification for a grocery item
  ///
  /// [item] - The grocery item to schedule notification for
  Future<void> scheduleExpiryNotification(GroceryItem item) async {
    if (!_isInitialized) await initialize();

    try {
      final now = DateTime.now();
      final expiryDate = item.expiryDate;

      // Schedule notification for default reminder days before expiry
      final reminderDate = expiryDate.subtract(
        Duration(days: defaultExpiryReminderDays),
      );

      if (reminderDate.isAfter(now)) {
        await _scheduleNotification(
          id: item.id.hashCode,
          title: 'Item Expiring Soon',
          body: '${item.name} expires in $defaultExpiryReminderDays days',
          scheduledDate: reminderDate,
          payload: 'expiry_${item.id}',
        );
      }

      // Schedule urgent notification for 1 day before expiry
      final urgentReminderDate = expiryDate.subtract(
        Duration(days: urgentExpiryReminderDays),
      );

      if (urgentReminderDate.isAfter(now)) {
        await _scheduleNotification(
          id: item.id.hashCode + 1,
          title: 'Item Expires Tomorrow!',
          body: '${item.name} expires tomorrow',
          scheduledDate: urgentReminderDate,
          payload: 'urgent_expiry_${item.id}',
        );
      }

      // Schedule notification on expiry date
      if (expiryDate.isAfter(now)) {
        await _scheduleNotification(
          id: item.id.hashCode + 2,
          title: 'Item Expired',
          body: '${item.name} has expired today',
          scheduledDate: expiryDate,
          payload: 'expired_${item.id}',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule expiry notification: $e');
    }
  }

  /// Cancel expiry notifications for a grocery item
  ///
  /// [itemId] - The ID of the item to cancel notifications for
  Future<void> cancelExpiryNotifications(String itemId) async {
    try {
      final baseId = itemId.hashCode;
      await _localNotifications.cancel(baseId);
      await _localNotifications.cancel(baseId + 1);
      await _localNotifications.cancel(baseId + 2);
    } catch (e) {
      debugPrint('Failed to cancel expiry notifications: $e');
    }
  }

  /// Schedule a local notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'expiry_reminders',
          'Expiry Reminders',
          channelDescription: 'Notifications for items expiring soon',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use zonedSchedule with TZDateTime conversion
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show immediate notification
  ///
  /// [title] - Notification title
  /// [body] - Notification body
  /// [payload] - Optional payload data
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'StayFresh',
        body: message.notification!.body ?? 'You have a new notification',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    // TODO: Navigate to appropriate screen based on message data
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Convert DateTime to TZDateTime for scheduling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Convert DateTime to TZDateTime using local timezone
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to FCM topic
  ///
  /// [topic] - Topic name to subscribe to
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from FCM topic
  ///
  /// [topic] - Topic name to unsubscribe from
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message processing here
}
