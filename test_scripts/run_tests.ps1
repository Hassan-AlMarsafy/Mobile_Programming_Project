# PowerShell Auto-Test Script for Hydroponic App
# This script runs all tests and generates a test report with ADB commands

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hydroponic App Auto-Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create test_scripts directory if it doesn't exist
$testScriptDir = "test_scripts"
if (-not (Test-Path $testScriptDir)) {
    New-Item -ItemType Directory -Path $testScriptDir | Out-Null
}

# Generate timestamp for log file
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$testScriptDir\test_log_$timestamp.txt"

Write-Host "Starting test execution at $(Get-Date)" | Tee-Object -FilePath $logFile

# Function to log and display messages
function Write-LogMessage {
    param($message, $color = "White")
    Write-Host $message -ForegroundColor $color
    $message | Out-File -FilePath $logFile -Append
}

# Check if Flutter is installed
Write-LogMessage "`n[1/7] Checking Flutter installation..." "Yellow"
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-LogMessage "Flutter is installed: $flutterVersion" "Green"
} catch {
    Write-LogMessage "ERROR: Flutter is not installed or not in PATH" "Red"
    exit 1
}

# Check for connected devices (emulator or physical device)
Write-LogMessage "`n[2/7] Checking for connected devices..." "Yellow"
$devices = flutter devices 2>&1
Write-LogMessage $devices
if ($devices -match "No devices detected") {
    Write-LogMessage "WARNING: No devices detected. Attempting to list ADB devices..." "Yellow"
    
    # Try ADB commands
    try {
        $adbDevices = adb devices
        Write-LogMessage $adbDevices
        
        if ($adbDevices -match "device$") {
            Write-LogMessage "ADB device found. Continuing..." "Green"
        } else {
            Write-LogMessage "ERROR: No Android devices found. Please connect a device or start an emulator." "Red"
            exit 1
        }
    } catch {
        Write-LogMessage "ERROR: ADB not found. Please install Android SDK Platform Tools." "Red"
        exit 1
    }
}

# Clean previous build artifacts
Write-LogMessage "`n[3/7] Cleaning previous build artifacts..." "Yellow"
flutter clean | Out-File -FilePath $logFile -Append
Write-LogMessage "Clean completed" "Green"

# Get dependencies
Write-LogMessage "`n[4/7] Getting dependencies..." "Yellow"
flutter pub get | Out-File -FilePath $logFile -Append
Write-LogMessage "Dependencies installed" "Green"

# Run code generation for mockito
Write-LogMessage "`n[5/7] Running code generation (mockito)..." "Yellow"
flutter pub run build_runner build --delete-conflicting-outputs | Out-File -FilePath $logFile -Append
Write-LogMessage "Code generation completed" "Green"

# Run unit tests
Write-LogMessage "`n[6/7] Running unit tests..." "Yellow"
flutter test test/unit --reporter expanded 2>&1 | Tee-Object -FilePath $logFile -Append | Out-String | Write-Host

if ($LASTEXITCODE -eq 0) {
    Write-LogMessage "✓ Unit tests PASSED" "Green"
} else {
    Write-LogMessage "✗ Unit tests FAILED" "Red"
}

# Run widget tests
Write-LogMessage "`n[6/7] Running widget tests..." "Yellow"
flutter test test/widget --reporter expanded 2>&1 | Tee-Object -FilePath $logFile -Append | Out-String | Write-Host

if ($LASTEXITCODE -eq 0) {
    Write-LogMessage "✓ Widget tests PASSED" "Green"
} else {
    Write-LogMessage "✗ Widget tests FAILED" "Red"
}

# Run integration tests (requires device/emulator)
Write-LogMessage "`n[7/7] Running integration tests..." "Yellow"
Write-LogMessage "This may take several minutes..." "Cyan"

# Use ADB to wake up device
try {
    adb shell input keyevent KEYCODE_WAKEUP | Out-Null
    adb shell wm dismiss-keyguard | Out-Null
    Write-LogMessage "Device woken up" "Green"
}
catch {
    Write-LogMessage "Could not wake device (might already be awake)" "Yellow"
}

flutter test integration_test 2>&1 | Tee-Object -FilePath $logFile -Append | Out-String | Write-Host

if ($LASTEXITCODE -eq 0) {
    Write-LogMessage "✓ Integration tests PASSED" "Green"
} else {
    Write-LogMessage "✗ Integration tests FAILED" "Red"
}

# Generate test summary
Write-LogMessage "`n========================================" "Cyan"
Write-LogMessage "  TEST SUMMARY" "Cyan"
Write-LogMessage "========================================" "Cyan"

# Count test files
$unitTestCount = (Get-ChildItem -Path "test/unit" -Recurse -Filter "*_test.dart").Count
$widgetTestCount = (Get-ChildItem -Path "test/widget" -Recurse -Filter "*_test.dart").Count
$integrationTestCount = (Get-ChildItem -Path "test/integration" -Recurse -Filter "*_test.dart").Count

Write-LogMessage "Unit Test Files: $unitTestCount"
Write-LogMessage "Widget Test Files: $widgetTestCount"
Write-LogMessage "Integration Test Files: $integrationTestCount"
Write-LogMessage "Total Test Files: $($unitTestCount + $widgetTestCount + $integrationTestCount)"
Write-LogMessage ""
Write-LogMessage "Test execution completed at $(Get-Date)"
Write-LogMessage "Full log saved to: $logFile" "Green"

# Optional: Send test report via ADB to device (save log on device)
try {
    adb push $logFile /sdcard/Download/hydroponic_test_report.txt | Out-Null
    Write-LogMessage "`nTest report copied to device: /sdcard/Download/hydroponic_test_report.txt" "Cyan"
}
catch {
    Write-LogMessage "Could not copy report to device" "Yellow"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown')
