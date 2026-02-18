/// Home Page
/// 
/// Main landing page after authentication showing recommendations and quick actions.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recProvider = Provider.of<RecommendationProvider>(context, listen: false);
    
    if (authProvider.firebaseUser != null) {
      // TODO: Replace with actual recommendation loading when function is deployed
      await recProvider.loadMockRecommendations(authProvider.firebaseUser!.uid);
    }
  }
  
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uzhavu Sei AI'),
        backgroundColor: AppTheme.deepGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: Consumer2<AuthProvider, RecommendationProvider>(
          builder: (context, authProvider, recProvider, child) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(authProvider),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  
                  // Recommendations Section
                  _buildRecommendationsSection(recProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard(AuthProvider authProvider) {
    final user = authProvider.userModel;
    final userName = user?.name ?? authProvider.firebaseUser?.displayName ?? 'Farmer';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.deepGreen,
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? const Icon(Icons.person, size: 30, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.shopping_bag,
                label: 'Marketplace',
                color: AppTheme.deepGreen,
                onTap: () {
                  // TODO: Navigate to marketplace
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_box,
                label: 'Add Product',
                color: AppTheme.accentGreen,
                onTap: () {
                  // TODO: Navigate to add product
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today,
                label: 'My Bookings',
                color: Colors.orange,
                onTap: () {
                  // TODO: Navigate to bookings
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person,
                label: 'My Profile',
                color: Colors.blue,
                onTap: () {
                  // TODO: Navigate to profile
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsSection(RecommendationProvider recProvider) {
    if (recProvider.isLoading) {
      return const LoadingIndicator(message: 'Loading recommendations...');
    }
    
    if (recProvider.errorMessage != null) {
      return _buildErrorWidget(recProvider);
    }
    
    if (!recProvider.hasRecommendations) {
      return _buildEmptyState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...recProvider.recommendations.map((rec) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.deepGreen.withOpacity(0.1),
                child: Icon(
                  _getIconForType(rec.type),
                  color: AppTheme.deepGreen,
                ),
              ),
              title: Text(
                rec.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(rec.description),
              trailing: Chip(
                label: Text(
                  '${(rec.confidenceScore * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppTheme.successGreen.withOpacity(0.2),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildErrorWidget(RecommendationProvider recProvider) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(
            'Failed to load recommendations',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            recProvider.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No recommendations yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your profile to get personalized recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'equipment':
        return Icons.agriculture;
      case 'product':
        return Icons.shopping_cart;
      case 'crop':
        return Icons.eco;
      case 'practice':
        return Icons.tips_and_updates;
      default:
        return Icons.star;
    }
  }
}
