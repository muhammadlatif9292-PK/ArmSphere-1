# ArmSphere Deployment Guide

## Overview

ArmSphere is a competitive arm wrestling championship platform built with:
- **Backend**: Node.js + Express + Drizzle ORM + PostgreSQL
- **Frontend**: React + Vite + Tailwind CSS
- **Infrastructure**: Docker + Docker Compose

This guide covers deploying ArmSphere to production and development environments.

---

## Deployment Status ✅

- ✅ Backend API: Production-ready (602 KB ESM bundle)
- ✅ Admin Web Frontend: Production-ready (976 KB total)
- ✅ Test Suite: 306/306 tests passing
- ✅ Security Hardening: Complete
- ✅ Environment Config: Production fail-closed

---

## Quick Start: Docker Compose (Development)

### Prerequisites
- Docker & Docker Compose installed
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/armsphere.git
   cd armsphere/remix-armsphere-1.0
   ```

2. **Create environment file**
   ```bash
   cat > .env.docker << EOF
   NODE_ENV=development
   DB_PASSWORD=dev-secure-password-123
   JWT_SECRET=dev-jwt-secret-change-in-production
   JWT_REFRESH_SECRET=dev-refresh-secret-change-in-production
   CRON_SECRET=dev-cron-secret-change-in-production
   STRIPE_SECRET_KEY=sk_test_placeholder
   LOG_LEVEL=debug
   EOF
   ```

3. **Build and start services**
   ```bash
   docker-compose up -d
   ```

4. **Initialize database**
   ```bash
   docker-compose exec api npm run migrate
   ```

5. **Verify deployment**
   ```bash
   # Check services
   docker-compose ps
   
   # Test API
   curl -s http://localhost:3001/health
   
   # Access admin web
   open http://localhost:3000
   ```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f admin-web
```

---

## Production Deployment

### Prerequisites
- Docker & Docker Compose
- PostgreSQL 16+ (or use managed service)
- Minimum 2GB RAM, 2 CPU cores
- SSL/TLS certificate
- Domain name

### Environment Configuration

Create `.env.production`:
```bash
# Database (use managed service or external PostgreSQL)
DATABASE_URL=postgresql://user:password@prod-db-host:5432/armsphere

# Security - MUST be changed from defaults
JWT_SECRET=<generate-strong-random-secret>
JWT_REFRESH_SECRET=<generate-strong-random-secret>
CRON_SECRET=<generate-strong-random-secret>

# Stripe (for payments)
STRIPE_SECRET_KEY=sk_live_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx

# AWS (for S3/SES - optional)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>

# Application
NODE_ENV=production
LOG_LEVEL=info
```

### Generating Secure Secrets

```bash
# On your local machine or production server
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Option 1: Docker Compose (Production)

1. **Prepare production environment**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

2. **Run migrations**
   ```bash
   docker-compose exec api npm run migrate
   ```

3. **Setup reverse proxy** (Nginx/HAProxy)
   ```nginx
   upstream armsphere_api {
       server api:3001;
   }
   
   upstream armsphere_web {
       server admin-web:80;
   }
   
   server {
       listen 443 ssl http2;
       server_name armsphere.example.com;
       
       ssl_certificate /etc/letsencrypt/live/armsphere.example.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/armsphere.example.com/privkey.pem;
       
       location / {
           proxy_pass http://armsphere_web;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;
       }
       
       location /api/ {
           proxy_pass http://armsphere_api;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;
       }
   }
   
   server {
       listen 80;
       server_name armsphere.example.com;
       return 301 https://$server_name$request_uri;
   }
   ```

### Option 2: Kubernetes Deployment

Create `k8s/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: armsphere-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: armsphere-api
  template:
    metadata:
      labels:
        app: armsphere-api
    spec:
      containers:
      - name: api
        image: armsphere:api-1.0.0
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: armsphere-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: armsphere-secrets
              key: jwt-secret
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: armsphere-api-service
spec:
  selector:
    app: armsphere-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3001
  type: LoadBalancer
```

Deploy:
```bash
kubectl apply -f k8s/deployment.yaml
```

### Option 3: Cloud Platforms

#### AWS ECS
```bash
# Push images to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag armsphere:api 123456789.dkr.ecr.us-east-1.amazonaws.com/armsphere:api-latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/armsphere:api-latest

