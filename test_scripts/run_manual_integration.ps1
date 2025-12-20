# Manual Integration Test with Screen Recording
# Launches app on device and records screen while you test manually

param(
    [string]$DeviceId = "5T4HPZOJY56DZ9QG",
    [int]$Duration = 120  # Recording duration in seconds (default 2 minutes)
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$VideosDir = Join-Path $OutputDir "videos"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create directories
if (-not (Test-Path $VideosDir)) { New-Item -ItemType Directory -Path $VideosDir -Force | Out-Null }

Write-Host ""
Write-Host "====== Manual Integration Test Runner ======" -ForegroundColor Cyan
Write-Host ""
Write-Host "Device: $DeviceId" -ForegroundColor Green
Write-Host "Recording Duration: $Duration seconds" -ForegroundColor Green
Write-Host ""

# Add ADB to path
$env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"

# Build and install APK
Write-Host "[1/3] Building APK..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter build apk --debug | Out-Null
$apkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
Pop-Location
Write-Host "  √ Build complete" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Installing app on device..." -ForegroundColor Yellow
adb -s $DeviceId install -r $apkPath | Out-Null
Write-Host "  √ App installed" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Starting screen recording and launching app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  The app will now launch on your phone." -ForegroundColor White
Write-Host "  Screen recording has started ($Duration seconds)." -ForegroundColor White
Write-Host "  " -ForegroundColor White
Write-Host "  Perform your test actions:" -ForegroundColor Yellow
Write-Host "    1. Tap Get Started button" -ForegroundColor White
Write-Host "    2. Navigate to login screen" -ForegroundColor White
Write-Host "    3. Test login functionality" -ForegroundColor White
Write-Host "    4. Test other features as needed" -ForegroundColor White
Write-Host "  " -ForegroundColor White
Write-Host "  Press Ctrl+C when done (or wait $Duration seconds)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

$videoFile = Join-Path $VideosDir "manual_test_$Timestamp.mp4"
$remoteVideo = "/sdcard/manual_test.mp4"

# Start screen recording
$recordJob = Start-Job -ScriptBlock {
    param($device, $remote, $dur)
    $env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"
    adb -s $device shell screenrecord --time-limit $dur $remote
} -ArgumentList $DeviceId, $remoteVideo, $Duration

Start-Sleep -Seconds 2

# Launch the app
$packageName = "com.example.mobile_programming_project"
adb -s $DeviceId shell am start -n "$packageName/.MainActivity" | Out-Null

Write-Host "App launched! Recording in progress..." -ForegroundColor Green
Write-Host ""

# Wait for recording to complete or user interrupt
try {
    Wait-Job -Job $recordJob -Timeout $Duration | Out-Null
} catch {
    Write-Host ""
    Write-Host "Recording stopped by user." -ForegroundColor Yellow
}

# Stop recording gracefully
adb -s $DeviceId shell "pkill -SIGINT screenrecord" 2>&1 | Out-Null
Start-Sleep -Seconds 3

$recordJob | Stop-Job -PassThru | Remove-Job -Force | Out-Null

Write-Host ""
Write-Host "Downloading video from device..." -ForegroundColor Yellow
adb -s $DeviceId pull $remoteVideo $videoFile 2>&1 | Out-Null
adb -s $DeviceId shell rm $remoteVideo 2>&1 | Out-Null

if (Test-Path $videoFile) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  Recording saved successfully!" -ForegroundColor Green
    Write-Host "  " -ForegroundColor White
    Write-Host "  Video: $videoFile" -ForegroundColor Cyan
    Write-Host "  " -ForegroundColor White
    Write-Host "  Opening video..." -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    # Open the video in default player
    Start-Process $videoFile
} else {
    Write-Host ""
    Write-Host "WARNING: Video file not found!" -ForegroundColor Red
    Write-Host "This can happen if:" -ForegroundColor Yellow
    Write-Host "  - Recording was too short" -ForegroundColor Yellow
    Write-Host "  - Device storage is full" -ForegroundColor Yellow
    Write-Host "  - Screen recording permission denied" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
Write-Host ""
