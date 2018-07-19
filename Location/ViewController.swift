//
//  ViewController.swift
//  Prints on the screen a list of obtained locations.
//
//  Created by Samuel Kobelkowsky on 7/18/18.
//  Copyright © 2018 Samuel Kobelkowsky. All rights reserved.
//

import UIKit
import CoreLocation
import os.log
import MapKit

// The main goal of this app is to show for each location point the horizontal accuracy and speed obtained.
// I wanted to know how these two values behave.
// A file with sample locations (Dinamos.gpx) has been included so you can simulate a walk in the park in XCode menu:
// Product > Scheme > Edit Scheme... > Run > Options > Default Location > Dinamos
class ViewController: UIViewController {
    
    // Labels for information on screen
    @IBOutlet weak var avgHorizontalAccuracy: UILabel!
    @IBOutlet weak var avgSpeed: UILabel!
    @IBOutlet weak var pctgHasHorizontalAccuracy: UILabel!
    @IBOutlet weak var pctgHasSpeed: UILabel!
    @IBOutlet weak var avgDelay: UILabel!
    
    // The list of locations obtained
    @IBOutlet weak var stackView: UIStackView!
    
    // The user has the ability to change the accuracy of the location pints
    @IBOutlet weak var accuracyButton: UISwitch!
    
    // Where the points obtained will be drawn
    @IBOutlet weak var map: MKMapView!
    
    // The location manager (imported in CoreLocation)
    var locationManager = CLLocationManager()

    // The number of obtained locations.
    var i = 0
    
    // These variables are used for statistics about the horizontal speed and accuracy
    var totalValidSpeedSamples = 0.0
    var totalInvalidSpeedSamples = 0.0
    var totalValidHorizontalAccuracySamples = 0.0
    var totalInvalidHorizontalAccuracySamples = 0.0
    var sumOfValidSpeedSamples = 0.0
    var sumOfValidHorizontalAccuracySamples = 0.0
    var sumOfDelays = 0.0

    // For mapping, these are the bound of the "region" where the map will be displayed. Default values provided in order to avoid ugly results.
    var minLatitude = 90.0
    var maxLatitude = -90.0
    var minLongitude = 180.0
    var maxLongitude = -180.0
    
    // Initialize the app
    override func viewDidLoad() {
        
        // We need to request both authorization requests.
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        // The delegate where the location events are processed.
        locationManager.delegate = self

        // Check that location services are enabled. The user can disable/enable them in the iOS Settings > Privacy > Location
        if CLLocationManager.locationServicesEnabled() {
            // Configure and start the updates
            startLocationUpdates()
        }
         // If we cannot use location services, show an error
        else {
            Alert.show(self, title: "Error", message: "Can't obtain your location")
        }
    }

    // Configure and start the location udpates
    func startLocationUpdates() {
        
        // Trigger a notification if the user position changes at least the amount given below (in meters)
        locationManager.distanceFilter = 5
        
        // Keep sending location updates even if the phone is blocked.  Need to add the following line in Info.plist:
        // <key>UIBackgroundModes</key><array><string>location</string></array>
        locationManager.allowsBackgroundLocationUpdates = true
        
        // Set the desired accuracy to "Best" or "Best for Navigation", the later using at least 30% more battery.
        locationManager.desiredAccuracy = accuracyButton.isOn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        
        // If we have enough authorization, start location updates
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        // If we don't have enough authorization, show an error message
        else {
            Alert.show(self, title: "Error", message: "Not authorized for location updates")
        }
    }
    
