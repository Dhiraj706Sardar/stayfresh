import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/grocery_item.dart';
import '../services/supabase_storage_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

/// ViewModel for managing grocery items following MVVM pattern
/// 
/// This ViewModel handles all business logic related to grocery items
/// including CRUD operations, image uploads, and state management.
/// Views should interact with this ViewModel, not directly with services.
/// 
/// Usage:
/// - Add item: await groceryViewModel.addItemWithImage(item, imageFile)
/// - Get items: groceryViewModel.items
/// - Listen to changes: Consumer&lt;GroceryViewModel&gt;(...)
class GroceryViewModel extends ChangeNotifier {
  // Private fields
  List<GroceryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _isUploading = false;

  // Services
  final SupabaseStorageService _storageService = SupabaseStorageService.instance;
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  // Getters
  List<GroceryItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUploading => _isUploading;

  /// Get items filtered by expiry status
  List<GroceryItem> get expiredItems => 
      _items.where((item) => item.expiryStatus == ExpiryStatus.expired).toList();
  
  List<GroceryItem> get expiringSoonItems => 
      _items.where((item) => item.expiryStatus == ExpiryStatus.expiringSoon).toList();
  
  List<GroceryItem> get freshItems => 
      _items.where((item) => item.expiryStatus == ExpiryStatus.fresh).toList();

  /// Initialize the ViewModel (load existing items)
  Future<void> initialize() async {
    await loadItems();
  }

  /// Load items from Firestore database
  Future<void> loadItems() async {
    _setLoading(true);
    _clearError();

    try {
      // Check if user is authenticated
      if (!_authService.isSignedIn) {
        // If not authenticated, sign in anonymously for demo purposes
        await _authService.signInAnonymously();
      }

      // Load items from Firestore
      _items = await _firestoreService.getAllGroceryItems();
      notifyListeners();
    } catch (e) {
      // If Firestore fails, fall back to dummy data for demo
      debugPrint('Failed to load from Firestore, using dummy data: $e');
      _items = _generateDummyItems();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new grocery item with optional image upload
  /// 
  /// [item] - The grocery item to add
  /// [imageFile] - Optional image file to upload
  /// 
  /// This method handles the complete flow:
  /// 1. Upload image if provided
  /// 2. Update item with image URL
  /// 3. Save item to database
  /// 4. Schedule expiry notification
  Future<void> addItemWithImage(GroceryItem item, File? imageFile) async {
    _setUploading(true);
    _clearError();

    try {
      GroceryItem finalItem = item;

      // Upload image if provided
      if (imageFile != null) {
        // Get actual user ID from authentication service
        final userId = _authService.currentUserId ?? 'anonymous';
        
        // Generate remote path for the image
        final extension = getFileExtension(imageFile.path);
        final remotePath = getImageRemotePath(userId, item.id, extension);

        // Upload image to Supabase Storage
        final imageUrl = await _storageService.uploadImage(imageFile, remotePath);
        
        // Update item with image URL
        finalItem = item.copyWith(imageUrl: imageUrl);
      }

      // Save to Firestore and add to local list
      await addItem(finalItem);

      // Schedule expiry notification
      await _notificationService.scheduleExpiryNotification(finalItem);

    } catch (e) {
      _setError('Failed to add item: $e');
      rethrow; // Re-throw so UI can handle the error
    } finally {
      _setUploading(false);
    }
  }

  /// Add item to the list (without image upload)
  /// 
  /// [item] - The grocery item to add
  Future<void> addItem(GroceryItem item) async {
    try {
      // Save to Firestore
      await _firestoreService.addGroceryItem(item);

      // Add to local list
      _items.add(item);
      _sortItemsByExpiryDate();
      notifyListeners();

    } catch (e) {
      _setError('Failed to save item: $e');
      rethrow;
    }
  }

  /// Update an existing grocery item
  /// 
  /// [updatedItem] - The updated grocery item
  /// [newImageFile] - Optional new image file to upload
  Future<void> updateItem(GroceryItem updatedItem, {File? newImageFile}) async {
    _setUploading(newImageFile != null);
    _clearError();

    try {
      GroceryItem finalItem = updatedItem;

      // Upload new image if provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (updatedItem.imageUrl != null) {
          await _deleteImageFromUrl(updatedItem.imageUrl!);
        }

        // Upload new image
        final userId = _authService.currentUserId ?? 'anonymous';
        final extension = getFileExtension(newImageFile.path);
        final remotePath = getImageRemotePath(userId, updatedItem.id, extension);
        
        final imageUrl = await _storageService.uploadImage(newImageFile, remotePath);
        finalItem = updatedItem.copyWith(imageUrl: imageUrl);
      }

      // Update in Firestore
      await _firestoreService.updateGroceryItem(finalItem);

      // Update in local list
      final index = _items.indexWhere((item) => item.id == finalItem.id);
      if (index != -1) {
        _items[index] = finalItem;
        _sortItemsByExpiryDate();
        notifyListeners();
      }

    } catch (e) {
      _setError('Failed to update item: $e');
      rethrow;
    } finally {
      _setUploading(false);
    }
  }

