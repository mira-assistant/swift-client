import Foundation
import CoreLocation

class LocationTracker: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var isTracking = false
    @Published var errorMessage: String?
    @Published var connectedClients: [String] = []
    @Published var clientRSSI: [String: Double] = [:]
    
    private let locationManager = CLLocationManager()
    private let networkManager: NetworkManager
    private var rssiUpdateTimer: Timer?
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Update every 5 meters for efficiency
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationTracking()
        @unknown default:
            errorMessage = "Unknown location authorization status"
        }
    }
    
    func startLocationTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services not enabled"
            return
        }
        
        isTracking = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
        
        // Start periodic client discovery and RSSI updates
        startRSSIUpdates()
    }
    
    func stopLocationTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        stopRSSIUpdates()
    }
    
    private func startRSSIUpdates() {
        // Fetch clients and update RSSI every 10 seconds
        rssiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await self.updateClientsAndRSSI()
            }
        }
        
        // Initial fetch
        Task {
            await updateClientsAndRSSI()
        }
    }
    
    private func stopRSSIUpdates() {
        rssiUpdateTimer?.invalidate()
        rssiUpdateTimer = nil
    }
    
    func fetchConnectedClients() async {
        await updateClientsAndRSSI()
    }
    
    private func updateClientsAndRSSI() async {
        await networkManager.fetchConnectedClients()
        
        // Update our published properties with network manager data
        await MainActor.run {
            self.connectedClients = self.networkManager.connectedClients
            self.clientRSSI = self.networkManager.clientRSSI
        }
    }
    
    private func reportCurrentLocation(_ location: CLLocation) {
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        // Report location to backend (no distance calculation needed)
        Task {
            await networkManager.reportLocation(location)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        reportCurrentLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location error: \(error.localizedDescription)"
            self.isTracking = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationTracking()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied"
                self.isTracking = false
            }
        case .notDetermined:
            break
        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = "Unknown authorization status"
                self.isTracking = false
            }
        }
    }
}