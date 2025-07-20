// core/services/event_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  static final CollectionReference _eventsCollection =
      _firestore.collection('events');
  static final CollectionReference _registrationsCollection =
      _firestore.collection('event_registrations');
  static final CollectionReference _usersCollection =
      _firestore.collection('users');

  /// Get all events
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      final QuerySnapshot querySnapshot =
          await _eventsCollection.orderBy('startDate', descending: false).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: ${e.toString()}');
    }
  }

  /// Get event by ID
  static Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final DocumentSnapshot doc = await _eventsCollection.doc(eventId).get();

      if (!doc.exists) {
        throw Exception('Event not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      // Get current user's registration status for this event
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final registrationQuery = await _registrationsCollection
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (registrationQuery.docs.isNotEmpty) {
          data['registrationStatus'] = 'registered';
        }

        // Check if event is bookmarked
        final userDoc = await _usersCollection.doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final bookmarkedEvents =
              List<String>.from(userData['bookmarkedEvents'] ?? []);
          data['isBookmarked'] = bookmarkedEvents.contains(eventId);
        }
      }

      return data;
    } catch (e) {
      throw Exception('Failed to fetch event: ${e.toString()}');
    }
  }

  /// Create new event
  static Future<Map<String, dynamic>> createEvent(
      Map<String, dynamic> eventData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add server timestamp and user info
      eventData['createdAt'] = FieldValue.serverTimestamp();
      eventData['updatedAt'] = FieldValue.serverTimestamp();
      eventData['organizerId'] = currentUser.uid;

      // Get organizer name from user document
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        eventData['organizerName'] =
            '${userData['firstName']} ${userData['lastName']}';
      }

      eventData['attendeesCount'] = 0;
      eventData['isLive'] = false;

      final DocumentReference docRef = await _eventsCollection.add(eventData);

      // Get the created document
      final createdDoc = await docRef.get();
      final createdData = createdDoc.data() as Map<String, dynamic>;
      createdData['id'] = docRef.id;

      return {
        'success': true,
        'event': createdData,
        'message': 'Event created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create event: ${e.toString()}',
      };
    }
  }

  /// Update event
  static Future<Map<String, dynamic>> updateEvent(
      String eventId, Map<String, dynamic> updates) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is the organizer or admin
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (eventData['organizerId'] != currentUser.uid &&
          !(userData['isAdmin'] ?? false)) {
        throw Exception('Not authorized to update this event');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _eventsCollection.doc(eventId).update(updates);

      // Get updated document
      final updatedDoc = await _eventsCollection.doc(eventId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      updatedData['id'] = eventId;

      return {
        'success': true,
        'event': updatedData,
        'message': 'Event updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update event: ${e.toString()}',
      };
    }
  }

  /// Delete event
  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is the organizer or admin
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (eventData['organizerId'] != currentUser.uid &&
          !(userData['isAdmin'] ?? false)) {
        throw Exception('Not authorized to delete this event');
      }

      // Delete all registrations for this event
      final registrations = await _registrationsCollection
          .where('eventId', isEqualTo: eventId)
          .get();

      final batch = _firestore.batch();
      for (final doc in registrations.docs) {
        batch.delete(doc.reference);
      }

      // Delete the event
      batch.delete(_eventsCollection.doc(eventId));

      await batch.commit();

      return {
        'success': true,
        'message': 'Event deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete event: ${e.toString()}',
      };
    }
  }

  /// Register for event
  static Future<Map<String, dynamic>> registerForEvent(String eventId) async {
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
        'amountPaid': eventData['price'] ?? 0.0,
        'hasAttended': false,
      };

      await _registrationsCollection.add(registrationData);

      // Update event attendees count
      await _eventsCollection.doc(eventId).update({
        'attendeesCount': FieldValue.increment(1),
      });

      // Update user's registered events
      await _usersCollection.doc(currentUser.uid).update({
        'registeredEvents': FieldValue.arrayUnion([eventId]),
      });

      return {
        'success': true,
        'message': 'Successfully registered for event',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to register for event: ${e.toString()}',
      };
    }
  }

  /// Toggle bookmark for event
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

      if (bookmarkedEvents.contains(eventId)) {
        // Remove bookmark
        await _usersCollection.doc(currentUser.uid).update({
          'bookmarkedEvents': FieldValue.arrayRemove([eventId]),
        });
        return {
          'success': true,
          'message': 'Bookmark removed',
          'isBookmarked': false,
        };
      } else {
        // Add bookmark
        await _usersCollection.doc(currentUser.uid).update({
          'bookmarkedEvents': FieldValue.arrayUnion([eventId]),
        });
        return {
          'success': true,
          'message': 'Event bookmarked',
          'isBookmarked': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to toggle bookmark: ${e.toString()}',
      };
    }
  }

  /// Check in attendee using QR code
  static Future<Map<String, dynamic>> checkInAttendee(
      String eventId, String qrData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Verify organizer or admin
      final eventDoc = await _eventsCollection.doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (eventData['organizerId'] != currentUser.uid &&
          !(userData['isAdmin'] ?? false)) {
        throw Exception('Not authorized to check in attendees');
      }

      // Find registration by QR data (could be registration ID or user ID)
      QuerySnapshot registrationQuery;

      try {
        // Try to find by registration ID first
        registrationQuery = await _registrationsCollection
            .where('eventId', isEqualTo: eventId)
            .where('id', isEqualTo: qrData)
            .limit(1)
            .get();

        if (registrationQuery.docs.isEmpty) {
          // Try to find by user ID
          registrationQuery = await _registrationsCollection
              .where('eventId', isEqualTo: eventId)
              .where('userId', isEqualTo: qrData)
              .limit(1)
              .get();
        }
      } catch (e) {
        throw Exception('Invalid QR code');
      }

      if (registrationQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Registration not found or invalid QR code',
        };
      }

      final registrationDoc = registrationQuery.docs.first;
      final registrationData = registrationDoc.data() as Map<String, dynamic>;

      if (registrationData['hasAttended'] == true) {
        return {
          'success': false,
          'message': 'Attendee has already checked in',
        };
      }

      // Update registration to mark as attended
      await registrationDoc.reference.update({
        'hasAttended': true,
        'attendanceTime': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'eventName': eventData['title'] ?? 'Event',
        'attendeeName': registrationData['userName'] ?? 'Attendee',
        'message': 'Check-in successful!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Check-in failed: ${e.toString()}',
      };
    }
  }

  /// Get user's registered events
  static Future<List<Map<String, dynamic>>> getUserRegisteredEvents() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final registrations = await _registrationsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final eventIds = registrations.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['eventId'] as String)
          .toList();

      if (eventIds.isEmpty) {
        return [];
      }

      final events = await _eventsCollection
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      return events.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch registered events: ${e.toString()}');
    }
  }

  /// Upload event image
  static Future<String> uploadEventImage(File imageFile, String eventId) async {
    try {
      final ref = _storage.ref().child(
          'event_images/$eventId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Search events
  static Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      final allEvents = await getAllEvents();
      final lowercaseQuery = query.toLowerCase();

      return allEvents.where((event) {
        final title = (event['title'] ?? '').toLowerCase();
        final description = (event['description'] ?? '').toLowerCase();
        final category = (event['category'] ?? '').toLowerCase();
        final organizerName = (event['organizerName'] ?? '').toLowerCase();

        return title.contains(lowercaseQuery) ||
            description.contains(lowercaseQuery) ||
            category.contains(lowercaseQuery) ||
            organizerName.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search events: ${e.toString()}');
    }
  }
}
