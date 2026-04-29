import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_session.dart';
import '../models/note_model.dart';
import '../models/project_model.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

class StorageService {
  static const String _sessionsPrefix = 'session_';
  static const String _projectsFileName = 'projects.json';
  static const String _notesFileName = 'notes.json';

  Future<List<ChatSession>> loadAllSessions() async {
    try {
      final directory = await _storageDirectory();
      final sessions = <ChatSession>[];

      for (final entity in directory.listSync()) {
        if (entity is! File) {
          continue;
        }

        final fileName = _fileName(entity.path);
        if (!fileName.startsWith(_sessionsPrefix) || !fileName.endsWith('.json')) {
          continue;
        }

        final contents = await entity.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        sessions.add(ChatSession.fromJson(json));
      }

      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (_) {
      return <ChatSession>[];
    }
  }

  Future<void> saveSession(ChatSession session) async {
    final directory = await _storageDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}session_${session.id}.json',
    );
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  Future<void> deleteSession(String id) async {
    final directory = await _storageDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}session_$id.json',
    );
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearAllSessions() async {
    final directory = await _storageDirectory();
    for (final entity in directory.listSync()) {
      if (entity is! File) {
        continue;
      }

      final name = _fileName(entity.path);
      if (name.startsWith(_sessionsPrefix) && name.endsWith('.json')) {
        await entity.delete();
      }
    }
  }

  Future<List<ProjectModel>> loadProjects() async {
    try {
      final file = await _projectsFile();
      if (!await file.exists()) {
        return <ProjectModel>[];
      }

      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      final projects = list
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList();
      projects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return projects;
    } catch (_) {
      return <ProjectModel>[];
    }
  }

  Future<void> saveProject(ProjectModel project) async {
    final file = await _projectsFile();
    final projects = await loadProjects();
    final updated = projects.where((item) => item.id != project.id).toList()
      ..add(project)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await file.writeAsString(
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteProject(String id) async {
    final file = await _projectsFile();
    final projects = await loadProjects();
    final updated = projects.where((item) => item.id != id).toList();
    await file.writeAsString(
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<Note>> loadNotes() async {
    try {
      final file = await _notesFile();
      if (!await file.exists()) {
        return <Note>[];
      }

      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      final notes = list
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (_) {
      return <Note>[];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final file = await _notesFile();
    await file.writeAsString(
      jsonEncode(notes.map((item) => item.toJson()).toList()),
    );
  }

  Future<String> getStoragePath() async {
    final directory = await _storageDirectory();
    return directory.path;
  }

  Future<Directory> _storageDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}echo_ai',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> _projectsFile() async {
    final directory = await _storageDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_projectsFileName');
  }

  Future<File> _notesFile() async {
    final directory = await _storageDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_notesFileName');
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
