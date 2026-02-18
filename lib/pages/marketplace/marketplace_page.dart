/// Marketplace Page - Role-Based with Location Sorting
///
/// Intelligent marketplace that shows different products based on user roles
/// and sorts by proximity
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/product_model.dart';
import '../../services/user_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  // Services
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  List<ProductModel> _products = [];
  List<String> _roles = [];
  double? _userLat;
  double? _userLng;
  String? _currentUserId;
  bool _loading = true;

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundLight = Color(0xFFF5F7F6);

  @override
  void initState() {
    super.initState();
    _loadMarketplace();
  }

  /// Load user profile and products
  Future<void> _loadMarketplace() async {
    setState(() {
      _loading = true;
    });

    try {
      // Step 1: Load user profile
      final profile = await _userService.getUserProfile();
      if (profile == null) {
        _showError('Unable to load user profile');
        return;
      }

      _roles = List<String>.from(profile['roles'] ?? []);
      _userLat = profile['latitude'] as double?;
      _userLng = profile['longitude'] as double?;
      _currentUserId = _userService.getCurrentUserId();

      // Step 2: Fetch products from Firestore
      final querySnapshot = await _firestore.collection('products').get();

      List<ProductModel> products = [];
      for (var doc in querySnapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          
          // Calculate distance if both user and product have coordinates
          if (_userLat != null && 
              _userLng != null && 
              product.latitude != null && 
              product.longitude != null) {
            final distanceInMeters = Geolocator.distanceBetween(
              _userLat!,
              _userLng!,
              product.latitude!,
              product.longitude!,
            );
            product.distance = distanceInMeters / 1000; // Convert to km
          }

          products.add(product);
        } catch (e) {
          print('Error parsing product ${doc.id}: $e');
        }
      }

      // Step 3: Filter products by role
      products = _filterProductsByRole(products);

      // Step 4: Sort by distance (nearest first)
      products.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      _showError('Error loading marketplace: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  /// Filter products based on user roles
  List<ProductModel> _filterProductsByRole(List<ProductModel> products) {
    if (_roles.isEmpty) {
      return products; // Show all if no roles
    }

    Set<String> allowedTypes = {};

    // Role-based filtering logic
    for (String role in _roles) {
      switch (role.toLowerCase()) {
        case 'farmer':
          // Farmers buy tools, fertilizers, equipment
          allowedTypes.addAll(['tool', 'fertilizer', 'equipment']);
          break;
        case 'buyer':
          // Buyers purchase crops
          allowedTypes.add('crop');
          break;
        case 'seller':
          // Sellers see all products
          allowedTypes.addAll(['crop', 'tool', 'fertilizer', 'equipment']);
          break;
        case 'renter':
          // Renters see equipment only
          allowedTypes.add('equipment');
          break;
      }
    }

    // Filter products
    return products.where((product) {
      return allowedTypes.contains(product.productType.toLowerCase());
    }).toList();
  }

  /// Get section title based on roles
  String _getSectionTitle() {
    if (_roles.isEmpty) return 'All Products';
    
    if (_roles.contains('buyer')) return 'Nearby Crops';
    if (_roles.contains('farmer')) return 'Farming Supplies';
    if (_roles.contains('renter')) return 'Equipment Near You';
    if (_roles.contains('seller')) return 'Marketplace Listings';
    
    return 'Products Near You';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMarketplace,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            )
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildProductList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No nearby items available for your role yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later or expand your search area.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadMarketplace,
      color: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSectionTitle(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_products.length} items found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Products grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isOwnListing = product.ownerId == _currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),

              // "My Listing" badge for sellers
              if (isOwnListing)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'My Listing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Product details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Distance
                  if (product.distance != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.distance!.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 120,
      color: lightGreen,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: primaryColor,
        ),
      ),
    );
  }
}
