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
  String get avatarLabel => 'Avatar';

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

  @override
  String get startRunButton => 'Koşmaya Başla';

  @override
  String get stopRunButton => 'Turu Bitir';

  @override
  String get newRunButton => 'Yeni Tur';

  @override
  String get runDistanceLabel => 'Mesafe';

  @override
  String get runAreaLabel => 'Alan';

  @override
  String get runFinishedTitle => 'Tur tamamlandı!';

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(String km) {
    return '$km km';
  }

  @override
  String areaSquareMeters(String value) {
    return '$value m²';
  }

  @override
  String areaSquareKilometers(String value) {
    return '$value km²';
  }

  @override
  String get runElapsedLabel => 'Süre';

  @override
  String get runPaceLabel => 'Tempo';

  @override
  String get runCaloriesLabel => 'Kalori';

  @override
  String caloriesValue(String value) {
    return '$value kcal';
  }

  @override
  String get paceSuffix => '/km';

  @override
  String get unitKilometers => 'km';

  @override
  String get unitMeters => 'm';

  @override
  String get unitKcal => 'kcal';

  @override
  String get runOngoingTitle => 'Koşu sürüyor';

  @override
  String get notificationChannelName => 'Koşu takibi';

  @override
  String get weightLabel => 'Kilo';

  @override
  String weightValue(String value) {
    return '$value kg';
  }

  @override
  String get claimTitle => 'Alanına isim ver';

  @override
  String claimMessage(String area) {
    return '$area büyüklüğünde bir alan çevreledin. Bir isim ver ya da kullanıcı adın kullanılsın diye boş bırak.';
  }

  @override
  String get territoryNameLabel => 'Alan adı';

  @override
  String get landNameHint => 'Tüm topraklarında görünür';

  @override
  String get saveButton => 'Kaydet';

  @override
  String get landNameUpdated => 'Alan adı güncellendi';

  @override
  String get claimButton => 'Alanı Sahiplen';

  @override
  String claimedSnack(String name) {
    return '\"$name\" alanını sahiplendin!';
  }

  @override
  String landsConquered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rakip alan fethedildi!',
      one: '1 rakip alan fethedildi!',
    );
    return '$_temp0';
  }

  @override
  String get runSavedSnack => 'Tur geçmişine kaydedildi.';

  @override
  String get loopNotClosedHint =>
      'Alan alınmadı — başlangıç noktana (ya da kendi alanına) geri dönerek halkayı kapat.';

  @override
  String get loopTooShortHint =>
      'Alan alınmadı — biraz daha ilerleyip dönerek halkayı kapat.';

  @override
  String get historyTitle => 'Yürüme Geçmişi';

  @override
  String get historyTooltip => 'Yürüme geçmişi';

  @override
  String get historyEmptyTitle => 'Henüz tur yok';

  @override
  String get historyEmptyMessage =>
      'Koşmaya başla; rotaların ve fethettiğin alanlar burada birikecek.';

  @override
  String get historyClaimedBadge => 'Alan alındı';

  @override
  String historyConqueredBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fetih',
      one: '1 fetih',
    );
    return '$_temp0';
  }

  @override
  String territoryOwnerLabel(String username) {
    return '$username alanı';
  }

  @override
  String get territoryYoursLabel => 'Senin alanın';

  @override
  String get territoryClaimedLabel => 'Alındı';

  @override
  String territoryConqueredFromLabel(String username) {
    return '$username alanından fethedildi';
  }

  @override
  String get leaderboardTitle => 'Sıralama';

  @override
  String get leaderboardTooltip => 'Sıralama';

  @override
  String get leaderboardYou => 'Sen';

  @override
  String get leaderboardEmpty => 'Henüz alan alınmadı. İlk sen ol!';

  @override
  String get leaderboardNoRank => 'Sıralamaya girmek için bir alan al.';

  @override
  String leaderboardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alan',
      one: '1 alan',
    );
    return '$_temp0';
  }

  @override
  String get howToPlayLabel => 'Nasıl oynanır';

  @override
  String get onboardingTitle1 => 'Yürü, alanı al';

  @override
  String get onboardingBody1 =>
      'Koşuya başla ve kapalı bir döngü yürü. Çevrelediğin alan senin toprağın olur.';

  @override
  String get onboardingTitle2 => 'Çevrele, fethet';

  @override
  String get onboardingBody2 =>
      'Bir rakibin alanının etrafını koş. Tamamen çevrelersen tümünü; sadece bir kısmından geçersen yalnızca o parçayı alırsın.';

  @override
  String get onboardingTitle3 => 'Haritaya hükmet';

  @override
  String get onboardingBody3 =>
      'Sıralamada yüksel, alan adını ayarlardan değiştir ve yakınındaki oyuncuları bul.';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get profileRankLabel => 'Sıra';

  @override
  String get profileLandsLabel => 'Alanlar';

  @override
  String get profileRunsLabel => 'Turlar';

  @override
  String get profileConquestsLabel => 'Fetihler';

  @override
  String get profileUnranked => 'Sırasız';

  @override
  String get chatTitle => 'Mesajlar';

  @override
  String get chatTooltip => 'Mesajlar';

  @override
  String get chatNearbyTitle => 'Yakındaki oyuncular';

  @override
  String get chatNearbyEmpty => 'Şu an yakında oyuncu yok.';

  @override
  String get chatNoLocation => 'Konumun bekleniyor…';

  @override
  String get chatEmptyTitle => 'Henüz sohbet yok';

  @override
  String get chatEmptyMessage => 'Yakındaki oyuncuları bul ve sohbet başlat.';

  @override
  String get chatMessageHint => 'Mesaj';

  @override
  String get chatEnded => 'Bu sohbet sonlandırıldı.';

  @override
  String get chatEndChat => 'Sohbeti bitir';

  @override
  String get chatEndConfirmTitle => 'Sohbeti bitir?';

  @override
  String get chatEndConfirmMessage =>
      'İkiniz de bir daha mesaj gönderemeyeceksiniz.';

  @override
  String chatAway(String dist) {
    return '$dist uzakta';
  }

  @override
  String get cancelButton => 'İptal';

  @override
  String get searchHint => 'Kullanıcı adına göre ara';

  @override
  String get searchNoResults => 'Kullanıcı bulunamadı';

  @override
  String searchNoTerritory(String username) {
    return '$username henüz alan almamış';
  }
}
