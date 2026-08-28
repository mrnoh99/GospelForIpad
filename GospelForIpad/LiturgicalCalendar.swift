//
//  LiturgicalCalendar.swift
//  GospelForIpad
//
//  Computes the Catholic liturgical position (season / week / Sunday cycle) and
//  the Korean liturgical day name for a date. Ported from the
//  ListenToGospel-Android model (LiturgicalCalendar.kt).
//

import Foundation

enum SundayCycle { case a, b, c }
enum WeekdayCycle { case i, ii }

enum LiturgicalSeason {
    case advent
    case christmas
    case ordinaryBeforeLent
    case lent
    case easter
    case ordinaryAfterPentecost
}

struct LiturgicalPosition {
    let season: LiturgicalSeason
    let week: Int
    /// Java-style day of week: Monday = 1 … Sunday = 7.
    let dayOfWeek: Int
    let sundayCycle: SundayCycle
    let weekdayCycle: WeekdayCycle
}

/// Date helpers operating on UTC-midnight dates, mirroring java.time.LocalDate.
enum LDate {
    static let sunday = 7
    static let monday = 1

    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func make(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(timeIntervalSince1970: 0)
    }

    /// Today's calendar date (in the device's local time zone), as a UTC-midnight date.
    static func today() -> Date {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let c = local.dateComponents([.year, .month, .day], from: Date())
        return make(c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    static func year(_ d: Date) -> Int { calendar.component(.year, from: d) }
    static func month(_ d: Date) -> Int { calendar.component(.month, from: d) }
    static func day(_ d: Date) -> Int { calendar.component(.day, from: d) }

    /// Monday = 1 … Sunday = 7.
    static func dayOfWeek(_ d: Date) -> Int {
        let w = calendar.component(.weekday, from: d) // Sun = 1 … Sat = 7
        return ((w + 5) % 7) + 1
    }

    static func addDays(_ d: Date, _ n: Int) -> Date {
        calendar.date(byAdding: .day, value: n, to: d) ?? d
    }

    static func addWeeks(_ d: Date, _ n: Int) -> Date { addDays(d, n * 7) }

    static func epochDay(_ d: Date) -> Int { Int((d.timeIntervalSince1970 / 86_400).rounded()) }

    static func previousOrSame(_ d: Date, weekday target: Int) -> Date {
        var x = d
        while dayOfWeek(x) != target { x = addDays(x, -1) }
        return x
    }

    static func next(_ d: Date, weekday target: Int) -> Date {
        var x = addDays(d, 1)
        while dayOfWeek(x) != target { x = addDays(x, 1) }
        return x
    }
}

enum LiturgicalCalendar {

    // Anonymous Gregorian algorithm (Meeus/Jones/Butcher)
    static func easterDate(_ year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = (h + l - 7 * m + 114) % 31 + 1
        return LDate.make(year, month, day)
    }

    // First Sunday of Advent = 4th Sunday before Christmas (incl. Christmas itself)
    static func firstSundayOfAdvent(_ year: Int) -> Date {
        let dec25 = LDate.make(year, 12, 25)
        let sundayBeforeOrOnDec25 = LDate.previousOrSame(dec25, weekday: LDate.sunday)
        return LDate.addWeeks(sundayBeforeOrOnDec25, -3)
    }

    // Sunday after January 6 (Epiphany fixed on Jan 6 per Korean Catholic practice)
    private static func baptismOfLord(_ year: Int) -> Date {
        let jan6 = LDate.make(year, 1, 6)
        return LDate.next(jan6, weekday: LDate.sunday)
    }

    private static func liturgicalYear(_ date: Date) -> Int {
        let advent = firstSundayOfAdvent(LDate.year(date))
        return date >= advent ? LDate.year(date) + 1 : LDate.year(date)
    }

    // Sunday cycle: Year A = Matthew, B = Mark, C = Luke (Liturgical Year 2026 = A)
    static func sundayCycle(_ date: Date) -> SundayCycle {
        let ly = liturgicalYear(date)
        switch (((ly - 2026) % 3) + 3) % 3 {
        case 0:  return .a
        case 1:  return .b
        default: return .c
        }
    }

    static func weekdayCycle(_ date: Date) -> WeekdayCycle {
        let ly = liturgicalYear(date)
        return ly % 2 != 0 ? .i : .ii
    }

    static func liturgicalPosition(_ date: Date) -> LiturgicalPosition {
        let year = LDate.year(date)
        let sc = sundayCycle(date)
        let wc = weekdayCycle(date)
        let dow = LDate.dayOfWeek(date)

        let advent = firstSundayOfAdvent(year)
        let inCurrentAdvent = date >= advent

        let christmasYear = inCurrentAdvent ? year : year - 1
        let easter = easterDate(inCurrentAdvent ? year + 1 : year)
        let baptism = baptismOfLord(christmasYear + 1)
        let christmas = LDate.make(christmasYear, 12, 25)
        let lYearStart = inCurrentAdvent ? advent : firstSundayOfAdvent(year - 1)

        let ashWednesday = LDate.addDays(easter, -46)
        let pentecost = LDate.addDays(easter, 49)

        let nextAdvent = inCurrentAdvent ? firstSundayOfAdvent(year + 1) : advent
        let christTheKing = LDate.addWeeks(nextAdvent, -1)

        let season: LiturgicalSeason
        if date >= lYearStart && date < christmas {
            season = .advent
        } else if date >= christmas && date < baptism {
            season = .christmas
        } else if date >= baptism && date < ashWednesday {
            season = .ordinaryBeforeLent
        } else if date >= ashWednesday && date < easter {
            season = .lent
        } else if date >= easter && date < pentecost {
            season = .easter
        } else {
            season = .ordinaryAfterPentecost
        }

        let week: Int
        switch season {
        case .advent:
            let days = LDate.epochDay(date) - LDate.epochDay(lYearStart)
            week = min(max(days / 7 + 1, 1), 4)
        case .christmas:
            let days = LDate.epochDay(date) - LDate.epochDay(christmas)
            week = min(max(days / 7 + 1, 1), 3)
        case .ordinaryBeforeLent:
            let mondayWeek2 = LDate.addDays(baptism, 1)
            let days = LDate.epochDay(date) - LDate.epochDay(mondayWeek2)
            week = min(max(days / 7 + 2, 2), 9)
        case .lent:
            let days = LDate.epochDay(date) - LDate.epochDay(ashWednesday)
            week = min(max(days / 7 + 1, 1), 6)
        case .easter:
            let days = LDate.epochDay(date) - LDate.epochDay(easter)
            week = min(max(days / 7 + 1, 1), 7)
        case .ordinaryAfterPentecost:
            let sundayOfWeek = LDate.previousOrSame(date, weekday: LDate.sunday)
            let days = LDate.epochDay(christTheKing) - LDate.epochDay(sundayOfWeek)
            week = min(max(34 - days / 7, 10), 34)
        }

        return LiturgicalPosition(season: season, week: week, dayOfWeek: dow, sundayCycle: sc, weekdayCycle: wc)
    }

    static func commemorationName(_ date: Date = LDate.today()) -> String? {
        let md = LDate.month(date) * 100 + LDate.day(date)
        switch md {
        case 114:  return "성 힐라리오 주교 학자 기념일"
        case 117:  return "성 안토니오 아빠스 기념일"
        case 122:  return "성 빈첸시오 보사포장 기념일"
        case 124:  return "성 프란치스코 드 살레스 주교 학자 기념일"
        case 125:  return "성 바오로 사도의 회심 기념일"
        case 202:  return "성 촉발라 동정 순교자 기념일"
        case 216:  return "성 다수에도 주교 기념일"
        case 306:  return "성 영아소 순교자 기념일"
        case 307:  return "성 도마스 아퀴나스 사제 학자 기념일"
        case 319:  return "성 요셉 기념일"
        case 323:  return "성 토리비오 알폰소 로드리게스 수사 기념일"
        case 325:  return "성 루스 처녀 기념일"
        case 405:  return "성 판크라티오 순교자 기념일"
        case 425:  return "성 마르코 복음사가 기념일"
        case 503:  return "성 필립보와 성 야고보 사도 기념일"
        case 514:  return "성 마티아 사도 기념일"
        case 528:  return "성 어거스틴 캔터베리 주교 기념일"
        case 531:  return "성 비시띠니에 수모 기념일"
        case 602:  return "성 마르첼리노와 성 베드로 순교자 기념일"
        case 609:  return "성 에프렘 디아콘 학자 기념일"
        case 611:  return "성 바르나바 사도 기념일"
        case 619:  return "성 로무알도 아빠스 기념일"
        case 624:  return "성 요한 세례자 탄생 축일"
        case 628:  return "성 이레나이오 주교 순교자 기념일"
        case 629:  return "성 베드로와 성 바오로 사도 축일"
        case 704:  return "성 엘리사벳 포르투갈 기념일"
        case 706:  return "성 마리아 고레띠 동정 순교자 기념일"
        case 709:  return "성 아우구스티노 주교 학자 기념일"
        case 710:  return "성 베네딕토 아빠스 기념일"
        case 720:  return "성 엘리야 예언자 기념일"
        case 722:  return "성 막달레나 기념일"
        case 723:  return "성 브리지따 수녀 기념일"
        case 724:  return "성 크리스토포로 순교자 기념일"
        case 725:  return "성 야고보 사도 기념일"
        case 726:  return "성 안나 기념일"
        case 803:  return "성 도미니쿠스 사제 기념일"
        case 806:  return "주님의 거룩한 변모 축일"
        case 810:  return "성 로렌시오 부제 순교자 기념일"
        case 811:  return "성 수산나 동정 순교자 기념일"
        case 813:  return "성 폰시아노 교황 순교자 기념일"
        case 815:  return "성모 승천 대축일"
        case 819:  return "성 요한 에우데스 사제 기념일"
        case 820:  return "성 베르나르도 아빠스 학자 기념일"
        case 821:  return "성 비오 10세 교황 기념일"
        case 822:  return "성 마리아의 모후 기념일"
        case 823:  return "성 로사 리마 동정 기념일"
        case 824:  return "성 바르톨로메오 사도 축일"
        case 827:  return "성 모니카 기념일"
        case 828:  return "성 아우구스티노 주교 학자 기념일"
        case 829:  return "성 요한 세례자 순교 기념일"
        case 830:  return "성 로사 리마 동정 기념일"
        case 914:  return "성 십자가 현양 축일"
        case 915:  return "성모 고통 기념일"
        case 916:  return "성 고르넬리오 교황과 성 키프리아노 주교 순교자 기념일"
        case 921:  return "성 마태오 사도 복음사가 축일"
        case 926:  return "성 코스마와 성 다미아노 순교자 기념일"
        case 929:  return "성 가브리엘, 성 미카엘, 성 라파엘 대천사 축일"
        case 1001: return "성 떼레사 아기 예수 동정 학자 기념일"
        case 1002: return "성 수호천사 기념일"
        case 1004: return "성 프란치스코 아시시 기념일"
        case 1006: return "성 브루노 사제 기념일"
        case 1007: return "성 마르첼루스 1세 교황 순교자 기념일"
        case 1015: return "성 테레사 아빌라 동정 학자 기념일"
        case 1018: return "성 루카 복음사가 축일"
        case 1019: return "성 요한 드 브레베쿠르 사제 기념일"
        case 1028: return "성 시몬과 성 유다 사도 축일"
        case 1031: return "성 알폰소 로드리게스 기념일"
        case 1101: return "모든 성인 대축일"
        case 1102: return "죽은 모든 이를 기억하는 위령의 날"
        case 1103: return "성 마르틴 투르 주교 기념일"
        case 1110: return "성 요한 레비 주교 기념일"
        case 1111: return "성 마르틴 투르 주교 기념일"
        case 1113: return "성 디에고 알칼라 사제 기념일"
        case 1114: return "성 레오파르도 기념일"
        case 1115: return "성 알베르토 대 주교 학자 기념일"
        case 1116: return "성 마르가리따 스코틀랜드 기념일"
        case 1119: return "성 엘리자벳 헝가리 기념일"
        case 1120: return "성 에드문도 킹 순교자 기념일"
        case 1121: return "성 프리젠따시오 사제 기념일"
        case 1122: return "성 체칠리아 동정 순교자 기념일"
        case 1123: return "성 클레멘스 1세 교황 순교자 기념일"
        case 1124: return "성 앤드류 두 뮈질 기념일"
        case 1125: return "성 카타리나 알렉산드리아 동정 순교자 기념일"
        case 1130: return "성 안드레아 사도 축일"
        case 1201: return "성모의 모후 기념일"
        case 1203: return "성 프란시스코 살레스 주교 기념일"
        case 1205: return "성 베르나르드 1세 기념일"
        case 1206: return "성 니콜라오 주교 기념일"
        case 1208: return "원죄 없이 잉태되신 복되신 동정 마리아 대축일"
        case 1214: return "성 요한 십자가 사제 학자 기념일"
        case 1221: return "성 베드로 캐니시오 사제 학자 기념일"
        case 1222: return "성 프란치스코 사비에르 사제 기념일"
        case 1223: return "성 요한 캔톤 주교 기념일"
        case 1225: return "주님 성탄 대축일"
        case 1226: return "성 스테파노 첫 순교자 축일"
        case 1227: return "성 요한 사도 복음사가 축일"
        case 1228: return "죄 없는 아기 순교자들 축일"
        case 1229: return "성 토마스 베켓 주교 순교자 기념일"
        case 1231: return "성 실베스테르 1세 교황 기념일"
        default: return nil
        }
    }

    static func liturgicalDayName(_ date: Date = LDate.today()) -> String {
        let md = LDate.month(date) * 100 + LDate.day(date)
        switch md {
        case 101:  return "천주의 성모 마리아 대축일"
        case 202:  return "주님 봉헌 축일"
        case 319:  return "복되신 동정 마리아의 배필 성 요셉 대축일"
        case 325:  return "주님 탄생 예고 대축일"
        case 624:  return "성 요한 세례자 탄생 대축일"
        case 629:  return "성 베드로와 성 바오로 사도 대축일"
        case 806:  return "주님의 거룩한 변모 축일"
        case 815:  return "성모 승천 대축일"
        case 1101: return "모든 성인 대축일"
        case 1102: return "죽은 모든 이를 기억하는 위령의 날"
        case 1208: return "한국 교회의 수호자 원죄 없이 잉태되신 복되신 동정 마리아 대축일"
        case 1225: return "주님 성탄 대축일"
        case 1226: return "성 스테파노 첫 순교자 축일"
        case 1228: return "죄 없는 아기 순교자들 축일"
        default: break
        }

        if LDate.month(date) == 12 && (17...24).contains(LDate.day(date)) {
            return "12월 \(LDate.day(date))일 대림"
        }

        // Korea: Epiphany on the Sunday between Jan 2–8
        if LDate.month(date) == 1 && (2...8).contains(LDate.day(date)) && LDate.dayOfWeek(date) == LDate.sunday {
            return "주님 공현 대축일"
        }

        let year = LDate.year(date)
        let easter = easterDate(year)
        let ashWed = LDate.addDays(easter, -46)
        let pentecost = LDate.addDays(easter, 49)
        let baptism = baptismOfLord(year)
        let dec25 = LDate.make(year, 12, 25)
        let holyFamily = LDate.dayOfWeek(dec25) == LDate.sunday
            ? LDate.make(year, 12, 30)
            : LDate.next(dec25, weekday: LDate.sunday)
        let christTheKing = LDate.addWeeks(firstSundayOfAdvent(year), -1)

        let movable: [(Date, String)] = [
            (baptism, "주님 세례 축일"),
            (ashWed, "재의 수요일"),
            (LDate.addDays(ashWed, 1), "재의 예식 다음 목요일"),
            (LDate.addDays(ashWed, 2), "재의 예식 다음 금요일"),
            (LDate.addDays(ashWed, 3), "재의 예식 다음 토요일"),
            (LDate.addDays(easter, -7), "주님 수난 성지 주일"),
            (LDate.addDays(easter, -3), "주님 만찬 성목요일"),
            (LDate.addDays(easter, -2), "주님 수난 성금요일"),
            (LDate.addDays(easter, -1), "성토요일"),
            (easter, "주님 부활 대축일"),
            (LDate.addDays(easter, 1), "부활 팔일 축제 월요일"),
            (LDate.addDays(easter, 2), "부활 팔일 축제 화요일"),
            (LDate.addDays(easter, 3), "부활 팔일 축제 수요일"),
            (LDate.addDays(easter, 4), "부활 팔일 축제 목요일"),
            (LDate.addDays(easter, 5), "부활 팔일 축제 금요일"),
            (LDate.addDays(easter, 6), "부활 팔일 축제 토요일"),
            (LDate.addDays(easter, 42), "주님 승천 대축일"),
            (pentecost, "성령 강림 대축일"),
            (LDate.addDays(pentecost, 1), "교회의 어머니 복되신 동정 마리아 기념일"),
            (LDate.addDays(pentecost, 7), "지극히 거룩하신 삼위일체 대축일"),
            (LDate.addDays(pentecost, 14), "지극히 거룩하신 그리스도의 성체 성혈 대축일"),
            (LDate.addDays(pentecost, 19), "지극히 거룩하신 예수 성심 대축일"),
            (holyFamily, "예수, 마리아, 요셉의 성가정 축일"),
            (christTheKing, "온 누리의 임금이신 우리 주 예수 그리스도 왕 대축일"),
        ]
        for (d, name) in movable where d == date {
            return name
        }

        let pos = liturgicalPosition(date)
        let s: String
        switch pos.season {
        case .advent:    s = "대림"
        case .christmas: s = "성탄"
        case .ordinaryBeforeLent, .ordinaryAfterPentecost: s = "연중"
        case .lent:      s = "사순"
        case .easter:    s = "부활"
        }
        switch pos.dayOfWeek {
        case 7: return "\(s) 제\(pos.week)주일"
        case 1: return "\(s) 제\(pos.week)주간 월요일"
        case 2: return "\(s) 제\(pos.week)주간 화요일"
        case 3: return "\(s) 제\(pos.week)주간 수요일"
        case 4: return "\(s) 제\(pos.week)주간 목요일"
        case 5: return "\(s) 제\(pos.week)주간 금요일"
        case 6: return "\(s) 제\(pos.week)주간 토요일"
        default: return s
        }
    }
}
