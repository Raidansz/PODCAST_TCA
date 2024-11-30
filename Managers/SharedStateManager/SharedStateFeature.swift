//
//  SharedStateFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 01..
//
import ComposableArchitecture
import AVFoundation
import Kingfisher
import ItunesPodcastManager

//struct SharedStateManager: Sendable {
//    public var episodes: IdentifiedArrayOf<Episode>? = []
//    public var podcasts: IdentifiedArrayOf<Podcast>? = []
//    public var topCategorizedPodcasts: [PodcastGenre: IdentifiedArrayOf<Podcast>?]?
//
//    public mutating func setEpisode(episode: [Episode]?) {
//        self.episodes = IdentifiedArrayOf(uniqueElements: episode ?? [])
//    }
//
//    public func getPodcastList() -> IdentifiedArrayOf<Podcast>? {
//        return podcasts
//    }
//
//    public mutating  func setPodcasts(podcasts: [Podcast]?, category: PodcastGenre? = nil) {
//        guard let category else {
//            self.podcasts = IdentifiedArrayOf(uniqueElements: podcasts ?? [])
//            return
//        }
//
//        if topCategorizedPodcasts == nil {
//            topCategorizedPodcasts = [:]
//        }
//
//        if let podcasts = podcasts, let firstPodcast = podcasts.first {
//            topCategorizedPodcasts?[category] = IdentifiedArrayOf(uniqueElements: podcasts)
//        }
//    }
//}
//
//extension PersistenceReaderKey where Self == InMemoryKey<SharedStateManager> {
//    static var sharedStateManager: Self {
//        inMemory("SharedStateManager")
//    }
//}

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
    PODLogInfo("URL cache cleared")

    // Clear temporary files
    let tempDirectory = FileManager.default.temporaryDirectory
    do {
        let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        for file in tempFiles {
            try FileManager.default.removeItem(at: file)
        }
        PODLogInfo("Temporary files cleared")
    } catch {
        PODLogError("Error clearing temporary files: \(error.localizedDescription)")
    }

    // Clear files in Documents directory
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    do {
        let documentFiles = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        for file in documentFiles {
            try FileManager.default.removeItem(at: file)
        }
        PODLogInfo("Documents directory cleared")
    } catch {
        PODLogError("Error clearing documents directory: \(error.localizedDescription)")
    }

    // Clear AVPlayer download tasks using a background session
    //THIS MIGHT BE USELESS
    let backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.podcast-ios.downloadSession")
    let downloadSession = AVAssetDownloadURLSession(
        configuration: backgroundConfig,
        assetDownloadDelegate: nil,
        delegateQueue: .main
    )

    downloadSession.getAllTasks { tasks in
        for task in tasks {
            task.cancel()
        }
        PODLogInfo("AVPlayer download tasks cleared")
    }

    // clear image cache
    KingfisherManager.shared.cache.clearCache()

//    @Shared(.sharedStateManager) var sharedStateManager = SharedStateManager()
//    sharedStateManager = SharedStateManager()
    return true
}
