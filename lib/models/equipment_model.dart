/// Equipment Model
///
/// Represents rental equipment available in the marketplace
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String name;
  final String description;
  final double pricePerDay;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final double latitude;
  final double longitude;
  final String locationName;
  final bool availability;
  final DateTime createdAt;
  double? distance; // Calculated distance from user (in km)

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerDay,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.availability,
    required this.createdAt,
    this.distance,
  });

  /// Create Equipment from Firestore document
  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      locationName: data['locationName'] ?? 'Unknown Location',
      availability: data['availability'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Equipment to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'pricePerDay': pricePerDay,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'availability': availability,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
