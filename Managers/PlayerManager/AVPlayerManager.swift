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

final class AVPlayerManager: NSObject, @unchecked Sendable {
    let player: AVPlayer

    // MARK: - Initializer
    init(player: AVPlayer) {
        self.player = player
    }
    deinit {
        PODLogInfo("AVPlayerManager was deinited")
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
}
