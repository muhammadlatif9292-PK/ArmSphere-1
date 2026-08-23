#!/usr/bin/env pwsh
# ArmSphere Production API Startup
#
# Secrets are loaded from the gitignored .env.production in the repo root —
# never hardcode credentials here (or anywhere else tracked by version control).

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $repoRoot ".env.production"

if (-not (Test-Path $envFile)) {
    Write-Host "ERROR: .env.production not found at $envFile" -ForegroundColor Red
    Write-Host "Create it from .env.production.example and fill in real values first." -ForegroundColor Yellow
    exit 1
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $idx = $line.IndexOf("=")
        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        Set-Item -Path "env:$key" -Value $value
    }
}

if (-not $env:NODE_ENV) { $env:NODE_ENV = "production" }
if (-not $env:PORT) { $env:PORT = "3001" }

Write-Host "ArmSphere Production API Server" -ForegroundColor Cyan
Write-Host "Environment loaded from .env.production (NODE_ENV=$env:NODE_ENV, PORT=$env:PORT)" -ForegroundColor Green
Write-Host ""

Set-Location (Join-Path $repoRoot "apps\api")
node dist/server.js
