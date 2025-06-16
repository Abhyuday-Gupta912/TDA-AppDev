import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange.shade600,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange.shade400,
          brightness: Brightness.light,
        ),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<JournalEntry> entries = [];

  @override
  void initState() {
    super.initState();
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  void _addNewEntry() async {
    String defaultDate;
    if (entries.isEmpty) {
      defaultDate = DateTime.now().toIso8601String().split('T')[0];
    } else {
      DateTime lastEntryDate = DateTime.parse(entries.first.date);
      DateTime nextDay = lastEntryDate.add(Duration(days: 1));
      defaultDate = nextDay.toIso8601String().split('T')[0];
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryScreen(
          entry: JournalEntry(
            date: defaultDate,
            content: '',
            createdAt: DateTime.now(),
          ),
          isEditing: false,
        ),
      ),
    );

    if (result != null && result is JournalEntry) {
      setState(() {
        entries.insert(0, result);
        entries.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      });
    }
  }

  void _viewEntry(JournalEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryScreen(
          entry: entry,
          isEditing: true,
        ),
      ),
    );

    if (result != null) {
      if (result is JournalEntry) {
        setState(() {
          int index = entries.indexWhere((e) => e.date == entry.date);
          if (index != -1) {
            entries[index] = result;
          }
        });
      } else if (result == 'delete') {
        setState(() {
          entries.removeWhere((e) => e.date == entry.date);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Journal'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: entries.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 80,
              color: Colors.orange.shade300,
            ),
            SizedBox(height: 20),
            Text(
              'Start Your Journal! ✨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No entries yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.brown.shade600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap the + button to write your first entry',
              style: TextStyle(
                fontSize: 14,
                color: Colors.brown.shade400,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            margin: EdgeInsets.all(8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  entry.mood,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              title: Text(
                _formatDate(entry.date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange.shade700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    entry.content.isEmpty
                        ? 'Tap to write something...'
                        : entry.content.length > 60
                        ? '${entry.content.substring(0, 60)}...'
                        : entry.content,
                    style: TextStyle(
                      color: entry.content.isEmpty
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontStyle: entry.content.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${entry.content.split(' ').where((word) => word.isNotEmpty).length} words',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade400,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.edit,
                color: Colors.orange.shade400,
              ),
              onTap: () => _viewEntry(entry),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class EntryScreen extends StatefulWidget {
  final JournalEntry entry;
  final bool isEditing;

  EntryScreen({
    required this.entry,
    required this.isEditing,
  });

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late TextEditingController _controller;
  late DateTime _selectedDate;
  late String _selectedMood;
  bool _hasChanges = false;

  final List<String> _moods = [
    '😊', '😢', '😍', '😴', '🎉', '😤', '🤔', '😌', '☕', '🌟', '🌳', '💪'
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.content);
    _selectedDate = DateTime.parse(widget.entry.date);
    _selectedMood = widget.entry.mood;
    _controller.addListener(() {
      setState(() {
        _hasChanges = _controller.text != widget.entry.content ||
            _selectedDate.toIso8601String().split('T')[0] != widget.entry.date ||
            _selectedMood != widget.entry.mood;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  void _showMoodPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How are you feeling?'),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = _moods[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedMood == _moods[index]
                            ? Colors.orange.shade600
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _moods[index],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEntry() {
    if (_controller.text.trim().isNotEmpty || widget.isEditing) {
      JournalEntry updatedEntry = JournalEntry(
        date: _selectedDate.toIso8601String().split('T')[0],
        content: _controller.text.trim(),
        createdAt: widget.entry.createdAt,
        mood: _selectedMood,
      );
      Navigator.pop(context, updatedEntry);
    } else {
      Navigator.pop(context);
    }
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Entry'),
          content: Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, 'delete');
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showUnsavedDialog() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Unsaved Changes'),
            content: Text('You have unsaved changes. Do you want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Go Back'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _showUnsavedDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Entry' : 'New Entry'),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          actions: [
            if (widget.isEditing && widget.entry.content.isNotEmpty)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _deleteEntry,
              ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveEntry,
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Date: ${_formatDate(_selectedDate)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: _selectDate,
                          child: Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Mood: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showMoodPicker,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange.shade600),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedMood,
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: _showMoodPicker,
                          child: Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Write your entry:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Share your thoughts, experiences, or what made today special...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'What happened today?\n\nTell me about your day...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showUnsavedDialog,
                      child: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade300,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}