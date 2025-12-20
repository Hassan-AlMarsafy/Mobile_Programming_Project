# Quick Test Runner - Run all tests (unit, widget, integration) locally
# Uses a template file for HTML to avoid PowerShell parsing issues

param(
    [switch]$SkipIntegration = $false
)

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$LogsDir = Join-Path $OutputDir "logs"
$ReportsDir = Join-Path $OutputDir "reports"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $ReportsDir "test_report_$Timestamp.html"
$LogFile = Join-Path $LogsDir "test_log_$Timestamp.txt"

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "`n==== $Message ====" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

# Create directories
function Initialize-Directories {
    $Directories = @($OutputDir, $LogsDir, $ReportsDir)
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        }
    }
}

# Run tests
function Run-AllTests {
    "Test Execution Log - $(Get-Date)" | Out-File -FilePath $LogFile
    "=" * 80 | Out-File -FilePath $LogFile -Append
    "" | Out-File -FilePath $LogFile -Append
    
    $allResults = @()
    
    # Test suites to run
    $testSuites = @(
        @{ Name = "Unit Tests"; Path = "test/unit"; Id = "UNIT" },
        @{ Name = "Widget Tests"; Path = "test/widget"; Id = "WIDGET" }
    )
    
    if (-not $SkipIntegration) {
        $testSuites += @{ Name = "Integration Tests"; Path = "test/integration"; Id = "INT" }
    }
    
    foreach ($suite in $testSuites) {
        Write-Step "Running $($suite.Name)"
        
        $startTime = Get-Date
        
        Push-Location $ProjectRoot
        $output = & flutter test $suite.Path 2>&1
        $exitCode = $LASTEXITCODE
        Pop-Location
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        # Parse results
        $passCount = 0
        $failCount = 0
        
        if ($output -match '\+(\d+)') {
            $passCount = [int]$matches[1]
        }
        if ($output -match '-(\d+)') {
            $failCount = [int]$matches[1]
        }
        
        $status = if ($exitCode -eq 0 -or $output -match "All tests passed") { "PASS" } else { "FAIL" }
        
        if ($status -eq "PASS") {
            Write-Success "$($suite.Name): $passCount tests passed in $([math]::Round($duration, 2))s"
        } else {
            Write-Error-Custom "$($suite.Name): $passCount passed, $failCount failed in $([math]::Round($duration, 2))s"
        }
        
        # Log
        "`n========================================" | Out-File -FilePath $LogFile -Append
        "$($suite.Name)" | Out-File -FilePath $LogFile -Append
        "========================================" | Out-File -FilePath $LogFile -Append
        $output | Out-File -FilePath $LogFile -Append
        "" | Out-File -FilePath $LogFile -Append
        
        # Store result
        $allResults += @{
            TestId = $suite.Id
            Name = $suite.Name
            Description = "$passCount passed, $failCount failed"
            Status = $status
            Duration = [math]::Round($duration, 2)
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            PassCount = $passCount
            FailCount = $failCount
        }
    }
    
    return $allResults
}

