import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImage;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> registeredEvents;
  final List<String> bookmarkedEvents;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImage,
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
    this.registeredEvents = const [],
    this.bookmarkedEvents = const [],
  });

  String get fullName => '$firstName $lastName';

  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}'
          '${lastName.isNotEmpty ? lastName[0] : ''}'
      .toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      isAdmin: json['isAdmin'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      registeredEvents: List<String>.from(json['registeredEvents'] ?? []),
      bookmarkedEvents: List<String>.from(json['bookmarkedEvents'] ?? []),
    );
  }

  /// Helper method to parse DateTime from various formats (Timestamp, String, or null)
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    // If it's already a DateTime
    if (dateValue is DateTime) return dateValue;

    // If it's a Firestore Timestamp
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    // If it's a string, try to parse it
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // If it's a milliseconds timestamp (int)
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }

    // Fallback
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profileImage': profileImage,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'registeredEvents': registeredEvents,
      'bookmarkedEvents': bookmarkedEvents,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? registeredEvents,
    List<String>? bookmarkedEvents,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      bookmarkedEvents: bookmarkedEvents ?? this.bookmarkedEvents,
    );
  }
}
