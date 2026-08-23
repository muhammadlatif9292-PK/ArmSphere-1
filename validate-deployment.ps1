#!/usr/bin/env pwsh
# ArmSphere Deployment Validation Script
# Verifies all systems are ready for production

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ArmSphere v1.0 - PRE-DEPLOYMENT VALIDATION" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$checksPassed = 0
$checksFailed = 0

function Check-Item {
    param([string]$Item, [scriptblock]$Test, [string]$FixCmd)
    
    $result = & $Test
    if ($result) {
        Write-Host "✅ $Item" -ForegroundColor Green
        $script:checksPassed++
    } else {
        Write-Host "❌ $Item" -ForegroundColor Red
        if ($FixCmd) {
            Write-Host "   Fix: $FixCmd" -ForegroundColor Yellow
        }
        $script:checksFailed++
    }
}

# ============================================================================
# 1. FILESYSTEM CHECKS
# ============================================================================
Write-Host "1️⃣  Filesystem Validation" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

Check-Item "Project root exists" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0"
} "Create project folder"

Check-Item "API dist/server.js exists" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0\apps\api\dist\server.js"
} "Run: npm run build"

Check-Item "Admin web dist exists" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0\apps\admin-web\dist"
} "Run: npm run build"

Check-Item "package.json exists" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0\package.json"
} "Check project structure"

Write-Host ""

# ============================================================================
# 2. BUILD VALIDATION
# ============================================================================
Write-Host "2️⃣  Build Validation" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

Check-Item "node_modules installed" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0\node_modules"
} "Run: npm install"

Check-Item "API bundle size > 500KB" {
    $size = (Get-Item "E:\Armsphere\remix-armsphere-1.0\apps\api\dist\server.js" -ErrorAction SilentlyContinue).Length
    $size -gt 500000
} "Run: npm run build"

Check-Item "TypeScript compilation clean" {
    $errors = @(npm run lint 2>&1 | Where-Object {$_ -match "error"})
    $errors.Count -eq 0
} "Fix TypeScript errors"

Write-Host ""

# ============================================================================
# 3. RUNTIME CHECKS
# ============================================================================
Write-Host "3️⃣  Runtime Validation" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

Check-Item "Port 3001 available or stale process detected" {
    $process = Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "   Port 3001 in use (process: $(Get-Process -Id $process.OwningProcess -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName))" -ForegroundColor Gray
        $true
    } else {
        $true
    }
}

Check-Item "Node.js version >= 20" {
    $version = node --version
    [int]($version -replace 'v(\d+)\..*', '$1') -ge 20
} "Update Node.js from nodejs.org"

Check-Item "npm available" {
    $null = npm --version
    $LASTEXITCODE -eq 0
} "Reinstall Node.js"

Write-Host ""

# ============================================================================
# 4. ENVIRONMENT CHECKS
# ============================================================================
Write-Host "4️⃣  Environment Configuration" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

Check-Item ".env.production file exists" {
    Test-Path "E:\Armsphere\remix-armsphere-1.0\.env.production"
} "Run: .\final-deploy.ps1"

if (Test-Path "E:\Armsphere\remix-armsphere-1.0\.env.production") {
    $envContent = Get-Content "E:\Armsphere\remix-armsphere-1.0\.env.production"
    
    Check-Item ".env.production has NODE_ENV=production" {
        $envContent -contains "NODE_ENV=production"
    "Edit .env.production"
    }
    
    Check-Item ".env.production has JWT secrets" {
        ($envContent -match "JWT_ACCESS_SECRET=.*[a-zA-Z0-9]{32}") -and `
        ($envContent -match "JWT_REFRESH_SECRET=.*[a-zA-Z0-9]{32}")
    } "Add JWT secrets minimum 32 characters each"
    
    Check-Item ".env.production has CRON_SECRET" {
        $envContent -match "CRON_SECRET=.*"
    } "Add CRON_SECRET"
}

Write-Host ""

# ============================================================================
# 5. API HEALTH CHECKS
# ============================================================================
Write-Host "5️⃣  API Health Checks" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

Check-Item "API responding on port 3001" {
    try {
        $response = Invoke-WebRequest -UseBasicParsing http://localhost:3001/api/health -ErrorAction SilentlyContinue -TimeoutSec 2
        $response.StatusCode -eq 200
    } catch {
        $false
    }
} "Start API: .\final-deploy.ps1 or NODE_ENV=production node apps/api/dist/server.js"

if (Test-Path "E:\Armsphere\remix-armsphere-1.0\.env.production") {
    Check-Item "API /api/ready endpoint working" {
        try {
            $response = Invoke-WebRequest -UseBasicParsing http://localhost:3001/api/ready -ErrorAction SilentlyContinue -TimeoutSec 2
            $response.StatusCode -eq 200
        } catch {
            $false
        }
    } "Start API server"
    
    Check-Item "API returning JSON health response" {
        try {
            $response = Invoke-WebRequest -UseBasicParsing http://localhost:3001/api/health -ErrorAction SilentlyContinue -TimeoutSec 2
            $json = $response.Content | ConvertFrom-Json
            $json.success -eq $true
        } catch {
            $false
        }
    } "Check API startup logs"
}

Write-Host ""

# ============================================================================
# 6. SUMMARY
# ============================================================================
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checks Passed: $checksPassed" -ForegroundColor Green
Write-Host "Checks Failed: $checksFailed" -ForegroundColor $(if ($checksFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($checksFailed -eq 0) {
    Write-Host "🎉 ALL CHECKS PASSED - READY FOR DEPLOYMENT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Get database URL (Neon: https://console.neon.tech)" -ForegroundColor Gray
    Write-Host "  2. Edit .env.production with DATABASE_URL" -ForegroundColor Gray
    Write-Host "  3. Run: npm run db:migrate" -ForegroundColor Gray
    Write-Host "  4. Run: NODE_ENV=production node apps/api/dist/server.js" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or run automated deployment:" -ForegroundColor Cyan
    Write-Host "  .\final-deploy.ps1" -ForegroundColor White
} else {
    Write-Host "[FAILED] SOME CHECKS FAILED - FIX ISSUES ABOVE BEFORE DEPLOYING" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  - npm run build" -ForegroundColor Gray
    Write-Host "  - npm install" -ForegroundColor Gray
    Write-Host "  - Check Node.js is installed" -ForegroundColor Gray
    Write-Host "  - Check env.production exists and has required values" -ForegroundColor Gray
}

Write-Host ""
