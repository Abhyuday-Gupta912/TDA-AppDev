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
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      registeredEvents: List<String>.from(json['registeredEvents'] ?? []),
      bookmarkedEvents: List<String>.from(json['bookmarkedEvents'] ?? []),
    );
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
