//
//  Edition.swift
//  GospelForIpad
//
//  Bible edition/translation definitions
//

import Foundation

struct Edition: Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String

    init(id: String, name: String, shortName: String = "") {
        self.id = id
        self.name = name
        self.shortName = shortName.isEmpty ? name : shortName
    }
}

struct Editions {
    static let knbNotes = Edition(id: "knbnotes", name: "주석 성경", shortName: "주석")
    static let knb = Edition(id: "knb", name: "가톨릭 성경", shortName: "가톨릭")

    static let all: [Edition] = [knbNotes, knb]

    static func edition(_ id: String) -> Edition? {
        all.first { $0.id == id }
    }
}
