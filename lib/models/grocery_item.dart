import 'package:hive/hive.dart';

part 'grocery_item.g.dart';

/// Model representing a grocery item in the StayFresh app
/// 
/// This model contains all the essential information about a grocery item
/// including its identification, details, dates, and optional image.
@HiveType(typeId: 1)
class GroceryItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String category;

  @HiveField(4)
  String? barcode;

  @HiveField(5)
  DateTime addedDate;

  @HiveField(6)
  DateTime expiryDate;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  bool isConsumed;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.barcode,
    required this.addedDate,
    required this.expiryDate,
    this.imageUrl,
    this.notes,
    this.isConsumed = false,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'barcode': barcode,
      'addedDate': addedDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  /// Create from Map (database retrieval)
  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      category: map['category'] as String,
      barcode: map['barcode'] as String?,
      addedDate: DateTime.parse(map['addedDate'] as String),
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON
  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem.fromMap(json);

  /// Create a copy with updated fields (immutable updates)
  GroceryItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? category,
    String? barcode,
    DateTime? addedDate,
    DateTime? expiryDate,
    String? imageUrl,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      addedDate: addedDate ?? this.addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Get days until expiry (negative if expired)
  int get daysUntilExpiry {
    final now = DateTime.now();
    final difference = expiryDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// Check if item is expired
  bool get isExpired => daysUntilExpiry < 0;

  /// Check if item is expiring soon (within 3 days)
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 3;

  /// Get expiry status for UI display
  ExpiryStatus get expiryStatus {
    if (isExpired) return ExpiryStatus.expired;
    if (isExpiringSoon) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.fresh;
  }

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, quantity: $quantity, category: $category, '
           'barcode: $barcode, addedDate: $addedDate, expiryDate: $expiryDate, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroceryItem &&
        other.id == id &&
        other.name == name &&
        other.quantity == quantity &&
        other.category == category &&
        other.barcode == barcode &&
        other.addedDate == addedDate &&
        other.expiryDate == expiryDate &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           name.hashCode ^
           quantity.hashCode ^
           category.hashCode ^
           barcode.hashCode ^
           addedDate.hashCode ^
           expiryDate.hashCode ^
           imageUrl.hashCode;
  }
}

/// Enum representing the expiry status of a grocery item
enum ExpiryStatus {
  fresh,
  expiringSoon,
  expired,
}