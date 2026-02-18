/// Firestore Service
/// 
/// Handles all Firestore database operations for users, products, and bookings.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../core/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ============= USER OPERATIONS =============
  
  /// Create or update user document in Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user: ${e.toString()}');
    }
  }
  
  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }
  
  /// Update user fields
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }
  
  /// Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }
  
  // ============= PRODUCT OPERATIONS =============
  
  /// Create new product
  Future<String> createProduct(ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }
  
  /// Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();
      
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch product: ${e.toString()}');
    }
  }
  
  /// Get all products (with optional filtering)
  Stream<List<ProductModel>> getProducts({
    String? category,
    String? ownerId,
    bool? isAvailable,
    int limit = AppConstants.itemsPerPage,
  }) {
    try {
      Query query = _firestore.collection(AppConstants.productsCollection);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      
      if (isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: isAvailable);
      }
      
      query = query.orderBy('createdAt', descending: true).limit(limit);
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }
  
  /// Search products by name or description
  Future<List<ProductModel>> searchProducts(String searchTerm) async {
    try {
      // Note: For better search, consider using Algolia or Elasticsearch
      // This is a basic implementation
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) {
            final term = searchTerm.toLowerCase();
            return product.name.toLowerCase().contains(term) ||
                   product.description.toLowerCase().contains(term) ||
                   product.category.toLowerCase().contains(term);
          })
          .toList();
      
      return products;
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }
  
  /// Update product
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }
  
  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }
  
  // ============= BOOKING OPERATIONS =============
  
  /// Create booking
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    try {
      bookingData['createdAt'] = Timestamp.now();
      bookingData['status'] = 'pending';
      
      final docRef = await _firestore
          .collection(AppConstants.bookingsCollection)
          .add(bookingData);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }
  
  /// Get user's bookings
  Stream<List<Map<String, dynamic>>> getUserBookings(String userId) {
    try {
      return _firestore
          .collection(AppConstants.bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to fetch bookings: ${e.toString()}');
    }
  }
  
  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
            'status': status,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }
}
