//
//  HomeFeatureTest.swift
//  AppTests
//
//  Created by Raidan on 2024. 11. 30..
//

import ComposableArchitecture
import Foundation
import Testing

@testable import podcast_ios

@MainActor
struct HomeFeatureTest {
@Test
    func test_initialState() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }
        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
    }
    @Test
    func test_fetchTrendingPodcastFlow() async throws {
        let state = HomeFeature.State()
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }
        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
        await store.send(\.loadView)
        await store.receive(\.fetchTrendingPodcasts)
        #expect(store.state.isLoading == true)
        await store.receive(\.trendingPodcastResponse)
        #expect(store.state.podcasts != nil)
        #expect(store.state.isLoading == false)
    }

    @Test
    func test_fetchTrendingPodcastCount() async throws {

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }

        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
        await store.send(\.loadView)
        await store.receive(\.fetchTrendingPodcasts)
        #expect(store.state.isLoading == true)
        await store.receive(\.trendingPodcastResponse)
        #expect(store.state.podcasts != nil)
        #expect(store.state.isLoading == false)
        #expect(store.state.podcasts?.count == 60)
    }

    @Test
    func test_fetchTrendingPodcastFirstItem() async throws {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }

        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
        await store.send(\.loadView)
        await store.receive(\.fetchTrendingPodcasts)
        #expect(store.state.isLoading == true)
        await store.receive(\.trendingPodcastResponse)
        #expect(store.state.podcasts != nil)
        #expect(store.state.isLoading == false)
        #expect(store.state.podcasts?.count == 60)
        #expect(store.state.podcasts?.first?.title == "Comic Geek Speak Podcast - The Best Comic Book Podcast")
    }

}
