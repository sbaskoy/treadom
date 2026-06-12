import ActivityKit
import Foundation

// Live Activity (Dynamic Island + kilit ekranı) için paylaşılan veri modeli.
//
// ÖNEMLİ: Bu dosya HEM `Runner` HEM de `TreadomWidget` hedeflerine eklenmelidir
// (Xcode'da dosyayı seçip File Inspector ▸ Target Membership'te ikisini de
// işaretle). Aktiviteyi `Runner` başlatır/günceller; `TreadomWidget` çizer.
@available(iOS 16.1, *)
struct RunActivityAttributes: ActivityAttributes {
    // Aktivite boyunca değişmeyen statik kısım.
    var title: String

    // Koşu sürerken güncellenen dinamik kısım.
    public struct ContentState: Codable, Hashable {
        // Süre sayacının cihazda kendiliğinden ilerlemesi için başlangıç anı
        // (epoch ms). Böylece her saniye güncelleme göndermeye gerek kalmaz.
        var startedAtMs: Double
        var distanceText: String
        var areaText: String
        var paceText: String

        var startDate: Date {
            Date(timeIntervalSince1970: startedAtMs / 1000.0)
        }
    }
}
