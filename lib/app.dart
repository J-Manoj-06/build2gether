/// Main App Widget
/// 
/// Configures MaterialApp with theme, routes, and providers.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'routes.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/recommendation_provider.dart';
import 'pages/splash/splash_screen.dart';
import 'pages/auth/farmer_login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/home/home_page.dart';

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
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const FarmerLoginPage(),
          AppRoutes.register: (context) => const RegisterPage(),
          AppRoutes.resetPassword: (context) => const ResetPasswordPage(),
          AppRoutes.home: (context) => const HomePage(),
        },
      ),
    );
  }
}
