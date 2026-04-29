import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/note_model.dart';
import '../services/storage_service.dart';

final notesProvider =
    StateNotifierProvider<NotesNotifier, List<Note>>(
  (ref) => NotesNotifier(StorageService()),
);

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier(this._storageService) : super([]) {
    _loadNotes();
  }

  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  Future<void> _loadNotes() async {
    try {
      final notes = await _storageService.loadNotes();
      state = notes;
    } catch (_) {
      state = [];
    }
  }

  Future<void> addNote(Note note) async {
    final newNote = note.copyWith(
      id: note.id.isEmpty ? _uuid.v4() : note.id,
      createdAt: note.createdAt.isAtSameMomentAs(DateTime(0))
          ? DateTime.now()
          : note.createdAt,
      updatedAt: DateTime.now(),
    );
    final updated = [...state, newNote];
    state = updated;
    await _storageService.saveNotes(updated);
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    final index = state.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      final newList = [...state];
      newList[index] = updated;
      state = newList;
      await _storageService.saveNotes(newList);
    }
  }

  Future<void> deleteNote(String id) async {
    final updated = state.where((note) => note.id != id).toList();
    state = updated;
    await _storageService.saveNotes(updated);
  }

  List<Note> getBySubject(String subject) {
    return state.where((note) => note.subject == subject).toList();
  }
}
