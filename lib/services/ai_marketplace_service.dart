/// AI Marketplace Recommendation Service
///
/// Generates personalized product category recommendations using Gemini AI
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_keys.dart';

class AIMarketplaceService {
  // Gemini API configuration
  static const String apiKey = ApiKeys.geminiApiKey;
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  // Cache configuration
  static const String cacheKey = 'ai_marketplace_recommendations';
  static const String cacheTimestampKey =
      'ai_marketplace_recommendations_timestamp';
  static const Duration cacheValidDuration = Duration(hours: 12);

  /// Get recommended marketplace categories based on farmer profile
  ///
  /// [cropType] - Type of crop being grown (e.g., "Paddy", "Wheat")
  /// [location] - Farmer's location
  /// [roles] - User roles (farmer, buyer, seller, renter)
  ///
  /// Returns list of recommended product categories
  Future<List<String>> getRecommendedCategories({
    required String cropType,
    required String location,
    required List<String> roles,
  }) async {
    try {
      // Check cache first
      final cachedResult = await _getCachedRecommendations();
      if (cachedResult != null) {
        print('✅ Using cached AI recommendations');
        return cachedResult;
      }

      print('🤖 Fetching AI marketplace recommendations...');

      // Build Gemini API prompt
      final prompt =
          '''You are an agriculture advisor AI.

Farmer crop: $cropType
Location: $location
User roles: ${roles.join(', ')}

Return ONLY a JSON array of marketplace product categories that should be recommended right now.

Allowed categories:
crop
fertilizer
tool
equipment
pesticide

Return example:
["fertilizer","equipment"]

Response format: Return only the JSON array, nothing else.''';

      // Prepare API request
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
            'role': 'user',
          },
        ],
        'generationConfig': {
          'temperature': 0.3, // Lower temperature for more consistent results
          'topK': 20,
          'topP': 0.8,
          'maxOutputTokens': 256, // Short response
        },
      };

      // Call Gemini API
      final response = await http.post(
        Uri.parse('$apiEndpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Parse response
        final responseData = json.decode(response.body);
        final aiText =
            responseData['candidates'][0]['content']['parts'][0]['text']
                as String;

        print('📥 AI response: $aiText');

        // Extract JSON array from response
        final categories = _parseRecommendations(aiText);

        if (categories.isNotEmpty) {
          // Cache successful result
          await _cacheRecommendations(categories);
          print('✅ AI recommendations: $categories');
          return categories;
        }
      } else {
        print('⚠️ Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting AI recommendations: $e');
    }

    // Fallback to default recommendations
    return _getFallbackRecommendations(roles);
  }

  /// Parse AI response to extract JSON array of categories
  List<String> _parseRecommendations(String aiText) {
    try {
      // Clean the response
      String cleaned = aiText.trim();

      // Extract JSON array if wrapped in markdown code blocks
      if (cleaned.contains('```json')) {
        final start = cleaned.indexOf('[');
        final end = cleaned.lastIndexOf(']') + 1;
        if (start != -1 && end > start) {
          cleaned = cleaned.substring(start, end);
        }
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.replaceAll('```', '');
      }

      // Find JSON array in text
      final arrayStart = cleaned.indexOf('[');
      final arrayEnd = cleaned.lastIndexOf(']') + 1;

      if (arrayStart != -1 && arrayEnd > arrayStart) {
        cleaned = cleaned.substring(arrayStart, arrayEnd);
      }

      // Parse JSON array
      final List<dynamic> parsed = json.decode(cleaned);
      final List<String> categories = parsed
          .map((e) => e.toString().toLowerCase())
          .toList();

      // Validate categories
      const allowedCategories = [
        'crop',
        'fertilizer',
        'tool',
        'equipment',
        'pesticide',
      ];
      return categories
          .where((cat) => allowedCategories.contains(cat))
          .toList();
    } catch (e) {
      print('⚠️ Failed to parse AI recommendations: $e');
      return [];
    }
  }

  /// Get cached recommendations if still valid
  Future<List<String>?> _getCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      final cachedData = prefs.getStringList(cacheKey);
      final timestamp = prefs.getInt(cacheTimestampKey);

      if (cachedData != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);

        // Return cache if less than 12 hours old
        if (age < cacheValidDuration) {
          return cachedData;
        }
      }
    } catch (e) {
      print('⚠️ Error reading cache: $e');
    }

    return null;
  }

  /// Cache recommendations with timestamp
  Future<void> _cacheRecommendations(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(cacheKey, categories);
      await prefs.setInt(
        cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('💾 Cached AI recommendations');
    } catch (e) {
      print('⚠️ Error caching recommendations: $e');
    }
  }

  /// Get fallback recommendations based on user roles
  List<String> _getFallbackRecommendations(List<String> roles) {
    print('📋 Using fallback recommendations');

    Set<String> recommendations = {};

    for (String role in roles) {
      switch (role.toLowerCase()) {
        case 'farmer':
          recommendations.addAll(['fertilizer', 'tool', 'pesticide']);
          break;
        case 'buyer':
          recommendations.add('crop');
          break;
        case 'renter':
          recommendations.add('equipment');
          break;
        case 'seller':
          recommendations.addAll(['crop', 'tool']);
          break;
      }
    }

    return recommendations.isEmpty
        ? ['fertilizer', 'tool']
        : recommendations.toList();
  }

  /// Clear cached recommendations (useful for testing or profile changes)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    await prefs.remove(cacheTimestampKey);
    print('🗑️ Cleared AI recommendations cache');
  }
}
