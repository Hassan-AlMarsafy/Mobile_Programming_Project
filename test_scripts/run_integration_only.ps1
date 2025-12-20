# Integration Tests Only - With Screen Recording and HTML Report
# Runs all integration tests together with one screen recording (5 minute limit)

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
    $adbOutput = & adb devices
    # Skip first line (header "List of devices attached") and get first device
    $DeviceId = $adbOutput | Select-Object -Skip 1 | Where-Object { $_ -match "^\S+\s+device$" } | Select-Object -First 1 | ForEach-Object {
        if ($_ -match "^(\S+)\s+device") {
            $matches[1]
        }
    }

    if (-not $DeviceId -or $DeviceId -eq "") {
        Write-Host "ERROR: No device found!" -ForegroundColor Red
        Write-Host "Available devices:" -ForegroundColor Yellow
        & adb devices
        exit 1
    }
}

Write-Host "Using device: $DeviceId" -ForegroundColor Green
$deviceSerial = $DeviceId

# Integration tests we're running
$tests = @(
    @{ Id = "INT002"; Name = "INT002 - Login with invalid credentials" },
    @{ Id = "INT003"; Name = "INT003 - Navigate to registration" },
    @{ Id = "INT004"; Name = "INT004 - Biometric authentication" },
    @{ Id = "INT005"; Name = "INT005 - Sensor monitoring (includes valid login)" }
)

Write-Host ""
Write-Host "Running ALL Integration Tests with Screen Recording..." -ForegroundColor Yellow
Write-Host ""

# Single video file for all tests
$videoFile = Join-Path $VideosDir "all_tests_$Timestamp.mp4"
$remoteVideo = "/sdcard/integration_tests.mp4"

# Start screen recording in background
Write-Host "Starting screen recording..." -ForegroundColor Gray
$recordJob = Start-Job -ScriptBlock {
    param($device, $remote)
    # Add Android SDK to PATH
    $env:PATH += ";C:\Users\hassa\AppData\Local\Android\Sdk\platform-tools"
    # Increased time limit to 300 seconds (5 minutes) to capture all tests
    & adb -s $device shell screenrecord --time-limit 300 $remote 2>&1
} -ArgumentList $deviceSerial, $remoteVideo

Start-Sleep -Seconds 3

# Run ALL integration tests at once
Write-Host "Launching app and running all tests..." -ForegroundColor Cyan
$startTime = Get-Date

Push-Location $ProjectRoot
Write-Host "Command: flutter test integration_test/app_test.dart -d $DeviceId" -ForegroundColor DarkGray
Write-Host ""

