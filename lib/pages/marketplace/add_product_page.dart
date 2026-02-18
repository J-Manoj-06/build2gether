/// Add Product Page
///
/// Allows users to add products with image upload to Cloudinary
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  // State variables
  File? _selectedImage;
  String? _selectedCategory;
  String? _selectedProductType;
  String? _selectedPriceType;
  bool _loading = false;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Cloudinary service
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Categories
  final List<String> _categories = [
    'Seeds',
    'Fertilizers',
    'Tools',
    'Crops',
    'Equipment',
  ];

  // Product Types (for role-based filtering)
  final List<String> _productTypes = [
    'Crop',
    'Tool',
    'Fertilizer',
    'Equipment',
  ];

  // Price Types
  final List<String> _priceTypes = ['Fixed', 'Per Hour', 'Per Day'];

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: primaryColor),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Add product to Firestore
  Future<void> _addProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if image is selected
    if (_selectedImage == null) {
      _showSnackBar('Please select a product image', isError: true);
      return;
    }

    // Check if category is selected
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    // Check if product type is selected
    if (_selectedProductType == null) {
      _showSnackBar('Please select a product type', isError: true);
      return;
    }

    // Check if price type is selected
    if (_selectedPriceType == null) {
      _showSnackBar('Please select a price type', isError: true);
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Step 1: Upload image to Cloudinary
      _showSnackBar('Uploading image...');
      final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);

      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      // Step 2: Get current user ID and user details
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? 'Unknown User';
      final userLat = userData['latitude'] as double?;
      final userLng = userData['longitude'] as double?;
      final userLocation = userData['location'] as String?;

      // Step 3: Create product document
      _showSnackBar('Saving product...');
      print('DEBUG: Adding product with imageUrl: $imageUrl');

      // Convert price type to lowercase with underscore
      String priceTypeValue = 'fixed';
      if (_selectedPriceType == 'Per Hour') {
        priceTypeValue = 'per_hour';
      } else if (_selectedPriceType == 'Per Day') {
        priceTypeValue = 'per_day';
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stockQuantity': int.parse(_quantityController.text.trim()),
        'category': _selectedCategory,
        'productType': _selectedProductType!
            .toLowerCase(), // crop, tool, fertilizer, equipment
        'imageUrls': [imageUrl], // Array of image URLs
        'ownerId': userId,
        'ownerName': userName,
        'priceType': priceTypeValue, // fixed, per_hour, per_day
        'location': userLocation,
        'latitude': userLat,
        'longitude': userLng,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Product added successfully with correct field names');

      // Success!
      _showSnackBar('✅ Product added successfully!');

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Section
              _buildImageUploadSection(),

              const SizedBox(height: 24),

              // Product Name
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'Enter product name',
                icon: Icons.inventory_2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter product description',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price
              _buildTextField(
                controller: _priceController,
                label: 'Price (₹)',
                hint: 'Enter price',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Quantity
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity',
                hint: 'Enter available quantity',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price Type Dropdown
              _buildPriceTypeDropdown(),

              const SizedBox(height: 16),

              // Category Dropdown
              _buildCategoryDropdown(),

              const SizedBox(height: 16),

              // Product Type Dropdown
              _buildProductTypeDropdown(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.image, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Product Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Image Preview or Upload Button
          _selectedImage == null
              ? _buildImagePlaceholder()
              : _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: _showImageSourceDialog,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to select image',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From camera or gallery',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Change Image'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category, color: primaryColor),
          border: InputBorder.none,
        ),
        hint: const Text('Select category'),
        items: _categories.map((category) {
          return DropdownMenuItem(value: category, child: Text(category));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPriceTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _selectedPriceType,
        decoration: InputDecoration(
          labelText: 'Price Type',
          prefixIcon: Icon(Icons.attach_money, color: primaryColor),
          border: InputBorder.none,
          helperText: 'How the price is calculated',
          helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        hint: const Text('Select price type'),
        items: _priceTypes.map((type) {
          return DropdownMenuItem(value: type, child: Text(type));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPriceType = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a price type';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProductTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedProductType,
        decoration: InputDecoration(
          labelText: 'Product Type',
          prefixIcon: Icon(Icons.label, color: primaryColor),
          border: InputBorder.none,
          helperText: 'Used for role-based marketplace filtering',
          helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        hint: const Text('Select product type'),
        items: _productTypes.map((type) {
          return DropdownMenuItem(value: type, child: Text(type));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProductType = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a product type';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _addProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Adding Product...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Text(
                'Add Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
