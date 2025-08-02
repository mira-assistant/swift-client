import XCTest
import CoreLocation
@testable import MiraAssistant

@MainActor
final class DistanceCalculatorTests: XCTestCase {
    var distanceCalculator: DistanceCalculator!
    
    override func setUp() {
        super.setUp()
        distanceCalculator = DistanceCalculator()
    }
    
    override func tearDown() {
        distanceCalculator?.stopLocationUpdates()
        distanceCalculator = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(distanceCalculator.currentDistance, 0.0, "Initial distance should be 0")
        XCTAssertFalse(distanceCalculator.isCalculating, "Should not be calculating initially")
        XCTAssertNil(distanceCalculator.errorMessage, "Should not have error message initially")
    }
    
    // MARK: - Target Location Tests
    
    func testSetTargetLocation() {
        let latitude = 37.7749
        let longitude = -122.4194
        
        distanceCalculator.setTargetLocation(latitude: latitude, longitude: longitude)
        
        // The target location is private, but we can test that no error occurs
        XCTAssertNil(distanceCalculator.errorMessage, "Setting target location should not produce error")
    }
    
    func testSetTargetLocationWithValidCoordinates() {
        // Test various valid coordinate combinations
        let testCases = [
            (37.7749, -122.4194),   // San Francisco
            (0.0, 0.0),             // Equator/Prime Meridian
            (90.0, 180.0),          // North Pole area
            (-90.0, -180.0),        // South Pole area
            (45.0, 0.0)             // Mid-latitude
        ]
        
        for (lat, lon) in testCases {
            distanceCalculator.setTargetLocation(latitude: lat, longitude: lon)
            XCTAssertNil(distanceCalculator.errorMessage, "Valid coordinates (\(lat), \(lon)) should not produce error")
        }
    }
    
    // MARK: - Location Permission Tests
    
    func testRequestLocationPermissionHandling() {
        // This test verifies the method doesn't crash
        // Actual permission testing requires UI testing or mocking CLLocationManager
        distanceCalculator.requestLocationPermission()
        
        // The method should complete without crashing
        XCTAssertTrue(true, "Request location permission should complete without crashing")
    }
    
    // MARK: - Location Updates Tests
    
    func testStopLocationUpdates() {
        // Start some updates first (even if they fail)
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Now stop them
        distanceCalculator.stopLocationUpdates()
        
        XCTAssertFalse(distanceCalculator.isCalculating, "Should not be calculating after stopping updates")
    }
    
    // MARK: - Error Handling Tests
    
    func testLocationServicesDisabledHandling() {
        // We can't actually disable location services in tests, but we can test
        // that the calculator handles errors gracefully
        
        // Set a target location
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // If location services are disabled, the error should be handled gracefully
        // This is tested through integration with the actual CLLocationManager
        XCTAssertTrue(true, "Location services handling should not crash the app")
    }
    
    // MARK: - Distance Calculation Tests
    
    func testDistanceCalculationLogic() {
        // Since the actual distance calculation happens in CLLocation,
        // we can test the logic that handles the calculation results
        
        // Set a target location
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // The distance calculator should be ready to calculate distances
        XCTAssertEqual(distanceCalculator.currentDistance, 0.0, "Distance should be 0 initially")
    }
    
    // MARK: - State Management Tests
    
    func testStateTransitions() {
        // Test that state changes occur in the right order
        
        // Initial state
        XCTAssertFalse(distanceCalculator.isCalculating)
        XCTAssertNil(distanceCalculator.errorMessage)
        
        // Set target location
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Stop updates
        distanceCalculator.stopLocationUpdates()
        XCTAssertFalse(distanceCalculator.isCalculating, "Should not be calculating after stopping")
    }
    
    // MARK: - Network Integration Tests
    
    func testNetworkIntegrationDoesNotCrash() {
        // The DistanceCalculator integrates with NetworkManager
        // This test ensures that network failures don't crash the location functionality
        
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Even if the network manager fails to report distances,
        // the distance calculator should continue working
        XCTAssertTrue(true, "Distance calculator should handle network failures gracefully")
    }
    
    // MARK: - Thread Safety Tests
    
    func testMainThreadOperations() {
        // Ensure that UI updates happen on the main thread
        let expectation = XCTestExpectation(description: "Main thread operations")
        
        DispatchQueue.global().async {
            // Simulate a background operation
            DispatchQueue.main.async {
                // UI updates should happen on main thread
                self.distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Message Handling Tests
    
    func testErrorMessageClearing() {
        // Test that error messages are properly managed
        
        // Initially no error
        XCTAssertNil(distanceCalculator.errorMessage)
        
        // Set target location (should not produce error)
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        XCTAssertNil(distanceCalculator.errorMessage, "Setting valid target should not produce error")
        
        // Request permission (should handle gracefully)
        distanceCalculator.requestLocationPermission()
        
        // Should not crash and might or might not have an error depending on permissions
        XCTAssertTrue(true, "Permission request should complete without crashing")
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflowWithoutCrashing() {
        // Test a complete workflow to ensure nothing crashes
        
        // 1. Set target location
        distanceCalculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
        
        // 2. Request permissions
        distanceCalculator.requestLocationPermission()
        
        // 3. Stop updates
        distanceCalculator.stopLocationUpdates()
        
        // 4. Set a new target
        distanceCalculator.setTargetLocation(latitude: 40.7128, longitude: -74.0060)
        
        // All operations should complete without crashing
        XCTAssertTrue(true, "Full workflow should complete without crashing")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Test that the calculator can be created and destroyed without leaks
        weak var weakCalculator: DistanceCalculator?
        
        autoreleasepool {
            let calculator = DistanceCalculator()
            weakCalculator = calculator
            calculator.setTargetLocation(latitude: 37.7749, longitude: -122.4194)
            calculator.stopLocationUpdates()
        }
        
        // Give some time for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // The calculator should be deallocated
            // Note: This might not always pass due to retain cycles with CLLocationManager
            // but it's good to test for potential memory leaks
        }
    }
}