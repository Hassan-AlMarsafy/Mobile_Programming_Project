# Automated Flutter Testing Script with Screen Recording and HTML Report
# Author: Auto-generated for Mobile Programming Project
# Date: December 20, 2025

param(
    [string]$BuildMode = "debug",
    [switch]$SkipBuild = $false
)

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$LogsDir = Join-Path $OutputDir "logs"
$VideosDir = Join-Path $OutputDir "videos"
$ReportsDir = Join-Path $OutputDir "reports"
$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-$BuildMode.apk"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $ReportsDir "test_report_$Timestamp.html"
$LogFile = Join-Path $LogsDir "test_log_$Timestamp.txt"

# Define test suites
$TestSuites = @(
    @{
        Id = "UNIT"
        Name = "Unit Tests"
        Description = "All unit tests (models, services, utilities)"
        Type = "suite"
        TestPath = "test/unit"
        RequiresDevice = $false
        RecordScreen = $false
    },
    @{
        Id = "WIDGET"
        Name = "Widget Tests"
        Description = "All widget tests (UI components)"
        Type = "suite"
        TestPath = "test/widget"
        RequiresDevice = $false
        RecordScreen = $false
    }
)

# Define integration test cases (run on devices with screen recording)
$IntegrationTests = @(
    @{
        Id = "INT001"
        Name = "Login Flow Test"
        Description = "Test complete login flow with valid credentials"
        Type = "integration"
        TestPath = "test/integration/app_test.dart"
        TestName = "Complete login flow with valid credentials"
        RequiresDevice = $true
        RecordScreen = $true
    },
    @{
        Id = "INT002"
        Name = "Invalid Login Test"
        Description = "Test login with invalid credentials"
        Type = "integration"
        TestPath = "test/integration/app_test.dart"
        TestName = "Login with invalid credentials shows error"
        RequiresDevice = $true
        RecordScreen = $true
    },
    @{
        Id = "INT003"
        Name = "Navigation Test"
        Description = "Test navigation to registration screen"
        Type = "integration"
        TestPath = "test/integration/app_test.dart"
        TestName = "Navigate to registration screen"
        RequiresDevice = $true
        RecordScreen = $true
    },
    @{
        Id = "INT004"
        Name = "Biometric Auth Test"
        Description = "Test biometric authentication flow"
        Type = "integration"
        TestPath = "test/integration/app_test.dart"
        TestName = "Biometric authentication flow"
        RequiresDevice = $true
        RecordScreen = $true
    },
    @{
        Id = "INT005"
        Name = "Sensor Monitoring Test"
        Description = "Test real-time sensor data viewing"
        Type = "integration"
        TestPath = "test/integration/app_test.dart"
        TestName = "View real-time sensor data"
        RequiresDevice = $true
        RecordScreen = $true
    }
)

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "`n==== $Message ====" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

# Initialize logging
function Initialize-Logging {
    "Test Execution Log - $(Get-Date)" | Out-File -FilePath $LogFile
    "=" * 80 | Out-File -FilePath $LogFile -Append
    "" | Out-File -FilePath $LogFile -Append
}

function Write-Log {
    param([string]$Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $LogMessage | Out-File -FilePath $LogFile -Append
    Write-Info $Message
}

# Step 1: Create directory structure
function Initialize-Directories {
    Write-Step "Initializing Directory Structure"
    
    $Directories = @($OutputDir, $LogsDir, $VideosDir, $ReportsDir)
    
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
            Write-Success "Created directory: $Dir"
        }
    }
    
    Write-Log "Directory structure initialized"
}

# Step 2: Check for connected devices
function Get-ConnectedDevices {
    Write-Step "Detecting Connected Android Devices"
    
    Write-Log "Checking for ADB..."
    
    try {
        $adbCheck = & adb version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "ADB not found"
        }
    }
    catch {
        Write-Error-Custom "ADB not found. Please install Android SDK Platform Tools."
        Write-Log "ERROR: ADB not found"
        exit 1
    }
    
    Write-Log "Running 'adb devices' command..."
    $devicesOutput = & adb devices 2>&1
    
    $devices = @()
    $devicesOutput | ForEach-Object {
        if ($_ -match '^([^\s]+)\s+device$') {
            $devices += $matches[1]
        }
    }
    
    if ($devices.Count -eq 0) {
        Write-Error-Custom "No Android devices connected!"
        Write-Host "`nPlease connect an Android device or start an emulator:" -ForegroundColor Yellow
        Write-Host "  - For physical device: Enable USB debugging in Developer Options" -ForegroundColor Yellow
        Write-Host "  - For emulator: Run 'flutter emulators --launch <emulator_id>'" -ForegroundColor Yellow
        Write-Log "ERROR: No devices detected"
        exit 1
    }
    
    Write-Success "Found $($devices.Count) connected device(s):"
    foreach ($device in $devices) {
        Write-Host "  - $device" -ForegroundColor Green
        Write-Log "Device detected: $device"
        
        # Get device details
        $deviceModel = & adb -s $device shell getprop ro.product.model 2>&1
        $androidVersion = & adb -s $device shell getprop ro.build.version.release 2>&1
        Write-Host "    Model: $deviceModel, Android: $androidVersion" -ForegroundColor Gray
        Write-Log "  Model: $deviceModel, Android: $androidVersion"
    }
    
    return $devices
}