    // What to do when we got a location udpate.  This function is called by the delegate (see below)
    func gotNewLocation(_ location: CLLocation) {
        
        // Increase the counter of received points
        i += 1

        // For nice display of the location update timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let locationTimestamp = formatter.string(from: location.timestamp)
        
        // Add the location update description to the list shown in the screen (in a StackView).
        let label = UILabel(frame: CGRect())
        label.sizeToFit()
        label.text = String(format: "%2d  %@  %.1f  %.1f", i, locationTimestamp, location.speed, location.horizontalAccuracy)
        label.font = UIFont(name: "Courier New", size: 14.0)
        stackView.addArrangedSubview(label)
        
        /////////// Update the statistics in the screen ///////////
        
        // For calculation of the ratio of valid/invalid horizontal speed in meters per second (value is less than 0) of samples
        if location.speed < 0 {
            totalInvalidSpeedSamples += 1.0
        }
        else {
            totalValidSpeedSamples += 1.0
            sumOfValidSpeedSamples += location.speed
        }
        
        // For calculation of the ratio of valid/invalid horizontal accuracy in meters (value is less than 0) of samples
        if location.horizontalAccuracy < 0 {
            totalInvalidHorizontalAccuracySamples += 1.0
        }
        else {
            totalValidHorizontalAccuracySamples += 1.0
            sumOfValidHorizontalAccuracySamples += location.horizontalAccuracy
        }
        
        // For calculation of average delay between obtaining the sample and processing (in seconds)
        sumOfDelays += Date().timeIntervalSince(location.timestamp)
        
        // Calculate the averages and percentages and update the statistics in the screen
        avgHorizontalAccuracy.text = String(format: "Avg. H. Accuracy: %.1f", sumOfValidHorizontalAccuracySamples / totalValidHorizontalAccuracySamples)
        avgSpeed.text  = String(format: "Avg. Speed: %.1f", sumOfValidSpeedSamples / totalValidSpeedSamples)
        pctgHasHorizontalAccuracy.text = String(format: "%% Has H. Accuracy: %.0f", 100.0 * totalValidHorizontalAccuracySamples / Double(i))
        pctgHasSpeed.text = String(format: "%% Has Speed: %.0f", 100.0 * totalValidSpeedSamples / Double(i))
        avgDelay.text = String(format: "Avg. Delay: %.1f", sumOfDelays / Double(i))
        
        /////////// Update the map in the screen ///////////
        
        // Calculate the boundaries of the map. The 2.0 factor is because the map is centered in the last sample, so we "waste" half of the map, but it looks niceer
        // than putting the last sample in one of the corners of the map.
        var deltaLatitude = (maxLatitude - minLatitude) * 2
        var deltaLongitude = (maxLongitude - minLongitude) * 2
        
        // If limit the boundaries to something that looks nice. One degree is many many kilometers and 0.0002 is about 1-2 blocks (depending on the latitude)
        if deltaLatitude >= 1.0 || deltaLatitude < 0.0002 {deltaLatitude = 0.0002}
        if deltaLongitude >= 1.0 || deltaLongitude < 0.002 {deltaLongitude = 0.002}
        print("ΔLatitude: \(deltaLatitude), ΔLongitude: \(deltaLongitude)")
        
        // Define the Region where the map will be shown
        let coordianteSpan = MKCoordinateSpan(latitudeDelta: deltaLatitude, longitudeDelta: deltaLongitude)
        let coordinateRegion = MKCoordinateRegionMake(location.coordinate, coordianteSpan)

        // Next iteration hopefully has better map boundaries
        if location.coordinate.latitude > maxLatitude {maxLatitude = location.coordinate.latitude}
        if location.coordinate.latitude < minLatitude {minLatitude = location.coordinate.latitude}
        if location.coordinate.longitude > maxLongitude {maxLongitude = location.coordinate.longitude}
        if location.coordinate.longitude < minLongitude {minLongitude = location.coordinate.longitude}
        
        // Update the map with the calculated region bound by the max/min latitude/longitude
        map.setRegion(coordinateRegion, animated: true)
       
        // Add a pinpoint with the current location
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        map.addAnnotation(annotation)
    }
    
    // Action for the Switch that allows the user to change the accuracy of the location upates
    @IBAction func accuracyButtonChanged(_ sender: Any) {
        locationManager.desiredAccuracy = accuracyButton.isOn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        if accuracyButton.isOn {
            Toast.show(message: "Changed to high accuracy mode", controller: self)
        }
    }
}

// Delegate for location services
extension ViewController: CLLocationManagerDelegate {

    // Process the location samples received
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            gotNewLocation(location)
        }
    }
    
    // The authorization status of the location services have changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .notDetermined, .restricted:
            Alert.show(self, title: "Error", message: "Can't obtain your location")
            break
        case .authorizedAlways, .authorizedWhenInUse:
            Toast.show(message: "Starting Location Updates", controller: self)
            startLocationUpdates()
            break
        }
    }
}
