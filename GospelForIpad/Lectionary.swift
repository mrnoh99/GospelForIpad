//
//  Lectionary.swift
//  GospelForIpad
//
//  Returns the Mass Gospel reading (chapter + start verse) for a given date,
//  limited to the four Gospels in this app. Ported from the
//  ListenToGospel-Android model (Lectionary.kt).
//

import Foundation

enum Lectionary {

    struct Reading {
        let chapter: BibleChapter
        let startVerse: Int
    }

    static func todayGospelReading(_ date: Date = LDate.today()) -> Reading? {
        let pos = LiturgicalCalendar.liturgicalPosition(date)

        // Proper gospels for solemnities & feasts take precedence over the seasonal cycle.
        if let proper = properReading(date, cycle: pos.sundayCycle) {
            return reading(from: proper)
        }

        let triple: (Bible.Gospel, Int, Int)?
        switch pos.season {
        case .advent:                 triple = adventGospel(pos)
        case .christmas:              triple = christmasGospel(pos)
        case .ordinaryBeforeLent:     triple = ordinaryGospel(pos)
        case .lent:                   triple = lentGospel(pos)
        case .easter:                 triple = easterGospel(pos)
        case .ordinaryAfterPentecost: triple = ordinaryGospel(pos)
        }
        guard let triple else { return nil }
        return reading(from: triple)
    }

    static func todayGospelChapter(_ date: Date = LDate.today()) -> BibleChapter? {
        todayGospelReading(date)?.chapter
    }

    // MARK: - Helpers

    private static let M = Bible.Gospel.matthew
    private static let Mk = Bible.Gospel.mark
    private static let L = Bible.Gospel.luke
    private static let J = Bible.Gospel.john

    private static func gc(_ g: Bible.Gospel, _ c: Int, _ v: Int = 1) -> (Bible.Gospel, Int, Int) { (g, c, v) }

    private static func reading(from triple: (Bible.Gospel, Int, Int)) -> Reading? {
        let (gospel, chapter, verse) = triple
        guard chapter >= 1, chapter <= gospel.chapterCount else { return nil }
        return Reading(chapter: BibleChapter(gospel: gospel, number: chapter), startVerse: verse)
    }

    private static let sunday = 7

    // MARK: - Proper gospels (solemnities & feasts)

    /// Saint feasts (사도·복음사가 축일) that yield to a Sunday when they coincide with one.
    private static let saintFeastMDs: Set<Int> = [125, 222, 425, 503, 514, 703, 824, 921, 1018, 1028, 1130, 1226, 1227, 1228]

