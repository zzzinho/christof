import ChristofKit
import os
import SwiftUI
import WidgetKit

@main
struct ChristofWidgetBundle: WidgetBundle {
    init() {
        #if os(macOS)
        _ = Self.updateWatcher
        #endif
    }

    var body: some Widget {
        ChristofWindowWidget()
    }
}

struct ChristofWindowWidget: Widget {
    static let kind = "ChristofWindow"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectRegionIntent.self, provider: WindowTimelineProvider()) { entry in
            WindowEntryView(entry: entry)
        }
        .configurationDisplayName("Christof Window")
        .description("Shows the weather, time, and holidays of the chosen region as the view outside a window.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#if os(macOS)
extension ChristofWidgetBundle {
    private static let logger = Logger(subsystem: "com.christof.Christof", category: "widget")

    // 위젯은 Christof.app/Contents/PlugIns/ 안에 있다. 앱이 업데이트되면 끝나서 chronod 가 새 번들로 다시 띄운다.
    private static let updateWatcher: BundleReplacementWatcher? = {
        let app = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let watcher = BundleReplacementWatcher(bundle: app) {
            logger.notice("앱 번들이 바뀌어 위젯 프로세스를 끝낸다 \(app.path, privacy: .public)")
            exit(0)
        }
        if watcher == nil { logger.error("앱 번들을 감시하지 못했다. 업데이트 뒤 위젯이 옛 버전으로 남을 수 있다 \(app.path, privacy: .public)") }
        return watcher
    }()
}
#endif