# Step 3: Build APK
function Build-APK {
    if ($SkipBuild) {
        Write-Step "Skipping APK Build (using existing APK)"
        Write-Log "APK build skipped"
        
        if (-not (Test-Path $ApkPath)) {
            Write-Error-Custom "APK not found at: $ApkPath"
            Write-Error-Custom "Run without -SkipBuild flag to build the APK"
            exit 1
        }
        
        return
    }
    
    Write-Step "Building APK ($BuildMode mode)"
    Write-Log "Starting APK build in $BuildMode mode..."
    
    Push-Location $ProjectRoot
    
    try {
        Write-Host "Running: flutter build apk --$BuildMode" -ForegroundColor Gray
        & flutter build apk --$BuildMode
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed"
        }
        
        if (-not (Test-Path $ApkPath)) {
            throw "APK not found after build"
        }
        
        $apkSize = (Get-Item $ApkPath).Length / 1MB
        Write-Success "APK built successfully: $ApkPath ($([math]::Round($apkSize, 2)) MB)"
        Write-Log "APK built successfully: $apkSize MB"
    }
    catch {
        Write-Error-Custom "Failed to build APK: $_"
        Write-Log "ERROR: APK build failed - $_"
        Pop-Location
        exit 1
    }
    finally {
        Pop-Location
    }
}

# Step 4: Install APK on devices
function Install-APK {
    param([array]$Devices)
    
    Write-Step "Installing APK on Connected Devices"
    
    foreach ($device in $Devices) {
        Write-Host "`nInstalling on device: $device" -ForegroundColor Cyan
        Write-Log "Installing APK on device: $device"
        
        try {
            # Uninstall existing app first
            Write-Host "  Uninstalling existing app..." -ForegroundColor Gray
            & adb -s $device uninstall com.example.hydroponic_app 2>&1 | Out-Null
            
            # Install new APK
            Write-Host "  Installing APK..." -ForegroundColor Gray
            $installOutput = & adb -s $device install -r $ApkPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  Installed successfully on $device"
                Write-Log "APK installed successfully on $device"
            }
            else {
                Write-Error-Custom "  Failed to install on $device"
                Write-Log "ERROR: APK installation failed on $device"
            }
        }
        catch {
            Write-Error-Custom "  Installation error: $_"
            Write-Log "ERROR: Installation error on $device - $_"
        }
    }
}

# Step 5: Start screen recording
function Start-ScreenRecording {
    param(
        [string]$DeviceId,
        [string]$TestId,
        [string]$OutputFile
    )
    
    Write-Log "Starting screen recording for $TestId on $DeviceId"
    
    $remoteFile = "/sdcard/$TestId.mp4"
    
    # Start recording in background
    $recordJob = Start-Job -ScriptBlock {
        param($device, $remote)
        & adb -s $device shell screenrecord --time-limit 180 $remote 2>&1
    } -ArgumentList $DeviceId, $remoteFile
    
    Start-Sleep -Seconds 2  # Give recording time to start
    
    return @{
        Job = $recordJob
        RemoteFile = $remoteFile
        OutputFile = $OutputFile
    }
}

