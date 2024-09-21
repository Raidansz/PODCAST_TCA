//
//  PodcastContentView.swift
//  podcast-ios
//
//  Created by Raidan on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct PodcastContentView: App {
    var body: some Scene {
        WindowGroup {
            HomeView(store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
            }
            )
        }
    }
}
