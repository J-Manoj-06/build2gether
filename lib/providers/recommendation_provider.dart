/// Recommendation Provider
///
/// Manages AI recommendation state using Provider pattern.
library;

import 'package:flutter/foundation.dart';
import '../models/recommendation_model.dart';
import '../services/ai_recommendation_service.dart';

class RecommendationProvider with ChangeNotifier {
  final AIRecommendationService _aiService = AIRecommendationService();

  List<RecommendationModel> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RecommendationModel> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasRecommendations => _recommendations.isNotEmpty;

  /// Load recommendations for user
  Future<void> loadRecommendations({
    required String userId,
    required Map<String, dynamic> context,
    List<Map<String, dynamic>>? items,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _recommendations = await _aiService.getRecommendations(
        userId: userId,
        context: context,
        items: items,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Load equipment recommendations
  Future<void> loadEquipmentRecommendations(
    String userId,
    String cropType,
    String location,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _recommendations = await _aiService.getEquipmentRecommendations(
        userId,
        cropType,
        location,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Load crop recommendations
  Future<void> loadCropRecommendations(
    String userId,
    String soilType,
    String season,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _recommendations = await _aiService.getCropRecommendations(
        userId,
        soilType,
        season,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Load product recommendations
  Future<void> loadProductRecommendations(
    String userId,
    List<String> viewedProductIds,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _recommendations = await _aiService.getProductRecommendations(
        userId,
        viewedProductIds,
      );
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Load mock recommendations for testing
  /// TODO: Remove in production
  Future<void> loadMockRecommendations(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _recommendations = await _aiService.getMockRecommendations(userId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Filter recommendations by type
  List<RecommendationModel> getRecommendationsByType(String type) {
    return _recommendations.where((rec) => rec.type == type).toList();
  }

  /// Get top recommendations by confidence score
  List<RecommendationModel> getTopRecommendations(int count) {
    final sorted = List<RecommendationModel>.from(_recommendations)
      ..sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return sorted.take(count).toList();
  }

  /// Clear recommendations
  void clearRecommendations() {
    _recommendations = [];
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Retry loading last request
  /// TODO: Store last request parameters to enable retry
  Future<void> retry() async {
    // Implementation depends on storing last request parameters
    clearError();
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
