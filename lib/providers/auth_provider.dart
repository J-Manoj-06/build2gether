/// Authentication Provider
/// 
/// Manages authentication state using Provider pattern.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  
  /// Initialize auth provider and listen to auth changes
  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }
  
  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    if (user != null) {
      // Load user model from Firestore
      await _loadUserModel(user.uid);
    } else {
      _userModel = null;
    }
    
    notifyListeners();
  }
  
  /// Load user model from Firestore
  Future<void> _loadUserModel(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);
      notifyListeners();
    } catch (e) {
      print('Failed to load user model: $e');
    }
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Register with email and password
  Future<bool> registerWithEmail(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // Create Firebase user
      final user = await _authService.registerWithEmail(email, password);
      
      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(userModel);
      
      // Update display name
      await _authService.updateDisplayName(name);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final user = await _authService.signInWithGoogle();
      
      // Check if user document exists, if not create one
      final existingUser = await _firestoreService.getUser(user.uid);
      
      if (existingUser == null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          role: 'farmer', // Default role
          profileImageUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        
        await _firestoreService.saveUser(userModel);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userModel = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_firebaseUser == null) return false;
    
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _firestoreService.updateUser(_firebaseUser!.uid, data);
      await _loadUserModel(_firebaseUser!.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
