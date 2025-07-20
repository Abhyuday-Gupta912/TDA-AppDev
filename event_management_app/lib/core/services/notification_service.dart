// core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Set default timezone
      final String timeZoneName = await _getTimeZoneName();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request permissions for Android 13+
      await _requestPermissions();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize notifications: $e');
      }
    }
  }

  static Future<String> _getTimeZoneName() async {
    try {
      // Try to get the system timezone
      // For simplicity, using UTC as default, but in a real app you'd want to detect the actual timezone
      return 'UTC';
    } catch (e) {
      return 'UTC'; // fallback
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request notification permissions: $e');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // Handle notification tap - could navigate to specific event
    // You could parse the payload and handle navigation here
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'event_channel',
        'Event Notifications',
        channelDescription: 'Notifications for event updates and reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to show notification: $e');
      }
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('Cannot schedule notification for past date');
        }
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'event_reminders',
        'Event Reminders',
        channelDescription: 'Scheduled reminders for upcoming events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule notification: $e');
      }
    }
  }

  static Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventStartDate,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    final reminderTime = eventStartDate.subtract(reminderBefore);

    await scheduleNotification(
      id: eventId.hashCode,
      title: 'Event Reminder',
      body: '$eventTitle starts in ${_formatDuration(reminderBefore)}',
      scheduledDate: reminderTime,
      payload: 'event:$eventId',
    );
  }

  static Future<void> scheduleMultipleEventReminders({
    required String eventId,
    required String eventTitle,
    required DateTime eventStartDate,
  }) async {
    // Schedule multiple reminders: 1 day, 1 hour, and 15 minutes before
    final reminders = [
      const Duration(days: 1),
      const Duration(hours: 1),
      const Duration(minutes: 15),
    ];

    for (int i = 0; i < reminders.length; i++) {
      final reminderTime = eventStartDate.subtract(reminders[i]);

      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: (eventId + i.toString()).hashCode,
          title: 'Event Reminder',
          body: '$eventTitle starts in ${_formatDuration(reminders[i])}',
          scheduledDate: reminderTime,
          payload: 'event:$eventId',
        );
      }
    }
  }

  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel notification: $e');
      }
    }
  }

  static Future<void> cancelEventNotifications(String eventId) async {
    // Cancel all notifications for an event (including multiple reminders)
    for (int i = 0; i < 3; i++) {
      await cancelNotification((eventId + i.toString()).hashCode);
    }
    await cancelNotification(eventId.hashCode);
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel all notifications: $e');
      }
    }
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get pending notifications: $e');
      }
      return [];
    }
  }

  // Event-specific notification methods
  static Future<void> notifyEventRegistration(String eventTitle) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Registration Successful! 🎉',
      body: 'You\'re registered for $eventTitle',
      payload: 'registration_success',
    );
  }

  static Future<void> notifyEventUpdate(
      String eventTitle, String updateMessage) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Event Update: $eventTitle',
      body: updateMessage,
      payload: 'event_update',
    );
  }

  static Future<void> notifyEventCancellation(String eventTitle) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Event Cancelled ⚠️',
      body: '$eventTitle has been cancelled',
      payload: 'event_cancelled',
    );
  }
}
