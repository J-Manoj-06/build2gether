/// Buyer Model
///
/// Represents a crop buyer with geocoding support
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class Buyer {
  final String id;
  final String companyName;
  final String cropInterested;
  final double requiredQuantity;
  final double latitude;
  final double longitude;
  final String locationName;
  final double rating;
  final String phone;

  // Calculated field
  double? distance;

  Buyer({
    required this.id,
    required this.companyName,
    required this.cropInterested,
    required this.requiredQuantity,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.rating,
    required this.phone,
    this.distance,
  });

  /// Create Buyer from Firestore document
  factory Buyer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Buyer(
      id: doc.id,
      companyName: data['companyName'] ?? '',
      cropInterested: data['cropInterested'] ?? '',
      requiredQuantity: (data['requiredQuantity'] ?? 0).toDouble(),
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      locationName: data['locationName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      phone: data['phone'] ?? '',
    );
  }

  /// Convert Buyer to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'companyName': companyName,
      'cropInterested': cropInterested,
      'requiredQuantity': requiredQuantity,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'rating': rating,
      'phone': phone,
    };
  }
}
