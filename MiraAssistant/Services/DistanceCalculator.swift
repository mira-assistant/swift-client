import Foundation
import CoreLocation

class DistanceCalculator: NSObject, ObservableObject {
    @Published var currentDistance: Double = 0.0
    @Published var isCalculating = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var targetLocation: CLLocation?
    private let networkManager = NetworkManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every meter
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            errorMessage = "Unknown location authorization status"
        }
    }
    
    func setTargetLocation(latitude: Double, longitude: Double) {
        targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services not enabled"
            return
        }
        
        isCalculating = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        isCalculating = false
        locationManager.stopUpdatingLocation()
    }
    
    private func calculateDistance(from currentLocation: CLLocation) {
        guard let target = targetLocation else {
            errorMessage = "Target location not set"
            return
        }
        
        let distance = currentLocation.distance(from: target)
        
        DispatchQueue.main.async {
            self.currentDistance = distance
        }
        
        // Report distance to backend
        Task {
            await networkManager.reportDistance(distance, from: currentLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DistanceCalculator: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        calculateDistance(from: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location error: \(error.localizedDescription)"
            self.isCalculating = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if targetLocation != nil {
                startLocationUpdates()
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied"
                self.isCalculating = false
            }
        case .notDetermined:
            break
        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = "Unknown authorization status"
                self.isCalculating = false
            }
        }
    }
}