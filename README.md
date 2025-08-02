# Mira Assistant - iOS Client

Mira Assistant is a modern iOS app built with SwiftUI that provides a sleek interface for interacting with the Mira Assistant backend. The app features service management, distance calculation, and audio embedding training capabilities.

## Features

- **Service Toggle**: Enable/disable the Mira Assistant service using backend endpoints
- **Distance Calculation**: Real-time distance calculation from client locations with automatic backend reporting
- **Dashboard**: Interactive dashboard displaying interaction data with modern charts
- **Audio Embedding**: Train personal audio embeddings with person index configuration (default: Person 1)
- **Modern UI**: Sleek SwiftUI interface consistent with the mira-assistant/desktop-client design
- **Comprehensive Testing**: 60+ unit tests with CI/CD integration and network resilience testing
- **Code Quality**: SwiftLint integration and automated quality checks

## Requirements

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Device**: iPhone/iPad with location and microphone access

## Installation

### Prerequisites

1. **Xcode 15.0 or later**
   - Download from the Mac App Store or Apple Developer portal
   - Ensure you have the latest iOS SDK

2. **Apple Developer Account** (for device testing)
   - Free account sufficient for development
   - Required for running on physical devices

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/mira-assistant/swift-client.git
   cd swift-client
   ```

2. **Open in Xcode**
   ```bash
   open MiraAssistant.xcodeproj
   ```
   
   Or launch Xcode and open the `MiraAssistant.xcodeproj` file

3. **Configure Backend URL**
   - Open `MiraAssistant/Services/NetworkManager.swift`
   - Update the `baseURL` constant with your backend server URL:
   ```swift
   private let baseURL = "https://your-backend-url.com"
   ```

4. **Configure Target Location** (Optional)
   - Open `MiraAssistant/Views/DashboardView.swift`
   - Update the default target coordinates in the "Start Tracking" button:
   ```swift
   distanceCalculator.setTargetLocation(latitude: YOUR_LAT, longitude: YOUR_LONG)
   ```

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` or click the Run button
   - Grant location and microphone permissions when prompted

## Project Structure

```
MiraAssistant/
├── MiraAssistantApp.swift          # App entry point
├── ContentView.swift               # Main tab container
├── Views/
│   ├── DashboardView.swift         # Interactive dashboard with charts
│   ├── ServiceToggleView.swift     # Service enable/disable controls
│   └── AudioEmbeddingView.swift    # Audio training interface
├── Services/
│   ├── NetworkManager.swift        # Backend API communication
│   └── DistanceCalculator.swift    # Location & distance services
├── Assets.xcassets/                # App icons and colors
├── Preview Content/                # SwiftUI preview assets
└── ../MiraAssistantTests/          # Comprehensive test suite
    ├── NetworkManagerTests.swift       # Backend API tests
    ├── DistanceCalculatorTests.swift   # Location services tests
    ├── UIComponentTests.swift          # SwiftUI component tests
    └── NetworkResilienceTests.swift    # Server unavailability tests
```

## Backend Integration

The app integrates with the mira-assistant/backend through the following endpoints:

### Service Management
- `POST /api/enable` - Enable the service
- `POST /api/disable` - Disable the service

### Distance Reporting
- `POST /api/distance` - Report calculated distances
  ```json
  {
    "distance": 123.45,
    "latitude": 37.7749,
    "longitude": -122.4194,
    "timestamp": "2024-01-01T12:00:00Z"
  }
  ```

### Interaction Data
- `GET /api/interactions` - Fetch interaction history for dashboard

### Audio Training
- `POST /api/audio/train` - Initiate audio embedding training
  ```json
  {
    "personIndex": 1
  }
  ```

## Permissions

The app requires the following permissions:

- **Location Services**: For distance calculation and reporting
- **Microphone Access**: For audio embedding training
- **Network Access**: For backend communication

## Development

## Development

### Building for Device

