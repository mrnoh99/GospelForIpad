//
//  DictionaryRequest.swift
//  GospelForIpad
//
//  Represents a dictionary lookup request
//

import Foundation

struct DictionaryRequest: Identifiable {
    let id = UUID()
    let timestamp = Date()

    init() {}
}