# Step 6: Stop screen recording and pull file
function Stop-ScreenRecording {
    param([hashtable]$RecordingInfo, [string]$DeviceId)
    
    Write-Log "Stopping screen recording on $DeviceId"
    
    # Stop recording by killing the process
    & adb -s $DeviceId shell "pkill -SIGINT screenrecord" 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    
    # Wait for job to complete (with timeout)
    $RecordingInfo.Job | Wait-Job -Timeout 5 | Out-Null
    $RecordingInfo.Job | Remove-Job -Force | Out-Null
    
    # Pull the video file
    Write-Host "  Pulling video file..." -ForegroundColor Gray
    & adb -s $DeviceId pull $RecordingInfo.RemoteFile $RecordingInfo.OutputFile 2>&1 | Out-Null
    
    # Clean up remote file
    & adb -s $DeviceId shell rm $RecordingInfo.RemoteFile 2>&1 | Out-Null
    
    if (Test-Path $RecordingInfo.OutputFile) {
        $videoSize = (Get-Item $RecordingInfo.OutputFile).Length / 1KB
        Write-Log "Video saved: $($RecordingInfo.OutputFile) ($([math]::Round($videoSize, 2)) KB)"
        return $true
    }
    else {
        Write-Log "WARNING: Video file not found"
        return $false
    }
}

# Step 7a: Run unit and widget tests
function Run-TestSuites {
    Write-Step "Running Unit and Widget Tests"
    
    $testResults = @()
    
    foreach ($suite in $TestSuites) {
        Write-Host "`n==== Running: $($suite.Name) ====" -ForegroundColor Magenta
        Write-Log "Starting test suite: $($suite.Id) - $($suite.Name)"
        
        $testStartTime = Get-Date
        
        try {
            Push-Location $ProjectRoot
            
            Write-Host "  Executing: flutter test $($suite.TestPath)" -ForegroundColor Gray
            $testOutput = & flutter test $suite.TestPath 2>&1
            
            $testEndTime = Get-Date
            $duration = ($testEndTime - $testStartTime).TotalSeconds
            
            # Parse test output for pass/fail counts
            $passCount = 0
            $failCount = 0
            
            if ($testOutput -match '\+(\d+)') {
                $passCount = [int]$matches[1]
            }
            if ($testOutput -match '-(\d+)') {
                $failCount = [int]$matches[1]
            }
            
            # Check if tests passed
            $status = "FAIL"
            if ($LASTEXITCODE -eq 0 -or $testOutput -match "All tests passed") {
                $status = "PASS"
                Write-Success "  Suite PASSED: $passCount tests passed ($([math]::Round($duration, 2))s)"
            }
            else {
                Write-Error-Custom "  Suite FAILED: $passCount passed, $failCount failed ($([math]::Round($duration, 2))s)"
            }
            
            Write-Log "Test suite $($suite.Id) result: $status (Duration: $([math]::Round($duration, 2))s, Passed: $passCount, Failed: $failCount)"
            
            # Save test output to log
            "`n========================================" | Out-File -FilePath $LogFile -Append
            "Test Suite: $($suite.Id) - $($suite.Name)" | Out-File -FilePath $LogFile -Append
            "========================================" | Out-File -FilePath $LogFile -Append
            $testOutput | Out-File -FilePath $LogFile -Append
            "`n" | Out-File -FilePath $LogFile -Append
            
            # Store test result
            $testResults += @{
                TestId = $suite.Id
                Name = $suite.Name
                Description = "$($suite.Description) ($passCount passed, $failCount failed)"
                Device = "N/A (Local)"
                Status = $status
                Duration = [math]::Round($duration, 2)
                VideoPath = ""
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Type = "suite"
            }
        }
        catch {
            $duration = ((Get-Date) - $testStartTime).TotalSeconds
            $status = "ERROR"
            Write-Error-Custom "  Suite ERROR: $_"
            Write-Log "ERROR: Test suite $($suite.Id) - $_"
            
            $testResults += @{
                TestId = $suite.Id
                Name = $suite.Name
                Description = $suite.Description
                Device = "N/A (Local)"
                Status = $status
                Duration = [math]::Round($duration, 2)
                VideoPath = ""
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Type = "suite"
            }
        }
        finally {
            Pop-Location
        }
    }
    
    return $testResults
}

