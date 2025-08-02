# Testing Guide - MiraAssistant iOS Client

This document provides comprehensive information about the testing infrastructure for the MiraAssistant iOS client.

## Overview

The MiraAssistant iOS client includes a robust test suite designed to ensure code quality and resilience, especially in scenarios where the backend server may be unavailable. This is particularly important for CI/CD environments where the server is not always running.

## Test Philosophy

**Key Principle: Server unavailability should NOT indicate bad Swift client code.**

All tests are designed to:
- ✅ Pass even when the backend server is unreachable
- ✅ Verify that the app handles network failures gracefully
- ✅ Ensure UI components work independently of network state
- ✅ Test local functionality without external dependencies

## Test Suite Structure

### 📁 Test Files

```
MiraAssistantTests/
├── NetworkManagerTests.swift       # Backend API integration tests
├── DistanceCalculatorTests.swift   # Location services tests
├── UIComponentTests.swift          # SwiftUI component tests
├── NetworkResilienceTests.swift    # Server unavailability tests
└── Info.plist                      # Test bundle configuration
```

### 🧪 Test Categories

#### 1. NetworkManagerTests (20+ tests)
Tests for backend API integration that handle server unavailability:

- **Service Toggle Tests**
  - `testEnableServiceWithUnreachableServer()`
  - `testDisableServiceWithUnreachableServer()`
  - `testServiceToggleLoadingStates()`

- **Distance Reporting Tests**
  - `testDistanceReportingWithUnreachableServer()`
  - `testDistanceReportingWithValidData()`

- **Interaction Data Tests**
  - `testFetchInteractionDataWithUnreachableServer()`
  - `testInteractionDataLoadingStates()`

- **Audio Training Tests**
  - `testAudioTrainingWithUnreachableServer()`
  - `testAudioTrainingWithDefaultPersonIndex()`

- **Data Model Tests**
  - `testDistanceReportDataModel()`
  - `testInteractionDataModel()`
  - `testAudioTrainingRequestModel()`

#### 2. DistanceCalculatorTests (15+ tests)
Tests for location services and distance calculation:

- **Initialization Tests**
  - `testInitialization()`
  - `testSetTargetLocation()`

- **Location Permission Tests**
  - `testRequestLocationPermissionHandling()`
  - `testLocationServicesDisabledHandling()`

- **State Management Tests**
  - `testStateTransitions()`
  - `testStopLocationUpdates()`

- **Error Handling Tests**
  - `testErrorMessageClearing()`
  - `testMemoryManagement()`

#### 3. UIComponentTests (25+ tests)
Tests for SwiftUI components that work independently of the server:

- **View Initialization Tests**
  - `testDashboardViewInitialization()`
  - `testServiceToggleViewInitialization()`
  - `testAudioEmbeddingViewInitialization()`

- **Data Display Tests**
  - `testInteractionDataDisplay()`
  - `testDistanceDisplayFormatting()`
  - `testErrorStateHandling()`

- **Performance Tests**
  - `testViewCreationPerformance()`
  - `testDataProcessingPerformance()`

- **Accessibility Tests**
  - `testAccessibilitySupport()`
  - `testSystemImageAvailability()`

#### 4. NetworkResilienceTests (20+ tests)
Comprehensive tests specifically for server unavailability scenarios:

- **Server Unreachable Tests**
  - `testAppFunctionalityWhenServerUnreachable()`
  - `testServiceToggleResilience()`
  - `testDistanceReportingResilience()`

- **CI/CD Specific Tests**
  - `testCIEnvironmentNetworkHandling()`
  - `testOfflineModeGracefulDegradation()`

- **Error Recovery Tests**
  - `testErrorRecoveryAfterServerReturns()`
  - `testTimeoutHandling()`

## Setting Up Tests

### Option 1: Automatic Setup (Using Xcode)

1. Open `MiraAssistant.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Select **iOS Unit Testing Bundle**
4. Name: `MiraAssistantTests`
5. Bundle ID: `com.mira-assistant.MiraAssistantTests`
6. Target to be tested: `MiraAssistant`
7. Click **Finish**
8. Add all `.swift` files from `MiraAssistantTests/` to the new target

### Option 2: Manual Setup (Using Script)

```bash
# Run the setup script
./setup-tests.sh
```

This script provides detailed instructions for manual setup.

### Option 3: Command Line (CI/CD)

The CI workflow automatically handles test setup and execution:

```bash
# Build for testing
xcodebuild build-for-testing \
  -project MiraAssistant.xcodeproj \
  -scheme MiraAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'

