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
        print("App has launched")
        let cache = ImageCache.default

        // Constrain Memory Cache to 30 MB
        cache.memoryStorage.config.totalCostLimit = 1024 * 1024 * 30

        // Constrain Disk Cache to 100 MB
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for notifications with device token: \(deviceToken)")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        KingfisherManager.shared.cache.clearCache()
    }
}
