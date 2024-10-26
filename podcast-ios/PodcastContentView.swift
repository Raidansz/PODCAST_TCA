//
//  PodcastContentView.swift
//  podcast-ios
//
//  Created by Raidan on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct RootModule: App {
    var body: some Scene {
        WindowGroup {
            SharedStateFileStorageView(
                store: Store(initialState: SharedStateFileStorage.State()) {
                  SharedStateFileStorage()
                })
//            TabView {
//                HomeView(store: Store(initialState: HomeFeature.State()) {
//                    HomeFeature()
//                })
//                .tabItem {
//                    Label("Home", systemImage: "house")
//                }
//
//                ExloreView(store: Store(initialState: ExploreFeature.State()) {
//                    ExploreFeature()
//                })
//                .tabItem {
//                    Label("Explore", systemImage: "magnifyingglass")
//                }
//            }
        }
    }
}
//
