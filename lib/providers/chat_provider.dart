import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/storage_service.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatSession>>(
  (ref) => ChatNotifier(ref.watch(storageServiceProvider)),
);

class ChatNotifier extends StateNotifier<List<ChatSession>> {
  ChatNotifier(this._storageService) : super(const <ChatSession>[]) {
    _loadSessions();
  }

  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  Future<void> _loadSessions() async {
    state = await _storageService.loadAllSessions();
  }

  Future<ChatSession> createSession({
    String? projectId,
    String? name,
  }) async {
    final now = DateTime.now();
    final session = ChatSession(
      id: _uuid.v4(),
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'New chat',
      messages: const <ChatMessage>[],
      isStarred: false,
      projectId: projectId,
      createdAt: now,
      updatedAt: now,
    );

    state = _sorted(<ChatSession>[session, ...state]);
    await _storageService.saveSession(session);
    return session;
  }

  Future<void> addMessage(String sessionId, ChatMessage message) async {
    final sessions = <ChatSession>[];

    for (final session in state) {
      if (session.id != sessionId) {
        sessions.add(session);
        continue;
      }

      final hasUserMessages = session.messages.any((item) => item.role == 'user');
      var nextName = session.name;

      if (!hasUserMessages &&
          message.role == 'user' &&
          session.name.toLowerCase() == 'new chat') {
        final trimmed = message.content.trim();
        nextName = trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed;
      }

      final updatedSession = session.copyWith(
        name: nextName,
        messages: <ChatMessage>[...session.messages, message],
        updatedAt: DateTime.now(),
      );

      sessions.add(updatedSession);
      await _storageService.saveSession(updatedSession);
    }

    state = _sorted(sessions);
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final sessions = <ChatSession>[];

    for (final session in state) {
      if (session.id != sessionId) {
        sessions.add(session);
        continue;
      }

      final updated = session.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );
      sessions.add(updated);
      await _storageService.saveSession(updated);
    }

    state = _sorted(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    state = state.where((session) => session.id != sessionId).toList();
    await _storageService.deleteSession(sessionId);
  }

  Future<void> toggleStar(String sessionId) async {
    final sessions = <ChatSession>[];

    for (final session in state) {
      if (session.id != sessionId) {
        sessions.add(session);
        continue;
      }

      final updated = session.copyWith(
        isStarred: !session.isStarred,
        updatedAt: DateTime.now(),
      );
      sessions.add(updated);
      await _storageService.saveSession(updated);
    }

    state = _sorted(sessions);
  }

  Future<void> assignToProject(String sessionId, String? projectId) async {
    final sessions = <ChatSession>[];

    for (final session in state) {
      if (session.id != sessionId) {
        sessions.add(session);
        continue;
      }

      final updated = session.copyWith(
        projectId: projectId,
        clearProjectId: projectId == null,
        updatedAt: DateTime.now(),
      );
      sessions.add(updated);
      await _storageService.saveSession(updated);
    }

    state = _sorted(sessions);
  }

  Future<void> clearAll() async {
    state = const <ChatSession>[];
    await _storageService.clearAllSessions();
  }

  List<ChatSession> _sorted(List<ChatSession> sessions) {
    final copy = <ChatSession>[...sessions];
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }
}
