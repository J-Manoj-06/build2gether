/// Gemini AI Service
///
/// Handles communication with Google's Gemini API
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🔐 GEMINI API KEY
  // Get your free key from: https://aistudio.google.com/app/apikey
  static const String apiKey = "AIzaSyCwIW3etG74lkZ_vRNGhIeOr_2NwxKZxH0";

  // Gemini API endpoint
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  /// Send message to Gemini AI with conversation history
  ///
  /// [message] - The current user message
  /// [history] - Previous conversation history
  ///
  /// Returns AI response text or error message
  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    try {
      // Build conversation contents array
      List<Map<String, dynamic>> contents = [];

      // Add conversation history
      for (var msg in history) {
        contents.add({
          'parts': [
            {'text': msg['text']},
          ],
          'role': msg['role'] == 'user' ? 'user' : 'model',
        });
      }

      // Add current user message
      contents.add({
        'parts': [
          {'text': message},
        ],
        'role': 'user',
      });

      // Prepare request body
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      print('📤 Sending request to Gemini API...');

      // Make API call
      final response = await http.post(
        Uri.parse('$apiEndpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = json.decode(response.body);

        // Extract AI response text
        final aiText =
            responseData['candidates'][0]['content']['parts'][0]['text']
                as String;

        print('✅ Gemini response received');
        return aiText;
      } else {
        // API error
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');

        // Check for common errors
        if (response.statusCode == 400) {
          return '⚠️ Invalid request. Please check your API key.';
        } else if (response.statusCode == 403) {
          return '⚠️ API key is invalid or doesn\'t have access.';
        } else if (response.statusCode == 429) {
          return '⚠️ Too many requests. Please try again later.';
        } else {
          return '⚠️ Failed to get response from AI. Please try again.';
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      return '⚠️ Network error. Please check your internet connection.';
    }
  }
}
