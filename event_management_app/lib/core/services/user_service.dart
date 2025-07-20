// core/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  static final CollectionReference _usersCollection =
      _firestore.collection('users');
  static final CollectionReference _registrationsCollection =
      _firestore.collection('event_registrations');
  static final CollectionReference _eventsCollection =
      _firestore.collection('events');

  /// Get user's registrations with event details
  static Future<List<Map<String, dynamic>>> getUserRegistrations() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final registrations = await _registrationsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('registrationDate', descending: true)
          .get();

      final List<Map<String, dynamic>> registrationsWithEvents = [];

      for (final doc in registrations.docs) {
        final registrationData = doc.data() as Map<String, dynamic>;
        registrationData['id'] = doc.id;

        // Get event details
        final eventDoc =
            await _eventsCollection.doc(registrationData['eventId']).get();

        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          eventData['id'] = eventDoc.id;
          registrationData['event'] = eventData;
        }

        registrationsWithEvents.add(registrationData);
      }

      return registrationsWithEvents;
    } catch (e) {
      throw Exception('Failed to load registrations: ${e.toString()}');
    }
  }

  /// Get user's bookmarked events
  static Future<List<Map<String, dynamic>>> getUserBookmarks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final bookmarkedEventIds =
          List<String>.from(userData['bookmarkedEvents'] ?? []);

      if (bookmarkedEventIds.isEmpty) {
        return [];
      }

      final events = await _eventsCollection
          .where(FieldPath.documentId, whereIn: bookmarkedEventIds)
          .get();

      return events.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['isBookmarked'] = true;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load bookmarks: ${e.toString()}');
    }
  }

  /// Register user for an event
  static Future<Map<String, dynamic>> registerForEvent(String eventId,
      {double? amount}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if event exists and is not full
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final maxAttendees = eventData['maxAttendees'] ?? 0;
      final currentAttendees = eventData['attendeesCount'] ?? 0;

      if (maxAttendees > 0 && currentAttendees >= maxAttendees) {
        return {
          'success': false,
          'message': 'Event is full',
        };
      }

      // Check if user is already registered
      final existingRegistration = await _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Already registered for this event',
        };
      }

      // Get user data
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // Create registration
      final registrationData = {
        'eventId': eventId,
        'userId': currentUser.uid,
        'userName':
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim(),
        'userEmail': currentUser.email ?? '',
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'amountPaid': amount ?? eventData['price'] ?? 0.0,
        'hasAttended': false,
        'qrCode': _generateQRCode(currentUser.uid, eventId),
      };

      print('🔥 ATTEMPTING REGISTRATION:');
      print('  User ID: ${currentUser.uid}');
      print('  Event ID: $eventId');
      print('  User authenticated: ${currentUser.uid != null}');
      print('  Registration data: $registrationData');

      final regDoc = await _registrationsCollection.add(registrationData);

      // Update event attendees count
      await _eventsCollection.doc(eventId).update({
        'attendeesCount': FieldValue.increment(1),
      });

      // Update user's registered events
      await _usersCollection.doc(currentUser.uid).update({
        'registeredEvents': FieldValue.arrayUnion([eventId]),
      });

      // Get the created registration
      final createdReg = await regDoc.get();
      final registrationResult = createdReg.data() as Map<String, dynamic>;
      registrationResult['id'] = regDoc.id;

      return {
        'success': true,
        'message': 'Successfully registered for event',
        'registration': registrationResult,
      };
    } catch (e) {
      print('❌ REGISTRATION ERROR: ${e.toString()}');
      print('   Error type: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  /// Cancel user's event registration
  static Future<Map<String, dynamic>> cancelRegistration(
      String registrationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final regDoc = await _registrationsCollection.doc(registrationId).get();
      if (!regDoc.exists) {
        throw Exception('Registration not found');
      }

      final regData = regDoc.data() as Map<String, dynamic>;

      // Verify ownership
      if (regData['userId'] != currentUser.uid) {
        throw Exception('Not authorized to cancel this registration');
      }

      final eventId = regData['eventId'];

      // Delete registration
      await _registrationsCollection.doc(registrationId).delete();

      // Update event attendees count
      await _eventsCollection.doc(eventId).update({
        'attendeesCount': FieldValue.increment(-1),
      });

      // Update user's registered events
      await _usersCollection.doc(currentUser.uid).update({
        'registeredEvents': FieldValue.arrayRemove([eventId]),
      });

      return {
        'success': true,
        'message': 'Registration cancelled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cancellation failed: ${e.toString()}',
      };
    }
  }

  /// Toggle event bookmark
  static Future<Map<String, dynamic>> toggleBookmark(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final bookmarkedEvents =
          List<String>.from(userData['bookmarkedEvents'] ?? []);

      bool isBookmarked = bookmarkedEvents.contains(eventId);

      if (isBookmarked) {
        // Remove bookmark
        await _usersCollection.doc(currentUser.uid).update({
          'bookmarkedEvents': FieldValue.arrayRemove([eventId]),
        });
        isBookmarked = false;
      } else {
        // Add bookmark
        await _usersCollection.doc(currentUser.uid).update({
          'bookmarkedEvents': FieldValue.arrayUnion([eventId]),
        });
        isBookmarked = true;
      }

      // Get event data to return
      final eventDoc = await _eventsCollection.doc(eventId).get();
      Map<String, dynamic>? eventData;
      if (eventDoc.exists) {
        eventData = eventDoc.data() as Map<String, dynamic>;
        eventData['id'] = eventDoc.id;
      }

      return {
        'success': true,
        'isBookmarked': isBookmarked,
        'message': isBookmarked ? 'Event bookmarked' : 'Bookmark removed',
        'event': eventData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bookmark failed: ${e.toString()}',
      };
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profileImage'] = profileImage;

      await _usersCollection.doc(currentUser.uid).update(updateData);

      // Update Firebase Auth display name if name changed
      if (firstName != null || lastName != null) {
        final userDoc = await _usersCollection.doc(currentUser.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>;
        String displayName = '${userData['firstName']} ${userData['lastName']}';
        await currentUser.updateDisplayName(displayName);
      }

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Profile update failed: ${e.toString()}',
      };
    }
  }

  /// Upload profile image
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final ref = _storage.ref().child(
          'profile_images/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Get user's attended events
  static Future<List<Map<String, dynamic>>> getUserAttendedEvents() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final attendedRegistrations = await _registrationsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .where('hasAttended', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> attendedEvents = [];

      for (final doc in attendedRegistrations.docs) {
        final regData = doc.data() as Map<String, dynamic>;
        final eventDoc = await _eventsCollection.doc(regData['eventId']).get();

        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          eventData['id'] = eventDoc.id;
          eventData['attendanceTime'] = regData['attendanceTime'];
          attendedEvents.add(eventData);
        }
      }

      return attendedEvents;
    } catch (e) {
      throw Exception('Failed to load attended events: ${e.toString()}');
    }
  }

  /// Get user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final registrations = await _registrationsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      final attendedCount = registrations.docs
          .where((doc) =>
              (doc.data() as Map<String, dynamic>)['hasAttended'] == true)
          .length;

      final registeredCount = registrations.docs.length;
      final bookmarkedCount =
          (userData['bookmarkedEvents'] as List?)?.length ?? 0;

      return {
        'attended': attendedCount,
        'registered': registeredCount,
        'bookmarked': bookmarkedCount,
      };
    } catch (e) {
      throw Exception('Failed to load statistics: ${e.toString()}');
    }
  }

  /// Generate QR code for registration
  static String _generateQRCode(String userId, String eventId) {
    return '${userId}_${eventId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
