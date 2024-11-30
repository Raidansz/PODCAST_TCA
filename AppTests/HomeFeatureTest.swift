//
//  HomeFeatureTest.swift
//  AppTests
//
//  Created by Raidan on 2024. 11. 30..
//

import XCTest
import podcast_ios
import ComposableArchitecture

@MainActor
final class HomeFeatureTest: XCTestCase {
    func test_fetchTrendingPodcast() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock(initialData: "test")
        }
        store.exhaustivity = .off
        XCTAssertNil(store.state.podcasts)
        XCTAssertFalse(store.state.isLoading)
        await store.send(.fetchTrendingPodcasts)
        XCTAssertTrue(store.state.isLoading)
        XCTAssertNotEqual(store.state.podcasts?.count, 1 )
    }
}
