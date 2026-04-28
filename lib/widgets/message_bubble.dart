import 'dart:async';

import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';

class MessageBubble extends ConsumerStatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.wordStream,
  });

  final ChatMessage message;
  final Stream<String>? wordStream;

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  StreamSubscription<String>? _subscription;
  late String _displayContent;

  @override
  void initState() {
    super.initState();
    _displayContent = widget.wordStream == null ? widget.message.content : '';
    _attachStream();
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wordStream != widget.wordStream) {
      _subscription?.cancel();
      _displayContent = widget.wordStream == null ? widget.message.content : '';
      _attachStream();
    } else if (widget.wordStream == null &&
        oldWidget.message.content != widget.message.content) {
      _displayContent = widget.message.content;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _attachStream() {
    final stream = widget.wordStream;
    if (stream == null) {
      return;
    }

    _subscription = stream.listen((word) {
      if (!mounted) {
        return;
      }

      setState(() {
        _displayContent =
            _displayContent.isEmpty ? word : '$_displayContent $word';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    final bubbleColor = isUser
        ? const Color(0xFF8B5CF6)
        : theme.colorScheme.surface;
    final textColor = isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _displayContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('hh:mm a').format(widget.message.timestamp),
                  style: theme.textTheme.bodySmall,
                ),
                if (!isUser) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.copy,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.message.content),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copiedMessage)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.speak,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () {
                      TtsService.instance.speak(
                        widget.message.content,
                        languageCode: settings.voiceLanguage,
                        volume: settings.volume,
                        pitch: settings.pitch,
                        speechRate: settings.speechRate,
                      );
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