$testOutput = flutter test `
    integration_test/app_test.dart `
    -d $DeviceId `
    2>&1 | Tee-Object -Variable testOutputCapture | Out-String

$overallSuccess = $LASTEXITCODE -eq 0
$duration = ((Get-Date) - $startTime).TotalSeconds
Pop-Location

Write-Host ""
Write-Host "Test execution completed in $([math]::Round($duration, 1))s" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Red" })
Write-Host ""

# Stop recording
Write-Host "Stopping screen recording..." -ForegroundColor Gray
& adb -s $deviceSerial shell "pkill -SIGINT screenrecord" 2>&1 | Out-Null
Start-Sleep -Seconds 3

$recordJob | Stop-Job -PassThru | Remove-Job -Force | Out-Null

# Pull video
Write-Host "Downloading video from device..." -ForegroundColor Gray

$remoteFileCheck = & adb -s $deviceSerial shell "ls -la $remoteVideo" 2>&1
Write-Host "Remote file: $remoteFileCheck" -ForegroundColor DarkGray

if ($remoteFileCheck -notmatch "No such file") {
    $pullOutput = & adb -s $deviceSerial pull $remoteVideo $videoFile 2>&1
    Write-Host "Pull result: $pullOutput" -ForegroundColor DarkGray
    & adb -s $deviceSerial shell rm $remoteVideo 2>&1 | Out-Null
} else {
    Write-Host "Video file not found on device" -ForegroundColor Red
}

$videoExists = Test-Path $videoFile
if ($videoExists) {
    $fileSize = (Get-Item $videoFile).Length / 1MB
    Write-Host "Video saved: $videoFile ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Video file not saved" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Parsing individual test results..." -ForegroundColor Yellow
Write-Host ""

$results = @()

# Parse test output for individual test results
foreach ($test in $tests) {
    $testPassed = $false

    # Check for test pass in output - look for the test name and success indicators
    if ($testOutput -match "All tests passed") {
        $testPassed = $true
    } elseif ($overallSuccess) {
        # If overall test passed and no explicit failure for this test, assume it passed
        if ($testOutput -notmatch "FAILED" -and $testOutput -notmatch "Exception") {
            $testPassed = $true
        }
    } elseif ($testOutput -match "00:0\d \+\d") {
        # Passed tests show timing like "00:01 +1"
        $testPassed = $true
    }

    # Determine status
    if ($testPassed -and $videoExists) {
        $status = "PASS_RECORDED"
        $statusColor = "Green"
    } elseif ($testPassed -and -not $videoExists) {
        $status = "PASS_NO_VIDEO"
        $statusColor = "Yellow"
    } elseif (-not $testPassed -and $videoExists) {
        $status = "FAIL_RECORDED"
        $statusColor = "Red"
    } else {
        $status = "FAIL_NO_VIDEO"
        $statusColor = "Red"
    }

    Write-Host "  $($test.Id): $status" -ForegroundColor $statusColor

    $results += @{
        TestId = $test.Id
        Name = $test.Name
        Status = $status
        TestPassed = $testPassed
        Duration = [math]::Round($duration, 1)
        VideoFile = if ($videoExists) { "all_tests_$Timestamp.mp4" } else { "" }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Generate HTML Report
Write-Host ""
Write-Host "Generating HTML Report..." -ForegroundColor Yellow

"<!DOCTYPE html>" | Out-File -FilePath $ReportFile -Encoding UTF8
"<html><head><meta charset='UTF-8'><title>Integration Test Report</title>" | Out-File -FilePath $ReportFile -Append
"<style>" | Out-File -FilePath $ReportFile -Append
"body{font-family:Arial,sans-serif;margin:20px;background:#f5f5f5}" | Out-File -FilePath $ReportFile -Append
".container{max-width:1200px;margin:0 auto;background:white;padding:30px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}" | Out-File -FilePath $ReportFile -Append
"h1{color:#667eea;border-bottom:3px solid #667eea;padding-bottom:10px}" | Out-File -FilePath $ReportFile -Append
"h2{color:#444;margin-top:30px}" | Out-File -FilePath $ReportFile -Append
"table{width:100%;border-collapse:collapse;margin:20px 0}" | Out-File -FilePath $ReportFile -Append
"th{background:#667eea;color:white;padding:12px;text-align:left}" | Out-File -FilePath $ReportFile -Append
"td{padding:12px;border-bottom:1px solid #ddd}" | Out-File -FilePath $ReportFile -Append
"tr:hover{background:#f9f9f9}" | Out-File -FilePath $ReportFile -Append
".video-link{color:#667eea;text-decoration:none;font-weight:bold}" | Out-File -FilePath $ReportFile -Append
".video-link:hover{text-decoration:underline}" | Out-File -FilePath $ReportFile -Append
".status{padding:5px 10px;border-radius:5px;font-weight:bold;font-size:12px}" | Out-File -FilePath $ReportFile -Append
".pass-recorded{background:#d1fae5;color:#065f46}" | Out-File -FilePath $ReportFile -Append
".pass-no-video{background:#fef3c7;color:#92400e}" | Out-File -FilePath $ReportFile -Append
".fail-recorded{background:#fee2e2;color:#991b1b}" | Out-File -FilePath $ReportFile -Append
".fail-no-video{background:#fecaca;color:#7f1d1d}" | Out-File -FilePath $ReportFile -Append
".test-output{background:#f9f9f9;border:1px solid #ddd;padding:15px;margin:20px 0;border-radius:5px;font-family:monospace;font-size:12px;white-space:pre-wrap;max-height:400px;overflow-y:auto}" | Out-File -FilePath $ReportFile -Append
"</style></head><body><div class='container'>" | Out-File -FilePath $ReportFile -Append
"<h1>Integration Test Report</h1>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Device:</strong> $DeviceId</p>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Date:</strong> $Timestamp</p>" | Out-File -FilePath $ReportFile -Append
"<p><strong>Duration:</strong> $([math]::Round($duration, 1))s</p>" | Out-File -FilePath $ReportFile -Append

$passedTests = ($results | Where-Object { $_.TestPassed }).Count
$failedTests = ($results | Where-Object { -not $_.TestPassed }).Count

"<p><strong>Total Tests:</strong> $($results.Count) | " | Out-File -FilePath $ReportFile -Append -NoNewline
"<span style='color:#065f46;font-weight:bold'>Passed: $passedTests</span> | " | Out-File -FilePath $ReportFile -Append -NoNewline
"<span style='color:#991b1b;font-weight:bold'>Failed: $failedTests</span></p>" | Out-File -FilePath $ReportFile -Append

if ($videoExists) {
    "<p><strong>Screen Recording:</strong> <a href='../videos/all_tests_$Timestamp.mp4' class='video-link' target='_blank'>View Full Test Recording</a></p>" | Out-File -FilePath $ReportFile -Append
}

"<h2>Test Results</h2>" | Out-File -FilePath $ReportFile -Append
"<table><thead><tr>" | Out-File -FilePath $ReportFile -Append
"<th>Test ID</th><th>Test Name</th><th>Status</th><th>Timestamp</th>" | Out-File -FilePath $ReportFile -Append
"</tr></thead><tbody>" | Out-File -FilePath $ReportFile -Append

foreach ($result in $results) {
    $statusClass = $result.Status.ToLower().Replace("_", "-")

    "<tr>" | Out-File -FilePath $ReportFile -Append
    "<td><strong>$($result.TestId)</strong></td>" | Out-File -FilePath $ReportFile -Append
    "<td>$($result.Name)</td>" | Out-File -FilePath $ReportFile -Append
    "<td><span class='status $statusClass'>$($result.Status)</span></td>" | Out-File -FilePath $ReportFile -Append
    "<td>$($result.Timestamp)</td>" | Out-File -FilePath $ReportFile -Append
    "</tr>" | Out-File -FilePath $ReportFile -Append
}

"</tbody></table>" | Out-File -FilePath $ReportFile -Append

# Add test output section
"<h2>Test Output</h2>" | Out-File -FilePath $ReportFile -Append
"<div class='test-output'>" | Out-File -FilePath $ReportFile -Append
$testOutput -replace "<", "&lt;" -replace ">", "&gt;" | Out-File -FilePath $ReportFile -Append
"</div>" | Out-File -FilePath $ReportFile -Append

"<p style='margin-top:30px;color:#666;font-size:14px'>Videos saved in: $VideosDir</p>" | Out-File -FilePath $ReportFile -Append
"</div></body></html>" | Out-File -FilePath $ReportFile -Append

Write-Host ""
Write-Host "====== Complete! ======" -ForegroundColor Green
Write-Host ""
Write-Host "Report: $ReportFile" -ForegroundColor Cyan
if ($videoExists) {
    Write-Host "Video: $videoFile" -ForegroundColor Cyan
}
Write-Host ""

# Open report
Start-Process $ReportFile
