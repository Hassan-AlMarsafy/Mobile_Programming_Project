#!/bin/bash
# Bash Auto-Test Script for Hydroponic App (Linux/macOS)
# This script runs all tests and generates a test report with ADB commands

echo "========================================"
echo "  Hydroponic App Auto-Test Script"
echo "========================================"
echo ""

# Create test_scripts directory if it doesn't exist
TEST_SCRIPT_DIR="test_scripts"
mkdir -p "$TEST_SCRIPT_DIR"

# Generate timestamp for log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$TEST_SCRIPT_DIR/test_log_$TIMESTAMP.txt"

echo "Starting test execution at $(date)" | tee "$LOG_FILE"

# Function to log and display messages
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Check if Flutter is installed
log_message ""
log_message "[1/7] Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    log_message "Flutter is installed: $FLUTTER_VERSION"
else
    log_message "ERROR: Flutter is not installed or not in PATH"
    exit 1
fi

# Check for connected devices
log_message ""
log_message "[2/7] Checking for connected devices..."
DEVICES=$(flutter devices 2>&1)
log_message "$DEVICES"

if echo "$DEVICES" | grep -q "No devices detected"; then
    log_message "WARNING: No devices detected. Attempting to list ADB devices..."
    
    # Try ADB commands
    if command -v adb &> /dev/null; then
        ADB_DEVICES=$(adb devices)
        log_message "$ADB_DEVICES"
        
        if echo "$ADB_DEVICES" | grep -q "device$"; then
            log_message "ADB device found. Continuing..."
        else
            log_message "ERROR: No Android devices found. Please connect a device or start an emulator."
            exit 1
        fi
    else
        log_message "ERROR: ADB not found. Please install Android SDK Platform Tools."
        exit 1
    fi
fi

# Clean previous build artifacts
log_message ""
log_message "[3/7] Cleaning previous build artifacts..."
flutter clean >> "$LOG_FILE" 2>&1
log_message "Clean completed"

# Get dependencies
log_message ""
log_message "[4/7] Getting dependencies..."
flutter pub get >> "$LOG_FILE" 2>&1
log_message "Dependencies installed"

# Run code generation for mockito
log_message ""
log_message "[5/7] Running code generation (mockito)..."
flutter pub run build_runner build --delete-conflicting-outputs >> "$LOG_FILE" 2>&1
log_message "Code generation completed"

# Run unit tests
log_message ""
log_message "[6/7] Running unit tests..."
if flutter test test/unit --reporter expanded >> "$LOG_FILE" 2>&1; then
    log_message "✓ Unit tests PASSED"
else
    log_message "✗ Unit tests FAILED"
fi

# Run widget tests
log_message ""
log_message "[6/7] Running widget tests..."
if flutter test test/widget --reporter expanded >> "$LOG_FILE" 2>&1; then
    log_message "✓ Widget tests PASSED"
else
    log_message "✗ Widget tests FAILED"
fi

# Run integration tests
log_message ""
log_message "[7/7] Running integration tests..."
log_message "This may take several minutes..."

# Use ADB to wake up device
if command -v adb &> /dev/null; then
    adb shell input keyevent KEYCODE_WAKEUP 2>&1 > /dev/null
    adb shell wm dismiss-keyguard 2>&1 > /dev/null
    log_message "Device woken up"
fi

if flutter test integration_test >> "$LOG_FILE" 2>&1; then
    log_message "✓ Integration tests PASSED"
else
    log_message "✗ Integration tests FAILED"
fi

# Generate test summary
log_message ""
log_message "========================================"
log_message "  TEST SUMMARY"
log_message "========================================"

# Count test files
UNIT_TEST_COUNT=$(find test/unit -name "*_test.dart" | wc -l)
WIDGET_TEST_COUNT=$(find test/widget -name "*_test.dart" | wc -l)
INTEGRATION_TEST_COUNT=$(find test/integration -name "*_test.dart" | wc -l)
TOTAL_TESTS=$((UNIT_TEST_COUNT + WIDGET_TEST_COUNT + INTEGRATION_TEST_COUNT))

log_message "Unit Test Files: $UNIT_TEST_COUNT"
log_message "Widget Test Files: $WIDGET_TEST_COUNT"
log_message "Integration Test Files: $INTEGRATION_TEST_COUNT"
log_message "Total Test Files: $TOTAL_TESTS"
log_message ""
log_message "Test execution completed at $(date)"
log_message "Full log saved to: $LOG_FILE"

# Optional: Send test report via ADB to device
if command -v adb &> /dev/null; then
    if adb push "$LOG_FILE" /sdcard/Download/hydroponic_test_report.txt 2>&1 > /dev/null; then
        log_message ""
        log_message "Test report copied to device: /sdcard/Download/hydroponic_test_report.txt"
    fi
fi

echo ""
echo "Test script completed. Press Enter to exit..."
read
