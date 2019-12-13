//
//  LocationManager.swift
//
//  Created by LIBEXTMAC on 12/01/19.
//  Copyright © 2019 Absin. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: Int {
	case reverseGeocoderFailure = 10
	
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
	let manager = CLLocationManager()
	
	let errorDomain = "weather.LocationManager"
	
	var onLocationFix: ((APIResult<Location>) -> Void)?
	
	override init() {
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		manager.requestLocation()
	}
	
	func getPermission() {
		if CLLocationManager.authorizationStatus() == .notDetermined {
			manager.requestWhenInUseAuthorization()
		}
	}
	
	func updateLocation() {
		manager.requestLocation()
	}
	
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			manager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		if let onLocationFix = onLocationFix {
			onLocationFix(.failure(error))
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		guard let currLocation = locations.first else { return }
		
		if let onLocationFix = onLocationFix {
			CLGeocoder().reverseGeocodeLocation(currLocation) { (placemarks, error) in
				
				
				if error != nil {
					onLocationFix(.failure(error!))
				} else {
					guard let placemark = placemarks?.first, let city = placemark.locality, let state = placemark.administrativeArea else {
						let error = createError(domain: self.errorDomain, code: LocationError.reverseGeocoderFailure.rawValue, message: "Failed to determine the name")
						onLocationFix(.failure(error))
						return
					}
					
					onLocationFix(.success(Location(coordinates: Coordinate(currLocation.coordinate), city: city, state: state)))
				}
			}
			
		}
	}
}
