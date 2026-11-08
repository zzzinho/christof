import Foundation

// 업데이트(Sparkle)는 앱 번들을 통째로 다른 자리로 옮기고 새 번들을 놓는다. 이미 떠 있던 위젯 프로세스는 끝나지 않고
// 옛 번들 정보로 계속 응답해서, chronod 가 리로드를 "Bundle version did not match" 로 거절하고 위젯이 멈춘다.
// 옛 번들이 옮겨지거나 지워지면 알려서 위젯이 스스로 끝나고 chronod 가 새 번들로 다시 띄우게 한다.
public final class BundleReplacementWatcher: @unchecked Sendable {
    private let source: any DispatchSourceFileSystemObject

    public init?(bundle: URL, onReplaced: @escaping @Sendable () -> Void) {
        let descriptor = open(bundle.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.rename, .delete], queue: .global())
        source.setEventHandler(handler: onReplaced)
        source.setCancelHandler { close(descriptor) }
        source.resume()
    }

    deinit {
        source.cancel()
    }
}
