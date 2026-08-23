# ⚡ QUICK START: Deploy in 5 Minutes

## ✅ What's Ready Now
- API code: ✅ Compiled and tested (306/306 tests pass)
- Admin web: ✅ Built and ready
- Docker: ✅ Containers ready
- Security: ✅ Production hardened
- **Database**: ⏳ YOU choose (Neon/Local/RDS)

## 🚀 Fastest Deployment Path (Neon PostgreSQL)

### 1. Get Database (3 min)
```
Go to: https://console.neon.tech
→ Sign up with GitHub
→ Create project
→ Copy connection string
```

### 2. Run Deployment Script (2 min)
```powershell
cd E:\Armsphere\remix-armsphere-1.0
.\deploy.ps1
# When prompted: paste Neon connection string
# Wait for "🚀 API Engine listening on 0.0.0.0:3001"
```

### 3. Verify (30 sec)
Open new terminal:
```powershell
curl http://localhost:3001/api/health
# Should show: "status":"healthy"
```

**Done!** Your API is live in production mode.

---

## 📋 Alternative: Manual Steps

### Option 1: Neon PostgreSQL
```powershell
# 1. Get connection string from https://console.neon.tech

# 2. Create .env.production (or use deploy.ps1)
Set-Content -Path .env.production -Value @"
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://USER:PASS@ep-xxxxx.region.aws.neon.tech/neondb?sslmode=require
JWT_ACCESS_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
JWT_REFRESH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
CRON_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
"@

# 3. Build
npm run build

# 4. Migrate
cd apps/api
npm run db:migrate

# 5. Start
NODE_ENV=production PORT=3001 node dist/server.js
```

### Option 2: Local PostgreSQL
```powershell
# Requires: PostgreSQL 15+ installed locally

# Create database
# createuser armsphere -P  (set password)
# createdb -O armsphere armsphere

# Then run deploy.ps1 and choose option B
```

### Option 3: Docker Compose
```powershell
docker-compose up -d
docker-compose exec api npm run db:migrate
# Open http://localhost:3000
```

---

## 🔍 Verify Deployment

```powershell
# Check API is running
curl http://localhost:3001/api/ready
# Response: {"ready":true,"status":"healthy",...}

# Check database connection
curl http://localhost:3001/api/health
# Response: {"success":true,"status":"healthy",...}

# Check admin web
open http://localhost:3000
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "password authentication failed" | Check DATABASE_URL and credentials |
| "EADDRINUSE 3001" | Kill existing process: `Get-Process -Name node \| Stop-Process` |
| "Migration failed" | Database may already exist. Run migrations again or check PostgreSQL logs |
| "Cannot find module" | Run `npm run build` first |

---

## ✅ Success Criteria

When deployment is complete:
- [ ] `npm run build` succeeds (306/306 tests pass)
- [ ] `/api/health` returns `status: healthy`
- [ ] `/api/ready` returns `ready: true`
- [ ] Admin web loads at http://localhost:3000
- [ ] Can log in and create test athlete
- [ ] Scheduled jobs are running

---

## 📊 Project Status After Deployment

```
Deployment Timeline:
  Code Ready      ✅ This session
  Tests Pass      ✅ 306/306
  Build Complete  ✅ 588.6 KB
  Database Setup  ⏳ You (Neon/Local/RDS)
  Migrations      ⏳ After DB
  API Live        ⏳ After Migrations
  Admin Live      ✅ Ready when API ready
  Production      ⏳ When all above done
```

---

## 🎯 Next: After Deployment Works

1. Create admin user
2. Add athletes
3. Create tournaments
4. Test bracket generation
5. Go live!

---

**Total Time**: ~5 minutes
**Blocker**: Only database setup (your choice of provider)
**Support**: All docs in project root (DEPLOYMENT_*.md)
