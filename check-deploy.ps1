#!/usr/bin/env pwsh
# ArmSphere Pre-Deployment Validation
# Checks all systems before deployment

Write-Host ""
Write-Host "=== ArmSphere v1.0 Pre-Deployment Validation ===" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Filesystem checks
Write-Host "Checking filesystem..." -ForegroundColor Yellow
if (Test-Path "E:\Armsphere\remix-armsphere-1.0\apps\api\dist\server.js") {
    Write-Host "  [PASS] API server bundle exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] API server bundle missing - run: npm run build" -ForegroundColor Red
    $failed++
}

if (Test-Path "E:\Armsphere\remix-armsphere-1.0\apps\admin-web\dist\index.html") {
    Write-Host "  [PASS] Admin web build exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Admin web build missing - run: npm run build" -ForegroundColor Red
    $failed++
}

if (Test-Path "E:\Armsphere\remix-armsphere-1.0\.env.production") {
    Write-Host "  [PASS] .env.production exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] .env.production missing - run: .\final-deploy.ps1" -ForegroundColor Red
    $failed++
}

# Runtime checks
Write-Host ""
Write-Host "Checking Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version
Write-Host "  [INFO] Node.js version: $nodeVersion" -ForegroundColor Gray
if ([int]($nodeVersion -replace 'v(\d+)\..*', '$1') -ge 20) {
    Write-Host "  [PASS] Node.js version is 20+" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Node.js 20+ required" -ForegroundColor Red
    $failed++
}

# Build artifacts
Write-Host ""
Write-Host "Checking build artifacts..." -ForegroundColor Yellow
$serverSize = (Get-Item "E:\Armsphere\remix-armsphere-1.0\apps\api\dist\server.js" -ErrorAction SilentlyContinue).Length
if ($serverSize -gt 500000) {
    Write-Host "  [PASS] API bundle size: $(($serverSize/1MB).ToString('F2'))MB" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] API bundle too small - rebuild needed" -ForegroundColor Red
    $failed++
}

# API health check
Write-Host ""
Write-Host "Checking API health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -UseBasicParsing http://localhost:3001/api/health -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($health.StatusCode -eq 200) {
        Write-Host "  [PASS] API responding on port 3001" -ForegroundColor Green
        $passed++
        $json = $health.Content | ConvertFrom-Json
        Write-Host "  [INFO] Status: $($json.status)" -ForegroundColor Gray
    } else {
        Write-Host "  [WARN] API not responding (may not be running)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [INFO] API not running (this is OK - start it for full check)" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "SUCCESS: All checks passed! Ready for deployment." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Get database URL (Neon: https://console.neon.tech)" -ForegroundColor Gray
    Write-Host "  2. Edit .env.production with DATABASE_URL" -ForegroundColor Gray
    Write-Host "  3. Run: npm run db:migrate" -ForegroundColor Gray
    Write-Host "  4. Run: NODE_ENV=production node apps/api/dist/server.js" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "ISSUES FOUND: Fix above before deploying" -ForegroundColor Red
}

Write-Host ""