# Create ECS task definition and service
aws ecs create-service --cluster armsphere --service-name armsphere-api --task-definition armsphere-api --desired-count 3
```

#### Heroku
```bash
heroku container:push web -a armsphere-prod
heroku container:release web -a armsphere-prod
heroku config:set NODE_ENV=production -a armsphere-prod
heroku config:set JWT_SECRET=<your-secret> -a armsphere-prod
```

#### Google Cloud Run
```bash
gcloud builds submit --tag gcr.io/your-project/armsphere:api
gcloud run deploy armsphere-api --image gcr.io/your-project/armsphere:api \
  --platform managed --region us-central1 \
  --set-env-vars DATABASE_URL=<your-db>,JWT_SECRET=<secret>
```

---

## Database Migrations

### Running Migrations

```bash
# Development
npm run migrate

# Production (with Docker)
docker-compose exec api npm run migrate
```

### Creating New Migrations

```bash
npm run migration:generate -- <migration-name>
```

---

## Monitoring & Logging

### Health Checks

```bash
# API health
curl http://localhost:3001/health

# Database connectivity
curl http://localhost:3001/health/db
```

### Logs

```bash
# Development - Docker Compose
docker-compose logs -f api

# Production - Container logs
docker logs armsphere-api -f

# Kubernetes
kubectl logs -f deployment/armsphere-api
```

### Metrics & APM

For production, integrate with:
- **Datadog**: `npm install dd-trace`
- **New Relic**: `npm install newrelic`
- **Sentry**: `npm install @sentry/node`

---

## Backup & Recovery

### Database Backup

```bash
# Local backup
docker-compose exec postgres pg_dump -U armsphere armsphere > backup.sql

# Restore
docker-compose exec -T postgres psql -U armsphere armsphere < backup.sql
```

### Automated Backups (Production)

Use managed database backups:
- AWS RDS: Automated backups enabled, 30-day retention
- Google Cloud SQL: Automated backups enabled
- Azure Database: Automated backups to geo-redundant storage

---

## Security Checklist

- ✅ Database credentials in secrets management (not .env)
- ✅ JWT secrets rotated regularly
- ✅ SSL/TLS certificates installed
- ✅ Firewall rules configured (only expose 80/443)
- ✅ Regular security updates for dependencies
- ✅ Rate limiting enabled on API endpoints
- ✅ CORS properly configured
- ✅ SQL injection prevented (Drizzle ORM)
- ✅ XSS protected (React escape by default)
- ✅ CSRF tokens in forms

---

## Troubleshooting

### API fails to start
```bash
# Check database connection
docker-compose exec api npm run migrate

# Check environment variables
docker-compose exec api env | grep DATABASE_URL
```

### Database connection refused
```bash
# Ensure PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres
```

### High memory usage
```bash
# Check node process
docker stats

# Increase memory limit in docker-compose.yml
# Then redeploy
docker-compose restart api
```

### Deployment rollback
```bash
# Keep previous image tag
docker tag armsphere:api-1.0.0 armsphere:api-stable

# Rollback if needed
docker-compose up -d  # uses latest in docker-compose.yml
# Update to image: armsphere:api-stable if issues arise
docker-compose up -d
```

---

## Performance Optimization

### Caching
```bash
# Redis cache layer (optional)
docker pull redis:7-alpine
docker run -d --name armsphere-redis -p 6379:6379 redis:7-alpine
```

### Database Indexing
```sql
CREATE INDEX idx_athletes_rating ON athlete_profiles(rating);
CREATE INDEX idx_matches_created ON matches(created_at);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
```

### CDN Setup
- Serve frontend assets from CDN (Cloudflare, AWS CloudFront)
- Cache static assets with 1-year expiry
- Use GZip compression

---

## Deployment Checklist

Before going live:
- ✅ All tests passing (306/306)
- ✅ Environment variables configured
- ✅ Database backups configured
- ✅ SSL/TLS certificates installed
- ✅ DNS records updated
- ✅ Monitoring/alerting set up
- ✅ Runbooks created
- ✅ Team trained on deployment process
- ✅ Rollback plan documented
- ✅ Security audit completed

---

## Support & Maintenance

### Scheduled Maintenance
- Database backups: Daily at 2 AM UTC
- Security patches: Weekly
- Feature deployments: Wednesday 10 AM UTC
- Major upgrades: Quarterly

### Incident Response
1. Alert triggered → page on-call engineer
2. Assess impact and severity
3. Activate war room if P1
4. Implement fix or rollback
5. Post-incident review within 24 hours

---

## Additional Resources

- [Architecture Documentation](./ArmSphere_Architecture_Freeze_v1.0.md)
- [API Documentation](./apps/api/README.md)
- [Admin Web Guide](./apps/admin-web/README.md)
- [Testing Guide](./TESTING.md)
- [Contributing Guidelines](./CONTRIBUTING.md)
