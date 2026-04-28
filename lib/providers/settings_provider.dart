import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _appPreferences;
String _bootstrapLocaleCode = 'en';
String _bootstrapThemeMode = 'system';

void configureAppPreferences(
  SharedPreferences preferences, {
  required String initialLocaleCode,
  required String initialThemeMode,
}) {
  _appPreferences = preferences;
  _bootstrapLocaleCode = initialLocaleCode;
  _bootstrapThemeMode = initialThemeMode;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(_appPreferences),
);

class SettingsState {
  const SettingsState({
    required this.appLanguage,
    required this.voiceLanguage,
    required this.themeMode,
    required this.fontSize,
    required this.volume,
    required this.pitch,
    required this.speechRate,
  });

  final String appLanguage;
  final String voiceLanguage;
  final ThemeMode themeMode;
  final double fontSize;
  final double volume;
  final double pitch;
  final double speechRate;

  Locale get locale => Locale(appLanguage);

  SettingsState copyWith({
    String? appLanguage,
    String? voiceLanguage,
    ThemeMode? themeMode,
    double? fontSize,
    double? volume,
    double? pitch,
    double? speechRate,
  }) {
    return SettingsState(
      appLanguage: appLanguage ?? this.appLanguage,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      speechRate: speechRate ?? this.speechRate,
    );
  }

  factory SettingsState.initialFromPreferences(SharedPreferences preferences) {
    return SettingsState(
      appLanguage: preferences.getString('appLanguage') ?? _bootstrapLocaleCode,
      voiceLanguage: preferences.getString('voiceLanguage') ?? 'en',
      themeMode: themeModeFromString(
        preferences.getString('themeMode') ?? _bootstrapThemeMode,
      ),
      fontSize: preferences.getDouble('fontSize') ?? 16,
      volume: preferences.getDouble('volume') ?? 1.0,
      pitch: preferences.getDouble('pitch') ?? 1.15,
      speechRate: preferences.getDouble('speechRate') ?? 0.42,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._preferences)
      : super(SettingsState.initialFromPreferences(_preferences));

  final SharedPreferences _preferences;

  Future<void> setAppLanguage(String languageCode) async {
    state = state.copyWith(appLanguage: languageCode);
    await _preferences.setString('appLanguage', languageCode);
  }

  Future<void> setVoiceLanguage(String languageCode) async {
    state = state.copyWith(voiceLanguage: languageCode);
    await _preferences.setString('voiceLanguage', languageCode);
  }

  Future<void> setThemeMode(String theme) async {
    final nextThemeMode = themeModeFromString(theme);
    state = state.copyWith(themeMode: nextThemeMode);
    await _preferences.setString('themeMode', theme);
  }

  Future<void> setFontSize(double value) async {
    state = state.copyWith(fontSize: value);
    await _preferences.setDouble('fontSize', value);
  }

  Future<void> setVolume(double value) async {
    state = state.copyWith(volume: value);
    await _preferences.setDouble('volume', value);
  }

  Future<void> setPitch(double value) async {
    state = state.copyWith(pitch: value);
    await _preferences.setDouble('pitch', value);
  }

  Future<void> setSpeechRate(double value) async {
    state = state.copyWith(speechRate: value);
    await _preferences.setDouble('speechRate', value);
  }
}

ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}
