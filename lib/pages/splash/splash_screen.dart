/// Splash Screen
///
/// Initial loading screen that checks auth state and navigates accordingly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/main_page.dart';
import '../auth/farmer_login_page.dart';
import '../onboarding/farmer_onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Colors matching the HTML design
  static const Color primaryColor = Color(0xFF1C5F20);
  static const Color mintLight = Color(0xFFE8F5E9);
  static const Color mintSoft = Color(0xFFC8E6C9);

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: mintSoft,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate after splash duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigate();
      }
    });
  }

  void _navigate() async {
    // Check if user is logged in using FirebaseAuth
    final currentUser = FirebaseAuth.instance.currentUser;

    // Add mounted check before navigation
    if (!mounted) return;

    if (currentUser != null) {
      // User is logged in - Check if profile is completed
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists && userDoc.data()?['profileCompleted'] == true) {
          // Profile completed - Navigate to MainPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        } else {
          // Profile not completed - Navigate to Onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmerOnboardingPage(),
            ),
          );
        }
      } catch (e) {
        // If error checking profile, navigate to onboarding to be safe
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FarmerOnboardingPage()),
        );
      }
    } else {
      // User is not logged in - Navigate to FarmerLoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FarmerLoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [mintLight, mintSoft],
              ),
            ),
          ),

          // Background Decorative Elements
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Stack(
                children: [
                  // Top left blur circle
                  Positioned(
                    top: -40,
                    left: -40,
                    child: Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom right blur circle
                  Positioned(
                    bottom: 80,
                    right: -40,
                    child: Container(
                      width: 256,
                      height: 256,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Grid Pattern
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPatternPainter(),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: SafeArea(
              child: Column(
                children: [
                  // Status bar spacer
                  const SizedBox(height: 48),

                  // Central Branding Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Logo Container
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                size: 60,
                                color: primaryColor,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Text Branding
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // App Title
                                  const Text(
                                    'Uzhavu Sei AI',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 8),

                                  // Subtitle
                                  Text(
                                    'Empowering Farmers with Intelligence',
                                    style: TextStyle(
                                      color: primaryColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer / Loading Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Material Style Loader
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Version Number
                          Text(
                            'V1.0.4',
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // iOS Home Indicator Safe Area Spacer
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Grid Pattern
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C5F20)
      ..style = PaintingStyle.fill;

    const gridSize = 24.0;
    const dotRadius = 0.5;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
