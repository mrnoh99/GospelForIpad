//
//  Typography.swift
//  GospelForIpad
//
//  Shared Myeongjo (serif) font used across the app.
//
//  iOS/iPadOS does NOT ship a Korean serif system font (e.g. AppleMyungjo is
//  macOS-only), so `Font.custom("AppleMyungjo", …)` silently falls back to the
//  system font. We therefore bundle Nanum Myeongjo (OFL) — registered in
//  Info.plist `UIAppFonts` — and reference it by its PostScript name.
//

import SwiftUI

enum AppFont {
    static let myeongjoRegular = "NanumMyeongjo"      // PostScript name
    static let myeongjoBold = "NanumMyeongjoBold"     // PostScript name
}

extension Font {
    /// Myeongjo serif font (Korean), scaling with Dynamic Type.
    static func myeongjo(_ size: CGFloat, relativeTo style: Font.TextStyle = .body, bold: Bool = false) -> Font {
        .custom(bold ? AppFont.myeongjoBold : AppFont.myeongjoRegular, size: size, relativeTo: style)
    }
}
