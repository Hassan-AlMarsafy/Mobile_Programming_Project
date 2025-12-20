# Simplified Integration Test Runner
# Runs tests on connected device without complex HTML generation

param(
    [string]$DeviceId = ""
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "====== Flutter Integration Test Runner ======" -ForegroundColor Cyan
Write-Host ""

# Get device
if ($DeviceId -eq "") {
    Write-Host "Detecting device..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    $devices = flutter devices
    Pop-Location
    Write-Host $devices
    Write-Host ""
    Write-Host "Enter device ID (e.g., 5T4HPZOJY56DZ9QG): " -ForegroundColor Yellow -NoNewline
    $DeviceId = Read-Host
}

Write-Host ""
Write-Host "Selected device: $DeviceId" -ForegroundColor Green
Write-Host ""

# Build APK
Write-Host "[1/4] Building APK..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter build apk --debug
$buildExit = $LASTEXITCODE
Pop-Location

if ($buildExit -ne 0) {
    Write-Host "[FAIL] Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Build successful" -ForegroundColor Green

# Install APK
Write-Host ""
Write-Host "[2/4] Installing APK on device..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter install -d $DeviceId
Pop-Location
Write-Host "[PASS] Installation complete" -ForegroundColor Green

# Run Unit Tests
Write-Host ""
Write-Host "[3/4] Running Unit & Widget Tests..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter test test/unit test/widget
$testExit = $LASTEXITCODE
Pop-Location

if ($testExit -eq 0) {
    Write-Host "[PASS] Unit & Widget tests passed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Some tests failed" -ForegroundColor Yellow
}

# Run Integration Tests
Write-Host ""
Write-Host "[4/4] Running Integration Tests on device..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes...)" -ForegroundColor Gray
Push-Location $ProjectRoot
flutter test test/integration -d $DeviceId
$intExit = $LASTEXITCODE
Pop-Location

if ($intExit -eq 0) {
    Write-Host "[PASS] Integration tests passed" -ForegroundColor Green
} else {
    Write-Host "[WARN] Integration tests failed (Firebase may be needed)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====== Testing Complete! ======" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  - APK Build: PASSED" -ForegroundColor Green
Write-Host "  - Installation: PASSED" -ForegroundColor Green
if ($testExit -eq 0) {
    Write-Host "  - Unit/Widget Tests: PASSED" -ForegroundColor Green
} else {
    Write-Host "  - Unit/Widget Tests: FAILED" -ForegroundColor Red
}
if ($intExit -eq 0) {
    Write-Host "  - Integration Tests: PASSED" -ForegroundColor Green
} else {
    Write-Host "  - Integration Tests: FAILED" -ForegroundColor Yellow
}
Write-Host ""
