import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: l10n.appLanguage,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: settings.appLanguage,
                items: supportedAppLanguages
                    .map(
                      (code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text(appLanguageNames[code] ?? code),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    settingsNotifier.setAppLanguage(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.voiceLanguage,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: settings.voiceLanguage,
                items: TtsService.supportedLanguageCodes
                    .map(
                      (code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text('${TtsService.languageNames[code]} ($code)'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    settingsNotifier.setVoiceLanguage(value);
                  }
                },
              ),
            ],
          ),
          _Section(
            title: l10n.voice,
            children: <Widget>[
              _SliderSetting(
                label: l10n.volume,
                value: settings.volume,
                min: 0,
                max: 1,
                onChanged: settingsNotifier.setVolume,
              ),
              _SliderSetting(
                label: l10n.pitch,
                value: settings.pitch,
                min: 0.8,
                max: 1.6,
                onChanged: settingsNotifier.setPitch,
              ),
              _SliderSetting(
                label: l10n.speechRate,
                value: settings.speechRate,
                min: 0.2,
                max: 0.7,
                onChanged: settingsNotifier.setSpeechRate,
              ),
            ],
          ),
          _Section(
            title: l10n.appearance,
            children: <Widget>[
              SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'system',
                    icon: const Icon(Icons.phone_android_outlined),
                    label: Text(l10n.systemDefault),
                  ),
                  ButtonSegment<String>(
                    value: 'light',
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.lightMode),
                  ),
                  ButtonSegment<String>(
                    value: 'dark',
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.darkMode),
                  ),
                ],
                selected: <String>{themeModeToString(settings.themeMode)},
                onSelectionChanged: (selection) {
                  settingsNotifier.setThemeMode(selection.first);
                },
              ),
              const SizedBox(height: 18),
              _SliderSetting(
                label: l10n.fontSize,
                value: settings.fontSize,
                min: 12,
                max: 24,
                onChanged: settingsNotifier.setFontSize,
              ),
            ],
          ),
          _Section(
            title: l10n.data,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.clearAllChats),
                subtitle: Text(l10n.clearAllChatsConfirm),
                trailing: const Icon(Icons.delete_outline),
                onTap: () => _confirmClearChats(context, ref, l10n),
              ),
              FutureBuilder<String>(
                future: ref.read(storageServiceProvider).getStoragePath(),
                builder: (context, snapshot) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.storageLocation),
                    subtitle: Text(
                      snapshot.data ?? l10n.storageUnavailable,
                    ),
                  );
                },
              ),
            ],
          ),
          _Section(
            title: l10n.about,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.appVersion),
                subtitle: const Text('Echo AI v3.0'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.developerInfo),
                subtitle: const Text('Built with Flutter, Groq, ML Kit, and AdMob.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearChats(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearAllChats),
          content: Text(l10n.confirmClear),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(chatProvider.notifier).clearAll();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clearAllChats)),
      );
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label),
              Text(value.toStringAsFixed(2)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
