import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../core/services/user_service.dart';
import '../core/services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  List<Event> _registeredEvents = [];
  List<Event> _bookmarkedEvents = [];
  List<Event> _attendedEvents = [];
  List<EventRegistration> _userRegistrations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get registeredEvents => _registeredEvents;
  List<Event> get bookmarkedEvents => _bookmarkedEvents;
  List<Event> get attendedEvents => _attendedEvents;
  List<EventRegistration> get userRegistrations => _userRegistrations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  int get attendedEventsCount => _attendedEvents.length;
  int get registeredEventsCount => _registeredEvents.length;
  int get bookmarkedEventsCount => _bookmarkedEvents.length;

  // Load user registrations
  Future<void> loadUserRegistrations() async {
    _setLoading(true);
    _setError(null);

    try {
      final registrationsData = await UserService.getUserRegistrations();

      _userRegistrations = registrationsData
          .map((json) => EventRegistration.fromJson(json))
          .toList();

      // Extract events from registrations
      _registeredEvents = _userRegistrations
          .where((reg) => reg.status == 'confirmed')
          .map((reg) => _getEventFromRegistration(reg))
          .where((event) => event != null)
          .cast<Event>()
          .toList();

      // Filter attended events
      _attendedEvents = _userRegistrations
          .where((reg) => reg.hasAttended)
          .map((reg) => _getEventFromRegistration(reg))
          .where((event) => event != null)
          .cast<Event>()
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load registrations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user bookmarks
  Future<void> loadUserBookmarks() async {
    try {
      final bookmarksData = await UserService.getUserBookmarks();

      _bookmarkedEvents =
          bookmarksData.map((json) => Event.fromJson(json)).toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load bookmarks: ${e.toString()}');
    }
  }

  // Register for event
  Future<bool> registerForEvent(String eventId, {double? amount}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response =
          await UserService.registerForEvent(eventId, amount: amount);

      if (response['success']) {
        // Add to registrations
        final registration =
            EventRegistration.fromJson(response['registration']);
        _userRegistrations.add(registration);

        // Add to registered events if confirmed
        if (registration.status == 'confirmed') {
          final event = _getEventFromRegistration(registration);
          if (event != null) {
            _registeredEvents.add(event);
          }
        }

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel registration
  Future<bool> cancelRegistration(String registrationId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await UserService.cancelRegistration(registrationId);

      if (response['success']) {
        // Remove from registrations
        _userRegistrations.removeWhere((reg) => reg.id == registrationId);

        // Remove from registered events
        final registration = _userRegistrations.firstWhere(
          (reg) => reg.id == registrationId,
          orElse: () => throw Exception('Registration not found'),
        );

        _registeredEvents
            .removeWhere((event) => event.id == registration.eventId);

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Cancellation failed');
        return false;
      }
    } catch (e) {
      _setError('Cancellation failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String eventId) async {
    try {
      final response = await UserService.toggleBookmark(eventId);

      if (response['success']) {
        final isBookmarked = response['isBookmarked'] ?? false;

        if (isBookmarked) {
          // Add to bookmarks
          final event = Event.fromJson(response['event']);
          _bookmarkedEvents.add(event);
        } else {
          // Remove from bookmarks
          _bookmarkedEvents.removeWhere((event) => event.id == eventId);
        }

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Bookmark failed');
        return false;
      }
    } catch (e) {
      _setError('Bookmark failed: ${e.toString()}');
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await UserService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: profileImage,
      );

      if (response['success']) {
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is registered for event
  bool isRegisteredForEvent(String eventId) {
    return _userRegistrations
        .any((reg) => reg.eventId == eventId && reg.status == 'confirmed');
  }

  // Check if user has bookmarked event
  bool hasBookmarkedEvent(String eventId) {
    return _bookmarkedEvents.any((event) => event.id == eventId);
  }

  // Get registration for event
  EventRegistration? getRegistrationForEvent(String eventId) {
    try {
      return _userRegistrations.firstWhere((reg) => reg.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  // Get user's upcoming events
  List<Event> getUpcomingEvents() {
    final now = DateTime.now();
    return _registeredEvents
        .where((event) => event.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  // Get user's past events
  List<Event> getPastEvents() {
    final now = DateTime.now();
    return _registeredEvents
        .where((event) => event.endDate.isBefore(now))
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
  }

  // Get events by category
  List<Event> getEventsByCategory(String category) {
    return _registeredEvents
        .where(
            (event) => event.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Private helper methods
  Event? _getEventFromRegistration(EventRegistration registration) {
    // In a real app, you might need to fetch event details
    // For now, we'll create a basic event object
    // This would typically be handled by the backend or cached locally
    return null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all user data
  Future<void> refreshUserData() async {
    await Future.wait([
      loadUserRegistrations(),
      loadUserBookmarks(),
    ]);
  }

  // Clear all user data (for logout)
  void clearUserData() {
    _registeredEvents.clear();
    _bookmarkedEvents.clear();
    _attendedEvents.clear();
    _userRegistrations.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
