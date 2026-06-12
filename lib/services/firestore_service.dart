import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Cloud Firestore okuma/yazma işlemlerini tek bir yerde toplayan servis.
///
/// Şimdilik yalnızca kullanıcı dökümanlarını yönetir; ileriki aşamalarda
/// fethedilen alanlar ve mesajlar da buraya eklenecek.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// `users` koleksiyonuna tipli erişim.
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Yeni kayıt olan kullanıcı için `users/{uid}` dökümanını oluşturur.
  /// [createdAt] sunucu zaman damgasıyla yazılır.
  Future<void> createUser({
    required String uid,
    required String username,
  }) {
    final user = AppUser(uid: uid, username: username);
    return _users.doc(uid).set(user.toFirestore());
  }

  /// Belirli bir kullanıcının dökümanını getirir (yoksa null).
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }
}
