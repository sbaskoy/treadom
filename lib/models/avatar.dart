import 'package:flutter/material.dart';

/// Kullanıcının harita üzerindeki konum işaretçisinde gösterilen avatar.
///
/// Avatarlar emoji tabanlıdır; böylece ek görsel varlık (asset) gerektirmez ve
/// her platformda çalışır. Varsayılan avatar koşan adamdır.
@immutable
class AppAvatar {
  const AppAvatar({required this.id, required this.emoji});

  /// Kalıcı olarak saklanan benzersiz kimlik.
  final String id;

  /// İşaretçide gösterilen emoji.
  final String emoji;

  @override
  bool operator ==(Object other) =>
      other is AppAvatar && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Seçilebilir tüm avatarlar. İlk öğe varsayılandır (koşan adam).
const List<AppAvatar> kAvatars = [
  AppAvatar(id: 'runner', emoji: '🏃'),
  AppAvatar(id: 'walker', emoji: '🚶'),
  AppAvatar(id: 'cyclist', emoji: '🚴'),
  AppAvatar(id: 'hiker', emoji: '🧗'),
  AppAvatar(id: 'fox', emoji: '🦊'),
  AppAvatar(id: 'rocket', emoji: '🚀'),
];

/// Varsayılan avatar (koşan adam).
const AppAvatar kDefaultAvatar = AppAvatar(id: 'runner', emoji: '🏃');

/// Kimliğe karşılık gelen avatarı döner; bulunamazsa varsayılan.
AppAvatar avatarById(String? id) {
  for (final a in kAvatars) {
    if (a.id == id) return a;
  }
  return kDefaultAvatar;
}
