//
//  ShowMorePodcastView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 12..
//

import SwiftUI
import ComposableArchitecture
import AVFAudio
import AVFoundation

@Reducer
struct DownloadsFeature {
    @ObservableState
    struct State {
        var episodes: IdentifiedArrayOf<Episode> = .init()
    }

    enum Action {
        case fetchAllDownloadedEpisodes
        case downloadedResponse([Audio])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchAllDownloadedEpisodes:
                return .run { @Sendable send in
                    await send(
                        .downloadedResponse(
                            DownloadManager.shared.fetchDownloadedFiles()
                        )
                    )
                }
            case .downloadedResponse(let result):
                result.forEach { audio in
                    state.episodes.append(Episode(audio: audio))
                }
                return .none
            }
        }
    }
}

struct DownloadsView: View {
    @Bindable var store: StoreOf<DownloadsFeature>
    @State private var audioPlayer: AVPlayer?
    
    var body: some View {
        NavigationStack {
            List(store.episodes) { episode in
                Text(episode.title)
                    .onTapGesture {
                        PODLogInfo("Tapped on episode: \(episode.title)")
                        playAudio(for: episode)
                    }
            }
        }
        .onAppear {
            store.send(.fetchAllDownloadedEpisodes)
        }
    }
    
    private func playAudio(for episode: Episode) {
        // Check if the episode has a valid file path
        guard var filePath = episode.fileUrl else {
            PODLogError("No file path found for episode: \(episode.title)")
            return
        }
        
        // Log the initial file path
        PODLogInfo("Original file path: \(filePath)")
        
        // Append .mp3 extension if missing
        if !filePath.hasSuffix(".mp3") {
            filePath.append(".mp3")
            PODLogInfo("Appended .mp3 extension. Updated file path: \(filePath)")
        }
        
        // Convert the file path to a URL and get its unencoded path for file existence check
        let fileURL = URL(fileURLWithPath: filePath)
        let unencodedPath = fileURL.path.removingPercentEncoding ?? fileURL.path
        PODLogInfo("Converted file path to URL: \(fileURL)")
        PODLogInfo("Unencoded path for existence check: \(unencodedPath)")

        // Check if the file exists at the unencoded path
        if FileManager.default.fileExists(atPath: unencodedPath) {
            PODLogInfo("File exists at path: \(unencodedPath)")
        } else {
            PODLogError("File does not exist at path: \(unencodedPath)")
            return
        }
        
        do {
            // Attempt to initialize AVAudioPlayer with the file URL
            audioPlayer = AVPlayer(url: fileURL)
            audioPlayer?.play()
            PODLogInfo("Successfully initialized and started playing audio for episode: \(episode.title)")
        } catch {
            // Log any errors that occur during AVAudioPlayer initialization or playback
            PODLogError("Failed to initialize AVAudioPlayer or start playback: \(error.localizedDescription)")
        }
    }

}
