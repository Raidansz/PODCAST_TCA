//
//  RootModule.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import SwiftUI
import ComposableArchitecture
import Combine

@main
struct RootModule: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Shared(.runningItem) var runningItem = RunningItem()

    var body: some Scene {
        WindowGroup {
            RootView {
                TabView {
                    HomeView(store: Store(initialState: HomeFeature.State()) {
                        HomeFeature()
                    })
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ExloreView(store: Store(initialState: ExploreFeature.State()) {
                        ExploreFeature()
                    })
                    .tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }

                    SettingsView(store: Store(initialState: SettingFeature.State()) {
                        SettingFeature()
                    })
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
                }
                .universalOverlay(show: .constant(true)) {

                            PlayerView(store: Store(initialState: PlayerFeature.State()) {
                                PlayerFeature()
                            })

                }
            }
        }
    }
}
