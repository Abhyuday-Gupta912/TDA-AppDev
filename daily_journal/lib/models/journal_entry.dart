class JournalEntry {
  final String date;
  String content;
  final DateTime createdAt;
  String mood;

  JournalEntry({
    required this.date,
    required this.content,
    required this.createdAt,
    this.mood = '😊',
  });

  JournalEntry copyWith({
    String? date,
    String? content,
    DateTime? createdAt,
    String? mood,
  }) {
    return JournalEntry(
      date: date ?? this.date,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      mood: mood ?? this.mood,
    );
  }

  bool get isEmpty => content.trim().isEmpty;

  String get preview {
    if (isEmpty) return 'Tap to write something...';
    return content.length > 60 ? '${content.substring(0, 60)}...' : content;
  }

  int get wordCount {
    if (isEmpty) return 0;
    return content.split(' ').where((word) => word.isNotEmpty).length;
  }
}
