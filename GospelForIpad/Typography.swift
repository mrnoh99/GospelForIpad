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

    var opposite: FontChoice { self == .myeongjo ? .gothic : .myeongjo }
}

enum EnglishFontChoice: String, CaseIterable, Identifiable {
    case georgia
    case sanfrancisco

    var id: String { rawValue }

    var label: String {
        switch self {
        case .georgia: return "Georgia"
        case .sanfrancisco: return "San Francisco"
        }
    }

    var shortLabel: String {
        switch self {
        case .georgia: return "G"
        case .sanfrancisco: return "SF"
        }
    }
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

/// App-wide English font selection, persisted in UserDefaults and observable by views.
final class EnglishFontSettings: ObservableObject {
    static let shared = EnglishFontSettings()

    private let key = "appEnglishFontChoice"

    @Published var choice: EnglishFontChoice {
        didSet { UserDefaults.standard.set(choice.rawValue, forKey: key) }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        choice = EnglishFontChoice(rawValue: raw) ?? .georgia
    }
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

    /// English font independently selectable.
    static func appEnglish(_ size: CGFloat, relativeTo style: Font.TextStyle = .body, bold: Bool = false) -> Font {
        switch EnglishFontSettings.shared.choice {
        case .georgia:
            return .custom(bold ? "Georgia-Bold" : "Georgia", size: size, relativeTo: style)
        case .sanfrancisco:
            return .system(size: size, weight: bold ? .bold : .regular)
        }
    }
}
