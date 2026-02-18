/// Farmer Onboarding Page
///
/// Collects farmer details on first login
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
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
  final _cropController = TextEditingController();
  final _landSizeController = TextEditingController();

  // Multi-role selection
  final Map<String, bool> _selectedRoles = {
    'Farmer': false,
    'Buyer': false,
    'Seller': false,
    'Renter': false,
  };

  String _selectedExperience = 'Beginner';
  bool _isLoading = false;

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
    _cropController.dispose();
    _landSizeController.dispose();
    super.dispose();
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
        profileData['primaryCrop'] = _cropController.text.trim();
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

                  // Location Field
                  _buildInputField(
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

                  const SizedBox(height: 16),

                  // Primary Crop Field (Show only if Farmer or Seller selected)
                  if (_needsCropField())
                    Column(
                      children: [
                        _buildInputField(
                          controller: _cropController,
                          label: 'Primary Crop',
                          icon: Icons.eco_outlined,
                          hint: 'e.g., Rice, Wheat, Cotton',
                          validator: (value) {
                            if (_needsCropField() &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter your primary crop';
                            }
                            return null;
                          },
                        ),
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
}
