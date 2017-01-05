//
//  LocationService.swift
//
//
//  Created by Anak Mirasing on 5/18/2558 BE.
//
// https://github.com/igroomgrim/CLLocationManager-Singleton-in-Swift

import Foundation
import CoreLocation

class FusumaLocationService: NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance: FusumaLocationService = {
        let instance = FusumaLocationService()
        return instance
    }()
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        requestPermissions()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // The accuracy of the location data
        locationManager.distanceFilter = 15 // The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
        locationManager.delegate = self
    }
    
    func startUpdatingLocation() {
        print("Starting Location Updates")
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("Stop Location Updates")
        self.locationManager?.stopUpdatingLocation()
    }
    
    func requestPermissions() {
        print("Requesting Permissions")
        self.locationManager?.requestWhenInUseAuthorization()
    }
    
    func updateSingleLocation(){
        if #available(iOS 9.0, *) {
            self.locationManager?.requestLocation()
        } else {
            //you need to call startUpdatingLocation/stopUpdatingLocation manually
        }
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        // singleton for get last(current) location
        self.currentLocation = location
  
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }

}
