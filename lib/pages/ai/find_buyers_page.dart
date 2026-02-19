/// Find Buyers Page
///
/// Real geo-based buyer discovery with distance calculation
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/buyer_model.dart';

class FindBuyersPage extends StatefulWidget {
  const FindBuyersPage({super.key});

  @override
  State<FindBuyersPage> createState() => _FindBuyersPageState();
}

class _FindBuyersPageState extends State<FindBuyersPage> {
  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Farmer profile data
  double? _farmerLat;
  double? _farmerLng;
  List<String> _farmerCrops = [];
  String? _selectedCropFilter; // For dropdown filter
  bool _loadingProfile = true;

  // Nearby radius in km
  final double _nearbyRadius = 20.0;

  @override
  void initState() {
    super.initState();
    _loadFarmerProfile();
  }

  /// Load farmer profile from Firestore
  Future<void> _loadFarmerProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _farmerLat = (data['latitude'] ?? 0).toDouble();
          _farmerLng = (data['longitude'] ?? 0).toDouble();

          // Get crops array (new system)
          if (data['crops'] != null && data['crops'] is List) {
            _farmerCrops = List<String>.from(data['crops']);
          }
          // Fallback to old system for backwards compatibility
          else if (data['primaryCrop'] != null) {
            _farmerCrops = [data['primaryCrop'] as String];
          }

          _loadingProfile = false;
        });

        print('DEBUG: Farmer crops loaded: $_farmerCrops');
      }
    } catch (e) {
      print('Error loading farmer profile: $e');
      setState(() => _loadingProfile = false);
    }
  }

  /// Calculate distance and filter buyers within radius
  List<Buyer> _processNearbyBuyers(List<Buyer> buyers) {
    if (_farmerLat == null || _farmerLng == null) return [];

    // Calculate distance for each buyer
    for (var buyer in buyers) {
      final distanceInMeters = Geolocator.distanceBetween(
        _farmerLat!,
        _farmerLng!,
        buyer.latitude,
        buyer.longitude,
      );
      buyer.distance = distanceInMeters / 1000; // Convert to km
    }

    // Filter within radius
    final nearbyBuyers = buyers.where((buyer) {
      return buyer.distance != null && buyer.distance! <= _nearbyRadius;
    }).toList();

    // Sort by distance (nearest first)
    nearbyBuyers.sort((a, b) => a.distance!.compareTo(b.distance!));

    return nearbyBuyers;
  }

  /// Launch phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'Find Crop Buyers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _farmerCrops.isEmpty
          ? _buildNoCropMessage()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('buyers')
                  .where(
                    'cropInterested',
                    whereIn: _farmerCrops.isEmpty ? [''] : _farmerCrops,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                // Convert to Buyer list
                List<Buyer> buyers = snapshot.data!.docs
                    .map((doc) => Buyer.fromFirestore(doc))
                    .toList();

                // Process nearby buyers
                final nearbyBuyers = _processNearbyBuyers(buyers);

                // Apply crop filter if selected
                final filteredBuyers =
                    _selectedCropFilter == null ||
                        _selectedCropFilter == 'All Crops'
                    ? nearbyBuyers
                    : nearbyBuyers
                          .where(
                            (buyer) =>
                                buyer.cropInterested == _selectedCropFilter,
                          )
                          .toList();

                if (filteredBuyers.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Crop filter dropdown
                    _buildCropFilterDropdown(),

                    // AI Suggestion Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nearby Buyers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Found ${filteredBuyers.length} buyers within 20 km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            _selectedCropFilter == null ||
                                    _selectedCropFilter == 'All Crops'
                                ? 'All Crop Buyers'
                                : 'Buyers for $_selectedCropFilter',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredBuyers.length} found',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Buyer List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredBuyers.length,
                        itemBuilder: (context, index) {
                          return _buildBuyerCard(filteredBuyers[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  /// Build buyer card
  Widget _buildBuyerCard(Buyer buyer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Buyer Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store, color: primaryColor, size: 28),
            ),

            const SizedBox(width: 14),

            // Buyer Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          buyer.companyName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buyer.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${buyer.distance!.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${buyer.locationName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Needs ${buyer.requiredQuantity.toStringAsFixed(0)} tons',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Contact Button
            ElevatedButton(
              onPressed: () => _makePhoneCall(buyer.phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Call',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build crop filter dropdown
  Widget _buildCropFilterDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCropFilter,
                hint: const Text('Filter by crop'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'All Crops',
                    child: Text('All Crops'),
                  ),
                  ..._farmerCrops.map((crop) {
                    return DropdownMenuItem(value: crop, child: Text(crop));
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCropFilter = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build no crop message
  Widget _buildNoCropMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Crops Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please complete your profile and add crops to find buyers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final cropText =
        _selectedCropFilter == null || _selectedCropFilter == 'All Crops'
        ? 'your crops'
        : _selectedCropFilter!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Buyers Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No buyers nearby for $cropText within 20 km.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try checking back later or expand your search area.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
