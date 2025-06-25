import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal_entry.dart';

class EntryScreen extends StatefulWidget {
  final JournalEntry entry;
  final bool isEditing;

  EntryScreen({required this.entry, required this.isEditing});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late TextEditingController _controller;
  late DateTime _selectedDate;
  late String _selectedMood;
  bool _hasChanges = false;

  final List<String> _moods = [
    '😊',
    '😢',
    '😍',
    '😴',
    '🎉',
    '😤',
    '🤔',
    '😌',
    '☕',
    '🌟',
    '🌳',
    '💪',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.content);
    _selectedDate = DateTime.parse(widget.entry.date);
    _selectedMood = widget.entry.mood;

    _controller.addListener(() {
      setState(() {
        _hasChanges =
            _controller.text != widget.entry.content ||
            _selectedDate.toIso8601String().split('T')[0] !=
                widget.entry.date ||
            _selectedMood != widget.entry.mood;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showUnsavedDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Edit Entry' : 'New Entry',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          actions: [
            if (widget.isEditing && widget.entry.content.isNotEmpty)
              IconButton(icon: Icon(Icons.delete), onPressed: _deleteEntry),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateMoodContainer(),
              SizedBox(height: 16),
              _buildContentInputArea(),
              SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateMoodContainer() {
    return Container(
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
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                  child: Text(_selectedMood, style: TextStyle(fontSize: 24)),
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
    );
  }

  Widget _buildContentInputArea() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your entry:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Share your thoughts, experiences, or what made today special...',
            style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'What happened today?\n\nTell me about your day...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _showUnsavedDialog,
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
            child: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
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
          title: Text(
            'How are you feeling?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
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
    JournalEntry updatedEntry = JournalEntry(
      date: _selectedDate.toIso8601String().split('T')[0],
      content: _controller.text.trim(),
      createdAt: widget.entry.createdAt,
      mood: _selectedMood,
    );

    Navigator.pop(context, updatedEntry);
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Entry',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this entry?',
            style: GoogleFonts.poppins(),
          ),
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
            title: Text(
              'Unsaved Changes',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'You have unsaved changes. Do you want to go back?',
              style: GoogleFonts.poppins(),
            ),
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
}
