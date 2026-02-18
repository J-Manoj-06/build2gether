/// AI Recommendation Service
/// 
/// Client-side service to call serverless AI recommendation function.
/// The actual AI API key is kept server-side for security.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation_model.dart';
import '../core/constants.dart';

class AIRecommendationService {
  /// Get AI recommendations for user
  /// 
  /// [userId] - User's UID
  /// [context] - User context (location, preferences, history, etc.)
  /// [items] - List of items/products for context
  /// 
  /// Returns list of AI-generated recommendations
  Future<List<RecommendationModel>> getRecommendations({
    required String userId,
    required Map<String, dynamic> context,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.aiRecommendationEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'context': context,
          'items': items ?? [],
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = (data['recommendations'] as List)
            .map((json) => RecommendationModel.fromJson(json))
            .toList();
        
        return recommendations;
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get recommendations: ${e.toString()}');
    }
  }
  
  /// Get equipment recommendations
  Future<List<RecommendationModel>> getEquipmentRecommendations(
    String userId,
    String cropType,
    String location,
  ) async {
    return getRecommendations(
      userId: userId,
      context: {
        'type': 'equipment',
        'cropType': cropType,
        'location': location,
      },
    );
  }
  
  /// Get crop recommendations
  Future<List<RecommendationModel>> getCropRecommendations(
    String userId,
    String soilType,
    String season,
  ) async {
    return getRecommendations(
      userId: userId,
      context: {
        'type': 'crop',
        'soilType': soilType,
        'season': season,
      },
    );
  }
  
  /// Get product recommendations based on user history
  Future<List<RecommendationModel>> getProductRecommendations(
    String userId,
    List<String> viewedProductIds,
  ) async {
    return getRecommendations(
      userId: userId,
      context: {
        'type': 'product',
        'viewedProducts': viewedProductIds,
      },
    );
  }
  
  /// Mock recommendations for testing (when function is not deployed)
  /// TODO: Remove this method in production
  Future<List<RecommendationModel>> getMockRecommendations(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    return [
      RecommendationModel(
        id: '1',
        userId: userId,
        title: 'Tractor Rental',
        description: 'Based on your farm size, we recommend renting a medium-sized tractor',
        type: 'equipment',
        confidenceScore: 0.85,
        metadata: {
          'category': 'equipment',
          'priceRange': '500-1000',
        },
        createdAt: DateTime.now(),
      ),
      RecommendationModel(
        id: '2',
        userId: userId,
        title: 'Organic Fertilizer',
        description: 'Organic fertilizer is recommended for your soil type',
        type: 'product',
        confidenceScore: 0.92,
        metadata: {
          'category': 'fertilizer',
          'organic': true,
        },
        createdAt: DateTime.now(),
      ),
      RecommendationModel(
        id: '3',
        userId: userId,
        title: 'Drip Irrigation System',
        description: 'Save 40% water with a drip irrigation system for your crops',
        type: 'equipment',
        confidenceScore: 0.78,
        metadata: {
          'category': 'irrigation',
          'waterSaving': 40,
        },
        createdAt: DateTime.now(),
      ),
    ];
  }
}
