/// User Service
///
/// Handles user profile operations including roles and location
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's roles
  ///
  /// Returns list of roles: ["farmer", "buyer", "seller", "renter"]
  /// Returns empty list if user not found or not authenticated
  Future<List<String>> getUserRoles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null || !data.containsKey('roles')) {
        return [];
      }

      return List<String>.from(data['roles'] ?? []);
    } catch (e) {
      print('Error getting user roles: $e');
      return [];
    }
  }

  /// Get current user's complete profile
  ///
  /// Returns map containing:
  /// - roles: List<String>
  /// - latitude: double
  /// - longitude: double
  /// - name: String
  /// - email: String
  /// - phoneNumber: String
  /// Returns null if user not found
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return {
        'roles': List<String>.from(data['roles'] ?? []),
        'latitude': (data['latitude'] ?? 0.0).toDouble(),
        'longitude': (data['longitude'] ?? 0.0).toDouble(),
        'name': data['name'] ?? '',
        'email': data['email'] ?? user.email ?? '',
        'phoneNumber': data['phoneNumber'] ?? '',
        'profileCompleted': data['profileCompleted'] ?? false,
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Get user's location coordinates
  ///
  /// Returns map with 'latitude' and 'longitude'
  /// Returns null if user not found or coordinates not set
  Future<Map<String, double>?> getUserLocation() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) {
        return null;
      }

      return {
        'latitude': profile['latitude'] as double,
        'longitude': profile['longitude'] as double,
      };
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  /// Check if user has a specific role
  ///
  /// Returns true if user has the specified role
  Future<bool> hasRole(String role) async {
    final roles = await getUserRoles();
    return roles.contains(role.toLowerCase());
  }

  /// Get current user ID
  ///
  /// Returns user ID or null if not authenticated
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
