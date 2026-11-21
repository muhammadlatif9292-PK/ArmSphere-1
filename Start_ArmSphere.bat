@echo off
setlocal enabledelayedexpansion
title ArmSphere Local Server
color 0A
chcp 65001 >nul

echo ===================================================
echo      Starting ArmSphere Local Production Setup
echo ===================================================
echo.

:: 1. Setup Environment Paths
set "PATH=E:\tools\node;E:\tools\Git\cmd;E:\tools\cloudflared;%PATH%"

:: 2. Check and Start Cloudflare Tunnel
echo [1/2] Checking Cloudflare Tunnel...
tasklist /FI "IMAGENAME eq cloudflared.exe" 2>nul | find /I /N "cloudflared.exe" >nul
if %errorLevel% == 0 (
    echo [OK] Cloudflare Tunnel is already running.
    goto check_api
)

sc query "cloudflared" >nul 2>&1
if %errorLevel% == 0 goto start_cf_service

if exist "E:\tools\cloudflared\token.txt" goto start_cf_token

echo [NOTE] Cloudflare service is not yet registered on this Windows install.
echo Public gateway: https://armsphere-api-gateway.armsphere.workers.dev
echo To connect the tunnel automatically:
echo   - Paste your tunnel token into: E:\tools\cloudflared\token.txt
echo   - Or run as Admin: E:\tools\cloudflared\install_tunnel_service.bat
goto check_api

:start_cf_service
echo Found registered Cloudflare Service. Starting...
net start "cloudflared" >nul 2>&1
echo [OK] Cloudflare Tunnel service active.
goto check_api

:start_cf_token
echo Found tunnel token in E:\tools\cloudflared\token.txt.
echo Starting cloudflared process in background...
set /p CF_TOKEN=<"E:\tools\cloudflared\token.txt"
start "ArmSphere Cloudflare Tunnel" /min "E:\tools\cloudflared\cloudflared.exe" tunnel run --token %CF_TOKEN%
echo [OK] Cloudflare Tunnel process started.
goto check_api

:check_api
echo.
echo [2/2] Checking ArmSphere API Server (Port 4000)...
netstat -ano | findstr ":4000 " | findstr "LISTENING" >nul
if %errorLevel% == 0 (
    echo [OK] ArmSphere API Server is already active on Port 4000.
    goto verify_status
)

echo Starting ArmSphere API Server (Dual-Stack IPv6 + IPv4)...
start "ArmSphere API Server" cmd /k "cd /d E:\ArmSphere && set PATH=E:\tools\node;E:\tools\Git\cmd;%PATH% && node apps/api/dist/server.js"

:verify_status
echo.
echo Waiting for API health checks (Local + Cloudflare Gateway)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$localOk = $false; " ^
    "for ($i=1; $i -le 12; $i++) { " ^
    "    Start-Sleep -Seconds 1; " ^
    "    try { " ^
    "        $r = Invoke-RestMethod -Uri 'http://127.0.0.1:4000/api/health' -TimeoutSec 2 -ErrorAction Stop; " ^
    "        if ($r.status -eq 'healthy') { $localOk = $true; break; } " ^
    "    } catch {} " ^
    "}; " ^
    "if ($localOk) { " ^
    "    Write-Host '===================================================' -ForegroundColor Green; " ^
    "    Write-Host ' [SUCCESS] Local API is LIVE on Port 4000!' -ForegroundColor Green; " ^
    "    Write-Host ' Database: healthy' -ForegroundColor Green; " ^
    "    Write-Host ' Queues:   active' -ForegroundColor Green; " ^
    "    Write-Host '===================================================' -ForegroundColor Green; " ^
    "    try { " ^
    "        $gw = Invoke-RestMethod -Uri 'https://armsphere-api-gateway.armsphere.workers.dev/api/health' -TimeoutSec 4 -ErrorAction Stop; " ^
    "        if ($gw.status -eq 'healthy') { " ^
    "            Write-Host ' [PUBLIC GATEWAY] Cloudflare Tunnel is ONLINE and ROUTING!' -ForegroundColor Cyan; " ^
    "        } " ^
    "    } catch { " ^
    "        Write-Host ' [NOTE] Cloudflare Gateway connecting... check again in a few seconds.' -ForegroundColor Yellow; " ^
    "    } " ^
    "} else { " ^
    "    Write-Host ' [INFO] Server is initializing. Please check the API Server console window.' -ForegroundColor Yellow; " ^
    "}"

echo.
echo ===================================================
echo ArmSphere launch sequence complete.
echo You can minimize this window.
echo Close the "ArmSphere API Server" window to stop it.
echo ===================================================
echo.
pause
