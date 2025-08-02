#!/bin/bash

# MiraAssistant Test Setup Script
# This script helps set up the test target in the Xcode project

echo "🧪 Setting up MiraAssistant Test Target..."

# Check if we're in the right directory
if [ ! -d "MiraAssistant.xcodeproj" ]; then
    echo "❌ Error: MiraAssistant.xcodeproj not found. Please run this script from the project root."
    exit 1
fi

# Check if test files exist
if [ ! -d "MiraAssistantTests" ]; then
    echo "❌ Error: MiraAssistantTests directory not found."
    exit 1
fi

echo "✅ Project structure verified"

# Instructions for manual Xcode setup
echo ""
echo "📋 Manual Xcode Setup Instructions:"
echo "1. Open MiraAssistant.xcodeproj in Xcode"
echo "2. In the Project Navigator, right-click on the project root"
echo "3. Select 'Add Files to MiraAssistant'"
echo "4. Navigate to and select the MiraAssistantTests folder"
echo "5. Make sure 'Create groups' is selected"
echo "6. Click 'Add'"
echo ""
echo "📋 Create Test Target:"
echo "1. Select the project in Project Navigator"
echo "2. Click the '+' button at the bottom of the targets list"
echo "3. Choose 'iOS Unit Testing Bundle'"
echo "4. Set Target Name: MiraAssistantTests"
echo "5. Set Bundle Identifier: com.mira-assistant.MiraAssistantTests"
echo "6. Select MiraAssistant as the target to be tested"
echo "7. Click 'Finish'"
echo ""
echo "📋 Configure Test Target:"
echo "1. Select MiraAssistantTests target"
echo "2. In Build Settings, set iOS Deployment Target to 17.0"
echo "3. In Build Phases > Compile Sources, add all .swift files from MiraAssistantTests"
echo "4. In General > Testing, ensure 'Host Application' is set to MiraAssistant"
echo ""

# Try to detect if Xcode CLI tools can help
if command -v xcodebuild >/dev/null 2>&1; then
    echo "🔧 Testing current project build..."
    
    # Try to build the current project
    if xcodebuild -project MiraAssistant.xcodeproj -scheme MiraAssistant -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build >/dev/null 2>&1; then
        echo "✅ Main project builds successfully"
    else
        echo "⚠️  Main project may need configuration"
    fi
    
    echo ""
    echo "🎯 Quick Test Commands:"
    echo "Build: xcodebuild -project MiraAssistant.xcodeproj -scheme MiraAssistant -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build"
    echo "Test:  xcodebuild test -project MiraAssistant.xcodeproj -scheme MiraAssistant -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'"
else
    echo "⚠️  Xcode CLI tools not found. Please install Xcode and run 'xcode-select --install'"
fi

echo ""
echo "🎉 Test files are ready! Follow the manual setup instructions above to complete the integration."
echo ""
echo "📊 Test Suite Overview:"
echo "- NetworkManagerTests.swift: Backend API integration tests"
echo "- DistanceCalculatorTests.swift: Location services tests"  
echo "- UIComponentTests.swift: SwiftUI component tests"
echo "- NetworkResilienceTests.swift: Server unavailability tests"
echo ""
echo "💡 All tests are designed to pass even when the backend server is unreachable!"
