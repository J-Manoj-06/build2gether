/// AI Recommendation model
///
/// Represents AI-generated recommendations for farmers.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type; // 'product', 'equipment', 'crop', 'practice'
  final double confidenceScore; // 0.0 to 1.0
  final Map<String, dynamic> metadata; // Additional context
  final DateTime createdAt;

  RecommendationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.confidenceScore,
    required this.metadata,
    required this.createdAt,
  });

  /// Creates RecommendationModel from Firestore document
  factory RecommendationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'product',
      confidenceScore: (data['confidenceScore'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Creates RecommendationModel from JSON (for API responses)
  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'product',
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Converts RecommendationModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'confidenceScore': confidenceScore,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'confidenceScore': confidenceScore,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RecommendationModel(id: $id, title: $title, type: $type, confidence: $confidenceScore)';
  }
}
