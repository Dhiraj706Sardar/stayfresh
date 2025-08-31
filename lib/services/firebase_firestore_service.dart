import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_item.dart';
import 'firebase_auth_service.dart';

/// Service for handling Firestore database operations
/// 
/// This service manages CRUD operations for grocery items in Firestore.
/// All operations are scoped to the current authenticated user.
/// 
/// Collection structure:
/// - users/{userId}/groceryItems/{itemId}
class FirebaseFirestoreService {
  static final FirebaseFirestoreService _instance = FirebaseFirestoreService._internal();
  static FirebaseFirestoreService get instance => _instance;
  
  FirebaseFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  /// Get the grocery items collection for the current user
  CollectionReference<Map<String, dynamic>> get _groceryItemsCollection {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('groceryItems');
  }

  /// Add a new grocery item
  /// 
  /// [item] - The grocery item to add
  /// 
  /// Returns the document ID of the created item
  Future<String> addGroceryItem(GroceryItem item) async {
    try {
      final docRef = await _groceryItemsCollection.add(item.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add grocery item: $e');
    }
  }

  /// Update an existing grocery item
  /// 
  /// [item] - The updated grocery item
  Future<void> updateGroceryItem(GroceryItem item) async {
    try {
      await _groceryItemsCollection.doc(item.id).update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update grocery item: $e');
    }
  }

  /// Delete a grocery item
  /// 
  /// [itemId] - The ID of the item to delete
  Future<void> deleteGroceryItem(String itemId) async {
    try {
      await _groceryItemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete grocery item: $e');
    }
  }

  /// Get a single grocery item by ID
  /// 
  /// [itemId] - The ID of the item to retrieve
  /// 
  /// Returns the grocery item or null if not found
  Future<GroceryItem?> getGroceryItem(String itemId) async {
    try {
      final doc = await _groceryItemsCollection.doc(itemId).get();
      if (doc.exists && doc.data() != null) {
        return GroceryItem.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get grocery item: $e');
    }
  }

  /// Get all grocery items for the current user
  /// 
  /// Returns a list of grocery items ordered by expiry date
  Future<List<GroceryItem>> getAllGroceryItems() async {
    try {
      final querySnapshot = await _groceryItemsCollection
          .orderBy('expiryDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Failed to get grocery items: $e');
    }
  }

  /// Get grocery items filtered by category
  /// 
  /// [category] - The category to filter by
  /// 
  /// Returns a list of grocery items in the specified category
  Future<List<GroceryItem>> getGroceryItemsByCategory(String category) async {
    try {
      final querySnapshot = await _groceryItemsCollection
          .where('category', isEqualTo: category)
          .orderBy('expiryDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Failed to get grocery items by category: $e');
    }
  }

  /// Get expired grocery items
  /// 
  /// Returns a list of expired grocery items
  Future<List<GroceryItem>> getExpiredGroceryItems() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _groceryItemsCollection
          .where('expiryDate', isLessThan: now.toIso8601String())
          .orderBy('expiryDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expired grocery items: $e');
    }
  }

  /// Get grocery items expiring soon (within specified days)
  /// 
  /// [days] - Number of days to look ahead (default: 3)
  /// 
  /// Returns a list of grocery items expiring soon
  Future<List<GroceryItem>> getGroceryItemsExpiringSoon({int days = 3}) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));
      
      final querySnapshot = await _groceryItemsCollection
          .where('expiryDate', isGreaterThanOrEqualTo: now.toIso8601String())
          .where('expiryDate', isLessThanOrEqualTo: futureDate.toIso8601String())
          .orderBy('expiryDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Failed to get grocery items expiring soon: $e');
    }
  }

  /// Stream of all grocery items for real-time updates
  /// 
  /// Returns a stream of grocery items ordered by expiry date
  Stream<List<GroceryItem>> streamGroceryItems() {
    try {
      return _groceryItemsCollection
          .orderBy('expiryDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream grocery items: $e');
    }
  }

  /// Search grocery items by name
  /// 
  /// [query] - The search query
  /// 
  /// Returns a list of grocery items matching the search query
  /// Note: Firestore doesn't support full-text search, so this uses array-contains
  /// for basic text matching. For better search, consider using Algolia or similar.
  Future<List<GroceryItem>> searchGroceryItems(String query) async {
    try {
      final querySnapshot = await _groceryItemsCollection.get();
      
      final allItems = querySnapshot.docs.map((doc) {
        return GroceryItem.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      // Client-side filtering for better search experience
      final searchQuery = query.toLowerCase();
      return allItems.where((item) {
        return item.name.toLowerCase().contains(searchQuery) ||
               item.category.toLowerCase().contains(searchQuery) ||
               (item.barcode?.contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search grocery items: $e');
    }
  }

  /// Batch delete multiple grocery items
  /// 
  /// [itemIds] - List of item IDs to delete
  Future<void> batchDeleteGroceryItems(List<String> itemIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final itemId in itemIds) {
        batch.delete(_groceryItemsCollection.doc(itemId));
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch delete grocery items: $e');
    }
  }

  /// Get grocery items count by category
  /// 
  /// Returns a map of category names to item counts
  Future<Map<String, int>> getItemCountByCategory() async {
    try {
      final querySnapshot = await _groceryItemsCollection.get();
      final Map<String, int> categoryCounts = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return categoryCounts;
    } catch (e) {
      throw Exception('Failed to get item count by category: $e');
    }
  }

  /// Clean up expired items (delete items expired for more than specified days)
  /// 
  /// [daysAfterExpiry] - Number of days after expiry to keep items (default: 30)
  /// 
  /// Returns the number of items deleted
  Future<int> cleanupExpiredItems({int daysAfterExpiry = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysAfterExpiry));
      
      final querySnapshot = await _groceryItemsCollection
          .where('expiryDate', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to cleanup expired items: $e');
    }
  }
}