  /// Delete a grocery item
  /// 
  /// [itemId] - The ID of the item to delete
  Future<void> deleteItem(String itemId) async {
    _clearError();

    try {
      final item = _items.firstWhere((item) => item.id == itemId);
      
      // Delete image if exists
      if (item.imageUrl != null) {
        await _deleteImageFromUrl(item.imageUrl!);
      }

      // Delete from Firestore
      await _firestoreService.deleteGroceryItem(itemId);

      // Cancel expiry notifications
      await _notificationService.cancelExpiryNotifications(itemId);

      // Remove from local list
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();

    } catch (e) {
      _setError('Failed to delete item: $e');
      rethrow;
    }
  }

  /// Get a specific item by ID
  GroceryItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search items by name
  List<GroceryItem> searchItems(String query) {
    if (query.isEmpty) return items;
    
    return _items.where((item) => 
      item.name.toLowerCase().contains(query.toLowerCase()) ||
      item.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Clear all error states
  void clearError() {
    _clearError();
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _sortItemsByExpiryDate() {
    _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// Extract image path from Supabase URL and delete it
  Future<void> _deleteImageFromUrl(String imageUrl) async {
    try {
      // Extract path from URL
      // Supabase URLs typically look like: https://project.supabase.co/storage/v1/object/public/bucket/path
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name and extract the path after it
      final bucketIndex = pathSegments.indexOf(supabaseStorageBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final imagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _storageService.deleteImage(imagePath);
      }
    } catch (e) {
      // Log error but don't throw - deletion failure shouldn't block other operations
      debugPrint('Failed to delete image: $e');
    }
  }

  /// Generate dummy data for testing
  /// TODO: Remove this when database integration is complete
  List<GroceryItem> _generateDummyItems() {
    final now = DateTime.now();
    return [
      GroceryItem(
        id: '1',
        name: 'Fresh Milk',
        quantity: 1,
        category: 'Dairy',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 5)),
      ),
      GroceryItem(
        id: '2',
        name: 'Organic Bananas',
        quantity: 6,
        category: 'Fruits',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 2)),
      ),
      GroceryItem(
        id: '3',
        name: 'Whole Wheat Bread',
        quantity: 1,
        category: 'Bakery',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 7)),
      ),
      GroceryItem(
        id: '4',
        name: 'Greek Yogurt',
        quantity: 4,
        category: 'Dairy',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 10)),
      ),
      GroceryItem(
        id: '5',
        name: 'Fresh Spinach',
        quantity: 1,
        category: 'Vegetables',
        addedDate: now,
        expiryDate: now.add(const Duration(days: 3)),
      ),
    ];
  }
}