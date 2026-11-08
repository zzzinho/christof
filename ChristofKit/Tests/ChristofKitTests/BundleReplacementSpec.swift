import Foundation
import Testing
@testable import ChristofKit

@Suite("업데이트 뒤 위젯 다시 띄우기")
struct BundleReplacementSpec {
    @Test("업데이트가 앱 번들을 다른 자리로 옮기면 위젯에 알린다")
    func moved() async throws {
        let bundle = try makeBundle()
        #expect(try await notified(bundle) { try FileManager.default.moveItem(at: bundle, to: bundle.appendingPathExtension("old")) })
    }

    // Sparkle 2.10.1 은 먼저 renamex_np(RENAME_SWAP) 으로 새 번들과 자리를 맞바꾸고, 안 되면 옮긴다(SUPlainInstaller).
    @Test("업데이트가 새 번들과 자리를 맞바꾸면 위젯에 알린다")
    func swapped() async throws {
        let bundle = try makeBundle()
        let new = try makeBundle()
        #expect(try await notified(bundle) {
            guard renamex_np(bundle.path, new.path, UInt32(RENAME_SWAP)) == 0 else { throw POSIXError(.init(rawValue: errno)!) }
        })
    }

    @Test("앱 번들이 지워지면 위젯에 알린다")
    func deleted() async throws {
        let bundle = try makeBundle()
        #expect(try await notified(bundle) { try FileManager.default.removeItem(at: bundle) })
    }

    @Test("앱 번들이 제자리에 있으면 안의 파일이 바뀌어도 알리지 않는다")
    func untouched() async throws {
        let bundle = try makeBundle()
        #expect(try await !notified(bundle) { try Data("x".utf8).write(to: bundle.appending(path: "new")) })
    }

    private func makeBundle() throws -> URL {
        let bundle = FileManager.default.temporaryDirectory.appending(path: "BundleReplacementSpec-\(UUID().uuidString).app")
        try FileManager.default.createDirectory(at: bundle.appending(path: "Contents"), withIntermediateDirectories: true)
        return bundle
    }

    private func notified(_ bundle: URL, after change: () throws -> Void) async throws -> Bool {
        let (events, continuation) = AsyncStream.makeStream(of: Bool.self)
        let watcher = try #require(BundleReplacementWatcher(bundle: bundle) { continuation.yield(true) })
        try change()
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            continuation.yield(false)
        }
        var iterator = events.makeAsyncIterator()
        let result = await iterator.next() ?? false
        withExtendedLifetime(watcher) {}
        return result
    }
}
