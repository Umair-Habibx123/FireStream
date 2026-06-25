import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme controller (light / dark / follow-system) with persistence.
///
/// Usage:
///   final theme = context.watch ThemeService;
///   theme.toggle();            // flip light <-> dark
///   theme.setMode(ThemeMode.system);
class ThemeService with ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  ThemeService() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      _mode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // Keep default on any storage failure.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {}
  }

  /// Simple light <-> dark toggle (used by the switch in settings).
  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

/// Centralised colour + theme definitions so every screen reads from one place.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF1565C0);
  static const Color accent = Color(0xFF1976D2);

  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0F1418) : const Color(0xFFF7F9FC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
      cardColor: isDark ? const Color(0xFF161B22) : Colors.white,
      dividerColor: isDark ? Colors.white12 : const Color(0xFFE4E7EC),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF2A2F36) : const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
