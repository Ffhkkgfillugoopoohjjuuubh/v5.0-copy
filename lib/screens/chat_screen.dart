import 'dart:async';

import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  StreamSubscription<bool>? _adRefreshSubscription;
  Timer? _streamResetTimer;
  Stream<String>? _wordStream;
  String? _streamingMessageId;
  bool _isThinking = false;
  bool _usedInitialPrompt = false;

  @override
  void initState() {
    super.initState();
    _adRefreshSubscription = _revenueOptimizer.adRefreshSignal.listen((_) {
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
    if (currentSession == null || _isThinking) {
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
        ? 'The user has shared an image containing: $ocrText. Answer: $fallbackQuestion'
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
    _revenueOptimizer.startSession(0);

    if (!mounted) {
      return;
    }

    setState(() {
      _isThinking = true;
      _streamingMessageId = null;
      _wordStream = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 3600));

      final apiMessages = <ChatMessage>[
        ...currentSession.messages,
        userMessage.copyWith(content: promptForApi),
      ];

      var response = await _apiService.sendMessage(apiMessages);
      if (_wordCount(response) < 100) {
        response = await _apiService.expandResponse(response);
      }

      await _addAssistantMessage(response);
    } catch (_) {
      await _addAssistantMessage(l10n.assistantUnavailable);
    }
  }

  Future<void> _addAssistantMessage(String content) async {
    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );

    await ref.read(chatProvider.notifier).addMessage(
          widget.sessionId,
          assistantMessage,
        );

    final stream = _revenueOptimizer.streamWords(content);

    if (!mounted) {
      return;
    }

    setState(() {
      _isThinking = false;
      _streamingMessageId = assistantMessage.id;
      _wordStream = stream;
    });

    _scheduleStreamReset(content, assistantMessage.id);
    _scrollToBottom(animated: true);
  }

  void _scheduleStreamReset(String text, String messageId) {
    _streamResetTimer?.cancel();
    _streamResetTimer = Timer(
      _revenueOptimizer.estimatedDuration(text) +
          const Duration(milliseconds: 350),
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

      final target = _scrollController.position.maxScrollExtent + 160;
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
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const BannerAdWidget(placement: BannerPlacement.top),
              _ChatHeader(
                title: l10n.appName,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(child: Center(child: Text(l10n.chatNotFound))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const BannerAdWidget(placement: BannerPlacement.top),
            _ChatHeader(
              title: session.name,
              isStarred: session.isStarred,
              onBack: () => Navigator.of(context).maybePop(),
              onRename: () => _renameSession(context, session),
              onShare: () => _copyTranscript(context, session),
              onToggleStar: () =>
                  ref.read(chatProvider.notifier).toggleStar(session.id),
              onDelete: () => _deleteSession(context, session),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                itemCount: session.messages.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = session.messages[index];
                  return MessageBubble(
                    key: ValueKey(message.id),
                    message: message,
                    wordStream:
                        message.id == _streamingMessageId ? _wordStream : null,
                  );
                },
              ),
            ),
            if (_isThinking)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ThinkingAnimation(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ChatInputWidget(
                isLoading: _isThinking,
                onSend: _handleSend,
                onFocusChanged: (hasFocus) {
                  if (hasFocus) {
                    _revenueOptimizer.pauseTimer();
                  } else {
                    _revenueOptimizer.resumeTimer();
                  }
                },
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

  Future<void> _copyTranscript(
    BuildContext context,
    ChatSession session,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final transcript = session.messages
        .map((message) => '${message.role.toUpperCase()}: ${message.content}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: transcript));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedMessage)),
    );
  }

  Future<void> _deleteSession(BuildContext context, ChatSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.delete),
          content: Text(l10n.confirmDeleteChat),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(chatProvider.notifier).deleteSession(session.id);
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.onBack,
    this.isStarred = false,
    this.onRename,
    this.onShare,
    this.onToggleStar,
    this.onDelete,
  });

  final String title;
  final bool isStarred;
  final VoidCallback onBack;
  final VoidCallback? onRename;
  final VoidCallback? onShare;
  final VoidCallback? onToggleStar;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D4AE0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: NavigationToolbar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        middle: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: l10n.rename,
              onPressed: onRename,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
            IconButton(
              tooltip: l10n.share,
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
            ),
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (value) {
                if (value == 'star') {
                  onToggleStar?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'star',
                  child: Text(isStarred ? l10n.unstar : l10n.star),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ],
        ),
        centerMiddle: true,
      ),
    );
  }
}
