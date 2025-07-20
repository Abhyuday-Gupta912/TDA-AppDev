import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? imageUrl;
  final double price;
  final int maxAttendees;
  final int attendeesCount;
  final String? registrationStatus;
  final bool isLive;
  final bool isBookmarked;
  final String organizerId;
  final String organizerName;
  final List<String> tags;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.imageUrl,
    this.price = 0.0,
    required this.maxAttendees,
    this.attendeesCount = 0,
    this.registrationStatus,
    this.isLive = false,
    this.isBookmarked = false,
    required this.organizerId,
    required this.organizerName,
    this.tags = const [],
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFree => price == 0;
  bool get isFull => attendeesCount >= maxAttendees;
  bool get isUpcoming {
    final now = DateTime.now();
    final isAfter = startDate.isAfter(now);
    print(
        'Event ${title}: startDate=${startDate}, now=${now}, isUpcoming=${isAfter}');
    return isAfter;
  }

  bool get isPast => endDate.isBefore(DateTime.now());

  double get availabilityPercentage =>
      maxAttendees > 0 ? (attendeesCount / maxAttendees) * 100 : 0;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'],
      price: (json['price'] ?? 0).toDouble(),
      maxAttendees: json['maxAttendees'] ?? 0,
      attendeesCount: json['attendeesCount'] ?? 0,
      registrationStatus: json['registrationStatus'],
      isLive: json['isLive'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      organizerId: json['organizerId'] ?? json['organizer']?['_id'] ?? '',
      organizerName: json['organizerName'] ?? json['organizer']?['name'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      additionalInfo: json['additionalInfo'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
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
      'title': title,
      'description': description,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'imageUrl': imageUrl,
      'price': price,
      'maxAttendees': maxAttendees,
      'attendeesCount': attendeesCount,
      'registrationStatus': registrationStatus,
      'isLive': isLive,
      'isBookmarked': isBookmarked,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'tags': tags,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    double? price,
    int? maxAttendees,
    int? attendeesCount,
    String? registrationStatus,
    bool? isLive,
    bool? isBookmarked,
    String? organizerId,
    String? organizerName,
    List<String>? tags,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      isLive: isLive ?? this.isLive,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      tags: tags ?? this.tags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Event Registration Model
class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime registrationDate;
  final String status; // 'confirmed', 'pending', 'cancelled'
  final double amountPaid;
  final String? paymentId;
  final String? qrCode;
  final bool hasAttended;
  final DateTime? attendanceTime;

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.registrationDate,
    this.status = 'pending',
    this.amountPaid = 0.0,
    this.paymentId,
    this.qrCode,
    this.hasAttended = false,
    this.attendanceTime,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['_id'] ?? json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      registrationDate: Event._parseDateTime(json['registrationDate']),
      status: json['status'] ?? 'pending',
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      paymentId: json['paymentId'],
      qrCode: json['qrCode'],
      hasAttended: json['hasAttended'] ?? false,
      attendanceTime: json['attendanceTime'] != null
          ? Event._parseDateTime(json['attendanceTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status,
      'amountPaid': amountPaid,
      'paymentId': paymentId,
      'qrCode': qrCode,
      'hasAttended': hasAttended,
      'attendanceTime': attendanceTime?.toIso8601String(),
    };
  }
}
