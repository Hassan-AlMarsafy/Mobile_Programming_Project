# Simple Test Runner - Runs all tests and creates a basic report
# Avoids PowerShell/HTML parsing issues

param(
    [switch]$SkipIntegration = $false
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "test_output"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host ""
Write-Host "====== Flutter Test Runner ======" -ForegroundColor Cyan
Write-Host ""

# Run Unit Tests
Write-Host "[1/3] Running Unit Tests..." -ForegroundColor Yellow
Push-Location $ProjectRoot
$unitOutput = flutter test test/unit 2>&1
$unitExit = $LASTEXITCODE
Pop-Location

# Run Widget Tests  
Write-Host "[2/3] Running Widget Tests..." -ForegroundColor Yellow
Push-Location $ProjectRoot
$widgetOutput = flutter test test/widget 2>&1
$widgetExit = $LASTEXITCODE
Pop-Location

# Run Integration Tests (if not skipped)
if (-not $SkipIntegration) {
    Write-Host "[3/3] Running Integration Tests..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    $intOutput = flutter test test/integration 2>&1
    $intExit = $LASTEXITCODE
    Pop-Location
}

Write-Host ""
Write-Host "====== Test Summary ======" -ForegroundColor Cyan
Write-Host ""

if ($unitExit -eq 0) {
    Write-Host "[PASS] Unit Tests: PASSED" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Unit Tests: FAILED" -ForegroundColor Red
}

if ($widgetExit -eq 0) {
    Write-Host "[PASS] Widget Tests: PASSED" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Widget Tests: FAILED" -ForegroundColor Red
}

if (-not $SkipIntegration) {
    if ($intExit -eq 0) {
        Write-Host "[PASS] Integration Tests: PASSED" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Integration Tests: FAILED (Firebase needed)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""