    /// Returns the proper Gospel (chapter, start verse) for a solemnity/feast on the given
    /// date, or nil to fall back to the seasonal cycle. Cycle-dependent feasts use the Sunday cycle.
    private static func properReading(_ date: Date, cycle: SundayCycle) -> (Bible.Gospel, Int, Int)? {
        let year = LDate.year(date)
        let md = LDate.month(date) * 100 + LDate.day(date)
        let isSunday = LDate.dayOfWeek(date) == sunday

        // Fixed-date solemnities & feasts (saint feasts skipped when on a Sunday).
        if !(saintFeastMDs.contains(md) && isSunday) {
            switch md {
            case 101:  return gc(L, 2, 16)   // 천주의 성모 마리아 대축일
            case 125:  return gc(Mk, 16, 15) // 성 바오로 사도의 회심 축일
            case 202:  return gc(L, 2, 22)   // 주님 봉헌 축일
            case 222:  return gc(M, 16, 13)  // 성 베드로 사도좌 축일
            case 319:  return gc(M, 1, 16)   // 성 요셉 대축일
            case 325:  return gc(L, 1, 26)   // 주님 탄생 예고 대축일
            case 425:  return gc(Mk, 16, 15) // 성 마르코 복음사가 축일
            case 503:  return gc(J, 14, 6)   // 성 필립보와 성 야고보 사도 축일
            case 514:  return gc(J, 15, 9)   // 성 마티아 사도 축일
            case 624:  return gc(L, 1, 57)   // 성 요한 세례자 탄생 대축일
            case 629:  return gc(M, 16, 13)  // 성 베드로와 성 바오로 사도 대축일
            case 703:  return gc(J, 20, 24)  // 성 토마스 사도 축일
            case 806:                        // 주님의 거룩한 변모 축일
                switch cycle { case .a: return gc(M, 17, 1); case .b: return gc(Mk, 9, 2); case .c: return gc(L, 9, 28) }
            case 815:  return gc(L, 1, 39)   // 성모 승천 대축일
            case 824:  return gc(J, 1, 45)   // 성 바르톨로메오 사도 축일
            case 914:  return gc(J, 3, 13)   // 성 십자가 현양 축일
            case 921:  return gc(M, 9, 9)    // 성 마태오 사도 복음사가 축일
            case 1018: return gc(L, 10, 1)   // 성 루카 복음사가 축일
            case 1028: return gc(L, 6, 12)   // 성 시몬과 성 유다 사도 축일
            case 1101: return gc(M, 5, 1)    // 모든 성인 대축일
            case 1102: return gc(J, 6, 37)   // 죽은 모든 이를 기억하는 위령의 날
            case 1109: return gc(J, 2, 13)   // 라테라노 대성전 봉헌 축일
            case 1130: return gc(M, 4, 18)   // 성 안드레아 사도 축일
            case 1208: return gc(L, 1, 26)   // 원죄 없이 잉태되신 복되신 동정 마리아 대축일
            case 1225: return gc(J, 1, 1)    // 주님 성탄 대축일 (낮 미사)
            case 1226: return gc(M, 10, 17)  // 성 스테파노 첫 순교자 축일
            case 1227: return gc(J, 20, 2)   // 성 요한 사도 복음사가 축일
            case 1228: return gc(M, 2, 13)   // 죄 없는 아기 순교자들 축일
            default: break
            }
        }

        // Movable solemnities & feasts of the Lord.
        let easter = LiturgicalCalendar.easterDate(year)
        let ashWednesday = LDate.addDays(easter, -46)
        let ascension = LDate.addDays(easter, 42)   // Korea: 7th Sunday of Easter
        let pentecost = LDate.addDays(easter, 49)
        let trinity = LDate.addDays(easter, 56)
        let corpusChristi = LDate.addDays(easter, 63)
        let sacredHeart = LDate.addDays(easter, 68)

        if date == ashWednesday { return gc(M, 6, 1) }               // 재의 수요일
        if date == ascension {                                       // 주님 승천 대축일
            switch cycle { case .a: return gc(M, 28, 16); case .b: return gc(Mk, 16, 15); case .c: return gc(L, 24, 46) }
        }
        if date == pentecost { return gc(J, 20, 19) }                // 성령 강림 대축일
        if date == trinity {                                         // 삼위일체 대축일
            switch cycle { case .a: return gc(J, 3, 16); case .b: return gc(M, 28, 16); case .c: return gc(J, 16, 12) }
        }
        if date == corpusChristi {                                   // 성체 성혈 대축일
            switch cycle { case .a: return gc(J, 6, 51); case .b: return gc(Mk, 14, 12); case .c: return gc(L, 9, 11) }
        }
        if date == sacredHeart {                                     // 예수 성심 대축일
            switch cycle { case .a: return gc(M, 11, 25); case .b: return gc(J, 19, 31); case .c: return gc(L, 15, 3) }
        }

        // Epiphany (Korea): the Sunday between Jan 2–8.
        if LDate.month(date) == 1, (2...8).contains(LDate.day(date)), isSunday {
            return gc(M, 2, 1)                                        // 주님 공현 대축일
        }
        // Baptism of the Lord: the Sunday after Jan 6.
        if date == LDate.next(LDate.make(year, 1, 6), weekday: sunday) {
            switch cycle { case .a: return gc(M, 3, 13); case .b: return gc(Mk, 1, 7); case .c: return gc(L, 3, 15) }
        }
        // Holy Family: the Sunday in the Christmas octave (or Dec 30).
        let dec25 = LDate.make(year, 12, 25)
        let holyFamily = LDate.dayOfWeek(dec25) == sunday ? LDate.make(year, 12, 30) : LDate.next(dec25, weekday: sunday)
        if date == holyFamily {
            switch cycle { case .a: return gc(M, 2, 13); case .b: return gc(L, 2, 22); case .c: return gc(L, 2, 41) }
        }

        return nil
    }

    // MARK: - Advent

