/// Main Page
///
/// Main navigation hub after authentication
library;

import 'package:flutter/material.dart';
import '../home/home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, MainPage redirects to HomePage
    // You can add bottom navigation or drawer here if needed
    return const HomePage();
  }
}
