import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.appLanguage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: settings.appLanguage,
                    items: _languageItems(l10n),
                    onChanged: (value) {
                      if (value != null) {
                        settingsNotifier.setAppLanguage(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.voiceLanguage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: settings.voiceLanguage,
                    items: _languageItems(l10n),
                    onChanged: (value) {
                      if (value != null) {
                        settingsNotifier.setVoiceLanguage(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: themeModeToString(settings.themeMode),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.system),
                      ),
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(l10n.light),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(l10n.dark),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settingsNotifier.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SliderSetting(
                    label: l10n.fontSize,
                    value: settings.fontSize,
                    min: 12,
                    max: 24,
                    onChanged: settingsNotifier.setFontSize,
                  ),
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
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(l10n.clearAllChats),
                  subtitle: Text(l10n.clearAllChatsConfirm),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () => _confirmClearChats(context, ref, l10n),
                ),
                FutureBuilder<String>(
                  future: ref.read(storageServiceProvider).getStoragePath(),
                  builder: (context, snapshot) {
                    return ListTile(
                      title: Text(l10n.storagePath),
                      subtitle: Text(
                        snapshot.data ?? l10n.storageUnavailable,
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(l10n.appVersion),
                  subtitle: const Text('1.0.0+1'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _languageItems(AppLocalizations l10n) {
    return <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'en', child: Text(l10n.english)),
      DropdownMenuItem(value: 'hi', child: Text(l10n.hindi)),
      DropdownMenuItem(value: 'bn', child: Text(l10n.bengali)),
    ];
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
          content: Text(l10n.clearAllChatsConfirm),
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

    await ref.read(chatProvider.notifier).clearAll();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clearAllChats)),
      );
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
