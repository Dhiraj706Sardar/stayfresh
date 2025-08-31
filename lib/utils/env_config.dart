import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart' as constants;

/// Environment configuration utility
/// 
/// This class provides a centralized way to access environment variables
/// with fallback to constants. It ensures that sensitive data is loaded
/// from .env file when available, and falls back to constants for
/// development/testing purposes.
class EnvConfig {
  /// Get Supabase URL from environment or constants
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? constants.supabaseUrl;
  }

  /// Get Supabase anon key from environment or constants
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? constants.supabaseAnonKey;
  }

  /// Get Firebase Web API key from environment or constants
  static String get firebaseWebApiKey {
    return dotenv.env['FIREBASE_WEB_API_KEY'] ?? constants.firebaseWebApiKey;
  }

  /// Get Firebase project ID from environment or constants
  static String get firebaseProjectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? constants.firebaseProjectId;
  }

  /// Get Firebase storage bucket from environment or constants
  static String get firebaseStorageBucket {
    return dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? constants.firebaseStorageBucket;
  }

  /// Get Firebase messaging sender ID from environment or constants
  static String get firebaseMessagingSenderId {
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? constants.firebaseMessagingSenderId;
  }

  /// Check if we're in development mode
  static bool get isDebugMode {
    return dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  }

  /// Get app environment (development, staging, production)
  static String get appEnvironment {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Check if all required environment variables are configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' &&
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
           firebaseWebApiKey != 'YOUR_FIREBASE_WEB_API_KEY' &&
           firebaseProjectId != 'YOUR_FIREBASE_PROJECT_ID';
  }

  /// Get configuration status for debugging
  static Map<String, dynamic> get configStatus {
    return {
      'supabase_configured': supabaseUrl != 'YOUR_SUPABASE_URL',
      'firebase_configured': firebaseWebApiKey != 'YOUR_FIREBASE_WEB_API_KEY',
      'environment': appEnvironment,
      'debug_mode': isDebugMode,
      'fully_configured': isConfigured,
    };
  }
}