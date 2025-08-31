import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_auth_service.dart';
import 'theme/theme_provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/grocery_viewmodel.dart';
import 'services/local_database_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'utils/env_config.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';

/// 🔹 Background message handler (runs in its own isolate)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // In background isolate, duplicate-app is not a real issue, so ignore it
    if (e is FirebaseException && e.code == 'duplicate-app') {
      debugPrint('⚠️ Firebase already initialized in background isolate.');
    } else {
      debugPrint('❌ Firebase init error in background: $e');
    }
  }

  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

/// 🔹 Safe Firebase initialization
Future<void> _ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint(
        '⚠️ Firebase already initialized (${Firebase.apps.length} apps)',
      );
    }
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      debugPrint('⚠️ Firebase app already exists, continuing...');
    } else {
      debugPrint('❌ Firebase initialization error: $e');
      rethrow;
    }
  }
}

/// 🔹 Main entry point
Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 Starting app initialization...');

  try {
    // 1️⃣ Local database
    try {
      await LocalDatabaseService.initialize();
      debugPrint('✅ Local database initialized');
    } catch (e) {
      debugPrint('⚠️ Local database initialization failed: $e');
    }

    // 2️⃣ Firebase
    try {
      await _ensureFirebaseInitialized();
      debugPrint('✅ Firebase initialized');

      // Enable persistence for Firebase Auth
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('✅ Firebase Auth persistence enabled');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
    }

    // 3️⃣ FCM background handler
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ FCM background handler set');
    } catch (e) {
      debugPrint('⚠️ FCM background handler setup failed: $e');
    }

    // 4️⃣ Environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment variables loaded from .env');
    } catch (_) {
      debugPrint('⚠️ No .env file found, using constants from constants.dart');
    }

    // 5️⃣ Supabase
    try {
      // Check if configuration is available
      if (EnvConfig.isConfigured) {
        await supabase.Supabase.initialize(
          url: EnvConfig.supabaseUrl,
          anonKey: EnvConfig.supabaseAnonKey,
        );
        debugPrint('✅ Supabase initialized');
        debugPrint('📊 Config status: ${EnvConfig.configStatus}');
      } else {
        debugPrint(
          '⚠️ Supabase credentials not configured, skipping initialization',
        );
        debugPrint('📊 Config status: ${EnvConfig.configStatus}');
      }
    } catch (e) {
      debugPrint('⚠️ Supabase initialization failed: $e');
    }

    // 6️⃣ FCM + Notifications (Initialize separately to isolate errors)
    try {
      await FCMService.instance.initialize();
      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      debugPrint('⚠️ FCM Service initialization failed: $e');
    }

    try {
      await NotificationService.instance.initialize();
      debugPrint('✅ Notification Service initialized');
    } catch (e) {
      debugPrint('⚠️ Notification Service initialization failed: $e');
    }

    // Initialize theme provider
    final prefs = await SharedPreferences.getInstance();

    // Initialize Firebase Auth Service
    final authService = FirebaseAuthService.instance;

    // Check if user has a valid token
    final hasToken = await authService.hasValidToken();

    runApp(
      MultiProvider(
        providers: [
          Provider<FirebaseAuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(
            create: (_) => GroceryViewModel()..initialize(),
          ),
        ],
        child: StayFreshApp(initialRoute: hasToken ? '/home' : '/login'),
      ),
    );
  } catch (e) {
    debugPrint('❌ Critical error during app initialization: $e');
    debugPrint('📱 Running app with limited functionality...');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

void main() async {
  await _initializeApp();
}

/// 🔹 Main App Widget
class StayFreshApp extends StatelessWidget {
  final String initialRoute;

  const StayFreshApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Using the singleton instance of FirebaseAuthService
        Provider<FirebaseAuthService>.value(
          value: FirebaseAuthService.instance,
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GroceryViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'StayFresh',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
