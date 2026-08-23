# Neon Database User Setup Guide

## Problem
The API is running but database queries fail with:
```
password authentication failed for user 'armsphere_user'
```

## Solution: Create Database Role in Neon

### Step 1: Access Neon Console
1. Go to https://console.neon.tech
2. Select your project (should contain your Neon database)
3. Click **SQL Editor** (or go to Roles section)

### Step 2: Create the Role

Run this SQL command:
```sql
-- Create the armsphere_user role
CREATE ROLE armsphere_user WITH LOGIN PASSWORD 'armsphere_prod_secret_12345_xyz';

-- Grant database connection
GRANT CONNECT ON DATABASE neondb TO armsphere_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO armsphere_user;
GRANT CREATE ON SCHEMA public TO armsphere_user;

-- Grant table/sequence privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO armsphere_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO armsphere_user;

-- Make grants apply to future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO armsphere_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO armsphere_user;
```

**Note:** Replace `armsphere_prod_secret_12345_xyz` with a secure password (32+ chars recommended)

### Step 3: Get Your Connection String

From Neon Console, copy the connection string for `armsphere_user`:
```
postgresql://armsphere_user:PASSWORD@ep-purple-wind-az32pzo8.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

### Step 4: Update Startup Script

Edit `E:\Armsphere\remix-armsphere-1.0\start-api.ps1`:

Find this line:
```powershell
$env:DATABASE_URL = "postgresql://neondb_owner:YOUR_NEON_PASSWORD@ep-purple-wind-az32pzo8.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

Replace with:
```powershell
$env:DATABASE_URL = "postgresql://armsphere_user:YOUR_PASSWORD@ep-purple-wind-az32pzo8.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

### Step 5: Kill and Restart Server

```powershell
# Kill existing process
Get-Process node | Stop-Process -Force

# Restart with new credentials
& E:\Armsphere\remix-armsphere-1.0\start-api.ps1
```

### Step 6: Verify Connection

```powershell
# Wait 5 seconds, then check health
Start-Sleep -Seconds 5
curl http://localhost:3001/api/health
```

Expected response:
```json
{
  "success": true,
  "status": "healthy",  ← Changed from "degraded"
  "timestamp": "2026-08-15T06:30:00.000Z",
  "details": {
    "database": "healthy",
    "queues": "postgresql-scheduled-jobs"
  }
}
```

---

## Alternative: Use neondb_owner (Quick Test)

If you want to test quickly without creating a new role, use the owner credentials:

```powershell
# In start-api.ps1, use:
$env:DATABASE_URL = "postgresql://neondb_owner:YOUR_NEON_PASSWORD@ep-purple-wind-az32pzo8.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

Then modify [apps/api/src/config/db.ts](apps/api/src/config/db.ts) to accept any user, or search the codebase for hardcoded `armsphere_user` references and replace them.

---

## Troubleshooting

### "Role already exists" error
The role may already exist. Try:
```sql
DROP ROLE IF EXISTS armsphere_user;
-- Then re-run the CREATE ROLE command
```

### Still getting auth errors after restart
1. Verify the connection string in start-api.ps1 is correct
2. Check Neon Console that the role has CONNECT privilege on the database
3. Confirm password doesn't contain special characters that need escaping

### Database is "unhealthy" but no auth error
Migrations haven't run yet. Once you have DB access working, run:
```powershell
cd E:\Armsphere\remix-armsphere-1.0\apps\api
npm run db:migrate
```

---

## Status Check

After setup, run this every time to verify:
```powershell
$response = curl http://localhost:3001/api/health
$json = $response | ConvertFrom-Json
Write-Host "Database: $($json.details.database)"
Write-Host "Status: $($json.status)"
```

Should show:
```
Database: healthy
Status: healthy
```

Done! 🎉
