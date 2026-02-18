/// Dynamic Home Page
///
/// Role-adaptive dashboard that shows different sections based on user roles
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_role.dart';
import '../ai/find_buyers_page.dart';
import '../chat/ai_chat_page.dart';
import '../marketplace/add_product_page.dart';

class DynamicHomePage extends StatefulWidget {
  const DynamicHomePage({super.key});

  @override
  State<DynamicHomePage> createState() => _DynamicHomePageState();
}

class _DynamicHomePageState extends State<DynamicHomePage> {
  List<UserRole> userRoles = [];
  String userName = 'User';
  bool isLoading = true;

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            userName = data?['name'] ?? 'User';

            // Load roles from Firestore
            final roles = data?['roles'] as List<dynamic>?;
            if (roles != null && roles.isNotEmpty) {
              userRoles = roles
                  .map((role) => UserRoleExtension.fromString(role.toString()))
                  .toList();
            } else {
              // Default to farmer if no roles found
              userRoles = [UserRole.farmer];
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        userRoles = [UserRole.farmer];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool hasMultipleRoles = userRoles.length > 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Dynamic Role-Based Dashboards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (userRoles.contains(UserRole.farmer))
                      _buildDashboardSection(
                        'Farmer Dashboard',
                        _buildFarmerDashboard(),
                        showLabel: hasMultipleRoles,
                      ),

                    if (userRoles.contains(UserRole.buyer))
                      _buildDashboardSection(
                        'Buyer Dashboard',
                        _buildBuyerDashboard(),
                        showLabel: hasMultipleRoles,
                      ),

                    if (userRoles.contains(UserRole.seller))
                      _buildDashboardSection(
                        'Seller Dashboard',
                        _buildSellerDashboard(),
                        showLabel: hasMultipleRoles,
                      ),

                    if (userRoles.contains(UserRole.renter))
                      _buildDashboardSection(
                        'Equipment Renter Dashboard',
                        _buildRenterDashboard(),
                        showLabel: hasMultipleRoles,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection(
    String title,
    Widget content, {
    bool showLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  // FARMER DASHBOARD
  Widget _buildFarmerDashboard() {
    return Column(
      children: [
        // AI Advisor Highlight Card
        _buildHighlightCard(
          title: 'AI Farming Advisor',
          subtitle: 'Get instant advice for your crops',
          icon: Icons.smart_toy,
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatPage()),
            );
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Crop Health',
                icon: Icons.eco,
                color: const Color(0xFF43A047),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Sell Crops',
                icon: Icons.sell,
                color: const Color(0xFF66BB6A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FindBuyersPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.wb_sunny,
          title: 'Weather Insight',
          subtitle: 'Sunny, 28°C - Good for irrigation',
          iconColor: Colors.orange,
        ),
      ],
    );
  }

  // BUYER DASHBOARD
  Widget _buildBuyerDashboard() {
    return Column(
      children: [
        _buildHighlightCard(
          title: 'Find Farmers',
          subtitle: 'Connect with farmers near you',
          icon: Icons.agriculture,
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindBuyersPage()),
            );
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Available Crops',
                icon: Icons.grass,
                color: const Color(0xFF1E88E5),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Price Trends',
                icon: Icons.trending_up,
                color: const Color(0xFF42A5F5),
                onTap: () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.location_on,
          title: 'Nearby Farmers',
          subtitle: '12 farmers within 10 km',
          iconColor: const Color(0xFF1976D2),
        ),
      ],
    );
  }

  // SELLER DASHBOARD
  Widget _buildSellerDashboard() {
    return Column(
      children: [
        _buildHighlightCard(
          title: 'Add New Product',
          subtitle: 'List your products for sale',
          icon: Icons.add_shopping_cart,
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFBF360C)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductPage()),
            );
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'My Listings',
                icon: Icons.inventory_2,
                color: const Color(0xFFFF6F00),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Sales Analytics',
                icon: Icons.analytics,
                color: const Color(0xFFFF8F00),
                onTap: () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.shopping_bag,
          title: 'Orders Received',
          subtitle: '8 new orders this week',
          iconColor: const Color(0xFFE65100),
        ),
      ],
    );
  }

  // RENTER DASHBOARD
  Widget _buildRenterDashboard() {
    return Column(
      children: [
        _buildHighlightCard(
          title: 'Rent Equipment',
          subtitle: 'Browse available equipment nearby',
          icon: Icons.agriculture,
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          ),
          onTap: () {},
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'My Equipment',
                icon: Icons.build,
                color: const Color(0xFF8E24AA),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Rental Requests',
                icon: Icons.request_page,
                color: const Color(0xFFAB47BC),
                onTap: () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.account_balance_wallet,
          title: 'Earnings Overview',
          subtitle: '₹12,450 this month',
          iconColor: const Color(0xFF6A1B9A),
        ),
      ],
    );
  }

  // REUSABLE CARD WIDGETS
  Widget _buildHighlightCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
