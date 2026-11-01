import SwiftUI

@main
struct ChristofApp: App {
    #if os(macOS)
    // 개발 빌드(빌드 번호 1)가 릴리스로 바뀌지 않게 릴리스 빌드에서만 업데이트를 켠다.
    #if DEBUG
    @State private var updater: AppUpdater?
    #else
    @State private var updater: AppUpdater? = AppUpdater()
    #endif
    #endif

    var body: some Scene {
        #if os(macOS)
        // 위젯을 누르면 떠 있는 앱을 앞으로 가져올 뿐 닫힌 창을 다시 열지 않는다. 창 하나짜리 Window 는 닫으면 앱이 끝나므로,
        // 다음에 누를 때 앱이 새로 뜨며 창이 열린다. 자동 설치는 이때(앱이 끝날 때) 일어난다.
        Window("Christof", id: "main") {
            PreviewScreen()
                .environment(updater)
        }
        #else
        WindowGroup {
            PreviewScreen()
        }
        #endif
    }
}
