/// Product Detail Page with Rental Booking
///
/// Shows complete product details with rental duration selection
/// and payment integration
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../services/payment_service.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  double _totalAmount = 0.0;
  int _durationHours = 0;
  bool _isProcessing = false;

  final PaymentService _paymentService = PaymentService();
  final _firestore = FirebaseFirestore.instance;

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color backgroundLight = Color(0xFFF5F7F6);

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  /// Calculate total amount based on duration
  void _calculateTotalAmount() {
    if (_startDateTime != null && _endDateTime != null) {
      final duration = _endDateTime!.difference(_startDateTime!);
      _durationHours = duration.inHours;

      // Minimum 1 hour
      if (_durationHours < 1) {
        _durationHours = 1;
      }

      setState(() {
        _totalAmount = _durationHours * widget.product.price;
      });

      print('DEBUG: Duration: $_durationHours hours, Total: ₹$_totalAmount');
    }
  }

  /// Select start date and time
  Future<void> _selectStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      // Reset end date if it's before start date
      if (_endDateTime != null && _endDateTime!.isBefore(_startDateTime!)) {
        _endDateTime = null;
      }
    });

    _calculateTotalAmount();
  }

  /// Select end date and time
  Future<void> _selectEndDateTime() async {
    if (_startDateTime == null) {
      _showSnackBar('Please select start date first', isError: true);
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime!,
      firstDate: _startDateTime!,
      lastDate: _startDateTime!.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Validation
    if (endDateTime.isBefore(_startDateTime!) ||
        endDateTime.isAtSameMomentAs(_startDateTime!)) {
      _showSnackBar('End time must be after start time', isError: true);
      return;
    }

    setState(() {
      _endDateTime = endDateTime;
    });

    _calculateTotalAmount();
  }

  /// Proceed to payment
  Future<void> _proceedToPayment() async {
    // Validation
    if (_startDateTime == null || _endDateTime == null) {
      _showSnackBar('Please select rental duration', isError: true);
      return;
    }

    if (_durationHours < 1) {
      _showSnackBar('Minimum rental duration is 1 hour', isError: true);
      return;
    }

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login to continue', isError: true);
      return;
    }

    // Get user details
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['name'] ?? 'User';
    final userEmail = user.email ?? '';
    final userPhone = userData['phone'] ?? '';

    setState(() {
      _isProcessing = true;
    });

    print('DEBUG: Opening Razorpay checkout for ₹$_totalAmount');

    // Open Razorpay payment
    await _paymentService.openCheckout(
      amount: _totalAmount,
      name: userName,
      email: userEmail,
      contact: userPhone,
      description: 'Rental: ${widget.product.name}',
      onSuccess: (response) async {
        print('✅ Payment Success: ${response['razorpay_payment_id']}');
        await _saveBooking(response['razorpay_payment_id']);
      },
      onFailure: (response) {
        print('❌ Payment Failed: ${response['message']}');
        setState(() {
          _isProcessing = false;
        });
        _showSnackBar('Payment failed: ${response['message']}', isError: true);
      },
    );
  }

  /// Save booking to Firestore
  Future<void> _saveBooking(String paymentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      await _firestore.collection('bookings').add({
        'productId': widget.product.id,
        'productName': widget.product.name,
        'ownerId': widget.product.ownerId,
        'renterId': user.uid,
        'startDateTime': Timestamp.fromDate(_startDateTime!),
        'endDateTime': Timestamp.fromDate(_endDateTime!),
        'durationHours': _durationHours,
        'totalAmount': _totalAmount,
        'paymentId': paymentId,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Booking saved successfully');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      print('❌ Error saving booking: $e');
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Error saving booking: $e', isError: true);
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your rental has been successfully booked.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Product', widget.product.name),
            _buildInfoRow('Duration', '$_durationHours hours'),
            _buildInfoRow('Total Paid', '₹${_totalAmount.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to marketplace
            },
            child: const Text(
              'Back to Marketplace',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: primaryColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.product.imageUrls.isNotEmpty
                      ? Image.network(
                          widget.product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: lightGreen,
                              child: const Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 80,
                                  color: primaryColor,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: lightGreen,
                          child: const Center(
                            child: Icon(
                              Icons.inventory_2,
                              size: 80,
                              color: primaryColor,
                            ),
                          ),
                        ),
                ),
              ),

              // Product details
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info card
                    _buildProductInfoCard(),

                    const SizedBox(height: 16),

                    // Description
                    _buildDescriptionCard(),

                    const SizedBox(height: 16),

                    // Rental selection
                    _buildRentalSelectionCard(),

                    const SizedBox(height: 16),

                    // Total amount
                    if (_totalAmount > 0) _buildTotalAmountCard(),

                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ],
          ),

          // Bottom button
          if (_totalAmount > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPaymentButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Product name
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // Location
          if (widget.product.location != null)
            Row(
              children: [
                const Icon(Icons.location_city, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  widget.product.location!,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Distance
          if (widget.product.distance != null)
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${widget.product.distance!.toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee, size: 20, color: primaryColor),
                Text(
                  '${widget.product.price.toStringAsFixed(0)} ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  '/ ${_getPriceTypeLabel(widget.product.priceType)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalSelectionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Rental Duration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Start date/time
          _buildDateTimeSelector(
            label: 'Start Date & Time',
            dateTime: _startDateTime,
            onTap: _selectStartDateTime,
          ),

          const SizedBox(height: 16),

          // End date/time
          _buildDateTimeSelector(
            label: 'End Date & Time',
            dateTime: _endDateTime,
            onTap: _selectEndDateTime,
          ),

          if (_durationHours > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: $_durationHours ${_durationHours == 1 ? 'hour' : 'hours'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required DateTime? dateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event,
              color: dateTime != null ? primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTime != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime)
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: dateTime != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: dateTime != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                    size: 28,
                  ),
                  Text(
                    _totalAmount.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.product.price.toStringAsFixed(0)} × $_durationHours ${_durationHours == 1 ? 'hour' : 'hours'}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _proceedToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Proceed to Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
}
