import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Açık/koyu/sistem tema modunu yöneten ve seçimi kalıcı olarak hatırlayan
/// sağlayıcı.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._prefs) {
    final stored = _prefs.getString(_prefsKey);
    _themeMode = _parse(stored);
  }

  ThemeMode get themeMode => _themeMode;

  /// Tema modunu değiştirir ve tercihi kaydeder.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_prefsKey, mode.name);
    notifyListeners();
  }

  /// Kaydedilmiş metni [ThemeMode]'a çevirir; tanınmazsa sistem moduna döner.
  ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
