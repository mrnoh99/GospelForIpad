//
//  SectionHeadings.swift
//  GospelForIpad
//
//  Positioned pericope section headings (소제목) for the four Gospels.
//
//  Every translation shown in the reader (성경 / 200주년 / 공동번역 / NAB) previously
//  differed in how it presented section titles: the 주석성경(공동번역) text carried an
//  inline "[제목;상호참조]" marker at each pericope-start verse, while 성경(CCK) only had
//  a single condensed per-chapter summary in the header. This type exposes a single,
//  well-positioned set of headings — derived from the 주석성경 pericope boundaries with
//  the cross-references stripped — so that the reader can render clean heading rows at
//  the correct verse for *every* translation.
//
//  Data source: SectionHeadings.json (generated from GospelTextKCB.json markers).
//

import Foundation

enum SectionHeadings {
    /// gospel → chapter → verse → title
    private static let data: [String: [String: [String: String]]] = load()

    private static func load() -> [String: [String: [String: String]]] {
        guard
            let url = Bundle.main.url(forResource: "SectionHeadings", withExtension: "json"),
            let raw = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: raw)
        else { return [:] }
        return decoded
    }

    private static func key(for gospel: Bible.Gospel) -> String {
        switch gospel {
        case .matthew: return "matthew"
        case .mark:    return "mark"
        case .luke:    return "luke"
        case .john:    return "john"
        }
    }

    /// Section heading that begins at the given 1-based verse, or nil when none.
    static func title(gospel: Bible.Gospel, chapter: Int, verse: Int) -> String? {
        data[key(for: gospel)]?[String(chapter)]?[String(verse)]
    }

    /// All (verse, title) headings for a chapter, ascending by verse.
    static func headings(gospel: Bible.Gospel, chapter: Int) -> [(verse: Int, title: String)] {
        guard let chapterDict = data[key(for: gospel)]?[String(chapter)] else { return [] }
        return chapterDict
            .compactMap { rawKey, title in Int(rawKey).map { (verse: $0, title: title) } }
            .sorted { $0.verse < $1.verse }
    }
}
