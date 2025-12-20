# Run Integration Tests on Device (No Screen Recording)
# For devices that don't support screenrecord command

$DeviceId = "5T4HPZOJY56DZ9QG"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "====== Integration Test Runner ======" -ForegroundColor Cyan
Write-Host ""
Write-Host "Device: $DeviceId" -ForegroundColor Green
Write-Host ""

# Run integration tests
Write-Host "Running integration tests on device..." -ForegroundColor Yellow
Write-Host "(App will launch on your phone - watch it test automatically)" -ForegroundColor Gray
Write-Host ""

Push-Location $ProjectRoot

# Run with flutter test which works better than flutter drive
flutter test integration_test/app_test.dart --device-id=$DeviceId -r expanded

$exitCode = $LASTEXITCODE

Pop-Location

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "  (This is normal if Firebase isn't configured)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
}
Write-Host ""
