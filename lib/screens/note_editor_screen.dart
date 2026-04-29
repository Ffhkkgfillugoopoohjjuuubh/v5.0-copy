import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.note});

  final Note note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _topicController;
  late String _selectedSubject;

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _topicController = TextEditingController(text: widget.note.topic);
    _selectedSubject = widget.note.subject;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final topic = _topicController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final note = Note(
      id: widget.note.id.isEmpty ? _uuid.v4() : widget.note.id,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      subject: _selectedSubject,
      topic: topic,
      createdAt: widget.note.createdAt.isAtSameMomentAs(DateTime(0))
          ? DateTime.now()
          : widget.note.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.note.id.isEmpty) {
      await ref.read(notesProvider.notifier).addNote(note);
    } else {
      await ref.read(notesProvider.notifier).updateNote(note);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note.id.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(notesProvider.notifier).deleteNote(widget.note.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.note.id.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Note' : 'Edit Note'),
        actions: <Widget>[
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Biology', child: Text('Biology')),
                DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                DropdownMenuItem(value: 'Chemistry', child: Text('Chemistry')),
                DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                DropdownMenuItem(value: 'History', child: Text('History')),
                DropdownMenuItem(value: 'Geography', child: Text('Geography')),
                DropdownMenuItem(value: 'Literature', child: Text('Literature')),
                DropdownMenuItem(
                  value: 'Computer Science',
                  child: Text('Computer Science'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSubject = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveNote,
        child: const Icon(Icons.save),
      ),
    );
  }
}
