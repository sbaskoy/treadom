import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Kullanıcıya gösterilecek (çevrilebilir) kimlik doğrulama hatası türleri.
/// UI katmanı bu türü l10n metnine dönüştürür.
enum AuthError {
  invalidCredentials,
  usernameTaken,
  weakPassword,
  network,
  generic,
}

/// Kimlik doğrulama akışını yöneten ve [AuthService] ile [FirestoreService]'i
/// koordine eden sağlayıcı.
///
/// Kayıt sırasında hem Firebase Auth hesabı oluşturur hem de Firestore'da
/// kullanıcı dökümanını yazar. Hataları yakalayıp [AuthError]'a çevirir.
class AuthProvider {
  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  /// Oturum durumu akışı (giriş/çıkış). Oturum hatırlama bununla otomatik olur.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Şu anda giriş yapmış kullanıcı (yoksa null).
  User? get currentUser => _authService.currentUser;

  /// Yeni hesap oluşturur ve Firestore'da kullanıcı dökümanını yazar.
  /// Başarılıysa null, hata varsa ilgili [AuthError] döner.
  Future<AuthError?> register({
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _authService.register(
        username: username,
        password: password,
      );
      final uid = credential.user!.uid;
      await _firestoreService.createUser(
        uid: uid,
        username: username.trim().toLowerCase(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return AuthError.generic;
    }
  }

  /// Mevcut hesapla oturum açar.
  /// Başarılıysa null, hata varsa ilgili [AuthError] döner.
  Future<AuthError?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      await _authService.signIn(username: username, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return AuthError.generic;
    }
  }

  /// Oturumu kapatır.
  Future<void> signOut() => _authService.signOut();

  /// Hesabı ve tüm kişisel verileri sunucuda siler, ardından oturumu kapatır
  /// (AuthGate otomatik olarak giriş ekranına döner). Hata olursa fırlatır.
  Future<void> deleteAccount() async {
    await _firestoreService.deleteAccount();
    await _authService.signOut();
  }

  /// Firebase hata kodlarını uygulama içi [AuthError] türüne dönüştürür.
  AuthError _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthError.usernameTaken;
      case 'weak-password':
        return AuthError.weakPassword;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return AuthError.invalidCredentials;
      case 'network-request-failed':
        return AuthError.network;
      default:
        return AuthError.generic;
    }
  }
}
