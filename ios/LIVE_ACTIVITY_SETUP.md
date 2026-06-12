# Live Activity / Dynamic Island — Xcode Kurulumu (Mac'te)

Koşu sürerken kilit ekranında ve Dynamic Island'da canlı süre/mesafe/alan/tempo
gösteren Live Activity. **Kod yazıldı**; ama bir **Widget Extension target'ı**
yalnızca Xcode'da oluşturulabilir (Linux'tan eklenemez). Aşağıdaki adımlar Mac'te.

> Gereksinim: iOS **16.1+** (Live Activity), Dynamic Island için **iPhone 14 Pro
> ve üzeri**. Gerçek cihazda test et (simülatörde sınırlı çalışır).

## Yazılmış dosyalar
| Dosya | Hangi hedef(ler)e |
|---|---|
| `ios/Shared/RunActivityAttributes.swift` | **Runner + TreadomWidget** (ikisi de) |
| `ios/Runner/LiveActivityManager.swift` | **Runner** |
| `ios/TreadomWidget/TreadomRunLiveActivity.swift` | **TreadomWidget** |
| `ios/TreadomWidget/TreadomWidgetBundle.swift` | **TreadomWidget** |
| `ios/TreadomWidget/Info.plist` | **TreadomWidget** |
| `ios/Runner/Info.plist` → `NSSupportsLiveActivities` | (zaten eklendi) |
| Dart: `lib/services/live_activity_service.dart` + `RunProvider` bağlantısı | (hazır) |

## Adımlar

### 1. Widget Extension target'ı oluştur
1. `open ios/Runner.xcworkspace`
2. **File ▸ New ▸ Target… ▸ Widget Extension**
3. Product Name: **`TreadomWidget`** · **"Include Live Activity" KUTUSUNU İŞARETLE**
   · "Include Configuration App Intent" işaretini KALDIR.
4. **Finish** → "Activate scheme?" sorusuna **Activate**.

Xcode bir `TreadomWidget` grubu + şablon dosyalar üretir ve gömme (embed) build
fazını otomatik ekler.

### 2. Şablon dosyaları benimkilerle değiştir
Xcode'un ürettiği şablon `...LiveActivity.swift`, `...Bundle.swift`,
`...Attributes` ve varsa `AppIntent.swift` dosyalarını **sil** (Move to Trash).
Ardından bu repodaki dosyaları ekle:
- `ios/TreadomWidget/TreadomRunLiveActivity.swift` ve `TreadomWidgetBundle.swift`
  → TreadomWidget grubuna sürükle, **Target Membership: TreadomWidget**.
- `ios/TreadomWidget/Info.plist` → target'ın Info.plist'i bu olsun (Build
  Settings ▸ *Info.plist File* yolunu doğrula veya üretileni bununla değiştir).

> Not: Widget hedefinde **yalnızca bir `@main`** olabilir. Şablon bundle'ı
> sildiğinden emin ol; `@main` benim `TreadomWidgetBundle`'ımda.

### 3. Paylaşılan modeli iki hedefe de ekle
`ios/Shared/RunActivityAttributes.swift` dosyasını projeye ekle ve **File
Inspector ▸ Target Membership**'te **hem Runner hem TreadomWidget**'i işaretle.
(Aktiviteyi Runner başlatır, Widget çizer — ikisi de aynı tipe ihtiyaç duyar.)

### 4. Köprüyü Runner'a ekle
`ios/Runner/LiveActivityManager.swift` **Runner** hedefinde olmalı (Runner
grubunda; değilse Target Membership: Runner). `AppDelegate.swift` zaten kanalı
kaydediyor.

### 5. Ayarlar
- **TreadomWidget** target ▸ General ▸ **Minimum Deployments: iOS 16.1**.
- **Signing & Capabilities**: TreadomWidget için de aynı **Team**'i seç
  (otomatik imzalama). Bundle id otomatik `...treadom.TreadomWidget` olur.
- Runner Info.plist'te `NSSupportsLiveActivities = YES` (eklendi).

### 6. Çalıştır ve test et
- Gerçek iPhone'da **▶︎ Run**.
- Uygulamada **"Koşmaya Başla"** → Live Activity başlar; telefonu kilitle ya da
  ana ekrana dön → kilit ekranında kart, Dynamic Island'da süre/mesafe görünür.
- **"Turu Bitir"** → Live Activity kapanır.
- İlk seferde Live Activity izni istenebilir; Ayarlar ▸ Treadom ▸ "Canlı
  Etkinlikler"in açık olduğunu doğrula.

## Nasıl çalışıyor (özet)
- `RunProvider.start()` → `LiveActivityService.start(...)` → MethodChannel
  `treadom/live_activity` → `LiveActivityManager` → `Activity.request(...)`.
- Mesafe/alan değiştikçe `RunProvider._pushLiveActivity()` → `update`.
- Süre cihazda `Text(startDate, style:.timer)` ile kendiliğinden ilerler
  (saniyelik güncelleme trafiği yok).
- `stop()/reset()` → `end` → `activity.end(.immediate)`.
- Android/web'de `LiveActivityService` tüm çağrıları **no-op** yapar; bu özellik
  yalnızca iOS'ta devreye girer (Android'de eşdeğeri zaten foreground bildirim).
