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
import '../../services/ai_marketplace_service.dart';
import 'product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  // Services
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIMarketplaceService _aiService = AIMarketplaceService();

  // State variables
  List<ProductModel> _products = [];
  List<ProductModel> _recommendedProducts = [];
  List<String> _roles = [];
  List<String> _aiRecommendedCategories = [];
  List<String> _crops = [];
  double? _userLat;
  double? _userLng;
  String? _currentUserId;
  String? _location;
  bool _loading = true;
  bool _loadingRecommendations = true;

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
      _loadingRecommendations = true;
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
      
      // Get crops array (new system)
      if (profile['crops'] != null && profile['crops'] is List) {
        _crops = List<String>.from(profile['crops']);
      } 
      // Fallback to old system for backwards compatibility
      else if (profile['cropType'] != null) {
        _crops = [profile['cropType'] as String];
      } else {
        _crops = ['General'];
      }
      
      _location = profile['location'] as String? ?? 'Unknown';

      // Load AI recommendations in parallel
      _loadAIRecommendations();

      // Step 2: Fetch products from Firestore
      print('DEBUG Marketplace: Fetching products from Firestore...');
      final querySnapshot = await _firestore.collection('products').get();
      print(
        'DEBUG Marketplace: Found ${querySnapshot.docs.length} products in database',
      );

      List<ProductModel> products = [];
      for (var doc in querySnapshot.docs) {
        try {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('DEBUG: Processing product document ${doc.id}');
          print('DEBUG: Raw data: ${doc.data()}');
          final product = ProductModel.fromFirestore(doc);
          print('DEBUG: ✅ Parsed product successfully:');
          print('  - Name: ${product.name}');
          print('  - Price: ₹${product.price}');
          print('  - Category: ${product.category}');
          print('  - ProductType: ${product.productType}');
          print('  - Images: ${product.imageUrls.length} image(s)');
          if (product.imageUrls.isNotEmpty) {
            print('  - First Image URL: ${product.imageUrls.first}');
          }
          print('  - Owner: ${product.ownerName} (${product.ownerId})');

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
            print('  - Distance: ${product.distance!.toStringAsFixed(2)} km');
          } else {
            print('  - Distance: Not available (missing coordinates)');
          }
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          products.add(product);
        } catch (e, stackTrace) {
          print('❌ Error parsing product ${doc.id}: $e');
          print('Stack trace: $stackTrace');
        }
      }

      // Step 3: Filter products by role
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(
        'DEBUG Marketplace: Total products before filtering: ${products.length}',
      );
      print('DEBUG Marketplace: User roles: $_roles');
      products = _filterProductsByRole(products);
      print(
        'DEBUG Marketplace: Total products after filtering: ${products.length}',
      );

      // Step 4: Sort by distance (nearest first)
      products.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
      print('DEBUG Marketplace: Products sorted by distance');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading marketplace: $e');
      print('Stack trace: $stackTrace');
      _showError('Error loading marketplace: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  /// Load AI-powered recommendations
  Future<void> _loadAIRecommendations() async {
    try {
      // Get AI recommended categories
      _aiRecommendedCategories = await _aiService.getRecommendedCategories(
        crops: _crops.isEmpty ? ['General'] : _crops,
        location: _location ?? 'Unknown',
        roles: _roles,
      );

      if (_aiRecommendedCategories.isEmpty) {
        setState(() {
          _loadingRecommendations = false;
        });
        return;
      }

      // Query Firestore for recommended products
      final querySnapshot = await _firestore
          .collection('products')
          .where('productType', whereIn: _aiRecommendedCategories)
          .limit(10)
          .get();

      List<ProductModel> recommendations = [];
      for (var doc in querySnapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);

          // Calculate distance
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
            product.distance = distanceInMeters / 1000;
          }

          recommendations.add(product);
        } catch (e) {
          print('Error parsing recommended product ${doc.id}: $e');
        }
      }

      // Sort by distance
      recommendations.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });

      setState(() {
        _recommendedProducts = recommendations;
        _loadingRecommendations = false;
      });
    } catch (e) {
      print('Error loading AI recommendations: $e');
      setState(() {
        _loadingRecommendations = false;
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Recommended Section
            if (_recommendedProducts.isNotEmpty) ...[
              _buildRecommendedSection(),
              const SizedBox(height: 24),
            ],

            // All Products Section
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Products grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended For You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Powered by AI',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal scroll of products
        SizedBox(
          height: 240,
          child: _loadingRecommendations
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedProducts.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildRecommendedProductCard(
                        _recommendedProducts[index],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendedProductCard(ProductModel product) {
    final isMyListing = product.ownerId == _currentUserId;

    // Debug logging
    print(
      '🌟 Rendering recommended product: ${product.name} with ${product.imageUrls.length} images',
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              color: lightGreen,
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 100,
                          color: lightGreen,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Error loading recommended image: $error');
                        return const Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
            ),
          ),

          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    '₹${product.price}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(),

                  // Distance or My Listing badge
                  if (isMyListing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'My Listing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (product.distance != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.distance!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isOwnListing = product.ownerId == _currentUserId;

    // Debug logging for image display
    if (product.imageUrls.isEmpty) {
      print('⚠️ Product ${product.name} has no images');
    } else {
      print(
        '📸 Product ${product.name} has ${product.imageUrls.length} image(s): ${product.imageUrls.first}',
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 120,
                              color: lightGreen,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        primaryColor,
                                      ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '❌ Error loading image for ${product.name}: $error',
                            );
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Location name
                  if (product.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 12,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.location!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (product.location != null) const SizedBox(height: 4),

                  // Distance
                  if (product.distance != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.distance!.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Rental price with type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              ' / ${_getPriceTypeLabel(product.priceType)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceTypeLabel(String priceType) {
    switch (priceType.toLowerCase()) {
      case 'per_hour':
        return 'hour';
      case 'per_day':
        return 'day';
      default:
        return 'fixed';
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 120,
      color: lightGreen,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: primaryColor),
      ),
    );
  }
}
