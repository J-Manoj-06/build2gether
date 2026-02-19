/// Farmer Onboarding Page
///
/// Collects farmer details on first login
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../main/main_page.dart';

class FarmerOnboardingPage extends StatefulWidget {
  const FarmerOnboardingPage({super.key});

  @override
  State<FarmerOnboardingPage> createState() => _FarmerOnboardingPageState();
}

class _FarmerOnboardingPageState extends State<FarmerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _landSizeController = TextEditingController();

  // Multi-crop selection
  final List<String> _selectedCrops = [];
  final TextEditingController _customCropController = TextEditingController();

  // Multi-role selection
  final Map<String, bool> _selectedRoles = {
    'Farmer': false,
    'Buyer': false,
    'Seller': false,
    'Renter': false,
  };

  String _selectedExperience = 'Beginner';
  bool _isLoading = false;
  bool _fetchingLocation = false;

  final List<String> _roles = ['Farmer', 'Buyer', 'Seller', 'Renter'];

  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Expert'];

  // Check if crop field is needed (Farmer or Seller)
  bool _needsCropField() {
    return _selectedRoles['Farmer'] == true || _selectedRoles['Seller'] == true;
  }

  // Check if land size is needed (only Farmer)
  bool _needsLandSize() {
    return _selectedRoles['Farmer'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _landSizeController.dispose();
    _customCropController.dispose();
    super.dispose();
  }

  /// Get current GPS location and reverse geocode to location name
  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Please enter location manually.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _fetchingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get location name
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String locationName = '';

        if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = place.locality!;
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          if (locationName.isNotEmpty) {
            locationName += ', ${place.administrativeArea}';
          } else {
            locationName = place.administrativeArea!;
          }
        }

        setState(() {
          _locationController.text = locationName;
          _fetchingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location detected: $locationName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _fetchingLocation = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveFarmerProfile() async {
    // Check if at least one role is selected
    if (!_selectedRoles.values.any((selected) => selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if crops are selected when needed
    if (_needsCropField() && _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one crop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get selected roles as list
      final List<String> roles = _selectedRoles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Convert location to coordinates using geocoding
      final locationText = _locationController.text.trim();
      double? latitude;
      double? longitude;

      try {
        final locations = await locationFromAddress(locationText);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        }
      } catch (e) {
        // Geocoding failed
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not find location: $locationText. Please enter a valid city or location.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Build profile data
      final Map<String, dynamic> profileData = {
        'name': _nameController.text.trim(),
        'email': currentUser.email,
        'roles': roles,
        'locationName': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'experience': _selectedExperience,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add conditional fields based on roles
      if (_needsCropField()) {
        profileData['crops'] = _selectedCrops;
        // Also save first crop as cropType for backwards compatibility
        profileData['cropType'] = _selectedCrops.isNotEmpty
            ? _selectedCrops.first
            : 'General';
      }
      if (_needsLandSize()) {
        profileData['landSize'] = _landSizeController.text.trim();
      }

      // Save profile to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(profileData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to MainPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Icon
                  const Icon(
                    Icons.agriculture,
                    size: 80,
                    color: Color(0xFF1B5E20),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Tell Us About Your Farm',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Help us personalize your experience',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Full Name Field
                  _buildInputField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    hint: 'Enter your full name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Role Selection (Multiple Checkboxes)
                  _buildRoleCheckboxes(),

                  const SizedBox(height: 16),

                  // Location Field with GPS button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _locationController,
                              label: 'Farm Location',
                              icon: Icons.location_on_outlined,
                              hint: 'City, State',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your location';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // GPS Button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _fetchingLocation
                                    ? null
                                    : _getCurrentLocation,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: _fetchingLocation
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'Tap 📍 to use GPS location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Crop Selection (Show only if Farmer or Seller selected)
                  if (_needsCropField())
                    Column(
                      children: [
                        _buildCropSelectionSection(),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Land Size Field (Show only if Farmer selected)
                  if (_needsLandSize())
                    Column(
                      children: [
                        _buildInputField(
                          controller: _landSizeController,
                          label: 'Land Size (in acres)',
                          icon: Icons.square_foot_outlined,
                          hint: 'Enter land size',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_needsLandSize() &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter land size';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Experience Level
                  _buildDropdownField(
                    label: 'Experience Level',
                    icon: Icons.school_outlined,
                    value: _selectedExperience,
                    items: _experienceLevels,
                    onChanged: (value) {
                      setState(() {
                        _selectedExperience = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveFarmerProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B5E20),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCheckboxes() {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 20,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Role(s)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select all that apply',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Checkboxes
            ..._roles.map((role) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  role,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _selectedRoles[role],
                activeColor: const Color(0xFF2E7D32),
                onChanged: (bool? value) {
                  setState(() {
                    _selectedRoles[role] = value ?? false;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: value,
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B5E20),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build crop selection section with chips
  Widget _buildCropSelectionSection() {
    // Available crop options
    final List<String> availableCrops = [
      'Rice',
      'Wheat',
      'Maize',
      'Sugarcane',
      'Cotton',
      'Millets',
      'Vegetables',
      'Fruits',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 20,
                  color: const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Your Crops',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose all crops you grow',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Crop chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Available crop chips
                ...availableCrops.map((crop) {
                  final isSelected = _selectedCrops.contains(crop);
                  return FilterChip(
                    label: Text(crop),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCrops.add(crop);
                        } else {
                          _selectedCrops.remove(crop);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFE8F5E9),
                    checkmarkColor: const Color(0xFF1B5E20),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  );
                }).toList(),

                // Add custom crop button
                ActionChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Add Custom'),
                    ],
                  ),
                  onPressed: _showAddCustomCropDialog,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[400]!),
                  labelStyle: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),

            // Show selected count
            if (_selectedCrops.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedCrops.length} ${_selectedCrops.length == 1 ? 'crop' : 'crops'} selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show dialog to add custom crop
  void _showAddCustomCropDialog() {
    _customCropController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF1B5E20)),
            SizedBox(width: 12),
            Text('Add Custom Crop'),
          ],
        ),
        content: TextField(
          controller: _customCropController,
          decoration: InputDecoration(
            labelText: 'Crop Name',
            hintText: 'e.g., Turmeric, Pulses',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              final cropName = _customCropController.text.trim();
              if (cropName.isNotEmpty && !_selectedCrops.contains(cropName)) {
                setState(() {
                  _selectedCrops.add(cropName);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$cropName added successfully'),
                    backgroundColor: const Color(0xFF1B5E20),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (_selectedCrops.contains(cropName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This crop is already selected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
