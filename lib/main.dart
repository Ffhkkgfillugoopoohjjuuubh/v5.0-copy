import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_tutor/l10n/app_localizations.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  try {
    final tts = TtsService();
    await tts.initialize();
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('appLanguage') ?? 'en';
  final savedTheme = prefs.getString('themeMode') ?? 'system';
  configureAppPreferences(
    prefs,
    initialLocaleCode: savedLocale,
    initialThemeMode: savedTheme,
  );
  runApp(const ProviderScope(child: EchoAIApp()));
}

class EchoAIApp extends ConsumerWidget {
  const EchoAIApp({super.key});

  static const Color _primaryColor = Color(0xFF8B5CF6);
  static const Color _darkBackground = Color(0xFF0F0F1A);
  static const Color _darkSurface = Color(0xFF1A1A2E);
  static const Color _lightBackground = Color(0xFFF7F7F8);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Echo AI',
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: SettingsState.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _buildTheme(
        brightness: Brightness.light,
        background: _lightBackground,
        surface: _lightSurface,
        fontScale: settings.fontSize / 16,
      ),
      darkTheme: _buildTheme(
        brightness: Brightness.dark,
        background: _darkBackground,
        surface: _darkSurface,
        fontScale: settings.fontSize / 16,
      ),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required double fontScale,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
    ).copyWith(
      primary: _primaryColor,
      secondary: _primaryColor,
      surface: surface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        fontSizeFactor: fontScale,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