    private static func adventGospel(_ pos: LiturgicalPosition) -> (Bible.Gospel, Int, Int)? {
        if pos.dayOfWeek != sunday {
            if pos.week == 4 {
                switch pos.dayOfWeek {
                case 1, 2: return gc(M, 1, 18)        // Monday, Tuesday
                default:   return gc(L, 1, 26)
                }
            }
        }
        return pos.dayOfWeek == sunday
            ? adventSundayGospel(pos.week, pos.sundayCycle)
            : adventWeekdayGospel(pos.week, pos.dayOfWeek)
    }

    private static func adventSundayGospel(_ week: Int, _ cycle: SundayCycle) -> (Bible.Gospel, Int, Int) {
        switch cycle {
        case .a:
            switch week { case 1: return gc(M, 24, 37); case 2: return gc(M, 3, 1); case 3: return gc(M, 11, 2); default: return gc(M, 1, 18) }
        case .b:
            switch week { case 1: return gc(Mk, 13, 33); case 2: return gc(Mk, 1, 1); case 3: return gc(J, 1, 6); default: return gc(L, 1, 26) }
        case .c:
            switch week { case 1: return gc(L, 21, 25); case 2: return gc(L, 3, 1); case 3: return gc(L, 3, 10); default: return gc(L, 1, 39) }
        }
    }

    private static func adventWeekdayGospel(_ week: Int, _ dow: Int) -> (Bible.Gospel, Int, Int) {
        let table = [
            [gc(L, 10, 25), gc(M, 15, 29), gc(L, 10, 21), gc(M, 15, 21), gc(M, 9, 27), gc(L, 20, 27)],
            [gc(L, 5, 17), gc(M, 17, 10), gc(M, 11, 28), gc(M, 11, 11), gc(L, 7, 24), gc(M, 17, 10)],
            [gc(M, 21, 28), gc(J, 1, 6), gc(M, 21, 28), gc(L, 7, 24), gc(L, 7, 31), gc(J, 1, 19)],
        ]
        let wIdx = min(max(week - 1, 0), 2)
        let dIdx = min(max(dow - 1, 0), 5)
        return table[wIdx][dIdx]
    }

    // MARK: - Christmas

    private static func christmasGospel(_ pos: LiturgicalPosition) -> (Bible.Gospel, Int, Int)? {
        pos.dayOfWeek == sunday
            ? christmasSundayGospel(pos.week, pos.sundayCycle)
            : christmasWeekdayGospel(pos.week, pos.dayOfWeek)
    }

    private static func christmasSundayGospel(_ week: Int, _ cycle: SundayCycle) -> (Bible.Gospel, Int, Int) {
        switch week {
        case 1: return gc(J, 1, 1)
        case 2:
            switch cycle {
            case .a: return gc(M, 2, 13)
            case .b: return gc(L, 2, 22)
            case .c: return gc(L, 2, 41)
            }
        default: return gc(J, 1, 1)
        }
    }

    private static func christmasWeekdayGospel(_ week: Int, _ dow: Int) -> (Bible.Gospel, Int, Int) {
        let table = [
            [gc(J, 1, 1), gc(J, 1, 1), gc(J, 1, 1), gc(J, 1, 1), gc(J, 1, 1), gc(J, 1, 1)],
            [gc(J, 1, 19), gc(J, 1, 29), gc(J, 2, 1), gc(J, 2, 1), gc(M, 2, 13), gc(J, 1, 43)],
        ]
        let wIdx = min(max(week - 1, 0), 1)
        let dIdx = min(max(dow - 1, 0), 5)
        return table[wIdx][dIdx]
    }

    // MARK: - Ordinary Time

    private static func ordinaryGospel(_ pos: LiturgicalPosition) -> (Bible.Gospel, Int, Int)? {
        pos.dayOfWeek == sunday
            ? ordinarySundayGospel(pos.week, pos.sundayCycle)
            : ordinaryWeekdayGospel(pos.week, pos.dayOfWeek)
    }

    private static func ordinarySundayGospel(_ week: Int, _ cycle: SundayCycle) -> (Bible.Gospel, Int, Int)? {
        switch cycle {
        case .a: return ordinarySundayA(week)
        case .b: return ordinarySundayB(week)
        case .c: return ordinarySundayC(week)
        }
    }

