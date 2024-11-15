//
//  AppDelegate.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 31..
//

import UIKit
import AppLogger
import Kingfisher

class AppDelegate: NSObject, UIApplicationDelegate {
    private let locationCountryDetector = LocationCountryDetector()

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

        locationCountryDetector.detectCountry { country in
            if let country = country {
                print("Detected country: \(country)")
                UserDefaults.standard.set(country.rawValue, forKey: "DetectedCountry")
            } else {
                print("Could not detect the country.")
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PODLogInfo("Registered for notifications with device token: \(deviceToken)")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        clearAllAppCache()
        PODLogWarn("applicationDidReceiveMemoryWarning")
        PODLogInfo("Kignfisher cache was cleared")
    }
}