# Generate HTML report
function Generate-Report {
    param([array]$Results)
    
    $passCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $totalCount = $Results.Count
    $totalTests = ($Results | ForEach-Object { $_.PassCount + $_.FailCount } | Measure-Object -Sum).Sum
    $totalPassedTests = ($Results | ForEach-Object { $_.PassCount } | Measure-Object -Sum).Sum
    $passRate = if ($totalTests -gt 0) { [math]::Round(($totalPassedTests / $totalTests) * 100, 2) } else { 0 }
    
    # Write HTML header
    "<!DOCTYPE html>" | Out-File -FilePath $ReportFile -Encoding UTF8
    "<html><head><meta charset='UTF-8'>" | Out-File -FilePath $ReportFile -Append
    "<title>Flutter Test Report - $Timestamp</title>" | Out-File -FilePath $ReportFile -Append
    "<style>" | Out-File -FilePath $ReportFile -Append
    "* { margin: 0; padding: 0; box-sizing: border-box; }" | Out-File -FilePath $ReportFile -Append
    "body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }" | Out-File -FilePath $ReportFile -Append
    ".container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden; }" | Out-File -FilePath $ReportFile -Append
    ".header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; }" | Out-File -FilePath $ReportFile -Append
    ".header h1 { font-size: 2.5em; margin-bottom: 10px; }" | Out-File -FilePath $ReportFile -Append
    ".summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 20px; padding: 40px; background: #f8f9fa; }" | Out-File -FilePath $ReportFile -Append
    ".summary-card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); text-align: center; }" | Out-File -FilePath $ReportFile -Append
    ".summary-card h3 { color: #666; font-size: 0.9em; text-transform: uppercase; margin-bottom: 10px; }" | Out-File -FilePath $ReportFile -Append
    ".summary-card .value { font-size: 2.5em; font-weight: bold; margin: 10px 0; }" | Out-File -FilePath $ReportFile -Append
    ".total .value { color: #667eea; }" | Out-File -FilePath $ReportFile -Append
    ".pass .value { color: #10b981; }" | Out-File -FilePath $ReportFile -Append
    ".fail .value { color: #ef4444; }" | Out-File -FilePath $ReportFile -Append
    ".rate .value { color: #8b5cf6; }" | Out-File -FilePath $ReportFile -Append
    ".tests .value { color: #f59e0b; }" | Out-File -FilePath $ReportFile -Append
    ".content { padding: 40px; }" | Out-File -FilePath $ReportFile -Append
    ".content h2 { color: #333; margin-bottom: 25px; padding-bottom: 10px; border-bottom: 3px solid #667eea; }" | Out-File -FilePath $ReportFile -Append
    "table { width: 100%; border-collapse: collapse; margin-top: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }" | Out-File -FilePath $ReportFile -Append
    "thead { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }" | Out-File -FilePath $ReportFile -Append
    "th { padding: 18px; text-align: left; font-weight: 600; text-transform: uppercase; font-size: 0.85em; }" | Out-File -FilePath $ReportFile -Append
    "td { padding: 18px; border-bottom: 1px solid #e5e7eb; }" | Out-File -FilePath $ReportFile -Append
    "tbody tr:hover { background-color: #f8f9fa; }" | Out-File -FilePath $ReportFile -Append
    ".status { display: inline-block; padding: 6px 16px; border-radius: 20px; font-weight: 600; font-size: 0.85em; text-transform: uppercase; }" | Out-File -FilePath $ReportFile -Append
    ".status.pass { background-color: #d1fae5; color: #065f46; }" | Out-File -FilePath $ReportFile -Append
    ".status.fail { background-color: #fee2e2; color: #991b1b; }" | Out-File -FilePath $ReportFile -Append
    ".footer { background: #f8f9fa; padding: 30px; text-align: center; color: #6b7280; border-top: 1px solid #e5e7eb; }" | Out-File -FilePath $ReportFile -Append
    "</style></head><body><div class='container'>" | Out-File -FilePath $ReportFile -Append
    "<div class='header'><h1>🧪 Flutter Test Report</h1>" | Out-File -FilePath $ReportFile -Append
    "<p>Mobile Programming Project - Hydroponic App</p>" | Out-File -FilePath $ReportFile -Append
    "<p style='margin-top: 10px;'>Generated: $Timestamp</p></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary'>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary-card total'><h3>Test Suites</h3><div class='value'>$totalCount</div></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary-card pass'><h3>Passed Suites</h3><div class='value'>$passCount</div></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary-card fail'><h3>Failed Suites</h3><div class='value'>$failCount</div></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary-card tests'><h3>Total Tests</h3><div class='value'>$totalTests</div></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='summary-card rate'><h3>Pass Rate</h3><div class='value'>$passRate%</div></div>" | Out-File -FilePath $ReportFile -Append
    "</div><div class='content'><h2>📊 Test Suite Results</h2><table><thead><tr>" | Out-File -FilePath $ReportFile -Append
    "<th>Suite ID</th><th>Suite Name</th><th>Details</th><th>Status</th><th>Duration (s)</th><th>Timestamp</th>" | Out-File -FilePath $ReportFile -Append
    "</tr></thead><tbody>" | Out-File -FilePath $ReportFile -Append
    
    foreach ($result in $Results) {
        $statusClass = $result.Status.ToLower()
        "<tr><td><strong>$($result.TestId)</strong></td>" | Out-File -FilePath $ReportFile -Append
        "<td>$($result.Name)</td>" | Out-File -FilePath $ReportFile -Append
        "<td>$($result.Description)</td>" | Out-File -FilePath $ReportFile -Append
        "<td><span class='status $statusClass'>$($result.Status)</span></td>" | Out-File -FilePath $ReportFile -Append
        "<td>$($result.Duration)</td>" | Out-File -FilePath $ReportFile -Append
        "<td>$($result.Timestamp)</td></tr>" | Out-File -FilePath $ReportFile -Append
    }
    
    "</tbody></table></div>" | Out-File -FilePath $ReportFile -Append
    "<div class='footer'><p><strong>Log File:</strong> $LogFile</p>" | Out-File -FilePath $ReportFile -Append
    "<p style='margin-top: 10px;'>© 2025 Mobile Programming Project</p></div>" | Out-File -FilePath $ReportFile -Append
    "</div></body></html>" | Out-File -FilePath $ReportFile -Append
    
    Write-Success "Report generated: $ReportFile"
    Start-Process $ReportFile
}

# Main
Write-Host @"

╔════════════════════════════════════════════════════════╗
║     Flutter Test Runner - All Tests                   ║
║     Unit • Widget • Integration                        ║
╚════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Initialize-Directories

$results = Run-AllTests

Generate-Report -Results $results

Write-Host "`n" -NoNewline
Write-Step "Complete!"
Write-Host "`n  Report: $ReportFile" -ForegroundColor Green
Write-Host "  Log: $LogFile`n" -ForegroundColor Green
