//
//  AVPlayerManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 06..
//

import AVFoundation
import UIKit
import MediaPlayer
import Combine
import Kingfisher

final class AVPlayerManager: @unchecked Sendable {
    let player: AVPlayer

    // MARK: - Initializer
    init(player: AVPlayer) {
        self.player = player
    }

    func play(playerItem: AVPlayerItem) {
        player.replaceCurrentItem(with: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    func seekBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    func seekForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    func seek(to time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: targetTime)
    }
}

import AVFoundation

class AudioStreamingManager: NSObject, AVAssetDownloadDelegate {
    
    var player: AVPlayer
    var downloadSession: AVAssetDownloadURLSession?
    var downloadTask: AVAssetDownloadTask?
    let downloadLocation = FileManager.default.temporaryDirectory.appendingPathComponent("DownloadedAudio")
    
    init(player: AVPlayer) {
        self.player = player
        super.init()
        configureDownloadSession()
    }
    
    // Step 1: Configure Download Session
    func configureDownloadSession() {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.AudioDownloadSession")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                    assetDownloadDelegate: self,
                                                    delegateQueue: OperationQueue.main)
    }
    
    // Step 2: Start Download and Playback
    func startDownloadingAndPlaying(from url: URL) {
        let asset = AVURLAsset(url: url)
        downloadTask = downloadSession?.makeAssetDownloadTask(asset: asset,
                                                              assetTitle: "MyAudioFile",
                                                              assetArtworkData: nil,
                                                              options: nil)
        downloadTask?.resume()
    }
    
    // Step 3: AVAssetDownloadDelegate Methods
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        // Move the downloaded file to your defined location if necessary
        do {
            try FileManager.default.moveItem(at: location, to: downloadLocation)
            print("Downloaded file moved to: \(downloadLocation.path)")
            startPlayingFromFile(url: downloadLocation)
        } catch {
            print("Error moving downloaded file: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didLoad timedMetadataGroups: [AVTimedMetadataGroup], timeRange: CMTimeRange) {
        // Track progress if desired
        print("Downloaded \(timeRange.duration.seconds) seconds of audio")
    }
    
    // Step 4: Start Playback
    func startPlayingFromFile(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player.play()
        
        // Optional: Monitor playback progress
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            let currentTime = CMTimeGetSeconds(time)
            print("Current playback time: \(currentTime)")
        }
    }
    
    // Step 5: Cache Management
    func deleteCachedAudio() {
        do {
            try FileManager.default.removeItem(at: downloadLocation)
            print("Cached audio deleted.")
        } catch {
            print("Error deleting cached audio: \(error)")
        }
    }
}
