//
//  HomeFeatureTest.swift
//  AppTests
//
//  Created by Raidan on 2024. 11. 30..
//

import XCTest
@testable import podcast_ios
import ComposableArchitecture

@MainActor
final class HomeFeatureTest: XCTestCase {
    func test_fetchTrendingPodcast() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }
        XCTAssertNil(store.state.sharedStateManager.podcasts)
        XCTAssertFalse(store.state.isLoading)
        await store.send(.fetchTrendingPodcasts)
        XCTAssertTrue(store.state.isLoading)
    }
    
}
