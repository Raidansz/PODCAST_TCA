//
//  AudioPlayerManagerModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 06..
//

import Foundation

enum PlaybackState: Int, Equatable {
    case waitingForSelection
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
}

protocol PlayableItemProtocol: Sendable, Identifiable, Equatable {
    var title: String { get }
    var author: String { get }
    var imageUrl: URL? { get }
    var streamURL: URL? { get }
    var id: String { get }
}
