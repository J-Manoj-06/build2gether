/// Core constants for Uzhavu Sei AI app
///
/// Contains app-wide constant values, API endpoints, and configuration keys.
library;

class AppConstants {
  // App metadata
  static const String appName = 'Uzhavu Sei AI';
  static const String appTagline = 'Empowering Farmers with Intelligence';

  // Navigation delays
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String bookingsCollection = 'bookings';
  static const String recommendationsCollection = 'recommendations';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String productImagesPath = 'product_images';

  // User roles
  static const String roleFarmer = 'farmer';
  static const String roleBuyer = 'buyer';
  static const String roleAdmin = 'admin';

  // API endpoints (for Cloud Functions)
  // TODO: Replace with your actual function URLs after deployment
  static const String aiRecommendationEndpoint =
      'https://your-region-your-project.cloudfunctions.net/getRecommendations';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;

  // Pagination
  static const int itemsPerPage = 20;

  // Map/Location
  static const double defaultLatitude = 11.0168; // Tamil Nadu, India
  static const double defaultLongitude = 76.9558;
  static const double searchRadiusKm = 50.0;

  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String authError = 'Authentication failed. Please login again.';
}
