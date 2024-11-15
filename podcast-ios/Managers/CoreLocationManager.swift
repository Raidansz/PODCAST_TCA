//
//  CoreLocationManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 07..
//

import CoreLocation
import AppServices

final class LocationCountryDetector: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((Country?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func detectCountry(completion: @escaping (Country?) -> Void) {
        // Prevent calling detectCountry multiple times without completing the previous request
        guard self.completion == nil else {
            print("Location detection already in progress")
            return
        }
        
        self.completion = completion
        locationManager.requestLocation()  // Request a single location update
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            completeWithCountry(nil)
            return
        }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let countryCode = placemarks?.first?.isoCountryCode,
               let country = Country.fromCountryCode(countryCode.lowercased()) {
                print("Detected country: \(country)")
                self.completeWithCountry(country)
            } else {
                print("Could not retrieve country from location")
                self.completeWithCountry(nil)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location detection failed with error: \(error.localizedDescription)")
        completeWithCountry(nil)
    }

    private func completeWithCountry(_ country: Country?) {
        // Call completion if set, then nil it out to prevent multiple calls
        completion?(country)
        completion = nil
    }
}
