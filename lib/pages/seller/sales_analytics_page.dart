import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  Future<Map<String, dynamic>> _loadAnalytics(String uid) async {
    int totalListings = 0;
    int activeListings = 0;
    int totalBookings = 0;
    double totalRevenue = 0;
    int totalOrders = 0;

    // Products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('ownerId', isEqualTo: uid)
        .get();
    totalListings = productsSnapshot.docs.length;
    activeListings = productsSnapshot.docs
        .where((doc) => (doc.data()['isAvailable'] ?? true) == true)
        .length;

    // Rental bookings revenue
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: uid)
        .get();
    totalBookings = bookingsSnapshot.docs.length;
    totalRevenue = bookingsSnapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0).toDouble(),
    );

    // Orders (if orders collection exists)
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .get();
      totalOrders = ordersSnapshot.docs.length;
    } catch (_) {
      totalOrders = 0;
    }

    return {
      'totalListings': totalListings,
      'activeListings': activeListings,
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: const Color(0xFFFF8F00),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view analytics.'))
          : FutureBuilder<Map<String, dynamic>>(
              future: _loadAnalytics(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text('Failed to load sales analytics.'),
                  );
                }

                final data = snapshot.data!;
                final totalListings = data['totalListings'] as int;
                final activeListings = data['activeListings'] as int;
                final totalBookings = data['totalBookings'] as int;
                final totalRevenue = data['totalRevenue'] as double;
                final totalOrders = data['totalOrders'] as int;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        title: 'Total Listings',
                        value: totalListings.toString(),
                        icon: Icons.inventory_2,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: 'Active Listings',
                        value: activeListings.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: 'Rental Bookings',
                        value: totalBookings.toString(),
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: 'Orders Received',
                        value: totalOrders.toString(),
                        icon: Icons.shopping_bag,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: 'Total Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
