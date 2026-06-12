# iOS — Kendi iPhone'una Kurma Kılavuzu

iOS derleme ve imzalama **yalnızca macOS + Xcode** ile yapılır. Bu depo Linux'ta
hazırlandığı için aşağıdaki adımlar **Mac'te** uygulanır. Kod ve yapılandırma
tarafı tamamlandı; sende kalan tek iş Xcode'da imzalama + cihaza yükleme.

## Hazır olanlar (kodda tamam)
- **Firebase iOS yapılandırıldı:** `lib/firebase_options.dart` içine `ios` bloğu
  eklendi ve Firebase projesinde bir iOS uygulaması kaydedildi
  (`1:308613082441:ios:…`). `ios/Runner/GoogleService-Info.plist` indirildi.
  Uygulama `DefaultFirebaseOptions.currentPlatform` ile başlatıldığından Firebase
  (Auth/Firestore) iOS'ta çalışır.
- **Info.plist:** konum izin metinleri (`NSLocationWhenInUse…`,
  `NSLocationAlwaysAndWhenInUse…`), `UIBackgroundModes` (location/fetch/processing),
  `BGTaskSchedulerPermittedIdentifiers`, ve AdMob `GADApplicationIdentifier`
  (Google iOS TEST kimliği — kendi gerçek kimliğinle değiştir ya da reklam
  kullanmayacaksan `google_mobile_ads`'i çıkar).
- **Bundle ID:** `com.salimbaskoy.treadom`.
- **Deployment target:** iOS 15.0 (Firebase pod'ları için). `Podfile` platform 15.0.
- **AppDelegate.swift / bridging header:** flutter_foreground_task için ayarlı.
- **Firestore kuralları** zaten deploy edildi (prototip; fetih şu an istemci
  tarafında, çalışıyor).

## Mac'te adımlar

### 1. Gereksinimler
```bash
xcode-select --install            # Xcode komut satırı araçları
sudo gem install cocoapods        # CocoaPods (yoksa)
flutter doctor                    # iOS toolchain'i ✓ olmalı
```

### 2. Bağımlılıklar
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3. GoogleService-Info.plist'i hedefe ekle
`ios/Runner/GoogleService-Info.plist` dosyası var. Xcode'da **Runner** hedefinde
görünmüyorsa: `ios/Runner.xcworkspace`'i aç → soldaki **Runner** grubuna dosyayı
sürükle → "Copy items if needed" kapalı, **Target: Runner** işaretli.
(Uygulama Dart tarafı seçeneklerle başladığı için çekirdek Firebase plist olmadan
da çalışır; yine de eklemek standarttır.)

### 4. İmzalama (Signing)
1. `open ios/Runner.xcworkspace`
2. Soldan **Runner** projesi → **Signing & Capabilities** sekmesi.
3. **Team**: kendi Apple ID'ni seç (Xcode ▸ Settings ▸ Accounts'tan ekle).
   - **Ücretsiz Apple ID** yeterli (App Store gerekmez). Sınırlar: uygulama
     **7 günde bir** yeniden yüklenmeli, aynı anda az sayıda uygulama/cihaz.
   - Bundle ID çakışırsa benzersiz yap (ör. `com.salimbaskoy.treadom2`).
4. **Automatically manage signing** açık olsun.
5. **Background Modes** capability'sinin açık ve "Location updates" işaretli
   olduğunu doğrula (Info.plist ile eşleşir).

### 5. Cihaza yükle
1. iPhone'u USB ile bağla, "Bu bilgisayara güven" de.
2. Xcode üst çubukta cihazını seç → ▶︎ Run. (veya `flutter run -d <cihaz-adı>`)
3. İlk açılışta iPhone: **Ayarlar ▸ Genel ▸ VPN ve Aygıt Yönetimi** →
   geliştirici profiline **Güven**.
4. Uygulamayı aç. "Koşmaya Başla" → konum (Always tercih) + bildirim izni ister.

### 6. Test kullanıcıları (hazır)
`ayse`, `mehmet`, `zeynep`, `fatih` — şifre `test1234`. Gerçek iPhone'da
yürüyerek ya da Xcode ▸ Debug ▸ Simulate Location ile rota oluşturup fetih
denenebilir (Android emülatörü gibi `adb` yok).

## Notlar / sonraki adımlar
- **AdMob:** şu an test kimliği. Reklam göstermeyeceksen `google_mobile_ads`'i
  `pubspec.yaml`'dan çıkar ve Info.plist'teki `GADApplicationIdentifier`'ı sil.
- **Fethi sunucuya taşıma (güvenli sürüm):** `functions/` altında hazır Cloud
  Function var ama deploy **Blaze planı** ister (proje şu an Spark). Blaze'e
  geçince fonksiyon deploy edilip istemci ona bağlanır, kurallar sıkılaştırılır.
- **Live Activity (Dynamic Island canlı widget):** kod yazıldı (Dart + Swift).
  Xcode'da bir Widget Extension target'ı oluşturmak için: **`ios/LIVE_ACTIVITY_SETUP.md`**.
