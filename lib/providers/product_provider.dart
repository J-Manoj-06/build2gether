/// Product Provider
/// 
/// Manages product state and operations using Provider pattern.
library;

import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  
  // Getters
  List<ProductModel> get products => _filteredProducts.isEmpty && _selectedCategory == null
      ? _products
      : _filteredProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  
  /// Load all products
  void loadProducts({String? category}) {
    _selectedCategory = category;
    _setLoading(true);
    
    _firestoreService.getProducts(category: category).listen(
      (productList) {
        _products = productList;
        _filteredProducts = productList;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }
  
  /// Load products by owner
  void loadProductsByOwner(String ownerId) {
    _setLoading(true);
    
    _firestoreService.getProducts(ownerId: ownerId).listen(
      (productList) {
        _products = productList;
        _filteredProducts = productList;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }
  
  /// Search products
  Future<void> searchProducts(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _filteredProducts = _products;
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    
    try {
      final results = await _firestoreService.searchProducts(searchTerm);
      _filteredProducts = results;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }
  
  /// Filter products by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    
    if (category == null) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) => product.category == category)
          .toList();
    }
    
    notifyListeners();
  }
  
  /// Filter products by availability
  void filterByAvailability(bool isAvailable) {
    _filteredProducts = _products
        .where((product) => product.isAvailable == isAvailable)
        .toList();
    
    notifyListeners();
  }
  
  /// Get product by ID
  Future<void> getProduct(String productId) async {
    _setLoading(true);
    
    try {
      _selectedProduct = await _firestoreService.getProduct(productId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }
  
  /// Create new product
  Future<bool> createProduct(ProductModel product) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _firestoreService.createProduct(product);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  /// Update product
  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _firestoreService.updateProduct(productId, data);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      await _firestoreService.deleteProduct(productId);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }
  
  /// Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _filteredProducts = _products;
    notifyListeners();
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
