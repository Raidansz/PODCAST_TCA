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
            TabBarView(store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
                    ._printChanges()
            }, exploreStore: Store(initialState: ExploreFeature.State()) {
                ExploreFeature()
                    ._printChanges()
            })
        }
    }
}

struct TabBarView: View {
    let store: StoreOf<HomeFeature>
    let exploreStore: StoreOf<ExploreFeature>

    var body: some View {
        TabView {
            HomeView(store: store)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ExloreView(store: exploreStore)
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }

            HomeView(store: store)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