# Step 7b: Run integration tests on devices
function Run-IntegrationTests {
    param([array]$Devices)
    
    Write-Step "Running Integration Tests on Devices"
    
    $testResults = @()
    
    foreach ($device in $Devices) {
        Write-Host "`n==== Testing on Device: $device ====" -ForegroundColor Magenta
        Write-Log "Starting integration tests on device: $device"
        
        foreach ($test in $IntegrationTests) {
            Write-Host "`n  Running: $($test.Name) ($($test.Id))" -ForegroundColor Cyan
            Write-Log "Running test: $($test.Id) - $($test.Name)"
            
            $videoFile = Join-Path $VideosDir "$($test.Id)_${device}_$Timestamp.mp4"
            $relativeVideoPath = "videos/$($test.Id)_${device}_$Timestamp.mp4"
            
            # Start screen recording
            $recording = Start-ScreenRecording -DeviceId $device -TestId $test.Id -OutputFile $videoFile
            
            # Run the test
            $testStartTime = Get-Date
            
            try {
                Push-Location $ProjectRoot
                
                # Run flutter drive for integration tests
                Write-Host "  Executing test..." -ForegroundColor Gray
                $testOutput = & flutter drive `
                    --driver=test_driver/integration_test.dart `
                    --target=$($test.TestPath) `
                    -d $device `
                    2>&1
                
                $testEndTime = Get-Date
                $duration = ($testEndTime - $testStartTime).TotalSeconds
                
                # Check if test passed
                $status = "FAIL"
                if ($LASTEXITCODE -eq 0 -and $testOutput -match "All tests passed") {
                    $status = "PASS"
                    Write-Success "  Test PASSED ($([math]::Round($duration, 2))s)"
                }
                else {
                    Write-Error-Custom "  Test FAILED ($([math]::Round($duration, 2))s)"
                }
                
                Write-Log "Test $($test.Id) result: $status (Duration: $([math]::Round($duration, 2))s)"
                
                # Save test output to log
                "`n========================================" | Out-File -FilePath $LogFile -Append
                "Integration Test: $($test.Id) - $($test.Name)" | Out-File -FilePath $LogFile -Append
                "Device: $device" | Out-File -FilePath $LogFile -Append
                "========================================" | Out-File -FilePath $LogFile -Append
                $testOutput | Out-File -FilePath $LogFile -Append
                "`n" | Out-File -FilePath $LogFile -Append
            }
            catch {
                $status = "ERROR"
                $duration = ((Get-Date) - $testStartTime).TotalSeconds
                Write-Error-Custom "  Test ERROR: $_"
                Write-Log "ERROR: Test $($test.Id) - $_"
            }
            finally {
                Pop-Location
                
                # Stop screen recording
                Start-Sleep -Seconds 1
                $videoExists = Stop-ScreenRecording -RecordingInfo $recording -DeviceId $device
            }
            
            # Store test result
            $testResults += @{
                TestId = $test.Id
                Name = $test.Name
                Description = $test.Description
                Device = $device
                Status = $status
                Duration = [math]::Round($duration, 2)
                VideoPath = if ($videoExists) { $relativeVideoPath } else { "" }
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Type = "integration"
            }
        }
    }
    
    return $testResults
}

