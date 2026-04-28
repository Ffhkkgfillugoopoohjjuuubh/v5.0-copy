import 'dart:async';

import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../providers/ad_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../services/revenue_optimizer.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/thinking_animation.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.sessionId,
    this.initialPrompt,
  });

  final String sessionId;
  final String? initialPrompt;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ApiService _apiService = ApiService();
  final RevenueOptimizer _revenueOptimizer = RevenueOptimizer();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  StreamSubscription<void>? _adRefreshSubscription;
  Timer? _streamResetTimer;
  Stream<String>? _wordStream;
  String? _streamingMessageId;
  bool _isThinking = false;
  bool _usedInitialPrompt = false;

  @override
  void initState() {
    super.initState();
    _adRefreshSubscription = _revenueOptimizer.adRefreshStream.listen((_) {
      ref.read(adProvider).reloadAds();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialPrompt != null && !_usedInitialPrompt) {
        _usedInitialPrompt = true;
        await _handleSend(widget.initialPrompt!, null);
      }
    });
  }

  @override
  void dispose() {
    _adRefreshSubscription?.cancel();
    _streamResetTimer?.cancel();
    _scrollController.dispose();
    _revenueOptimizer.dispose();
    super.dispose();
  }

  ChatSession? _findSession(List<ChatSession> sessions) {
    for (final session in sessions) {
      if (session.id == widget.sessionId) {
        return session;
      }
    }
    return null;
  }

  Future<void> _handleSend(String text, String? extractedOcrText) async {
    final l10n = AppLocalizations.of(context)!;
    final currentSession = _findSession(ref.read(chatProvider));
    if (currentSession == null) {
      return;
    }

    final trimmedText = text.trim();
    final visibleQuestion =
        trimmedText.isNotEmpty ? trimmedText : l10n.imageOnlyPrompt;
    final fallbackQuestion =
        trimmedText.isNotEmpty ? trimmedText : l10n.imageQuestionFallback;
    final ocrText = extractedOcrText?.trim();
    final hasOcr = ocrText != null && ocrText.isNotEmpty;

    final promptForApi = hasOcr
        ? 'The user has shared an image containing: $ocrText. Answer this: $fallbackQuestion'
        : fallbackQuestion;

    if (promptForApi.trim().isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: visibleQuestion,
      timestamp: DateTime.now(),
    );

    await ref.read(chatProvider.notifier).addMessage(widget.sessionId, userMessage);
    _scrollToBottom();

    if (!mounted) {
      return;
    }

    setState(() {
      _isThinking = true;
      _streamingMessageId = null;
      _wordStream = null;
    });

    try {
      final apiMessages = <ChatMessage>[
        ...currentSession.messages,
        userMessage.copyWith(content: promptForApi),
      ];

      var response = await _apiService.sendMessage(apiMessages);
      if (_wordCount(response) < 80) {
        response = await _apiService.expandResponse(response);
      }

      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      await ref.read(chatProvider.notifier).addMessage(
            widget.sessionId,
            assistantMessage,
          );

      final stream = _revenueOptimizer.streamWords(response);

      if (!mounted) {
        return;
      }

      setState(() {
        _isThinking = false;
        _streamingMessageId = assistantMessage.id;
        _wordStream = stream;
      });

      _scheduleStreamReset(response, assistantMessage.id);
      _scrollToBottom(animated: true);
    } catch (_) {
      final failureMessage = ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content: l10n.assistantUnavailable,
        timestamp: DateTime.now(),
      );

      await ref.read(chatProvider.notifier).addMessage(
            widget.sessionId,
            failureMessage,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isThinking = false;
        _streamingMessageId = null;
        _wordStream = null;
      });
      _scrollToBottom(animated: true);
    }
  }

  void _scheduleStreamReset(String text, String messageId) {
    _streamResetTimer?.cancel();
    _streamResetTimer = Timer(
      _revenueOptimizer.estimatedDuration(text) +
          const Duration(milliseconds: 250),
      () {
        if (!mounted || _streamingMessageId != messageId) {
          return;
        }

        setState(() {
          _streamingMessageId = null;
          _wordStream = null;
        });
      },
    );
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent + 120;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  int _wordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(chatProvider);
    final session = _findSession(sessions);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appName)),
        body: Center(child: Text(l10n.chatNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ref.read(chatProvider.notifier).toggleStar(session.id);
            },
            icon: Icon(
              session.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
            ),
          ),
          IconButton(
            onPressed: () => _renameSession(context, session),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const BannerAdWidget(placement: BannerPlacement.top),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                itemCount: session.messages.length,
                separatorBuilder: (_, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final message = session.messages[index];
                  return MessageBubble(
                    key: ValueKey(message.id),
                    message: message,
                    wordStream: message.id == _streamingMessageId ? _wordStream : null,
                  );
                },
              ),
            ),
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    const ThinkingAnimation(),
                    const SizedBox(width: 12),
                    Text(l10n.thinking),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ChatInputWidget(
                isLoading: _isThinking,
                onSend: _handleSend,
              ),
            ),
            const BannerAdWidget(placement: BannerPlacement.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _renameSession(BuildContext context, ChatSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: session.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renameChat),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.renameChat),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    await ref.read(chatProvider.notifier).renameSession(session.id, result);
  }
}
