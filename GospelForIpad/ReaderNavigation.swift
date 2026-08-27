//
//  ReaderNavigation.swift
//  GospelForIpad
//
//  Manages navigation and search state for the Bible reader
//

import Foundation

@Observable
final class ReaderNavigation {
    var selectedBookID: String?
    var pendingChapter: Int = 0
    var activeHighlight: VerseRef?
    var searchQuery: String = ""

    static let shared = ReaderNavigation()

    func lookUp() {
        // Placeholder for lookup functionality
    }
}
