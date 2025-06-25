import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String name;
  final String preferredLanguage;
  final int age;
  final double weight;
  final double height;
  final String? apiToken;
  final String?
      fitnessGoal; // e.g., "lose weight", "build muscle", "improve endurance"
  final int? workoutsPerWeek;
  final String? experienceLevel; // "beginner", "intermediate", "advanced"
  final List<String>? preferredWorkouts; // e.g., ["cardio", "strength", "yoga"]
  final String? healthConditions; // Any health conditions to consider

  UserProfile({
    required this.uid,
    required this.name,
    required this.preferredLanguage,
    required this.age,
    required this.weight,
    required this.height,
    this.apiToken,
    this.fitnessGoal,
    this.workoutsPerWeek,
    this.experienceLevel,
    this.preferredWorkouts,
    this.healthConditions,
  });

  bool get hasValidApiToken =>
      true; // Always true since API token is now server-side

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'preferredLanguage': preferredLanguage,
      'age': age,
      'weight': weight,
      'height': height,
      'apiToken': apiToken,
      'fitnessGoal': fitnessGoal,
      'workoutsPerWeek': workoutsPerWeek,
      'experienceLevel': experienceLevel,
      'preferredWorkouts': preferredWorkouts,
      'healthConditions': healthConditions,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      apiToken: json['apiToken'] as String?,
      fitnessGoal: json['fitnessGoal'] as String?,
      workoutsPerWeek: json['workoutsPerWeek'] as int?,
      experienceLevel: json['experienceLevel'] as String?,
      preferredWorkouts:
          (json['preferredWorkouts'] as List<dynamic>?)?.cast<String>(),
      healthConditions: json['healthConditions'] as String?,
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  Future<void> save() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'User authentication error',
          code: 'unauthenticated',
        );
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(toJson(), SetOptions(merge: true))
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Connection timeout',
            code: 'timeout',
          );
        },
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'No permission to save profile',
          code: e.code,
        );
      } else if (e.code == 'unavailable') {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Network connection error',
          code: e.code,
        );
      }
      rethrow;
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to save profile: ${e.toString()}',
        code: 'unknown',
      );
    }
  }

  UserProfile copyWith({
    String? name,
    String? preferredLanguage,
    int? age,
    double? weight,
    double? height,
    String? apiToken,
    String? fitnessGoal,
    int? workoutsPerWeek,
    String? experienceLevel,
    List<String>? preferredWorkouts,
    String? healthConditions,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      apiToken: apiToken ?? this.apiToken,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredWorkouts: preferredWorkouts ?? this.preferredWorkouts,
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }
}
