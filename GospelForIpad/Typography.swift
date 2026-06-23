//
//  Typography.swift
//  GospelForIpad
//
//  Shared Myeongjo (serif) font used across the app.
//

import SwiftUI

extension Font {
    /// Myeongjo serif font (Korean), scaling with Dynamic Type.
    static func myeongjo(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("AppleMyungjo", size: size, relativeTo: style)
    }
}
