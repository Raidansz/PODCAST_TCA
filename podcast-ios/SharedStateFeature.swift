//
//  SharedStateFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 01..
//
import SwiftUI
import ComposableArchitecture

struct RunningItem: Codable {
    private(set) var episode: Episode?
    private(set) var currentTime: Double = 0
    private(set) var totalTime: Double = 100
    mutating func setEpisode(episode: Episode) {
        if self.episode?.id != episode.id {
            currentTime = 0
            totalTime = 0
            self.episode = episode
        }
    }

    mutating func setCurrentTime(value: Double) {
        self.currentTime = value
    }

    mutating func setTotalTime(value: Double) {
        self.totalTime = value
    }
}

extension PersistenceReaderKey where Self == InMemoryKey<RunningItem> {
    static var runningItem: Self {
        inMemory("RunningItem")
    }
}
