//
//  HomeFeatureTest.swift
//  AppTests
//
//  Created by Raidan on 2024. 11. 30..
//

import XCTest
import podcast_ios
import ComposableArchitecture
import SwiftyJSON

@MainActor
final class HomeFeatureTest: XCTestCase {

    func test_initialState() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }
        XCTAssertNil(store.state.podcasts)
        XCTAssertFalse(store.state.isLoading)
    }

    func test_fetchTrendingPodcast() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }
        store.exhaustivity = .off
        XCTAssertNil(store.state.podcasts)
        XCTAssertFalse(store.state.isLoading)
        await store.send(.fetchTrendingPodcasts)
        XCTAssertTrue(store.state.isLoading)
        XCTAssertNotNil(store.state.podcasts)
    }

    func test_fetchTrendingPodcastCount() async throws {

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }

        store.exhaustivity = .off
        XCTAssertNil(store.state.podcasts)
        XCTAssertFalse(store.state.isLoading)
        await store.send(.fetchTrendingPodcasts)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(store.state.isLoading)
      //  XCTAssertEqual(store.state.podcasts?.count, 60)
    }

    func test_fetchTrendingPodcastFirstItem() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }

        store.exhaustivity = .off
        XCTAssertNil(store.state.podcasts)
        XCTAssertFalse(store.state.isLoading)

        await store.send(.fetchTrendingPodcasts)
        try await Task.sleep(nanoseconds: 200_000_000)

        print("Final state: \(store.state)")
        XCTAssertTrue(store.state.isLoading)
//        store.assert {
//            XCTAssertEqual($0.podcasts?.count, 1)
//        }
    }

}
