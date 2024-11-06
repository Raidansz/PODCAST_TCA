//
//  Theme.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 06..
//

import SwiftUICore

enum Theme: String, CaseIterable, Equatable, Hashable, Identifiable, Codable {
    case bubblegum, buttercup, indigo, lavender, magenta, navy, orange, oxblood, periwinkle, poppy, purple, seafoam, sky, tan, teal, yellow
    var id: Self { self }

    var accentColor: Color {
        switch self {
        case .bubblegum, .buttercup, .lavender, .orange, .periwinkle, .poppy, .seafoam, .sky, .tan, .teal, .yellow:
            return .black
        case .indigo, .magenta, .navy, .oxblood, .purple:
            return .white
        }
    }

    var mainColor: Color {
        switch self {
        case .bubblegum: return Color.pink
        case .buttercup: return Color.yellow
        case .indigo: return Color.indigo
        case .lavender: return Color.purple.opacity(0.7)
        case .magenta: return Color.pink.opacity(0.8)
        case .navy: return Color.blue.opacity(0.8)
        case .orange: return Color.orange
        case .oxblood: return Color.red.opacity(0.7)
        case .periwinkle: return Color.blue.opacity(0.6)
        case .poppy: return Color.red
        case .purple: return Color.purple
        case .seafoam: return Color.green.opacity(0.5)
        case .sky: return Color.blue.opacity(0.5)
        case .tan: return Color.brown.opacity(0.5)
        case .teal: return Color.teal
        case .yellow: return Color.yellow
        }
    }

    var name: String { self.rawValue.capitalized }
}

func getRandomTheme() -> Theme {
    return Theme.allCases.randomElement()!
}
