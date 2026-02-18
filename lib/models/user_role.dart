/// User Role Model
///
/// Enum for different user roles in the platform
library;

enum UserRole {
  farmer,
  buyer,
  seller,
  renter,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.renter:
        return 'Renter';
    }
  }

  String get value {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.buyer:
        return 'buyer';
      case UserRole.seller:
        return 'seller';
      case UserRole.renter:
        return 'renter';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'farmer':
        return UserRole.farmer;
      case 'buyer':
        return UserRole.buyer;
      case 'seller':
        return UserRole.seller;
      case 'renter':
        return UserRole.renter;
      default:
        return UserRole.farmer;
    }
  }
}
