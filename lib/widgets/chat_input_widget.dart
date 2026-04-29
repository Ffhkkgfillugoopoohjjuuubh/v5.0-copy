import 'dart:io';

import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/ocr_service.dart';

class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    super.key,
    required this.onSend,
    this.onFocusChanged,
    this.isLoading = false,
  });

  final Future<void> Function(String text, String? extractedOcrText) onSend;
  final ValueChanged<bool>? onFocusChanged;
  final bool isLoading;

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _ocrText;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionGranted = await _requestPermission(source);
    if (!permissionGranted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.attachmentPermissionDenied)),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _isProcessingImage = true;
    });

    final file = File(picked.path);
    final extracted = await _ocrService.extractTextFromFile(file);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = file;
      _ocrText = extracted;
      _isProcessingImage = false;
    });
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return (await Permission.camera.request()).isGranted;
    }

    if (Platform.isAndroid) {
      final photoPermission = await Permission.photos.request();
      if (photoPermission.isGranted || photoPermission.isLimited) {
        return true;
      }

      return (await Permission.storage.request()).isGranted;
    }

    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final ocrText = _ocrText?.trim();

    if (widget.isLoading ||
        _isProcessingImage ||
        (text.isEmpty && (ocrText == null || ocrText.isEmpty))) {
      return;
    }

    await widget.onSend(text, ocrText);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _ocrText = null;
    });
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final disabled = widget.isLoading || _isProcessingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_selectedImage != null || _isProcessingImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InputChip(
              avatar: _isProcessingImage
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined, size: 18),
              label: Text(
                _isProcessingImage ? l10n.processingImage : l10n.imageAttached,
              ),
              onDeleted: _isProcessingImage
                  ? null
                  : () {
                      setState(() {
                        _selectedImage = null;
                        _ocrText = null;
                      });
                    },
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: l10n.camera,
                  onPressed:
                      disabled ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                IconButton(
                  tooltip: l10n.gallery,
                  onPressed:
                      disabled ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: disabled ? null : _send,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
