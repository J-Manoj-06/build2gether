/// Farmer Rent Equipment Page
///
/// Allows farmers to discover and rent nearby equipment with realtime updates
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../models/rental_request_model.dart';

class FarmerRentPage extends StatefulWidget {
  const FarmerRentPage({super.key});

  @override
  State<FarmerRentPage> createState() => _FarmerRentPageState();
}

class _FarmerRentPageState extends State<FarmerRentPage> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  double? _userLat;
  double? _userLng;
  String _searchQuery = '';
  bool _loadingLocation = true;

  // UI Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color accentGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// Get current user location
  Future<void> _getUserLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showError('Location permission denied. Cannot show nearby equipment.');
        setState(() => _loadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _loadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      _showError('Failed to get location');
      setState(() => _loadingLocation = false);
    }
  }

  /// Calculate distance and sort equipment by proximity
  List<Equipment> _sortEquipmentByDistance(List<Equipment> equipmentList) {
    if (_userLat == null || _userLng == null) return equipmentList;

    // Calculate distance for each equipment
    for (var equipment in equipmentList) {
      final distanceInMeters = Geolocator.distanceBetween(
        _userLat!,
        _userLng!,
        equipment.latitude,
        equipment.longitude,
      );
      equipment.distance = distanceInMeters / 1000; // Convert to km
    }

    // Sort by distance (nearest first)
    equipmentList.sort((a, b) {
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    });

    return equipmentList;
  }

  /// Filter equipment by search query
  List<Equipment> _filterEquipment(List<Equipment> equipmentList) {
    if (_searchQuery.isEmpty) return equipmentList;

    return equipmentList.where((equipment) {
      return equipment.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          equipment.locationName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  /// Show rental bottom sheet
  void _showRentBottomSheet(Equipment equipment) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalDays = endDate.difference(startDate).inDays + 1;
          final totalPrice = equipment.pricePerDay * totalDays;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: primaryGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rent Equipment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              equipment.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price per day
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price per day:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₹${equipment.pricePerDay.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Pickers
                  const Text(
                    'Select Rental Period',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Start Date
                  _buildDateSelector(
                    label: 'Start Date',
                    date: startDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          startDate = picked;
                          // Ensure end date is after start date
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // End Date
                  _buildDateSelector(
                    label: 'End Date',
                    date: endDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => endDate = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Days:'),
                            Text(
                              '$totalDays days',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _sendRentalRequest(
                        equipment,
                        startDate,
                        endDate,
                        totalPrice,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Send Rental Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build date selector widget
  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Row(
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 20, color: primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Send rental request to Firestore
  Future<void> _sendRentalRequest(
    Equipment equipment,
    DateTime startDate,
    DateTime endDate,
    double totalPrice,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError('Please login to send rental request');
        return;
      }

      // Validate dates
      if (endDate.isBefore(startDate)) {
        _showError('End date must be after start date');
        return;
      }

      // Get user name
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // Create rental request
      await _firestore.collection('rental_requests').add({
        'equipmentId': equipment.id,
        'equipmentName': equipment.name,
        'ownerId': equipment.ownerId,
        'renterId': currentUser.uid,
        'renterName': userName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'totalPrice': totalPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Close bottom sheet
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental request sent successfully!'),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error sending rental request: $e');
      _showError('Failed to send rental request');
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rent Equipment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search equipment...',
                    prefixIcon: const Icon(Icons.search, color: primaryGreen),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Location Filter Chip
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Nearby First',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: _loadingLocation
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryGreen),
                        SizedBox(height: 16),
                        Text('Getting your location...'),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('equipment')
                        .where('availability', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        );
                      }

                      // Convert to Equipment list
                      List<Equipment> equipmentList = snapshot.data!.docs
                          .map((doc) => Equipment.fromFirestore(doc))
                          .toList();

                      // Sort by distance
                      equipmentList = _sortEquipmentByDistance(equipmentList);

                      // Filter by search query
                      equipmentList = _filterEquipment(equipmentList);

                      if (equipmentList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.agriculture,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No equipment available nearby',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: equipmentList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == equipmentList.length) {
                            // My Rental Requests section
                            return _buildMyRequestsSection();
                          }

                          return _buildEquipmentCard(equipmentList[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build equipment card
  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRentBottomSheet(equipment),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: equipment.imageUrl.isNotEmpty
                  ? Image.network(
                      equipment.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: lightGreen,
                          child: const Icon(
                            Icons.agriculture,
                            size: 60,
                            color: primaryGreen,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      color: lightGreen,
                      child: const Icon(
                        Icons.agriculture,
                        size: 60,
                        color: primaryGreen,
                      ),
                    ),
            ),

            // Equipment Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Availability Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          equipment.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          equipment.locationName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Distance
                  if (equipment.distance != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 16,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${equipment.distance!.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontSize: 14,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Price and Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${equipment.pricePerDay.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          Text(
                            'per day',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showRentBottomSheet(equipment),
                        icon: const Icon(Icons.schedule, color: Colors.white),
                        label: const Text(
                          'Rent Now',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  /// Build My Rental Requests section
  Widget _buildMyRequestsSection() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'My Rental Requests',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('rental_requests')
              .where('renterId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }

            final requests = snapshot.data!.docs
                .map((doc) => RentalRequest.fromFirestore(doc))
                .toList();

            if (requests.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'You have no rental requests yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: requests
                  .map((request) => _buildRequestCard(request))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// Build rental request card
  Widget _buildRequestCard(RentalRequest request) {
    Color statusColor;
    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.equipmentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${request.totalDays} days',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '₹${request.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
