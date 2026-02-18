/// Main Page
///
/// Main navigation hub with centered AI FAB
library;

import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../marketplace/marketplace_page.dart';
import '../chat/ai_chat_page.dart';
import '../alerts/alerts_page.dart';
import '../profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color backgroundLight = Color(0xFFF5F7F6);

  // Pages list
  final List<Widget> _pages = [
    const HomePage(),
    const MarketplacePage(),
    const AlertsPage(),
    const ProfilePage(),
  ];

  void _openAIAdvisor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAIAdvisor,
        backgroundColor: primaryColor,
        elevation: 6,
        child: const Icon(Icons.smart_toy, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.store, label: 'Marketplace', index: 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(
                icon: Icons.notifications_outlined,
                label: 'Alerts',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.account_circle_outlined,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? primaryColor : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? primaryColor : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
