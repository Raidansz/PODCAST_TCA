//
//  SharedStateFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 01..
//
import SwiftUI
import ComposableArchitecture
import AVFoundation
import Kingfisher

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

@MainActor func clearAllAppCache() -> Bool {
    // Clear URLCache
    URLCache.shared.removeAllCachedResponses()
    print("URL cache cleared")

    // Clear temporary files
    let tempDirectory = FileManager.default.temporaryDirectory
    do {
        let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        for file in tempFiles {
            try FileManager.default.removeItem(at: file)
        }
        print("Temporary files cleared")
    } catch {
        print("Error clearing temporary files: \(error.localizedDescription)")
    }

    // Clear files in Documents directory
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    do {
        let documentFiles = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        for file in documentFiles {
            try FileManager.default.removeItem(at: file)
        }
        print("Documents directory cleared")
    } catch {
        print("Error clearing documents directory: \(error.localizedDescription)")
    }

    // Clear AVPlayer download tasks using a background session
    let backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.yourApp.downloadSession")
    let downloadSession = AVAssetDownloadURLSession(configuration: backgroundConfig, assetDownloadDelegate: nil, delegateQueue: .main)
    downloadSession.getAllTasks { tasks in
        for task in tasks {
            task.cancel()
        }
        print("AVPlayer download tasks cleared")
    }

    // clear image cache
    KingfisherManager.shared.cache.clearCache()
    // Provide user feedback that cache was cleared
    return true
}