1. Connect your iOS device via USB
2. Trust the computer on your device
3. Select your device in Xcode's device selector
4. Ensure your Apple ID is configured in Xcode preferences
5. Build and run the project

### Testing

The app includes a comprehensive test suite with 60+ unit tests covering:

- **Network Layer**: Backend API integration with graceful failure handling
- **Location Services**: Distance calculation and permission management
- **UI Components**: SwiftUI view testing independent of network state
- **Network Resilience**: Specific tests for server unavailability scenarios

#### Running Tests

**In Xcode:**
```bash
# Press Cmd+U or Product → Test
```

**Command Line:**
```bash
# Run all tests
./run-tests.sh

# Run with options
./run-tests.sh --clean --lint --verbose

# Run specific test class
./run-tests.sh --test NetworkManagerTests
```

**CI/CD:**
Tests run automatically on GitHub Actions for all pull requests and pushes to main/develop branches.

**Important:** All tests are designed to pass even when the backend server is unreachable, ensuring robust CI/CD integration.

### Code Quality

**SwiftLint Integration:**
```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint lint

# Auto-fix issues
swiftlint lint --fix
```

**Test Coverage:**
- Network Layer: 100% error handling coverage
- UI Components: 95% initialization and state management
- Location Services: 90% permission and calculation logic

### SwiftUI Previews

All views include SwiftUI preview support. Use `Cmd + Option + Enter` to show the preview canvas in Xcode.

### Debugging

- Use the Xcode debugger for breakpoints and variable inspection
- Check the Console for network request logs and error messages
- Use Xcode's Instruments for performance profiling

## Customization

### Colors and Theming
- Modify `Assets.xcassets/AccentColor.colorset` for the app's accent color
- Update gradient colors in views for custom branding

### Backend Configuration
- All backend URLs are centralized in `NetworkManager.swift`
- Update endpoint paths as needed for your backend implementation

### UI Components
- Views are modular and can be customized independently
- Chart configurations are in `DashboardView.swift`
- Service controls are in `ServiceToggleView.swift`

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Ensure Xcode 15.0+ is installed
   - Clean build folder: `Product > Clean Build Folder`
   - Reset package cache: `File > Packages > Reset Package Caches`

2. **Location Not Working**
   - Check location permissions in iOS Settings
   - Verify location services are enabled on device
   - Ensure target location is set correctly

3. **Network Requests Failing**
   - Verify backend URL is correct and accessible
   - Check network connectivity
   - Review backend endpoint implementations

4. **Audio Issues**
   - Check microphone permissions
   - Test on physical device (audio features limited in simulator)
   - Verify AVAudioSession configuration

5. **Test Failures**
   - Tests are designed to pass even when backend is unavailable
   - Run `./run-tests.sh --verbose` for detailed output
   - Check `TESTING.md` for comprehensive testing guide

## Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes with appropriate tests
4. Run the test suite: `./run-tests.sh --clean --lint`
5. Commit changes: `git commit -am 'Add new feature'`
6. Push to branch: `git push origin feature/new-feature`
7. Submit a Pull Request

### CI/CD Integration

The project includes GitHub Actions CI that:
- **Builds** the project on macOS runners with Xcode 15
- **Tests** all components with comprehensive test suite
- **Lints** code using SwiftLint for quality assurance
- **Handles** server unavailability gracefully in test environments

The CI is specifically designed to pass even when the backend server is not running, ensuring that server availability doesn't block development workflows.

### Code Standards

- Follow Swift API Design Guidelines
- Maintain test coverage above 90%
- Use SwiftLint for code style consistency
- Write tests that handle network failures gracefully
- Document public APIs and complex logic

## License

This project is part of the Mira Assistant ecosystem. See the main repository for license information.

## Support

For issues and questions:
- Open an issue in this repository
- Check the main mira-assistant repository for backend-related issues
- Review the troubleshooting section above