import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication'ı saran servis.
///
/// Uygulama yalnızca **kullanıcı adı + şifre** ile çalışır. Firebase'in
/// Email/Password sağlayıcısını kullanabilmek için kullanıcı adı arka planda
/// `kullaniciadi@treadom.app` formatında bir e-postaya çevrilir. Kullanıcı
/// bu e-postayı hiçbir zaman görmez.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Kullanıcı adından üretilen sahte e-postalarda kullanılan alan adı.
  static const String emailDomain = 'treadom.app';

  /// Oturum durumu değişimlerini yayınlayan akış (giriş/çıkış).
  /// Oturum hatırlama bu akış sayesinde otomatik çalışır: Firebase Auth
  /// oturumu cihazda saklar ve uygulama açıldığında currentUser'ı geri yükler.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Şu anda giriş yapmış kullanıcı (yoksa null).
  User? get currentUser => _auth.currentUser;

  /// Kullanıcı adını normalize edip Firebase için e-postaya çevirir.
  /// Saf bir dönüşüm olduğu için statiktir (kolay test edilebilir).
  static String usernameToEmail(String username) {
    final normalized = username.trim().toLowerCase();
    return '$normalized@$emailDomain';
  }

  /// Yeni hesap oluşturur ve oturum açar.
  Future<UserCredential> register({
    required String username,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: usernameToEmail(username),
      password: password,
    );
  }

  /// Mevcut hesapla oturum açar.
  Future<UserCredential> signIn({
    required String username,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: usernameToEmail(username),
      password: password,
    );
  }

  /// Oturumu kapatır.
  Future<void> signOut() => _auth.signOut();
}
