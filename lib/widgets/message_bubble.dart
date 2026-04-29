import 'dart:async';

import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/chat_message.dart';
import '../models/note_model.dart';
import '../providers/settings_provider.dart';
import '../providers/notes_provider.dart';
import '../services/note_categorizer.dart';
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
  StreamSubscription<String>? _wordSubscription;
  StreamSubscription<bool>? _speakingSubscription;
  late String _displayContent;
  bool _isPreparingSpeech = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _displayContent = widget.wordStream == null ? widget.message.content : '';
    _isSpeaking = TtsService.instance.isSpeaking;
    _attachWordStream();
    _speakingSubscription = TtsService.instance.speakingStream.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = value;
        if (value) {
          _isPreparingSpeech = false;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wordStream != widget.wordStream) {
      _wordSubscription?.cancel();
      _displayContent = widget.wordStream == null ? widget.message.content : '';
      _attachWordStream();
    } else if (widget.wordStream == null &&
        oldWidget.message.content != widget.message.content) {
      _displayContent = widget.message.content;
    }
  }

  @override
  void dispose() {
    _wordSubscription?.cancel();
    _speakingSubscription?.cancel();
    super.dispose();
  }

  void _attachWordStream() {
    final stream = widget.wordStream;
    if (stream == null) {
      return;
    }

    _wordSubscription = stream.listen((word) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isUser ? _buildUserMessage(context) : _buildAssistantMessage(context),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF8B5CF6),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _displayContent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MarkdownBody(
              data: _displayContent,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                h1: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                h3: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                code: TextStyle(
                  backgroundColor: isDark
                      ? const Color(0xFF101018)
                      : const Color(0xFFEDEAFD),
                  color: isDark ? Colors.white : const Color(0xFF312E81),
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101018)
                      : const Color(0xFF1F1F2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                codeblockPadding: const EdgeInsets.all(14),
                blockquoteDecoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFF8B5CF6), width: 4),
                  ),
                ),
              ),
              builders: <String, MarkdownElementBuilder>{
                'pre': _CodeBlockBuilder(),
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('hh:mm a').format(widget.message.timestamp),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l10n.copy,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => _copyText(context, widget.message.content),
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  tooltip: _isSpeaking ? l10n.stop : l10n.speak,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: _isPreparingSpeech
                      ? null
                      : () => _toggleSpeech(settings),
                  icon: _isPreparingSpeech
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isSpeaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_rounded,
                        ),
                ),
                IconButton(
                  tooltip: 'Add to Notebook',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => _addToNotebook(context),
                  icon: const Icon(Icons.note_add_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSpeech(SettingsState settings) async {
    if (_isSpeaking) {
      await TtsService.instance.stop();
      return;
    }

    setState(() {
      _isPreparingSpeech = true;
    });

    try {
      await TtsService.instance.speak(
        widget.message.content,
        languageCode: settings.voiceLanguage,
        volume: settings.volume,
        pitch: settings.pitch,
        speechRate: settings.speechRate,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingSpeech = false;
        });
      }
    }
  }

  Future<void> _copyText(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedMessage)),
    );
  }

  Future<void> _addToNotebook(BuildContext context) async {
    final content = widget.message.content;
    final title = content.length > 30
        ? '${content.substring(0, 30)}...'
        : content;
    final subject = NoteCategorizer.detectSubject(content);

    final note = Note(
      id: '',
      title: title,
      content: content,
      subject: subject,
      topic: '',
      createdAt: DateTime(0),
      updatedAt: DateTime(0),
    );

    await ref.read(notesProvider.notifier).addNote(note);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to Notebook')),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trimRight();
    return _CodeBlock(text: text);
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: l10n.copy,
              visualDensity: VisualDensity.compact,
              color: Colors.white,
              iconSize: 18,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.copiedMessage)),
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