    private static func ordinarySundayA(_ week: Int) -> (Bible.Gospel, Int, Int)? {
        switch week {
        case 2:  return gc(J, 1, 29)
        case 3:  return gc(M, 4, 12)
        case 4:  return gc(M, 5, 1)
        case 5:  return gc(M, 5, 13)
        case 6:  return gc(M, 5, 17)
        case 7:  return gc(M, 5, 38)
        case 8:  return gc(M, 6, 24)
        case 9:  return gc(M, 7, 21)
        case 10: return gc(M, 9, 9)
        case 11: return gc(M, 9, 36)
        case 12: return gc(M, 10, 26)
        case 13: return gc(M, 10, 37)
        case 14: return gc(M, 11, 25)
        case 15: return gc(M, 13, 1)
        case 16: return gc(M, 13, 24)
        case 17: return gc(M, 13, 44)
        case 18: return gc(M, 14, 13)
        case 19: return gc(M, 14, 22)
        case 20: return gc(M, 15, 21)
        case 21: return gc(M, 16, 13)
        case 22: return gc(M, 16, 21)
        case 23: return gc(M, 18, 15)
        case 24: return gc(M, 18, 21)
        case 25: return gc(M, 20, 1)
        case 26: return gc(M, 21, 28)
        case 27: return gc(M, 21, 33)
        case 28: return gc(M, 22, 1)
        case 29: return gc(M, 22, 15)
        case 30: return gc(M, 22, 34)
        case 31: return gc(M, 23, 1)
        case 32: return gc(M, 25, 1)
        case 33: return gc(M, 25, 14)
        case 34: return gc(M, 25, 31)
        default: return nil
        }
    }

    private static func ordinarySundayB(_ week: Int) -> (Bible.Gospel, Int, Int)? {
        switch week {
        case 2:  return gc(J, 1, 35)
        case 3:  return gc(Mk, 1, 14)
        case 4:  return gc(Mk, 1, 21)
        case 5:  return gc(Mk, 1, 29)
        case 6:  return gc(Mk, 1, 40)
        case 7:  return gc(Mk, 2, 1)
        case 8:  return gc(Mk, 2, 18)
        case 9:  return gc(Mk, 2, 23)
        case 10: return gc(Mk, 3, 20)
        case 11: return gc(Mk, 4, 26)
        case 12: return gc(Mk, 4, 35)
        case 13: return gc(Mk, 5, 21)
        case 14: return gc(Mk, 6, 1)
        case 15: return gc(Mk, 6, 7)
        case 16: return gc(Mk, 6, 30)
        case 17: return gc(J, 6, 1)
        case 18: return gc(J, 6, 24)
        case 19: return gc(J, 6, 41)
        case 20: return gc(J, 6, 51)
        case 21: return gc(J, 6, 60)
        case 22: return gc(Mk, 7, 1)
        case 23: return gc(Mk, 7, 31)
        case 24: return gc(Mk, 8, 27)
        case 25: return gc(Mk, 9, 30)
        case 26: return gc(Mk, 9, 38)
        case 27: return gc(Mk, 10, 2)
        case 28: return gc(Mk, 10, 17)
        case 29: return gc(Mk, 10, 35)
        case 30: return gc(Mk, 10, 46)
        case 31: return gc(Mk, 12, 28)
        case 32: return gc(Mk, 12, 38)
        case 33: return gc(Mk, 13, 24)
        case 34: return gc(J, 18, 33)
        default: return nil
        }
    }

    private static func ordinarySundayC(_ week: Int) -> (Bible.Gospel, Int, Int)? {
        switch week {
        case 2:  return gc(J, 2, 1)
        case 3:  return gc(L, 4, 14)
        case 4:  return gc(L, 4, 21)
        case 5:  return gc(L, 5, 1)
        case 6:  return gc(L, 6, 17)
        case 7:  return gc(L, 6, 27)
        case 8:  return gc(L, 6, 39)
        case 9:  return gc(L, 7, 1)
        case 10: return gc(L, 7, 11)
        case 11: return gc(L, 7, 36)
        case 12: return gc(L, 9, 18)
        case 13: return gc(L, 9, 51)
        case 14: return gc(L, 10, 1)
        case 15: return gc(L, 10, 25)
        case 16: return gc(L, 10, 38)
        case 17: return gc(L, 11, 1)
        case 18: return gc(L, 12, 13)
        case 19: return gc(L, 12, 32)
        case 20: return gc(L, 12, 49)
        case 21: return gc(L, 13, 22)
        case 22: return gc(L, 14, 1)
        case 23: return gc(L, 14, 25)
        case 24: return gc(L, 15, 1)
        case 25: return gc(L, 16, 1)
        case 26: return gc(L, 16, 19)
        case 27: return gc(L, 17, 5)
        case 28: return gc(L, 17, 11)
        case 29: return gc(L, 18, 1)
        case 30: return gc(L, 18, 9)
        case 31: return gc(L, 19, 1)
        case 32: return gc(L, 20, 27)
        case 33: return gc(L, 21, 5)
        case 34: return gc(L, 23, 35)
        default: return nil
        }
    }

