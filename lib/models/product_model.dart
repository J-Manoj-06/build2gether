/// Product model for marketplace
///
/// Represents agricultural equipment, tools, or supplies available for rent/purchase.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'equipment', 'seeds', 'tools', 'fertilizer'
  final String productType; // 'crop', 'tool', 'fertilizer', 'equipment'
  final double price;
  final String priceType; // 'per_day', 'per_hour', 'fixed'
  final String ownerId;
  final String ownerName;
  final List<String> imageUrls;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime? updatedAt;
  double? distance; // Calculated distance from user (in km)

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.productType,
    required this.price,
    required this.priceType,
    required this.ownerId,
    required this.ownerName,
    required this.imageUrls,
    this.location,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    this.stockQuantity = 1,
    required this.createdAt,
    this.updatedAt,
    this.distance,
  });

  /// Creates ProductModel from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle both old and new field names for backward compatibility
    final name = data['name'] ?? data['productName'] ?? 'Unnamed Product';
    final ownerId = data['ownerId'] ?? data['sellerId'] ?? '';
    final stockQuantity = data['stockQuantity'] ?? data['quantity'] ?? 1;

    // Handle both single imageUrl and imageUrls array
    List<String> imageUrls = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      imageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null && data['imageUrl'] is String) {
      imageUrls = [data['imageUrl'] as String];
    }

    print(
      'DEBUG ProductModel.fromFirestore: id=${doc.id}, name=$name, imageUrls=$imageUrls, price=${data['price']}',
    );

    return ProductModel(
      id: doc.id,
      name: name,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      productType: data['productType'] ?? 'crop', // Default to crop if not set
      price: (data['price'] ?? 0).toDouble(),
      priceType: data['priceType'] ?? 'fixed',
      ownerId: ownerId,
      ownerName: data['ownerName'] ?? 'Unknown',
      imageUrls: imageUrls,
      location: data['location'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      stockQuantity: stockQuantity,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts ProductModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'productType': productType,
      'price': price,
      'priceType': priceType,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'imageUrls': imageUrls,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Creates a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? productType,
    double? price,
    String? priceType,
    String? ownerId,
    String? ownerName,
    List<String>? imageUrls,
    String? location,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distance,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, category: $category, price: $price)';
  }
}
