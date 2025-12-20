# Simple Integration Test with Screen Recording
# Just records your screen while you manually test the app

$DeviceId = "5T4HPZOJY56DZ9QG"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output\videos"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$VideoFile = Join-Path $OutputDir "test_recording_$Timestamp.mp4"
$RemoteVideo = "/sdcard/test_recording.mp4"

# Create output directory
if (-not (Test-Path $OutputDir)) { 
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null 
}

# Add ADB to path
$env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"

Write-Host ""
Write-Host "====== Simple Integration Test Recorder ======" -ForegroundColor Cyan
Write-Host ""

# Clear any existing recording
Write-Host "Preparing device..." -ForegroundColor Yellow
adb -s $DeviceId shell "rm -f $RemoteVideo" 2>&1 | Out-Null

# Start screen recording in background
Write-Host "Starting screen recording..." -ForegroundColor Yellow
Start-Process -FilePath "adb" -ArgumentList "-s", $DeviceId, "shell", "/system/bin/screenrecord", "--time-limit", "180", $RemoteVideo -NoNewWindow -PassThru | Out-Null

Start-Sleep -Seconds 2

# Launch the app
Write-Host "Launching app on your phone..." -ForegroundColor Yellow
$packageName = "com.example.first_project"
adb -s $DeviceId shell am start -n "$packageName/.MainActivity" | Out-Null

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  RECORDING IN PROGRESS!" -ForegroundColor Green
Write-Host ""
Write-Host "  Your app should now be open on your phone." -ForegroundColor White
Write-Host "  The screen is being recorded." -ForegroundColor White
Write-Host ""
Write-Host "  Test your app now:" -ForegroundColor Yellow
Write-Host "    - Tap buttons" -ForegroundColor Gray
Write-Host "    - Navigate through screens" -ForegroundColor Gray
Write-Host "    - Test login/features" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press ENTER when done testing..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# Wait for user
Read-Host "Press ENTER to stop recording"

# Stop recording
Write-Host ""
Write-Host "Stopping recording..." -ForegroundColor Yellow
adb -s $DeviceId shell "pkill -SIGINT screenrecord" 2>&1 | Out-Null
Start-Sleep -Seconds 3

# Download video
Write-Host "Downloading video from device..." -ForegroundColor Yellow
adb -s $DeviceId pull $RemoteVideo $VideoFile 2>&1 | Out-Null

# Cleanup device
adb -s $DeviceId shell "rm -f $RemoteVideo" 2>&1 | Out-Null

if (Test-Path $VideoFile) {
    $fileSize = (Get-Item $VideoFile).Length
    if ($fileSize -gt 1000) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "  SUCCESS! Video saved:" -ForegroundColor Green
        Write-Host ""
        Write-Host "  $VideoFile" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Opening video..." -ForegroundColor Gray
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        
        # Open video
        Start-Process $VideoFile
    } else {
        Write-Host ""
        Write-Host "WARNING: Video file too small ($fileSize bytes)" -ForegroundColor Yellow
        Write-Host "Recording may have failed. Try again." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "ERROR: Video file not created!" -ForegroundColor Red
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "  - Screen recording permission denied on device" -ForegroundColor Gray
    Write-Host "  - Device storage full" -ForegroundColor Gray
    Write-Host "  - Recording stopped too quickly" -ForegroundColor Gray
}

Write-Host ""
