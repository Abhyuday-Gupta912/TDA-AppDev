import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import 'entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Journal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          final entries = journalProvider.entries;

          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          return _buildEntriesList(entries, journalProvider, context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewEntry(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 80, color: Colors.orange.shade300),
          SizedBox(height: 20),
          Text(
            'Start Your Journal! ✨',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No entries yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.brown.shade600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the + button to write your first entry',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.brown.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    List<JournalEntry> entries,
    JournalProvider provider,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry, provider, context);
      },
    );
  }

  Widget _buildEntryCard(
    JournalEntry entry,
    JournalProvider provider,
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(entry.mood, style: TextStyle(fontSize: 20)),
        ),
        title: Text(
          _formatDate(entry.date),
          style: GoogleFonts.poppins(
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
              entry.preview,
              style: GoogleFonts.poppins(
                color: entry.isEmpty
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                fontStyle: entry.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${entry.wordCount} words',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange.shade400,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.edit, color: Colors.orange.shade400),
        onTap: () => _viewEntry(context, entry, provider),
      ),
    );
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  void _addNewEntry(BuildContext context) async {
    final provider = Provider.of<JournalProvider>(context, listen: false);

    final defaultDate = provider.defaultNewEntryDate;

    final newEntry = JournalEntry(
      date: defaultDate,
      content: '',
      createdAt: DateTime.now(),
      mood: '😊',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryScreen(entry: newEntry, isEditing: false),
      ),
    );

    if (result != null && result is JournalEntry) {
      provider.addEntry(result);
    }
  }

  Future<void> _viewEntry(
    BuildContext context,
    JournalEntry entry,
    JournalProvider provider,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryScreen(entry: entry, isEditing: true),
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        provider.deleteEntry(entry.date);
      } else if (result is JournalEntry) {
        provider.updateEntry(entry.date, result);
      }
    }
  }
}