    private static func ordinaryWeekdayGospel(_ week: Int, _ dow: Int) -> (Bible.Gospel, Int, Int)? {
        let table: [[(Bible.Gospel, Int, Int)]] = [
            [gc(Mk, 1, 14), gc(Mk, 1, 21), gc(Mk, 1, 29), gc(Mk, 1, 40), gc(Mk, 2, 1), gc(Mk, 2, 13)],
            [gc(Mk, 2, 18), gc(Mk, 2, 23), gc(Mk, 3, 1), gc(Mk, 3, 7), gc(Mk, 3, 13), gc(Mk, 3, 20)],
            [gc(Mk, 3, 22), gc(Mk, 3, 31), gc(Mk, 4, 1), gc(Mk, 4, 21), gc(Mk, 4, 26), gc(Mk, 4, 35)],
            [gc(Mk, 4, 35), gc(Mk, 5, 1), gc(Mk, 5, 21), gc(Mk, 5, 21), gc(Mk, 5, 35), gc(Mk, 5, 35)],
            [gc(Mk, 6, 1), gc(Mk, 6, 7), gc(Mk, 6, 14), gc(Mk, 6, 30), gc(Mk, 6, 34), gc(Mk, 7, 1)],
            [gc(Mk, 7, 1), gc(Mk, 7, 14), gc(Mk, 7, 24), gc(Mk, 7, 31), gc(Mk, 8, 1), gc(Mk, 8, 14)],
            [gc(Mk, 8, 22), gc(Mk, 8, 22), gc(Mk, 9, 2), gc(Mk, 9, 14), gc(Mk, 9, 30), gc(Mk, 9, 38)],
            [gc(Mk, 9, 38), gc(Mk, 9, 41), gc(Mk, 10, 1), gc(Mk, 10, 13), gc(Mk, 10, 17), gc(Mk, 10, 28)],
            [gc(Mk, 10, 32), gc(Mk, 10, 35), gc(Mk, 10, 46), gc(Mk, 12, 28), gc(Mk, 12, 35), gc(Mk, 12, 38)],
            [gc(M, 5, 1), gc(M, 5, 13), gc(M, 5, 17), gc(M, 5, 20), gc(M, 5, 27), gc(M, 5, 33)],
            [gc(M, 5, 38), gc(M, 5, 43), gc(M, 6, 1), gc(M, 6, 7), gc(M, 6, 19), gc(M, 6, 24)],
            [gc(M, 7, 1), gc(M, 7, 6), gc(M, 7, 15), gc(M, 7, 21), gc(M, 8, 1), gc(M, 8, 5)],
            [gc(M, 8, 18), gc(M, 8, 23), gc(M, 8, 28), gc(M, 9, 1), gc(M, 9, 9), gc(M, 9, 14)],
            [gc(M, 9, 18), gc(M, 9, 32), gc(M, 10, 1), gc(M, 10, 7), gc(M, 10, 16), gc(M, 10, 24)],
            [gc(M, 10, 34), gc(M, 11, 20), gc(M, 11, 25), gc(M, 11, 28), gc(M, 12, 1), gc(M, 12, 14)],
            [gc(M, 12, 38), gc(M, 12, 46), gc(M, 13, 1), gc(M, 13, 10), gc(M, 13, 18), gc(M, 13, 24)],
            [gc(M, 13, 31), gc(M, 13, 36), gc(M, 13, 44), gc(M, 13, 47), gc(M, 13, 54), gc(M, 14, 1)],
            [gc(M, 14, 13), gc(M, 14, 22), gc(M, 15, 21), gc(M, 16, 13), gc(M, 17, 1), gc(M, 17, 14)],
            [gc(M, 17, 22), gc(M, 18, 1), gc(M, 18, 15), gc(M, 18, 21), gc(M, 18, 21), gc(M, 18, 21)],
            [gc(M, 19, 3), gc(M, 19, 13), gc(M, 19, 23), gc(M, 20, 1), gc(M, 20, 17), gc(M, 20, 24)],
            [gc(M, 23, 1), gc(M, 23, 13), gc(M, 23, 27), gc(M, 24, 37), gc(M, 25, 1), gc(M, 25, 14)],
            [gc(L, 4, 16), gc(L, 4, 31), gc(L, 4, 38), gc(L, 5, 1), gc(L, 5, 33), gc(L, 6, 1)],
            [gc(L, 6, 6), gc(L, 6, 12), gc(L, 6, 20), gc(L, 6, 27), gc(L, 6, 39), gc(L, 6, 43)],
            [gc(L, 7, 1), gc(L, 7, 11), gc(L, 7, 31), gc(L, 7, 36), gc(L, 8, 1), gc(L, 8, 4)],
            [gc(L, 8, 16), gc(L, 8, 19), gc(L, 9, 1), gc(L, 9, 7), gc(L, 9, 18), gc(L, 9, 43)],
            [gc(L, 9, 46), gc(L, 9, 51), gc(L, 9, 57), gc(L, 10, 1), gc(L, 10, 13), gc(L, 10, 17)],
            [gc(L, 10, 25), gc(L, 10, 38), gc(L, 11, 1), gc(L, 11, 5), gc(L, 11, 15), gc(L, 11, 27)],
            [gc(L, 11, 29), gc(L, 11, 37), gc(L, 11, 42), gc(L, 11, 47), gc(L, 12, 1), gc(L, 12, 8)],
            [gc(L, 12, 13), gc(L, 12, 35), gc(L, 12, 39), gc(L, 12, 49), gc(L, 12, 54), gc(L, 13, 1)],
            [gc(L, 13, 10), gc(L, 13, 18), gc(L, 13, 22), gc(L, 13, 31), gc(L, 14, 1), gc(L, 14, 7)],
            [gc(L, 14, 12), gc(L, 14, 15), gc(L, 14, 25), gc(L, 15, 1), gc(L, 16, 1), gc(L, 16, 9)],
            [gc(L, 17, 1), gc(L, 17, 7), gc(L, 17, 11), gc(L, 17, 20), gc(L, 17, 26), gc(L, 18, 1)],
            [gc(L, 18, 35), gc(L, 19, 1), gc(L, 19, 11), gc(L, 19, 41), gc(L, 19, 45), gc(L, 20, 27)],
            [gc(L, 21, 1), gc(L, 21, 5), gc(L, 21, 12), gc(L, 21, 20), gc(L, 21, 29), gc(L, 21, 34)],
        ]
        let wIdx = min(max(week - 1, 0), 33)
        let dIdx = min(max(dow - 1, 0), 5)
        return table[wIdx][dIdx]
    }

