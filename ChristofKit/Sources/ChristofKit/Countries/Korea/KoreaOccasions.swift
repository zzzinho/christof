import Foundation

/// 명절은 그날 2주 전부터 보인다. 모양은 구성 요소(창문, 사람·옷, 고양이, 방 안, 시계)마다 고르고,
/// moment 는 그 이벤트다운 사람·고양이 순간이다.
public enum KoreaOccasions {
    private static let lead = 14

    public static let all: [Occasion] = [
        Occasion(id: "KR.seollal", name: LocalizedName(en: "Seollal", ko: "설날"), rule: LunarDateRule(calendar: .dangi, month: 1, day: 1, daysBefore: lead, daysAfter: 1), looks: OccasionLooks(
            window: [Kite()], person: [Daenggi()], outfit: .seollal, cat: [CatItem.yut], room: [DeskItem.tteokguk], clock: [Bokjumeoni()],
            moment: OccasionMoment(hours: 7...10, cat: .eat))),  // 떡국 같이 먹기
        Occasion(id: "KR.jeongwolDaeboreum", name: LocalizedName(en: "Jeongwol Daeboreum", ko: "정월대보름"), rule: LunarDateRule(calendar: .dangi, month: 1, day: 15, daysBefore: lead), looks: OccasionLooks(
            window: [MoonHalo(), Daljip()], person: [PersonSprite.moonPin], outfit: .daeboreum, cat: [CatItem.walnut], room: [DeskItem.bureom],
            clock: [ClockFace(face: "moon")], moment: OccasionMoment(hours: 7...9, cat: .eat))),  // 부럼 깨기
        Occasion(id: "KR.buddhasBirthday", name: LocalizedName(en: "Buddha's Birthday", ko: "부처님오신날"), rule: LunarDateRule(calendar: .dangi, month: 4, day: 8, daysBefore: lead), looks: OccasionLooks(
            window: [LanternString()], person: [PersonSprite.lotusPin], outfit: .buddha, cat: [CatItem.lotus], room: [SillItem.lotusBowl],
            clock: [ClockLantern()], moment: OccasionMoment(hours: 19...22, cat: .beside))),  // 연등 같이 보기
        // 추석 무렵엔 머리가 어깨 길이라 댕기가 옷깃에 묻히므로 옆머리에 리본 핀을 꽂는다.
        Occasion(id: "KR.chuseok", name: LocalizedName(en: "Chuseok", ko: "추석"), rule: LunarDateRule(calendar: .dangi, month: 8, day: 15, daysBefore: lead, daysAfter: 1), looks: OccasionLooks(
            window: [MoonHalo(), PineBranch()], person: [PersonSprite.ribbonPin], outfit: .chuseok, cat: [CatItem.bojagi],
            room: [DeskItem.songpyeon], clock: [ClockFace(face: "moon")], moment: OccasionMoment(hours: 19...23, cat: .beside))),  // 보름달 같이 보기
        Occasion(id: "KR.newYearsDay", name: LocalizedName(en: "New Year's Day", ko: "새해 첫날"), rule: GregorianDateRule(month: 1, day: 1, daysBefore: lead), looks: OccasionLooks(
            window: [SunGlow()], person: [PersonSprite.beanie, PersonSprite.scarf], outfit: .newYear, cat: [CatHeadItem.beanie],
            room: [DeskItem.calendar], clock: [Sparkles()], moment: OccasionMoment(hours: 6...8, cat: .beside))),  // 첫 해 같이 보기
        Occasion(id: "KR.halloween", name: LocalizedName(en: "Halloween", ko: "할로윈"), rule: GregorianDateRule(month: 10, day: 31, daysBefore: lead), looks: OccasionLooks(
            window: [Bats()], person: [PersonSprite.witchHat], outfit: .halloween, cat: [CatHeadItem.wizardHat], room: [SillItem.pumpkin, Cobweb()],
            clock: [Spider()], moment: OccasionMoment(hours: 19...23, cat: .walk))),  // 고양이 혼자 밤 순찰
        Occasion(id: "KR.christmasEve", name: LocalizedName(en: "Christmas Eve", ko: "크리스마스 이브"), rule: GregorianDateRule(month: 12, day: 24, daysBefore: lead),
                 looks: christmas(moment: OccasionMoment(hours: 20...23, cat: .shoulder))),  // 어깨에서 잠든 고양이
        Occasion(id: "KR.christmas", name: LocalizedName(en: "Christmas", ko: "크리스마스"), rule: GregorianDateRule(month: 12, day: 25, daysBefore: lead),
                 looks: christmas(moment: OccasionMoment(hours: 8...11, cat: .pet))),  // 크리스마스 아침 쓰다듬기
    ]

    private static func christmas(moment: OccasionMoment) -> OccasionLooks {
        OccasionLooks(
            window: [Frost()], person: [PersonSprite.santaHat], outfit: .christmas, cat: [CatScarf.santa], room: [ChristmasTree()], clock: [Holly()],
            moment: moment)
    }
}
