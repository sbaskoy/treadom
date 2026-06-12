// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Treadom';

  @override
  String get appTagline => 'Yürü. Fethet. Haritaya hükmet.';

  @override
  String get welcomeMessage => 'Treadom\'a hoş geldin!';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageSystem => 'Sistem varsayılanı';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistem varsayılanı';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get loginTitle => 'Giriş Yap';

  @override
  String get registerTitle => 'Hesap Oluştur';

  @override
  String get usernameLabel => 'Kullanıcı adı';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get confirmPasswordLabel => 'Şifre (tekrar)';

  @override
  String get signInButton => 'Giriş Yap';

  @override
  String get signUpButton => 'Kayıt Ol';

  @override
  String get signOutButton => 'Çıkış Yap';

  @override
  String get noAccountPrompt => 'Hesabın yok mu?';

  @override
  String get haveAccountPrompt => 'Zaten hesabın var mı?';

  @override
  String get goToRegister => 'Kayıt Ol';

  @override
  String get goToLogin => 'Giriş Yap';

  @override
  String get validationUsernameRequired => 'Lütfen bir kullanıcı adı gir';

  @override
  String get validationUsernameTooShort =>
      'Kullanıcı adı en az 3 karakter olmalı';

  @override
  String get validationUsernameInvalid =>
      'Yalnızca harf, rakam ve alt çizgi kullan';

  @override
  String get validationPasswordRequired => 'Lütfen bir şifre gir';

  @override
  String get validationPasswordTooShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get validationPasswordMismatch => 'Şifreler eşleşmiyor';

  @override
  String get authErrorUserNotFound => 'Bu kullanıcı adıyla hesap bulunamadı';

  @override
  String get authErrorWrongPassword => 'Şifre yanlış';

  @override
  String get authErrorInvalidCredentials => 'Kullanıcı adı veya şifre hatalı';

  @override
  String get authErrorUsernameTaken => 'Bu kullanıcı adı zaten alınmış';

  @override
  String get authErrorWeakPassword => 'Şifre çok zayıf';

  @override
  String get authErrorNetwork => 'Ağ hatası. Bağlantını kontrol et';

  @override
  String get authErrorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar dene';

  @override
  String loggedInAs(String username) {
    return '$username olarak giriş yapıldı';
  }

  @override
  String get mapTitle => 'Harita';

  @override
  String get recenterTooltip => 'Konumuma dön';

  @override
  String get locationLoading => 'Konumun alınıyor…';

  @override
  String get locationServiceDisabledTitle => 'Konum kapalı';

  @override
  String get locationServiceDisabledMessage =>
      'Haritada konumunu görebilmek için cihazının konum (GPS) servisini aç.';

  @override
  String get locationPermissionDeniedTitle => 'Konum izni gerekli';

  @override
  String get locationPermissionDeniedMessage =>
      'Treadom çalışmak için konumuna ihtiyaç duyar. Lütfen konum iznini ver.';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Konum izni kalıcı olarak reddedildi. İzni sistem ayarlarından açman gerekiyor.';

  @override
  String get openSettingsButton => 'Ayarları Aç';

  @override
  String get retryButton => 'Tekrar Dene';
}
