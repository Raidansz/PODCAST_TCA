//
//  AppDelegate.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 31..
//

import UIKit
import Kingfisher

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PODLogInfo("AppdidFinishLaunchingWithOptions")
        let cache = ImageCache.default

        // Constrain Memory Cache to 20 MB
        cache.memoryStorage.config.totalCostLimit = 1024 * 1024 * 10
        PODLogInfo("In-memory image cache was set to 10mbs")

        // Constrain Disk Cache to 200 MB
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 30
        PODLogInfo("Disk image cache was set to 30mbs")

        DownloadManager.shared.downloadAudio(item: episode2)
        DownloadManager.shared.printAllDownloadedFiles()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PODLogInfo("Registered for notifications with device token: \(deviceToken)")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        KingfisherManager.shared.cache.clearCache()
        PODLogWarn("applicationDidReceiveMemoryWarning")
        PODLogInfo("Kignfisher cache was cleared")
    }
}





// swiftlint:disable all
//
//  Mock.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import Foundation

final class Episodee: PlayableItemProtocol, Sendable {
    var title: String
    var author: String
    var imageUrl: URL?
    var streamURL: URL?
    var id: String

    init(title: String, author: String, imageUrl: URL? = nil, streamURL: URL, id: String) {
        self.title = title
        self.author = author
        self.imageUrl = imageUrl
        self.streamURL = streamURL
        self.id = id
    }

    static func == (lhs: Episodee, rhs: Episodee) -> Bool {
        lhs.id == rhs.id
    }
}

var episode: Episodee {
    .init(title: "Song", author: "Author", imageUrl: URL(string: "https://picsum.photos/200"), streamURL: URL(string: streamURL1)!, id: "\(UUID())")
}

var episode2: Episodee {
    .init(title: "Song2", author: "Author2", imageUrl: URL(string: "https://picsum.photos/200"), streamURL: URL(string: streamURL2)!, id: "\(UUID())")
}

@MainActor let episodes = [episode, episode2]

public let streamURL1 = "https://op3.dev/e,pg=e85a9a88-0ddf-5f39-9cc8-49d74fd9d96b/https://d12wklypp119aj.cloudfront.net/track/86d38d9a-2f4b-44ae-a77f-a72e034f6d54.mp3"

public let streamURL2 = "https://op3.dev/e,pg=81cfe3db-0b34-52d6-835c-61a3510bea82/https://d12wklypp119aj.cloudfront.net/track/0cada75d-2986-4960-8c0d-b3309367b97b.mp3"
