import Foundation
import SwiftUI

/// 그리기에 쓰는 장면 값. 시안의 sceneContext() 를 옮겼다.
struct DotScene {
    /// 창밖과 벽 색을 고르는 때. 색 이름은 --lofi-<때>-<이름> 이다.
    enum Phase: String {
        case night, grey, dusk, day
    }

    enum Headwear: CaseIterable {
        case headphones, neck, bare
    }

    enum CatState: Sendable {
        case window, sleep, walk, beside, pet, shoulder, eat
    }

    /// 사람과 고양이의 상호작용. 시각이 종류를 정하고, 종류 안의 고양이 상태는 시드로 고른다.
    enum Interaction {
        case apart, together, meal

        var cats: [CatState] {
            switch self {
            case .apart: [.window, .sleep, .walk]
            case .together: [.beside, .pet, .shoulder]
            case .meal: [.eat]
            }
        }

        /// [시작 시각, 종류]. 아침(7~8시)·점심(12시)·저녁(18~19시)은 밥, 사람이 일하는 낮은 따로, 밤은 같이.
        static let daily: [(from: Int, kind: Interaction)] = [(0, .together), (7, .meal), (9, .apart), (12, .meal), (13, .apart), (18, .meal), (20, .together)]

        static func at(hour: Int) -> Interaction {
            daily.last { hour >= $0.from }?.kind ?? .together
        }
    }

    let phase: Phase
    let hour: Int
    let minute: Int
    let season: Season
    let weather: WeatherSample?
    let sunAltitude: Double
    let moonPhase: Double
    let sunPoint: CelestialPosition.Point?
    let moonPoint: CelestialPosition.Point?
    let snowCovered: Bool
    let headwear: Headwear
    let catState: CatState
    let hair: Double
    /// 0 = 일요일
    let weekday: Int
    let outfit: Outfit
    let looks: OccasionLooks
    let farView: any FarView
    let theme: Theme
    /// 시각마다 바뀌는 시드. 같은 날 같은 시각이면 늘 같다.
    let seed: UInt64

    var lightOn: Bool { phase != .day }

    init(_ context: SceneContext) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.region.timeZone
        let parts = calendar.dateComponents([.month, .day, .hour, .minute], from: context.date)
        let month = parts.month ?? 1, day = parts.day ?? 1
        weekday = calendar.component(.weekday, from: context.date) - 1
        hour = parts.hour ?? 0
        minute = parts.minute ?? 0
        season = context.season
        weather = context.weather
        sunAltitude = context.sun.altitude
        moonPhase = context.moon.phase

        let gloomy = weather.map { $0.condition.hasCloudDeck || $0.condition == .fog } ?? false
        // 흐린 날은 해 질 녘도 회색 하늘로 둔다. 비·눈·안개 색은 night 와 grey 에만 있다.
        phase = sunAltitude < -6 ? .night : gloomy ? .grey : sunAltitude < 6 ? .dusk : .day
        sunPoint = gloomy ? nil : CelestialPosition.sun(context.sun, latitude: context.region.latitude)
        moonPoint = gloomy || sunAltitude >= 0 ? nil : CelestialPosition.moon(context.moon, latitude: context.region.latitude)
        // 따뜻한 겨울(부산·제주)은 마른 풍경으로 두고, 눈이 오거나 영하일 때만 지붕에 눈을 얹는다.
        snowCovered = weather.map { $0.condition == .snow || (context.season == .winter && $0.temperatureCelsius <= 0) } ?? false

        var looks = OccasionLooks.merged(context.occasions.map(\.looks))
        // 겨울엔 고양이가 요일 색 목도리를 한다. 크리스마스의 빨간 목도리가 있으면 그것만 둔다.
        if season == .winter, !looks.cat.contains(where: { $0 is CatScarf }) { looks.cat.append(CatScarf.winter) }
        self.looks = looks
        farView = context.region.looks.far
        theme = context.theme
        seed = UInt64((month * 100 + day) * 100 + hour)
        // 같은 날 같은 시각이면 늘 같은 모습이고, 한 시간마다 바뀐다. 순간이 덮어도 뽑는 순서(헤드폰 → 고양이)는 같다.
        var random = SeededRandom(seed: seed)
        headwear = Headwear.allCases[random.int(0, Headwear.allCases.count - 1)]
        let cats = Interaction.at(hour: hour).cats, picked = cats[random.int(0, cats.count - 1)]
        let moment = context.occasions.lazy.compactMap(\.looks.moment).first { [hour] in $0.hours.contains(hour) }
        catState = moment?.cat ?? picked
        // 봄(3월 1일)에 턱선 단발로 자르고 겨울 끝(2월 말)까지 자란다.
        hair = (Double((month + 9) % 12) + Double(day - 1) / 31) / 12
        outfit = looks.outfit ?? theme.outfit
    }

    /// 때마다 다른 색
    func color(_ name: String) -> UInt32 {
        LofiPalette.color("\(phase.rawValue)-\(name)")
    }
}
