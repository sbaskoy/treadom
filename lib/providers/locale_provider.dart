import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın dil (locale) seçimini yöneten ve seçimi kalıcı olarak
/// hatırlayan sağlayıcı.
///
/// [locale] `null` ise cihazın sistem dili kullanılır. Kullanıcı ayarlardan
/// TR/EN seçtiğinde tercih [SharedPreferences] içine kaydedilir ve uygulama
/// yeniden açıldığında geri yüklenir.
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'locale_code';

  final SharedPreferences _prefs;
  Locale? _locale;

  LocaleProvider(this._prefs) {
    final code = _prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
  }

  /// Seçili dil; `null` ise sistem dili izlenir.
  Locale? get locale => _locale;

  /// Dili değiştirir. [locale] `null` verilirse sistem diline dönülür.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }
}
