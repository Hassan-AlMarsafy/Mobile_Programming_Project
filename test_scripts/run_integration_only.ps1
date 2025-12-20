# Integration Tests Only - With Screen Recording and HTML Report
# Runs integration tests on device with screen recording

param(
    [string]$DeviceId = ""
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$VideosDir = Join-Path $OutputDir "videos"
$ReportsDir = Join-Path $OutputDir "reports"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $ReportsDir "integration_report_$Timestamp.html"

# Create directories
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
if (-not (Test-Path $VideosDir)) { New-Item -ItemType Directory -Path $VideosDir -Force | Out-Null }
if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }

Write-Host ""
Write-Host "====== Integration Test Runner with Screen Recording ======" -ForegroundColor Cyan
Write-Host ""

# Get device
if ($DeviceId -eq "") {
    $DeviceId = "5T4HPZOJY56DZ9QG"
}

Write-Host "Using device: $DeviceId" -ForegroundColor Green

# Get device serial (for adb commands)
$deviceSerial = $DeviceId

# Integration tests to run
$tests = @(
    @{ Id = "INT001"; Name = "Login with valid credentials" },
    @{ Id = "INT002"; Name = "Login with invalid credentials" },
    @{ Id = "INT003"; Name = "Navigate to registration" },
    @{ Id = "INT004"; Name = "Biometric authentication" },
    @{ Id = "INT005"; Name = "Sensor monitoring" }
)

$results = @()

Write-Host ""
Write-Host "Skipping build/install - using existing app on device" -ForegroundColor Gray
Write-Host ""
Write-Host "Running Integration Tests with Screen Recording..." -ForegroundColor Yellow
Write-Host ""

