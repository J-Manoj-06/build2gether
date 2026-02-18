/// Rental Request Model
///
/// Represents a rental request from farmer to equipment owner
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRequest {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String ownerId;
  final String renterId;
  final String renterName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  RentalRequest({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.ownerId,
    required this.renterId,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  /// Create RentalRequest from Firestore document
  factory RentalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RentalRequest(
      id: doc.id,
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? 'Unknown',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert RentalRequest to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'ownerId': ownerId,
      'renterId': renterId,
      'renterName': renterName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Calculate total rental days
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'orange';
    }
  }
}