# Step 8: Generate HTML report
function Generate-HTMLReport {
    param([array]$TestResults)
    
    Write-Step "Generating HTML Report"
    Write-Log "Generating HTML report: $ReportFile"
    
    $passCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($TestResults | Where-Object { $_.Status -eq "ERROR" }).Count
    $totalCount = $TestResults.Count
    $passRate = if ($totalCount -gt 0) { [math]::Round(($passCount / $totalCount) * 100, 2) } else { 0 }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Integration Test Report - $Timestamp</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }
        
        .summary-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }
        
        .summary-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 12px rgba(0,0,0,0.15);
        }
        
        .summary-card h3 {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }
        
        .summary-card .value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .summary-card.total .value { color: #667eea; }
        .summary-card.pass .value { color: #10b981; }
        .summary-card.fail .value { color: #ef4444; }
        .summary-card.error .value { color: #f59e0b; }
        .summary-card.rate .value { color: #8b5cf6; }
        
        .content {
            padding: 40px;
        }
        
        .content h2 {
            color: #333;
            margin-bottom: 25px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
            font-size: 1.8em;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        th {
            padding: 18px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.85em;
            letter-spacing: 0.5px;
        }
        
        td {
            padding: 18px;
            border-bottom: 1px solid #e5e7eb;
        }
        
        tbody tr {
            transition: background-color 0.2s;
        }
        
        tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        tbody tr:last-child td {
            border-bottom: none;
        }
        
        .status {
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 0.85em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .status.pass {
            background-color: #d1fae5;
            color: #065f46;
        }
        
        .status.fail {
            background-color: #fee2e2;
            color: #991b1b;
        }
        
        .status.error {
            background-color: #fed7aa;
            color: #92400e;
        }
        
        .video-link {
            display: inline-block;
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
            padding: 8px 16px;
            border: 2px solid #667eea;
            border-radius: 5px;
            transition: all 0.3s;
        }
        
        .video-link:hover {
            background-color: #667eea;
            color: white;
            transform: scale(1.05);
        }
        
        .no-video {
            color: #9ca3af;
            font-style: italic;
        }
        
        .footer {
            background: #f8f9fa;
            padding: 30px;
            text-align: center;
            color: #6b7280;
            border-top: 1px solid #e5e7eb;
        }
        
        .device-badge {
            display: inline-block;
            background: #e0e7ff;
            color: #4338ca;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85em;
            font-weight: 500;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
            }
            
            .video-link {
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Flutter Test Report - Complete Suite</h1>
            <p>Mobile Programming Project - Hydroponic App</p>
            <p style="font-size: 1em; margin-top: 5px;">Unit Tests • Widget Tests • Integration Tests</p>
            <p style="font-size: 0.9em; margin-top: 10px;">Generated: $Timestamp</p>
        </div>
        
        <div class="summary">
            <div class="summary-card total">
                <h3>Total Tests</h3>
                <div class="value">$totalCount</div>
            </div>
            <div class="summary-card pass">
                <h3>Passed</h3>
                <div class="value">$passCount</div>
            </div>
            <div class="summary-card fail">
                <h3>Failed</h3>
                <div class="value">$failCount</div>
            </div>
            <div class="summary-card error">
                <h3>Errors</h3>
                <div class="value">$errorCount</div>
            </div>
            <div class="summary-card rate">
                <h3>Pass Rate</h3>
                <div class="value">$passRate%</div>
            </div>
        </div>
        
        <div class="content">
            <h2>📊 Test Results (All Suites)</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test ID</th>
                        <th>Test Name</th>
                        <th>Description</th>
                        <th>Device</th>
                        <th>Status</th>
                        <th>Duration (s)</th>
                        <th>Timestamp</th>
                        <th>Screen Recording</th>
                    </tr>
                </thead>
                <tbody>
"@
    
    foreach ($result in $TestResults) {
        $statusClass = $result.Status.ToLower()
        $videoCell = if ($result.VideoPath) {
            "<a href='$($result.VideoPath)' class='video-link' target='_blank'>📹 View Recording</a>"
        } else {
            "<span class='no-video'>No video</span>"
        }
        
        $deviceShort = $result.Device -replace '^emulator-', 'emu-'
        
        $html += @"
                    <tr>
                        <td><strong>$($result.TestId)</strong></td>
                        <td>$($result.Name)</td>
                        <td>$($result.Description)</td>
                        <td><span class="device-badge">$deviceShort</span></td>
                        <td><span class="status $statusClass">$($result.Status)</span></td>
                        <td>$($result.Duration)</td>
                        <td>$($result.Timestamp)</td>
                        <td>$videoCell</td>
                    </tr>
"@
    }
    
    $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p><strong>Log File:</strong> $LogFile</p>
            <p style="margin-top: 10px;">Generated by PowerShell Automated Testing Script</p>
            <p style="margin-top: 5px; font-size: 0.9em;">© 2025 Mobile Programming Project</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-Success "HTML Report generated: $ReportFile"
    Write-Log "HTML report generated successfully"
    
    # Open report in browser
    Start-Process $ReportFile
}

# Main execution
function Main {
    Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║     Flutter Integration Testing Automation Script             ║
║     Mobile Programming Project - Hydroponic App               ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
    
    Initialize-Directories
    Initialize-Logging
    
    $devices = Get-ConnectedDevices
    
    Build-APK
    
    Install-APK -Devices $devices
    
    # Run unit and widget tests first (no device needed)
    Write-Host "`n" -NoNewline
    $allTestResults = Run-TestSuites
    
    # Then run integration tests on devices
    Write-Host "`n⚠️  NOTE: Integration tests with screen recording require:" -ForegroundColor Yellow
    Write-Host "  - Test driver setup (test_driver/integration_test.dart)" -ForegroundColor Yellow
    Write-Host "  - Tests must be runnable with 'flutter drive'" -ForegroundColor Yellow
    Write-Host "`nPress Enter to continue with integration tests or Ctrl+C to stop..." -ForegroundColor Yellow
    Read-Host
    
    $integrationResults = Run-IntegrationTests -Devices $devices
    $allTestResults += $integrationResults
    
    Generate-HTMLReport -TestResults $allTestResults
    
    Write-Host "`n" -NoNewline
    Write-Step "Testing Complete!"
    Write-Host "`nResults Summary:" -ForegroundColor Cyan
    Write-Host "  - HTML Report: $ReportFile" -ForegroundColor Green
    Write-Host "  - Log File: $LogFile" -ForegroundColor Green
    Write-Host "  - Videos Directory: $VideosDir" -ForegroundColor Green
    Write-Host "`n✨ All done! The HTML report should open automatically.`n" -ForegroundColor Green
}

# Run the script
Main