# Run tests
xcodebuild test-without-building \
  -project MiraAssistant.xcodeproj \
  -scheme MiraAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'
```

## Running Tests

### 🖥️ In Xcode

1. Select the `MiraAssistant` scheme
2. Press `Cmd + U` to run all tests
3. Or use **Product → Test** from the menu

### 🔧 Command Line

```bash
# Run all tests
xcodebuild test \
  -project MiraAssistant.xcodeproj \
  -scheme MiraAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'

# Run specific test class
xcodebuild test \
  -project MiraAssistant.xcodeproj \
  -scheme MiraAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  -only-testing:MiraAssistantTests/NetworkResilienceTests
```

### 🤖 CI/CD (GitHub Actions)

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

The CI workflow includes:
- Building the project
- Running the full test suite
- SwiftLint code quality checks
- Artifact collection for debugging

## Test Expectations for Server Unavailability

When the backend server is not available (common in CI environments), tests should:

### ✅ Expected Behaviors

- **Network operations fail gracefully** with appropriate error messages
- **Loading states resolve properly** (not stuck in loading)
- **UI components remain functional** and responsive
- **Local functionality continues working** (distance calculation, UI navigation)
- **App does not crash** or become unresponsive
- **Error messages are user-friendly** and informative

### ❌ What Should NOT Happen

- Tests should not fail due to network connectivity issues
- App should not crash when server is unreachable
- UI should not become unresponsive during network failures
- Loading states should not persist indefinitely

## Code Quality

### SwiftLint Integration

The project includes SwiftLint configuration (`.swiftlint.yml`) for code quality:

```bash
# Install SwiftLint
brew install swiftlint

# Run SwiftLint
swiftlint lint
```

### Test Coverage Goals

- **Network Layer**: 100% of error handling paths
- **UI Components**: 95% of view initialization and state management
- **Location Services**: 90% of permission and calculation logic
- **Data Models**: 100% of serialization/deserialization

## Debugging Tests

### Common Issues

1. **Simulator Issues**
   ```bash
   # Reset simulator
   xcrun simctl erase all
   ```

2. **Build Cache Issues**
   ```bash
   # Clean build
   xcodebuild clean -project MiraAssistant.xcodeproj
   ```

3. **Network Timeout Issues**
   - Increase timeout values in test expectations
   - Check network connectivity on the test machine

### Test Logs

Tests generate detailed logs for debugging:

```bash
# View test logs
tail -f ~/Library/Logs/DiagnosticReports/MiraAssistantTests_*.crash
```

## Contributing Test Code

### Test Naming Convention

```swift
func test[ComponentName][Scenario][ExpectedResult]() {
    // Test implementation
}

// Examples:
func testNetworkManagerEnableServiceWithUnreachableServer()
func testDistanceCalculatorLocationPermissionHandling()
func testDashboardViewInitializationWithEmptyData()
```

### Test Structure

```swift
func testExampleScenario() async {
    // Arrange: Set up test data and conditions
    let networkManager = NetworkManager()
    
    // Act: Perform the action being tested
    await networkManager.enableService()
    
    // Assert: Verify the expected outcomes
    XCTAssertFalse(networkManager.isLoading, "Loading should be false after operation")
    XCTAssertNotNil(networkManager.errorMessage, "Error message should be set when server unreachable")
}
```

### Adding New Tests

1. Identify the component or scenario to test
2. Choose the appropriate test file or create a new one
3. Follow the naming convention
4. Ensure tests pass with server unavailable
5. Add appropriate documentation

## Backend API Requirements

For reference, the client expects these backend endpoints:

- `POST /api/enable` - Enable service
- `POST /api/disable` - Disable service
- `POST /api/distance` - Report distance data
- `GET /api/interactions` - Fetch interaction history
- `POST /api/audio/train` - Start audio training

All endpoints should return appropriate HTTP status codes and handle JSON content.

## Performance Considerations

Tests are designed to be fast and efficient:

- **Network tests**: Use short timeouts to avoid hanging
- **UI tests**: Focus on component initialization rather than full rendering
- **Async tests**: Use proper expectations to avoid race conditions
- **Memory tests**: Include cleanup verification to prevent leaks

## Continuous Integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) ensures:

- Tests run on every pull request
- Multiple iOS versions are supported
- SwiftLint quality checks pass
- Build artifacts are preserved for debugging
- Tests pass regardless of server availability

This comprehensive testing strategy ensures the MiraAssistant iOS client is robust, reliable, and ready for production deployment.