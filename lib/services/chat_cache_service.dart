/// Chat Cache Service
///
/// Handles saving and loading chat history using SharedPreferences
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatCacheService {
  // Storage key for chat history
  static const String _chatHistoryKey = 'ai_chat_history';

  /// Save chat messages to local storage
  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert messages to JSON list
      final jsonList = messages
          .map((msg) => json.encode(msg.toJson()))
          .toList();

      // Save to SharedPreferences
      await prefs.setStringList(_chatHistoryKey, jsonList);

      print('💾 Saved ${messages.length} messages to cache');
    } catch (e) {
      print('❌ Error saving messages: $e');
    }
  }

  /// Load chat messages from local storage
  Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get saved JSON list
      final jsonList = prefs.getStringList(_chatHistoryKey);

      if (jsonList == null || jsonList.isEmpty) {
        print('📭 No cached messages found');
        return [];
      }

      // Convert JSON back to ChatMessage objects
      final messages = jsonList
          .map((jsonStr) => ChatMessage.fromJson(json.decode(jsonStr)))
          .toList();

      print('📬 Loaded ${messages.length} messages from cache');
      return messages;
    } catch (e) {
      print('❌ Error loading messages: $e');
      return [];
    }
  }

  /// Clear all chat history
  Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      print('🗑️ Chat history cleared');
    } catch (e) {
      print('❌ Error clearing messages: $e');
    }
  }
}
