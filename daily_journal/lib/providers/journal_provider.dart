import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class JournalProvider extends ChangeNotifier {
  final List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  JournalProvider();

  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
    _entries.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );
    notifyListeners();
  }

  void updateEntry(String date, JournalEntry updatedEntry) {
    final index = _entries.indexWhere((entry) => entry.date == date);

    if (index != -1) {
      _entries[index] = updatedEntry;
      _entries.sort(
        (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
      );
      notifyListeners();
    }
  }

  void deleteEntry(String date) {
    _entries.removeWhere((entry) => entry.date == date);
    notifyListeners();
  }

  bool hasEntryForDate(String date) {
    return _entries.any((entry) => entry.date == date);
  }

  JournalEntry? getEntryForDate(String date) {
    try {
      return _entries.firstWhere((entry) => entry.date == date);
    } catch (e) {
      return null;
    }
  }

  String get todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get defaultNewEntryDate {
    if (_entries.isEmpty) {
      return todayString;
    } else {
      DateTime lastEntryDate = DateTime.parse(_entries.first.date);
      DateTime nextDay = lastEntryDate.add(Duration(days: 1));
      return '${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}';
    }
  }

  bool get hasTodayEntry => hasEntryForDate(todayString);

  JournalEntry? get todayEntry => getEntryForDate(todayString);
}
