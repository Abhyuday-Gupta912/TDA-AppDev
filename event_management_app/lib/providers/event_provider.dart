import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../core/services/event_service.dart';
import '../core/services/storage_service.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered events
  List<Event> get upcomingEvents {
    final upcoming = _events
        .where((event) => event.isUpcoming && !event.isLive)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    print(
        'EventProvider: Total events: ${_events.length}, Upcoming: ${upcoming.length}');
    for (var event in _events) {
      print(
          'Event: ${event.title}, Start: ${event.startDate}, isUpcoming: ${event.isUpcoming}, isLive: ${event.isLive}');
    }
    return upcoming;
  }

  List<Event> get liveEvents => _events.where((event) => event.isLive).toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));

  List<Event> get popularEvents =>
      _events.where((event) => !event.isPast).toList()
        ..sort((a, b) => b.attendeesCount.compareTo(a.attendeesCount));

  List<Event> get pastEvents => _events.where((event) => event.isPast).toList()
    ..sort((a, b) => b.endDate.compareTo(a.endDate));

  Future<void> loadEvents() async {
    _setLoading(true);
    _setError(null);

    try {
      final eventsData = await EventService.getAllEvents();
      _events = eventsData.map((json) => Event.fromJson(json)).toList();
      print('EventProvider: Loaded ${_events.length} events'); // Debug log
      notifyListeners();
    } catch (e) {
      print('EventProvider Error: ${e.toString()}'); // Debug log
      _setError('Failed to load events: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      // First check if event is already in local list
      final localEvent = _events.firstWhere(
        (event) => event.id == eventId,
        orElse: () => throw Exception('Not found locally'),
      );
      return localEvent;
    } catch (e) {
      // If not found locally, fetch from API
      try {
        final eventData = await EventService.getEventById(eventId);
        return Event.fromJson(eventData);
      } catch (e) {
        return null;
      }
    }
  }

  Future<bool> createEvent(Event event) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await EventService.createEvent(event.toJson());
      if (response['success']) {
        final newEvent = Event.fromJson(response['event']);
        _events.insert(0, newEvent);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to create event');
        return false;
      }
    } catch (e) {
      _setError('Failed to create event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await EventService.updateEvent(eventId, updates);
      if (response['success']) {
        final updatedEvent = Event.fromJson(response['event']);
        final index = _events.indexWhere((event) => event.id == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
          notifyListeners();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update event');
        return false;
      }
    } catch (e) {
      _setError('Failed to update event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await EventService.deleteEvent(eventId);
      if (response['success']) {
        _events.removeWhere((event) => event.id == eventId);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to delete event');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerForEvent(String eventId) async {
    try {
      final response = await EventService.registerForEvent(eventId);
      if (response['success']) {
        // Update local event data
        final index = _events.indexWhere((event) => event.id == eventId);
        if (index != -1) {
          _events[index] = _events[index].copyWith(
            attendeesCount: _events[index].attendeesCount + 1,
          );
          notifyListeners();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to register for event');
        return false;
      }
    } catch (e) {
      _setError('Failed to register for event: ${e.toString()}');
      return false;
    }
  }

  Future<bool> toggleBookmark(String eventId) async {
    try {
      final response = await EventService.toggleBookmark(eventId);
      if (response['success']) {
        // Update local event data
        final index = _events.indexWhere((event) => event.id == eventId);
        if (index != -1) {
          _events[index] = _events[index].copyWith(
            isBookmarked: !_events[index].isBookmarked,
          );
          notifyListeners();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to bookmark event');
        return false;
      }
    } catch (e) {
      _setError('Failed to bookmark event: ${e.toString()}');
      return false;
    }
  }

  List<Event> searchEvents(String query) {
    if (query.isEmpty) return _events;

    final lowercaseQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowercaseQuery) ||
          event.description.toLowerCase().contains(lowercaseQuery) ||
          event.category.toLowerCase().contains(lowercaseQuery) ||
          event.organizerName.toLowerCase().contains(lowercaseQuery) ||
          event.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  List<Event> filterEventsByCategory(String category) {
    if (category == 'All') return _events;
    return _events
        .where(
            (event) => event.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<Event> getEventsByDateRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.startDate.isAfter(start) && event.startDate.isBefore(end);
    }).toList();
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

  void refreshEvents() {
    loadEvents();
  }
}
