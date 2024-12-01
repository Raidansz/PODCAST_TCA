//
//  ExploreFeatureTests.swift
//  AppTests
//
//  Created by Raidan on 2024. 12. 01..
//

import ComposableArchitecture
import Foundation
import Testing

@testable import podcast_ios

@MainActor
struct ExploreFeatureTests {
@Test
    func test_initialState() async throws {
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        }
        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
        #expect(store.state.searchTerm == "")
        #expect(store.state.searchPodcastResults == nil)
        #expect(store.state.catagoryList.count == 9)
    }
    @Test
    func test_categoryUserFlow() async throws {
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }
        let firstCategory = store.state.catagoryList.first!
        #expect(firstCategory.id == .arts)
        #expect(store.state.path.isEmpty)
        await store.send(.catagoryTapped(firstCategory))
        #expect(!store.state.path.isEmpty)
    }

    @Test
    func test_searchTermTest() async throws {

        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.podHubClient = .mock()
        }
        #expect(store.state.podcasts == nil)
        #expect(store.state.isLoading == false)
        #expect(store.state.searchTerm == "")
        #expect(store.state.searchPodcastResults == nil)
        #expect(store.state.catagoryList.count == 9)
        let newText = "Hungary"
        await store.send(\.searchTermChanged, newText) {
            $0.searchTerm = newText
        }
        #expect(store.state.searchTerm == "Hungary")
    }
 }