foreach ($test in $tests) {
    Write-Host "Running: $($test.Name) ($($test.Id))..." -ForegroundColor Cyan
    
    $videoFile = Join-Path $VideosDir "$($test.Id)_$Timestamp.mp4"
    $remoteVideo = "/sdcard/test_$($test.Id).mp4"
    
    # Start screen recording in background
    Write-Host "  - Starting screen recording..." -ForegroundColor Gray
    $recordJob = Start-Job -ScriptBlock {
        param($device, $remote)
        $env:PATH += ";E:\Flutter_install\flutter\bin\cache\dart-sdk\bin;C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"
        & adb -s $device shell screenrecord --time-limit 180 $remote 2>&1
    } -ArgumentList $deviceSerial, $remoteVideo
    
    Start-Sleep -Seconds 3
    
    # Run the app on device with flutter drive (proper way for integration tests)
    Write-Host "  - Launching app and running test..." -ForegroundColor Gray
    $startTime = Get-Date
    
    Push-Location $ProjectRoot
    # Use flutter drive which keeps the app running
    $testOutput = flutter drive `
        --driver=test_driver/integration_test.dart `
        --target=test/integration/app_test.dart `
        -d $DeviceId `
        2>&1
    
    $duration = ((Get-Date) - $startTime).TotalSeconds
    Pop-Location
    
    # Stop recording
    Write-Host "  - Stopping screen recording..." -ForegroundColor Gray
    $env:PATH += ";C:\Users\mazen\AppData\Local\Android\Sdk\platform-tools"
    & adb -s $deviceSerial shell "pkill -SIGINT screenrecord" 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    
    $recordJob | Stop-Job -PassThru | Remove-Job -Force | Out-Null
    
    # Pull video
    Write-Host "  - Downloading video..." -ForegroundColor Gray
    & adb -s $deviceSerial pull $remoteVideo $videoFile 2>&1 | Out-Null
    & adb -s $deviceSerial shell rm $remoteVideo 2>&1 | Out-Null
    
    $videoExists = Test-Path $videoFile
    $status = if ($videoExists) { "RECORDED" } else { "NO_VIDEO" }
    
    Write-Host "  - Status: $status" -ForegroundColor $(if ($videoExists) { "Green" } else { "Yellow" })
    Write-Host ""
    
    $results += @{
        TestId = $test.Id
        Name = $test.Name
        Status = $status
        Duration = [math]::Round($duration, 1)
        VideoFile = if ($videoExists) { "$($test.Id)_$Timestamp.mp4" } else { "" }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Generate HTML Report
Write-Host "Generating HTML Report..." -ForegroundColor Yellow

"<!DOCTYPE html>" | Out-File -FilePath $ReportFile -Encoding UTF8
"<html><head><meta charset='UTF-8'><title>Integration Test Report</title>" | Out-File -FilePath $ReportFile -Append
"<style>" | Out-File -FilePath $ReportFile -Append
"body{font-family:Arial,sans-serif;margin:20px;background:#f5f5f5}" | Out-File -FilePath $ReportFile -Append
".container{max-width:1200px;margin:0 auto;background:white;padding:30px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}" | Out-File -FilePath $ReportFile -Append
"h1{color:#667eea;border-bottom:3px solid #667eea;padding-bottom:10px}" | Out-File -FilePath $ReportFile -Append
"table{width:100%;border-collapse:collapse;margin:20px 0}" | Out-File -FilePath $ReportFile -Append
"th{background:#667eea;color:white;padding:12px;text-align:left}" | Out-File -FilePath $ReportFile -Append
"td{padding:12px;border-bottom:1px solid #ddd}" | Out-File -FilePath $ReportFile -Append
"tr:hover{background:#f9f9f9}" | Out-File -FilePath $ReportFile -Append
".video-link{color:#667eea;text-decoration:none;font-weight:bold}" | Out-File -FilePath $ReportFile -Append
".video-link:hover{text-decoration:underline}" | Out-File -FilePath $ReportFile -Append
".status{padding:5px 10px;border-radius:5px;font-weight:bold}" | Out-File -FilePath $ReportFile -Append
".recorded{background:#d1fae5;color:#065f46}" | Out-File -FilePath $ReportFile -Append
".no-video{background:#fed7aa;color:#92400e}" | Out-File -FilePath $ReportFile -Append
"</style></head><body><div class='container'>" | Out-File -FilePath $ReportFile -Append
"<h1>Integration Test Report with Screen Recordings</h1>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Device:</strong> $DeviceId</p>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Date:</strong> $Timestamp</p>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Total Tests:</strong> $($results.Count)</p>" | Out-File -FilePath $ReportFile -Append
"<table><thead><tr>" | Out-File -FilePath $ReportFile -Append
"<th>Test ID</th><th>Test Name</th><th>Status</th><th>Duration (s)</th><th>Timestamp</th><th>Screen Recording</th>" | Out-File -FilePath $ReportFile -Append
"</tr></thead><tbody>" | Out-File -FilePath $ReportFile -Append

foreach ($result in $results) {
    $statusClass = $result.Status.ToLower().Replace("_", "-")
    $videoLink = if ($result.VideoFile) {
        "<a href='../videos/$($result.VideoFile)' class='video-link' target='_blank'>View Video</a>"
    } else {
        "<span style='color:#999'>No video</span>"
    }
    
    "<tr>" | Out-File -FilePath $ReportFile -Append
    "<td><strong>$($result.TestId)</strong></td>" | Out-File -FilePath $ReportFile -Append
    "<td>$($result.Name)</td>" | Out-File -FilePath $ReportFile -Append
    "<td><span class='status $statusClass'>$($result.Status)</span></td>" | Out-File -FilePath $ReportFile -Append
    "<td>$($result.Duration)</td>" | Out-File -FilePath $ReportFile -Append
    "<td>$($result.Timestamp)</td>" | Out-File -FilePath $ReportFile -Append
    "<td>$videoLink</td>" | Out-File -FilePath $ReportFile -Append
    "</tr>" | Out-File -FilePath $ReportFile -Append
}

"</tbody></table>" | Out-File -FilePath $ReportFile -Append
"<p style='margin-top:30px;color:#666;font-size:14px'>Videos saved in: $VideosDir</p>" | Out-File -FilePath $ReportFile -Append
"</div></body></html>" | Out-File -FilePath $ReportFile -Append

Write-Host ""
Write-Host "====== Complete! ======" -ForegroundColor Green
Write-Host ""
Write-Host "Report: $ReportFile" -ForegroundColor Cyan
Write-Host "Videos: $VideosDir" -ForegroundColor Cyan
Write-Host ""

# Open report
Start-Process $ReportFile
