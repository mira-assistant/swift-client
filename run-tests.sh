#!/bin/bash

# MiraAssistant Test Runner
# This script runs the test suite locally with proper configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="MiraAssistant"
SCHEME_NAME="MiraAssistant"
SIMULATOR_NAME="iPhone 15"
IOS_VERSION="17.2"
DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME},OS=${IOS_VERSION}"

echo -e "${BLUE}🧪 MiraAssistant Test Runner${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: ${PROJECT_NAME}.xcodeproj not found${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if test files exist
if [ ! -d "MiraAssistantTests" ]; then
    echo -e "${RED}❌ Error: MiraAssistantTests directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project structure verified${NC}"

# Function to run a command with status
run_command() {
    local description=$1
    local command=$2
    
    echo -e "\n${YELLOW}🔧 ${description}...${NC}"
    
    if eval "$command"; then
        echo -e "${GREEN}✅ ${description} completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ ${description} failed${NC}"
        return 1
    fi
}

# Parse command line arguments
CLEAN_BUILD=false
RUN_LINT=false
VERBOSE=false
SPECIFIC_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --lint)
            RUN_LINT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --clean     Clean build before testing"
            echo "  --lint      Run SwiftLint before testing"
            echo "  --verbose   Show detailed output"
            echo "  --test      Run specific test class (e.g., NetworkManagerTests)"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check for required tools
echo -e "\n${BLUE}🔍 Checking required tools...${NC}"

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found. Please install Xcode and command line tools.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ xcodebuild found${NC}"

if command -v xcrun simctl &> /dev/null; then
    echo -e "${GREEN}✅ iOS Simulator tools found${NC}"
else
    echo -e "${YELLOW}⚠️  iOS Simulator tools not found. Some tests may fail.${NC}"
fi

# Check if SwiftLint is available (optional)
if command -v swiftlint &> /dev/null; then
    echo -e "${GREEN}✅ SwiftLint found${NC}"
    SWIFTLINT_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️  SwiftLint not found. Code quality checks will be skipped.${NC}"
    echo -e "   Install with: brew install swiftlint"
    SWIFTLINT_AVAILABLE=false
fi

# List available simulators
echo -e "\n${BLUE}📱 Checking available simulators...${NC}"
if xcrun simctl list devices available | grep -q "${SIMULATOR_NAME}"; then
    echo -e "${GREEN}✅ ${SIMULATOR_NAME} simulator available${NC}"
else
    echo -e "${YELLOW}⚠️  ${SIMULATOR_NAME} simulator not found. Using any available iPhone simulator.${NC}"
    DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro,OS=latest"
fi

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    run_command "Cleaning build folder" \
        "xcodebuild clean -project ${PROJECT_NAME}.xcodeproj -scheme ${SCHEME_NAME}"
fi

# Run SwiftLint if requested and available
if [ "$RUN_LINT" = true ] && [ "$SWIFTLINT_AVAILABLE" = true ]; then
    run_command "Running SwiftLint" \
        "swiftlint lint --reporter xcode"
elif [ "$RUN_LINT" = true ]; then
    echo -e "${YELLOW}⚠️  SwiftLint requested but not available${NC}"
fi

# Build the project
run_command "Building project" \
    "xcodebuild build -project ${PROJECT_NAME}.xcodeproj -scheme ${SCHEME_NAME} -destination '${DESTINATION}'"

# Build for testing
run_command "Building for testing" \
    "xcodebuild build-for-testing -project ${PROJECT_NAME}.xcodeproj -scheme ${SCHEME_NAME} -destination '${DESTINATION}'"

# Run tests
echo -e "\n${BLUE}🧪 Running tests...${NC}"
echo "Note: These tests are designed to pass even when the backend server is unreachable."

if [ -n "$SPECIFIC_TEST" ]; then
    echo -e "${YELLOW}Running specific test: ${SPECIFIC_TEST}${NC}"
    TEST_COMMAND="xcodebuild test-without-building -project ${PROJECT_NAME}.xcodeproj -scheme ${SCHEME_NAME} -destination '${DESTINATION}' -only-testing:MiraAssistantTests/${SPECIFIC_TEST}"
else
    TEST_COMMAND="xcodebuild test-without-building -project ${PROJECT_NAME}.xcodeproj -scheme ${SCHEME_NAME} -destination '${DESTINATION}'"
fi

if [ "$VERBOSE" = true ]; then
    TEST_COMMAND="$TEST_COMMAND -verbose"
fi

if eval "$TEST_COMMAND"; then
    echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
    echo -e "${GREEN}✅ The Swift client handles server unavailability correctly${NC}"
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    echo -e "${YELLOW}💡 If tests failed due to network issues, this is expected when the server is unavailable.${NC}"
    echo -e "${YELLOW}   The tests are designed to verify graceful error handling.${NC}"
    exit 1
fi

# Test summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "=================================="
echo -e "Project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "Scheme: ${GREEN}${SCHEME_NAME}${NC}"
echo -e "Destination: ${GREEN}${DESTINATION}${NC}"
echo -e "Test Files: ${GREEN}$(find MiraAssistantTests -name "*.swift" | wc -l | tr -d ' ')${NC}"

if [ -n "$SPECIFIC_TEST" ]; then
    echo -e "Test Class: ${GREEN}${SPECIFIC_TEST}${NC}"
else
    echo -e "Test Scope: ${GREEN}All Tests${NC}"
fi

echo -e "\n${BLUE}📋 Available Test Classes:${NC}"
find MiraAssistantTests -name "*Tests.swift" -exec basename {} .swift \; | sort | sed 's/^/  • /'

echo -e "\n${GREEN}✅ Testing completed successfully!${NC}"
echo -e "${BLUE}💡 Use './run-tests.sh --help' for more options${NC}"