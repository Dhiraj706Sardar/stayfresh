/// Application constants and configuration
library;

/// Application constants with actual configuration values
///
/// Configuration priority:
/// 1. Environment variables from .env file (RECOMMENDED for sensitive data)
/// 2. These constants as fallback values
///
/// These constants contain your actual project credentials and serve as
/// fallback values when .env file is not available or missing values.

// Supabase Configuration (Fallback values - use .env for actual credentials)
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const String supabaseStorageBucket = 'item_images'; // Storage bucket name

// Firebase Configuration (Fallback values - use .env for actual credentials)
const String firebaseWebApiKey = 'YOUR_FIREBASE_WEB_API_KEY';
const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
const String firebaseStorageBucket = 'YOUR_FIREBASE_STORAGE_BUCKET';
const String firebaseMessagingSenderId = 'YOUR_FIREBASE_MESSAGING_SENDER_ID';

// App Configuration
const String appName = 'StayFresh';
const String appVersion = '1.0.0';

// Storage Configuration
const int maxImageSizeMb = 5;
const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

// Notification Configuration
const int defaultExpiryReminderDays = 3;
const int urgentExpiryReminderDays = 1;

/// Remote path pattern for uploaded images
/// Example: images/{userId}/{itemId}.jpg
/// This ensures each user's images are organized in their own folder
String getImageRemotePath(String userId, String itemId, String extension) {
  return 'images/$userId/$itemId.$extension';
}

/// Get file extension from filename
String getFileExtension(String filename) {
  return filename.split('.').last.toLowerCase();
}
