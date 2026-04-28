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
    this.isLoading = false,
  });

  final Future<void> Function(String text, String? extractedOcrText) onSend;
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
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.camera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

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

    if (text.isEmpty && (ocrText == null || ocrText.isEmpty)) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_selectedImage != null || _isProcessingImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InputChip(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed:
                    widget.isLoading || _isProcessingImage ? null : _pickImage,
                icon: const Icon(Icons.attach_file_rounded),
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
                    hintText: l10n.searchHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.isLoading || _isProcessingImage ? null : _send,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
