//
//  XADLocationManager.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/3/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManager {
    func getCurrentLocation() -> CLLocation?
}


class XADLocationManager:NSObject, LocationManager, CLLocationManagerDelegate {
    func getCurrentLocation() -> CLLocation? {
        return mCurrentLocation
    }

    var sysLocationManager:CLLocationManager
    var mCurrentLocation:CLLocation?
    
    override init() {
        self.sysLocationManager = CLLocationManager()
        super.init()
        self.sysLocationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.sysLocationManager.delegate = self
            self.sysLocationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.sysLocationManager.distanceFilter = Constants.kDistantFilter
            self.sysLocationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.count > 0 else {
            return
        }
        
        self.mCurrentLocation = locations[0]
    }
    
    deinit {
        XADLogger.debug(message: "deinit")
        self.sysLocationManager.stopUpdatingLocation()
    }
}
