import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalori tahmini için kullanılan kullanıcı kilosunu (kg) yöneten ve seçimi
/// kalıcı olarak hatırlayan sağlayıcı. Hiç ayarlanmadıysa varsayılan 70 kg.
class WeightProvider extends ChangeNotifier {
  static const String _prefsKey = 'weight_kg';
  static const double defaultWeightKg = 70;
  static const double minWeightKg = 30;
  static const double maxWeightKg = 200;

  final SharedPreferences _prefs;
  double _weightKg = defaultWeightKg;

  WeightProvider(this._prefs) {
    _weightKg = _prefs.getDouble(_prefsKey) ?? defaultWeightKg;
  }

  /// Geçerli kilo (kg).
  double get weightKg => _weightKg;

  /// Kiloyu geçerli aralığa kırpıp ayarlar ve tercihi kaydeder.
  Future<void> setWeight(double kg) async {
    final clamped = kg.clamp(minWeightKg, maxWeightKg).toDouble();
    if (clamped == _weightKg) return;
    _weightKg = clamped;
    await _prefs.setDouble(_prefsKey, clamped);
    notifyListeners();
  }
}