    // MARK: - Lent

    private static func lentGospel(_ pos: LiturgicalPosition) -> (Bible.Gospel, Int, Int)? {
        pos.dayOfWeek == sunday
            ? lentSundayGospel(pos.week, pos.sundayCycle)
            : lentWeekdayGospel(pos.week, pos.dayOfWeek)
    }

    private static func lentSundayGospel(_ week: Int, _ cycle: SundayCycle) -> (Bible.Gospel, Int, Int)? {
        switch cycle {
        case .a:
            switch week {
            case 1: return gc(M, 4, 1); case 2: return gc(M, 17, 1); case 3: return gc(J, 4, 5)
            case 4: return gc(J, 9, 1); case 5: return gc(J, 11, 1); case 6: return gc(M, 26, 14)
            default: return nil
            }
        case .b:
            switch week {
            case 1: return gc(Mk, 1, 12); case 2: return gc(Mk, 9, 2); case 3: return gc(J, 2, 13)
            case 4: return gc(J, 3, 14); case 5: return gc(J, 12, 20); case 6: return gc(Mk, 14, 1)
            default: return nil
            }
        case .c:
            switch week {
            case 1: return gc(L, 4, 1); case 2: return gc(L, 9, 28); case 3: return gc(J, 4, 5)
            case 4: return gc(L, 15, 1); case 5: return gc(J, 8, 1); case 6: return gc(L, 22, 14)
            default: return nil
            }
        }
    }

