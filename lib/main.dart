/// Main entry point for Uzhavu Sei AI
///
/// Initializes Firebase and runs the app with providers.
library;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/recommendation_provider.dart';
import 'pages/splash/splash_screen.dart';
import 'pages/auth/farmer_login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/main/main_page.dart';
import 'pages/onboarding/farmer_onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, ignore the error
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'Uzhavu Sei AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const FarmerLoginPage(),
          '/register': (context) => const RegisterPage(),
          '/main': (context) => const MainPage(),
          '/onboarding': (context) => const FarmerOnboardingPage(),
        },
      ),
    );
  }
}
