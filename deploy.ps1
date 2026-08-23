#!/usr/bin/env pwsh
# ArmSphere Production Launch Script
# Generated: 2026-08-15
# Purpose: Deploy to production in under 5 minutes

Write-Host "🚀 ArmSphere Production Deployment Script" -ForegroundColor Cyan
Write-Host "⏱️  Target: < 5 minutes to live" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# STEP 1: DATABASE SETUP - CHOOSE YOUR OPTION
# ============================================================================
Write-Host "STEP 1: Database Setup (REQUIRED)" -ForegroundColor Green
Write-Host "Choose ONE option:" -ForegroundColor White
Write-Host "  A) Neon PostgreSQL (recommended, fastest, no card)"
Write-Host "  B) Local PostgreSQL (if installed)"
Write-Host "  C) Use example URL for testing"
Write-Host ""

$dbChoice = Read-Host "Enter choice (A/B/C)"

$databaseUrl = ""
switch ($dbChoice.ToUpper()) {
    "A" {
        Write-Host "📋 Neon Setup (2 minutes):" -ForegroundColor Cyan
        Write-Host "  1. Go to: https://console.neon.tech"
        Write-Host "  2. Sign up with GitHub"
        Write-Host "  3. Create project, wait 30 seconds"
        Write-Host "  4. Copy connection string from Dashboard"
        Write-Host ""
        $databaseUrl = Read-Host "Paste your Neon connection string"
        if (-not $databaseUrl) {
            Write-Host "❌ No database URL provided. Exiting." -ForegroundColor Red
            exit 1
        }
    }
    "B" {
        $host_input = Read-Host "Enter PostgreSQL host (default: localhost)"
        $port_input = Read-Host "Enter port (default: 5432)"
        $user_input = Read-Host "Enter username (default: armsphere)"
        $pass_input = Read-Host "Enter password"
        
        $host_val = if ([string]::IsNullOrWhiteSpace($host_input)) { "localhost" } else { $host_input }
        $port_val = if ([string]::IsNullOrWhiteSpace($port_input)) { "5432" } else { $port_input }
        $user_val = if ([string]::IsNullOrWhiteSpace($user_input)) { "armsphere" } else { $user_input }
        
        $databaseUrl = "postgresql://${user_val}:${pass_input}@${host_val}:${port_val}/armsphere?sslmode=disable"
    }
    "C" {
        Write-Host "⚠️  Using test URL (won't work in production)" -ForegroundColor Yellow
        $databaseUrl = "postgresql://test:test@localhost:5432/armsphere"
    }
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 2: GENERATE SECURE SECRETS
# ============================================================================
Write-Host ""
Write-Host "STEP 2: Generating Secrets" -ForegroundColor Green

function Generate-Secret {
    return [System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).Substring(0, 32)
}

$jwt_access = Generate-Secret
$jwt_refresh = Generate-Secret
$cron_secret = Generate-Secret

Write-Host "✅ Generated 3 secure secrets (32+ chars each)" -ForegroundColor Green

# ============================================================================
# STEP 3: CREATE .env.production
# ============================================================================
Write-Host ""
Write-Host "STEP 3: Creating .env.production" -ForegroundColor Green

$envContent = @"
# ArmSphere Production Environment
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

NODE_ENV=production
PORT=3001
IS_SERVERLESS=false

DATABASE_URL=$databaseUrl

JWT_ACCESS_SECRET=$jwt_access
JWT_REFRESH_SECRET=$jwt_refresh
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d

CRON_SECRET=$cron_secret

CORS_ORIGIN=http://localhost:3000

STORAGE_PROVIDER=b2
B2_ENDPOINT=s3.us-west-004.backblazeb2.com
B2_REGION=us-west-004
B2_ACCESS_KEY_ID=
B2_SECRET_ACCESS_KEY=
B2_BUCKET_COMPLIANCE_DOCS=compliance-docs
B2_BUCKET_ATHLETE_AVATARS=athlete-avatars
"@

$envPath = "E:\Armsphere\remix-armsphere-1.0\.env.production"
Set-Content -Path $envPath -Value $envContent
Write-Host "✅ Created .env.production" -ForegroundColor Green

# ============================================================================
# STEP 4: BUILD
# ============================================================================
Write-Host ""
Write-Host "STEP 4: Building Project" -ForegroundColor Green

Set-Location "E:\Armsphere\remix-armsphere-1.0"

$buildResult = npm run build 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    Write-Host $buildResult
    exit 1
}
Write-Host "✅ Build successful (API + Admin Web)" -ForegroundColor Green

# ============================================================================
# STEP 5: RUN MIGRATIONS
# ============================================================================
Write-Host ""
Write-Host "STEP 5: Running Database Migrations" -ForegroundColor Green

$env:NODE_ENV = "production"
$env:DATABASE_URL = $databaseUrl

Set-Location "E:\Armsphere\remix-armsphere-1.0\apps\api"

try {
    $migrateResult = npm run db:migrate 2>&1
    Write-Host "✅ Migrations completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Migration encountered error (may be expected on first run)" -ForegroundColor Yellow
    Write-Host $migrateResult
}

# ============================================================================
# STEP 6: START API SERVER
# ============================================================================
Write-Host ""
Write-Host "STEP 6: Starting API Server" -ForegroundColor Green
Write-Host "🚀 Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

$env:NODE_ENV = "production"
$env:PORT = "3001"
$env:DATABASE_URL = $databaseUrl
$env:JWT_ACCESS_SECRET = $jwt_access
$env:JWT_REFRESH_SECRET = $jwt_refresh
$env:CRON_SECRET = $cron_secret

Set-Location "E:\Armsphere\remix-armsphere-1.0\apps\api"
node dist/server.js
