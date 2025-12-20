# Manual Integration Test with Screen Recording
# You manually test the app while it records the screen

param(
    [string]$TestName = "integration_test",
    [int]$RecordSeconds = 60
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$VideosDir = Join-Path $OutputDir "videos"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Setup ADB
$env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"

# Create directories
if (-not (Test-Path $VideosDir)) { New-Item -ItemType Directory -Path $VideosDir -Force | Out-Null }

Write-Host ""
Write-Host "====== Manual Integration Test with Screen Recording ======" -ForegroundColor Cyan
Write-Host ""

# Get device
$deviceOutput = adb devices
Write-Host $deviceOutput
$devices = $deviceOutput | Select-String -Pattern "(\S+)\s+device$" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($devices.Count -eq 0) {
    Write-Host "[ERROR] No device connected!" -ForegroundColor Red
    exit 1
}

$deviceId = $devices[0]
Write-Host "Using device: $deviceId" -ForegroundColor Green
Write-Host ""

# Build and install
Write-Host "[1/3] Building APK..." -ForegroundColor Yellow
Push-Location $ProjectRoot
flutter build apk --debug | Out-Null
Pop-Location

$apkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "[2/3] Installing APK on device..." -ForegroundColor Yellow
adb -s $deviceId install -r $apkPath

Write-Host ""
Write-Host "[3/3] Starting Screen Recording..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Cyan
Write-Host "  1. Screen recording will start in 3 seconds" -ForegroundColor White
Write-Host "  2. Manually open and test the app on your phone" -ForegroundColor White
Write-Host "  3. Recording will stop after $RecordSeconds seconds" -ForegroundColor White
Write-Host "  4. Video will be saved automatically" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to start recording..." -ForegroundColor Yellow
Read-Host

$videoFile = Join-Path $VideosDir "${TestName}_$Timestamp.mp4"
$remoteVideo = "/sdcard/screenrecord_$Timestamp.mp4"

Write-Host "Recording started! ($RecordSeconds seconds)" -ForegroundColor Green
Write-Host "Testing on your phone NOW..." -ForegroundColor Yellow

# Start recording
$recordJob = Start-Job -ScriptBlock {
    param($device, $remote, $duration)
    $env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"
    adb -s $device shell screenrecord --time-limit $duration $remote
} -ArgumentList $deviceId, $remoteVideo, $RecordSeconds

# Wait for recording
Wait-Job $recordJob | Out-Null
Remove-Job $recordJob

Write-Host ""
Write-Host "Recording stopped!" -ForegroundColor Green
Write-Host "Downloading video..." -ForegroundColor Yellow

# Pull video
adb -s $deviceId pull $remoteVideo $videoFile
adb -s $deviceId shell rm $remoteVideo

if (Test-Path $videoFile) {
    $fileSize = (Get-Item $videoFile).Length / 1MB
    Write-Host ""
    Write-Host "====== Success! ======" -ForegroundColor Green
    Write-Host ""
    Write-Host "Video saved: $videoFile" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    
    # Open video
    Start-Process $videoFile
} else {
    Write-Host ""
    Write-Host "[ERROR] Video file not found!" -ForegroundColor Red
}
