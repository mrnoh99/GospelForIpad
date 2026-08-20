//
//  Typography.swift
//  GospelForIpad
//
//  User-selectable app font (Myeongjo serif vs system Gothic).
//
//  iOS/iPadOS has no Korean serif system font, so the Myeongjo option uses the
//  bundled Nanum Myeongjo (registered in Info.plist `UIAppFonts`). The Gothic
//  option uses the system font (Apple SD Gothic Neo on Korean devices).
//
//  English fonts: Myeongjo uses Georgia (serif), Gothic uses San Francisco (sans-serif).
//

import SwiftUI
import Combine

enum FontChoice: String, CaseIterable, Identifiable {
    case myeongjo
    case gothic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .myeongjo: return "명조체"
        case .gothic:   return "고딕체"
        }
    }

    /// Compact label for the toggle button.
    var shortLabel: String {
        switch self {
        case .myeongjo: return "명조"
        case .gothic:   return "고딕"
        }
    }

    var toggled: FontChoice { self == .myeongjo ? .gothic : .myeongjo }
}

/// App-wide font selection, persisted in UserDefaults and observable by views.
final class FontSettings: ObservableObject {
    static let shared = FontSettings()

    private let key = "appFontChoice"

    @Published var choice: FontChoice {
        didSet { UserDefaults.standard.set(choice.rawValue, forKey: key) }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        choice = FontChoice(rawValue: raw) ?? .myeongjo
    }

    func toggle() { choice = choice.toggled }
}

extension Font {
    /// The app's selectable text font, scaling with Dynamic Type.
    static func app(_ size: CGFloat, relativeTo style: Font.TextStyle = .body, bold: Bool = false) -> Font {
        switch FontSettings.shared.choice {
        case .myeongjo:
            return .custom(bold ? "NanumMyeongjoBold" : "NanumMyeongjo", size: size, relativeTo: style)
        case .gothic:
            return .system(size: size, weight: bold ? .bold : .regular)
        }
    }

    /// English font coordinated with Korean font selection.
    /// Myeongjo uses Georgia serif; Gothic uses San Francisco sans-serif.
    static func appEnglish(_ size: CGFloat, relativeTo style: Font.TextStyle = .body, bold: Bool = false) -> Font {
        switch FontSettings.shared.choice {
        case .myeongjo:
            return .custom(bold ? "Georgia-Bold" : "Georgia", size: size, relativeTo: style)
        case .gothic:
            return .system(size: size, weight: bold ? .bold : .regular)
        }
    }
}
