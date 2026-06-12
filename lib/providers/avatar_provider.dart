import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';

/// Kullanıcının seçtiği konum avatarını yöneten ve seçimi kalıcı olarak
/// hatırlayan sağlayıcı. Hiç seçim yoksa varsayılan (koşan adam) gelir.
class AvatarProvider extends ChangeNotifier {
  static const String _prefsKey = 'avatar_id';

  final SharedPreferences _prefs;
  AppAvatar _avatar = kDefaultAvatar;

  AvatarProvider(this._prefs) {
    _avatar = avatarById(_prefs.getString(_prefsKey));
  }

  /// Seçili avatar.
  AppAvatar get avatar => _avatar;

  /// Avatarı değiştirir ve tercihi kaydeder.
  Future<void> setAvatar(AppAvatar avatar) async {
    if (_avatar == avatar) return;
    _avatar = avatar;
    await _prefs.setString(_prefsKey, avatar.id);
    notifyListeners();
  }
}
