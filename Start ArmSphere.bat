@echo off
setlocal
title ArmSphere Local Server
color 0A

echo ===================================================
echo      Starting ArmSphere Local Production Setup
echo ===================================================
echo.

:: 1. Setup Environment Paths
set "PATH=E:\tools\node;E:\tools\Git\cmd;E:\tools\cloudflared;%PATH%"

:: 2. Check and Start Cloudflare Tunnel
echo [1/2] Checking Cloudflare Tunnel...
sc query "cloudflared" >nul 2>&1
if %errorLevel% == 0 goto start_cf_service

if exist "E:\tools\cloudflared\token.txt" goto start_cf_token

echo [NOTE] Cloudflare service is not yet registered on this Windows install.
echo Public gateway: https://armsphere-api-gateway.armsphere.workers.dev
echo To connect the tunnel automatically:
echo   - Paste your tunnel token into: E:\tools\cloudflared\token.txt
echo   - Or run as Admin: E:\tools\cloudflared\install_tunnel_service.bat
goto start_api

:start_cf_service
echo Found registered Cloudflare Service. Starting...
net start "cloudflared" >nul 2>&1
echo [OK] Cloudflare Tunnel service active.
goto start_api

:start_cf_token
echo Found tunnel token in E:\tools\cloudflared\token.txt.
echo Starting cloudflared process in background...
set /p CF_TOKEN=<"E:\tools\cloudflared\token.txt"
start "ArmSphere Cloudflare Tunnel" /min "E:\tools\cloudflared\cloudflared.exe" tunnel run --token %CF_TOKEN%
echo [OK] Cloudflare Tunnel process started.
goto start_api

:start_api
echo.
echo [2/2] Starting ArmSphere API Server (Port 4000)...
start "ArmSphere API Server" cmd /k "cd /d E:\ArmSphere && set PATH=E:\tools\node;E:\tools\Git\cmd;%PATH% && node apps/api/dist/server.js"

echo.
echo Waiting for API server to initialize...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$h=$false; for ($i=1; $i -le 10; $i++) { Start-Sleep -Seconds 1; try { $r = Invoke-RestMethod -Uri 'http://127.0.0.1:4000/api/health' -TimeoutSec 2 -ErrorAction Stop; if ($r.status -eq 'healthy') { Write-Host '===================================================' -ForegroundColor Green; Write-Host ' [SUCCESS] ArmSphere API is LIVE on Port 4000!' -ForegroundColor Green; Write-Host ' Status:   ' $r.status -ForegroundColor Green; Write-Host ' Database: ' $r.details.database -ForegroundColor Green; Write-Host ' Queues:   ' $r.details.queues -ForegroundColor Green; Write-Host '===================================================' -ForegroundColor Green; $h=$true; break; } } catch {} }; if (-not $h) { Write-Host ' [INFO] Server is starting up. Check the API Server window for live logs.' -ForegroundColor Yellow; }"

echo.
echo ===================================================
echo ArmSphere launch sequence complete.
echo You can minimize this window.
echo Close the "ArmSphere API Server" window to stop it.
echo ===================================================
echo.
pause
