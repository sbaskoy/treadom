import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'daki `users/{uid}` dökümanını temsil eden kullanıcı modeli.
///
/// Kimlik doğrulama Firebase Auth ile yapılır; bu model ise oyunla ilgili
/// kullanıcı verisini (görünen kullanıcı adı, toplam fethedilen alan vb.)
/// Firestore'da tutar.
class AppUser {
  /// Firebase Auth kullanıcı kimliği (döküman kimliği olarak da kullanılır).
  final String uid;

  /// Kullanıcının seçtiği görünen ad (küçük harfe normalize edilmiş hali).
  final String username;

  /// Şimdiye kadar fethedilen toplam alan (metrekare). Aşama 4+ ile dolacak.
  final double totalAreaM2;

  /// Hesabın oluşturulma zamanı.
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.username,
    this.totalAreaM2 = 0,
    this.createdAt,
  });

  /// Firestore dökümanından model oluşturur.
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      username: (data['username'] as String?) ?? '',
      totalAreaM2: (data['totalAreaM2'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Modeli Firestore'a yazılacak haritaya dönüştürür.
  /// [createdAt] yeni kayıtlarda sunucu zaman damgasıyla yazılır.
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'totalAreaM2': totalAreaM2,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
