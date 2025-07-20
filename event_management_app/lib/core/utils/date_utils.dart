import 'package:intl/intl.dart';

class AppDateUtils {
  // Date formats
  static const String _dayMonthFormat = 'dd MMM';
  static const String _dayMonthYearFormat = 'dd MMM yyyy';
  static const String _timeFormat = 'HH:mm';
  static const String _time12Format = 'h:mm a';
  static const String _fullDateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String _dayFormat = 'EEEE';
  static const String _monthYearFormat = 'MMM yyyy';

  /// Formats date to "15 Jan" format
  static String formatDayMonth(DateTime date) {
    return DateFormat(_dayMonthFormat).format(date);
  }

  /// Formats date to "15 Jan 2024" format
  static String formatDayMonthYear(DateTime date) {
    return DateFormat(_dayMonthYearFormat).format(date);
  }

  /// Formats time to "14:30" format
  static String formatTime24(DateTime date) {
    return DateFormat(_timeFormat).format(date);
  }

  /// Formats time to "2:30 PM" format
  static String formatTime12(DateTime date) {
    return DateFormat(_time12Format).format(date);
  }

  /// Formats full date and time to "15 Jan 2024, 14:30" format
  static String formatFullDateTime(DateTime date) {
    return DateFormat(_fullDateTimeFormat).format(date);
  }

  /// Formats date to day name "Monday"
  static String formatDayName(DateTime date) {
    return DateFormat(_dayFormat).format(date);
  }

  /// Formats date to "Jan 2024" format
  static String formatMonthYear(DateTime date) {
    return DateFormat(_monthYearFormat).format(date);
  }

  /// Returns a relative time string like "in 2 hours", "yesterday", etc.
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'in $years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'in $months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays == 0 && difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays == 0 && difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inDays == 0 &&
        difference.inMinutes <= 0 &&
        difference.inMinutes > -60) {
      return 'now';
    } else if (difference.inDays == 0 &&
        difference.inHours < 0 &&
        difference.inHours > -24) {
      final hours = difference.inHours.abs();
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 0 && difference.inDays > -2) {
      return 'yesterday';
    } else if (difference.inDays < 0 && difference.inDays > -7) {
      final days = difference.inDays.abs();
      return '$days day${days > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 0 && difference.inDays > -30) {
      final weeks = (difference.inDays.abs() / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 0 && difference.inDays > -365) {
      final months = (difference.inDays.abs() / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays.abs() / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Returns event status based on dates
  static String getEventStatus(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return 'upcoming';
    } else if (now.isAfter(startDate) && now.isBefore(endDate)) {
      return 'live';
    } else {
      return 'ended';
    }
  }

  /// Formats date range (alias for formatEventDateRange)
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    return formatEventDateRange(startDate, endDate);
  }

  /// Formats event date and time for display
  static String formatEventDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today, ${formatTime12(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow, ${formatTime12(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${formatDayName(dateTime)}, ${formatTime12(dateTime)}';
    } else {
      return '${formatDayMonth(dateTime)}, ${formatTime12(dateTime)}';
    }
  }

  /// Formats event date range
  static String formatEventDateRange(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final isToday = startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;

    final isTomorrow = startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day + 1;

    final isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (isToday) {
      if (isSameDay) {
        return 'Today, ${formatTime12(startDate)} - ${formatTime12(endDate)}';
      } else {
        return 'Today, ${formatTime12(startDate)} - ${formatDayMonth(endDate)}, ${formatTime12(endDate)}';
      }
    } else if (isTomorrow) {
      if (isSameDay) {
        return 'Tomorrow, ${formatTime12(startDate)} - ${formatTime12(endDate)}';
      } else {
        return 'Tomorrow, ${formatTime12(startDate)} - ${formatDayMonth(endDate)}, ${formatTime12(endDate)}';
      }
    } else {
      if (isSameDay) {
        return '${formatDayMonth(startDate)}, ${formatTime12(startDate)} - ${formatTime12(endDate)}';
      } else {
        return '${formatDayMonth(startDate)}, ${formatTime12(startDate)} - ${formatDayMonth(endDate)}, ${formatTime12(endDate)}';
      }
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Get time until event starts
  static String getTimeUntilEvent(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      return 'Event started';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Starting soon';
    }
  }

  /// Calculate event duration
  static String getEventDuration(DateTime startDate, DateTime endDate) {
    final duration = endDate.difference(startDate);

    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ${hours}h';
      } else {
        return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
      }
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${duration.inHours}h ${minutes}m';
      } else {
        return '${duration.inHours}h';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
