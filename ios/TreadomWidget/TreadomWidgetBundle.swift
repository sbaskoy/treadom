import SwiftUI
import WidgetKit

// Widget Extension giriş noktası. Şimdilik yalnızca koşu Live Activity'sini
// içerir; ileride normal (ana ekran) widget'ları da buraya eklenebilir.
@main
struct TreadomWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TreadomRunLiveActivity()
        }
    }
}