    private static func lentWeekdayGospel(_ week: Int, _ dow: Int) -> (Bible.Gospel, Int, Int)? {
        let table: [[(Bible.Gospel, Int, Int)]] = [
            [gc(M, 25, 31), gc(M, 6, 1), gc(M, 6, 7), gc(L, 11, 1), gc(M, 7, 7), gc(M, 5, 43)],
            [gc(L, 6, 36), gc(M, 23, 1), gc(L, 13, 22), gc(M, 20, 17), gc(L, 15, 1), gc(L, 15, 11)],
            [gc(L, 4, 24), gc(M, 5, 17), gc(L, 11, 29), gc(J, 4, 43), gc(Mk, 12, 28), gc(L, 18, 9)],
            [gc(J, 4, 43), gc(J, 5, 1), gc(J, 5, 17), gc(J, 5, 31), gc(J, 7, 1), gc(J, 7, 40)],
            [gc(J, 8, 1), gc(J, 8, 21), gc(J, 8, 31), gc(J, 8, 51), gc(J, 10, 31), gc(J, 11, 45)],
            [gc(J, 12, 1), gc(J, 13, 21), gc(M, 26, 14), gc(J, 13, 1), gc(J, 18, 1), gc(L, 23, 50)],
        ]
        let wIdx = min(max(week - 1, 0), 5)
        let dIdx = min(max(dow - 1, 0), 5)
        return table[wIdx][dIdx]
    }

    // MARK: - Easter

    private static func easterGospel(_ pos: LiturgicalPosition) -> (Bible.Gospel, Int, Int)? {
        pos.dayOfWeek == sunday
            ? easterSundayGospel(pos.week, pos.sundayCycle)
            : easterWeekdayGospel(pos.week, pos.dayOfWeek)
    }

    private static func easterSundayGospel(_ week: Int, _ cycle: SundayCycle) -> (Bible.Gospel, Int, Int)? {
        switch week {
        case 1: return gc(J, 20, 1)
        case 2: return gc(J, 20, 19)
        case 3:
            switch cycle {
            case .a: return gc(L, 24, 13)
            case .b: return gc(L, 24, 35)
            case .c: return gc(J, 21, 1)
            }
        case 4:
            switch cycle {
            case .a: return gc(J, 10, 1)
            case .b: return gc(J, 10, 11)
            case .c: return gc(J, 10, 27)
            }
        case 5:
            switch cycle {
            case .a: return gc(J, 14, 1)
            case .b: return gc(J, 15, 1)
            case .c: return gc(J, 13, 31)
            }
        case 6:
            switch cycle {
            case .a: return gc(J, 14, 15)
            case .b: return gc(J, 15, 9)
            case .c: return gc(J, 14, 23)
            }
        case 7:
            switch cycle {
            case .a: return gc(J, 17, 1)
            case .b: return gc(J, 17, 11)
            case .c: return gc(J, 17, 20)
            }
        default: return nil
        }
    }

    private static func easterWeekdayGospel(_ week: Int, _ dow: Int) -> (Bible.Gospel, Int, Int)? {
        let table: [[(Bible.Gospel, Int, Int)]] = [
            [gc(M, 28, 8), gc(J, 20, 11), gc(L, 24, 13), gc(L, 24, 35), gc(J, 21, 1), gc(J, 21, 1)],
            [gc(J, 3, 1), gc(J, 3, 7), gc(J, 3, 16), gc(J, 3, 31), gc(J, 6, 1), gc(J, 6, 16)],
            [gc(J, 6, 22), gc(J, 6, 30), gc(J, 6, 35), gc(J, 6, 44), gc(J, 6, 52), gc(J, 6, 60)],
            [gc(J, 10, 1), gc(J, 10, 22), gc(J, 12, 44), gc(J, 13, 16), gc(J, 14, 1), gc(J, 14, 7)],
            [gc(J, 14, 21), gc(J, 14, 27), gc(J, 15, 1), gc(J, 15, 9), gc(J, 15, 12), gc(J, 15, 18)],
            [gc(J, 15, 26), gc(J, 16, 5), gc(J, 16, 12), gc(J, 16, 16), gc(J, 16, 20), gc(J, 16, 23)],
            [gc(J, 16, 29), gc(J, 17, 1), gc(J, 17, 11), gc(J, 17, 20), gc(J, 21, 15), gc(J, 21, 20)],
        ]
        let wIdx = min(max(week - 1, 0), 6)
        let dIdx = min(max(dow - 1, 0), 5)
        return table[wIdx][dIdx]
    }
}
