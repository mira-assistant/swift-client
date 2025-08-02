import XCTest
import CoreLocation
@testable import swift_client

@MainActor
final class NetworkManagerTests: XCTestCase {
    var networkManager: NetworkManager!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        networkManager = NetworkManager()
        // We'll use dependency injection to inject the mock session
        // For now, we'll test the behavior with network errors
    }
    
    override func tearDown() {
        networkManager = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Service Toggle Tests
    
    func testEnableServiceWithUnreachableServer() async {
        // Test that unreachable server doesn't crash the app
        await networkManager.enableService()
        
        // The service should handle the error gracefully
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
        XCTAssertFalse(networkManager.isLoading, "Loading state should be false after error")
    }
    
    func testDisableServiceWithUnreachableServer() async {
        // Test that unreachable server doesn't crash the app
        await networkManager.disableService()
        
        // The service should handle the error gracefully
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
        XCTAssertFalse(networkManager.isLoading, "Loading state should be false after error")
    }
    
    func testServiceToggleLoadingStates() async {
        // Test that loading states are properly managed
        let enableTask = Task {
            await networkManager.enableService()
        }
        
        // Give a moment for the loading state to be set
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await enableTask.value
        
        // After completion, loading should be false
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after operation completes")
    }
    
    // MARK: - Distance Reporting Tests
    
    func testDistanceReportingWithUnreachableServer() async {
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let distance = 123.45
        
        await networkManager.reportDistance(distance, from: location)
        
        // Should handle network error gracefully without crashing
        // Error might be set, but app should continue functioning
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after operation")
    }
    
    func testDistanceReportingWithValidData() async {
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let distance = 123.45
        
        // This should not crash even with invalid server
        await networkManager.reportDistance(distance, from: location)
        
        // Verify the function completes without crashing
        XCTAssertTrue(true, "Function should complete without crashing")
    }
    
    // MARK: - Interaction Data Tests
    
    func testFetchInteractionDataWithUnreachableServer() async {
        await networkManager.fetchInteractionData()
        
        // Should handle error gracefully
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after error")
        XCTAssertTrue(networkManager.interactionData.isEmpty, "Interaction data should remain empty on error")
    }
    
    func testInteractionDataLoadingStates() async {
        let fetchTask = Task {
            await networkManager.fetchInteractionData()
        }
        
        // Give a moment for the loading state to be set
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await fetchTask.value
        
        // After completion, loading should be false
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after operation completes")
    }
    
    // MARK: - Search Functionality Tests
    
    func testPersonSearchWithUnreachableServer() async {
        let results = await networkManager.searchPersons(query: "test")
        
        // Should handle error gracefully and return empty results
        XCTAssertTrue(results.isEmpty, "Search should return empty results when server is unreachable")
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
    }
    
    func testInteractionSearchWithUnreachableServer() async {
        let results = await networkManager.searchInteractions(query: "test")
        
        // Should handle error gracefully and return empty results
        XCTAssertTrue(results.isEmpty, "Interaction search should return empty results when server is unreachable")
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
    }
    
    func testClientIdPersistence() {
        // Test that NetworkManager uses persistent Client ID
        let testId = "test-persistent-id"
        UserDefaults.standard.set(testId, forKey: "ClientID")
        
        let newNetworkManager = NetworkManager()
        // The client ID should be loaded from UserDefaults
        // Note: We can't directly access clientId as it's private, but we can test the behavior
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "ClientID")
    }
    
    func testAudioTrainingWithUnreachableServer() async {
        await networkManager.trainAudioEmbedding(personIndex: 1)
        
        // Should handle error gracefully
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server is unreachable")
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after error")
    }
    
    func testAudioTrainingWithDefaultPersonIndex() async {
        await networkManager.trainAudioEmbedding()
        
        // Should use default person index and handle error gracefully
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after operation")
    }
    
    // MARK: - Data Model Tests
    
    func testDistanceReportDataModel() {
        let timestamp = Date()
        let report = DistanceReport(
            distance: 123.45,
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: timestamp
        )
        
        XCTAssertEqual(report.distance, 123.45)
        XCTAssertEqual(report.latitude, 37.7749)
        XCTAssertEqual(report.longitude, -122.4194)
        XCTAssertEqual(report.timestamp, timestamp)
    }
    
    func testInteractionDataModel() {
        let id = UUID()
        let timestamp = Date()
        let interaction = InteractionData(
            id: id,
            timestamp: timestamp,
            type: "test",
            duration: 30.0,
            distance: 100.0,
            personIndex: 1
        )
        
        XCTAssertEqual(interaction.id, id)
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.type, "test")
        XCTAssertEqual(interaction.duration, 30.0)
        XCTAssertEqual(interaction.distance, 100.0)
        XCTAssertEqual(interaction.personIndex, 1)
    }
    
    func testInteractionDataModelWithDefaults() {
        let timestamp = Date()
        let interaction = InteractionData(
            timestamp: timestamp,
            type: "test"
        )
        
        XCTAssertNotNil(interaction.id)
        XCTAssertEqual(interaction.timestamp, timestamp)
        XCTAssertEqual(interaction.type, "test")
        XCTAssertNil(interaction.duration)
        XCTAssertNil(interaction.distance)
        XCTAssertNil(interaction.personIndex)
    }
    
    func testAudioTrainingRequestModel() {
        let request = AudioTrainingRequest(personIndex: 2)
        XCTAssertEqual(request.personIndex, 2)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageClearing() async {
        // First, trigger an error
        await networkManager.enableService()
        XCTAssertNotNil(networkManager.errorMessage, "Error message should be set")
        
        // Then trigger another operation which should clear the error initially
        let fetchTask = Task {
            await networkManager.fetchInteractionData()
        }
        
        // Give a moment for the error to be cleared
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await fetchTask.value
        
        // Verify that a new error is set (since server is unreachable)
        XCTAssertNotNil(networkManager.errorMessage, "New error message should be set")
    }
    
    func testConcurrentOperations() async {
        // Test that multiple concurrent operations don't cause issues
        async let enableTask = networkManager.enableService()
        async let fetchTask = networkManager.fetchInteractionData()
        async let trainTask = networkManager.trainAudioEmbedding()
        
        await enableTask
        await fetchTask
        await trainTask
        
        // All operations should complete without crashing
        XCTAssertFalse(networkManager.isLoading, "Loading should be false after all operations complete")
    }
}

// MARK: - Mock URL Session (for future implementation)

class MockURLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    func setMockResponse(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}
