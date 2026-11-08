import ChristofKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// 앱 아이콘(Christof/AppIcon.icon/Assets/scene.png)과 README GIF(docs/images/)를 앱과 같은 그리기 코드로 다시 만든다.
// 스냅샷 도구처럼 실제 지역·날짜를 SceneContextFactory 에 넣고 날씨만 가짜로 준다. 인자는 레포 루트(기본 현재 폴더).

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".", isDirectory: true)
let busan = CountryRegistry.standard.region(id: "KR.busan")!
let calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = busan.timeZone; return c }()

typealias Weather = (WeatherCondition, Double, Double, Double)
struct Frame { let date: Date; let weather: Weather; var occasion: String? = nil }
let clear: Weather = (.clear, 0, 0.1, 22)

func time(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
}

func sun(_ month: Int, _ day: Int, _ event: KeyPath<SunState, Date?>) -> Date {
    SolarCalculator.state(at: time(month, day, 12), latitude: busan.latitude, longitude: busan.longitude, timeZone: busan.timeZone)[keyPath: event]!
}

func context(_ frame: Frame) -> SceneContext {
    let w = frame.weather
    let forecast = WeatherForecast(samples: [WeatherSample(time: frame.date, condition: w.0, intensity: w.1, cloudCover: w.2, temperatureCelsius: w.3)])
    let context = SceneContextFactory().context(at: frame.date, region: busan, forecast: forecast)
    if let id = frame.occasion, !context.occasions.contains(where: { $0.id == id }) {
        fatalError("\(id) 가 진행 중이 아니다. 실제 이벤트 \(context.occasions.map(\.id))")
    }
    return context
}

func save(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("저장 실패: \(url.path)") }
}

// 앱 아이콘: 부산 6월 10일 21:00 맑음(광안대교 야경)을 64x64 칸에 그려 1칸 16px 로 키운다. 도트가 흐려지지 않게 칸을 그대로 칠한다.
@MainActor func appIcon() {
    let (cells, px) = (64, 1024)
    let grid = SceneComposer.grid(for: context(Frame(date: time(6, 10, 21), weather: (.clear, 0, 0.05, 18))), cols: cells, rows: cells)
    let scale = Double(px) / Double(cells)
    let cg = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    cg.setShouldAntialias(false)
    for y in 0..<cells { for x in 0..<cells {
        guard let c = grid.cells[y * cells + x] else { continue }
        cg.setFillColor(red: Double((c >> 16) & 0xFF) / 255, green: Double((c >> 8) & 0xFF) / 255, blue: Double(c & 0xFF) / 255, alpha: 1)
        let x0 = (Double(x) * scale).rounded(), x1 = (Double(x + 1) * scale).rounded()
        let y0 = (Double(y) * scale).rounded(), y1 = (Double(y + 1) * scale).rounded()
        cg.fill(CGRect(x: x0, y: Double(px) - y1, width: x1 - x0, height: y1 - y0))
    }}
    let url = root.appending(path: "Christof/AppIcon.icon/Assets/scene.png")
    save(cg.makeImage()!, to: url)
    print(url.path)
}

// README GIF: 중간 위젯 크기를 2배로 그려 프레임마다 담는다.
let gifs: [(name: String, delay: Double, frames: [Frame])] = [
    ("busan-time", 0.8, [
        Frame(date: time(6, 10, 4, 30), weather: clear),
        Frame(date: sun(6, 10, \.sunrise), weather: clear, occasion: "sky.sunrise"),
        Frame(date: time(6, 10, 8), weather: clear),
        Frame(date: time(6, 10, 12), weather: clear),
        Frame(date: time(6, 10, 16), weather: clear),
        Frame(date: sun(6, 10, \.sunset), weather: clear, occasion: "sky.sunset"),
        Frame(date: time(6, 10, 20, 30), weather: clear),
        Frame(date: time(6, 10, 23, 30), weather: clear),
    ]),
    ("busan-weather", 1.0, [
        Frame(date: time(1, 15, 14), weather: (.clear, 0, 0.1, 8)),
        Frame(date: time(1, 15, 14), weather: (.partlyCloudy, 0, 0.4, 8)),
        Frame(date: time(1, 15, 14), weather: (.overcast, 0, 0.95, 6)),
        Frame(date: time(1, 15, 14), weather: (.fog, 0.7, 0.6, 5)),
        Frame(date: time(1, 15, 14), weather: (.drizzle, 0.3, 0.9, 6)),
        Frame(date: time(1, 15, 14), weather: (.rain, 0.6, 0.95, 5)),
        Frame(date: time(1, 15, 14), weather: (.snow, 0.6, 0.9, -2)),
        Frame(date: time(1, 15, 14), weather: (.thunderstorm, 0.8, 1, 7)),
    ]),
    ("busan-events", 1.4, [
        Frame(date: sun(1, 1, \.sunrise), weather: (.clear, 0, 0.1, -6), occasion: "KR.newYearsDay"),
        Frame(date: time(2, 17, 8), weather: (.clear, 0, 0.1, -3), occasion: "KR.seollal"),
        Frame(date: time(3, 3, 21), weather: (.clear, 0, 0.05, 2), occasion: "KR.jeongwolDaeboreum"),
        Frame(date: sun(5, 24, \.sunset), weather: (.clear, 0, 0.1, 20), occasion: "KR.buddhasBirthday"),
        Frame(date: time(9, 25, 21), weather: (.clear, 0, 0.05, 19), occasion: "KR.chuseok"),
        Frame(date: time(10, 31, 20), weather: (.partlyCloudy, 0, 0.4, 12), occasion: "KR.halloween"),
        Frame(date: time(12, 24, 21), weather: (.clear, 0, 0.1, -5), occasion: "KR.christmasEve"),
        Frame(date: time(12, 25, 10), weather: (.snow, 0.6, 0.9, -2), occasion: "KR.christmas"),
    ]),
]

@MainActor func readmeGIFs() {
    let size = WindowSize.regular.referenceSize
    for gif in gifs {
        let url = root.appending(path: "docs/images/\(gif.name).gif")
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, gif.frames.count, nil)!
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in gif.frames {
            let view = WindowView(context: context(frame))
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            CGImageDestinationAddImage(destination, renderer.cgImage!, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: gif.delay]] as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { fatalError("저장 실패: \(url.path)") }
        print(url.path)
    }
}

appIcon()
readmeGIFs()
