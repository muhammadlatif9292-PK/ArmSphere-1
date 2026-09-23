# ArmSphere Post-Launch Verification Protocol (T+24h & T+72h)

This protocol governs the operational checks to be executed 24 hours and 72 hours after public launch approval.

---

## 1. T+24h Operational Inspection Checklist

At approximately 24 hours following public traffic admission:

1. **Uptime & Endpoint Health**:
   ```bash
   curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/health
   curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/api/health
   curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/api/ready
   ```
   *Expectation: All endpoints return HTTP 200.*

2. **Database Engine & Connection Pool Health**:
   Execute diagnostic query on host:
   ```powershell
   node -e "const { Client } = require('E:/ArmSphere/node_modules/pg'); const c = new Client({ connectionString: require('fs').readFileSync('C:/ProgramData/ArmSphere/production.env','utf8').match(/^DATABASE_URL=(.+)$/m)[1].trim() }); c.connect().then(async () => { const r = await c.query('SELECT count(*) FROM pg_stat_activity WHERE state = \'active\';'); console.log('Active queries:', r.rows[0].count); c.end(); });"
   ```
   *Expectation: Active connection count within bounds (< 10).*

3. **Tunnel Stability & Error Logs**:
   Check host Windows Service logs for crash or restart events:
   - `C:\ProgramData\ArmSphere\api.log`
   - `C:\ProgramData\ArmSphere\api_error.log`
   *Expectation: Zero unhandled process exits.*

4. **Security & Authentication Anomalies**:
   Inspect audit log for token reuse alerts or lockouts:
   ```sql
   SELECT action, count(*) FROM audit_logs WHERE created_at > NOW() - INTERVAL '24 hours' GROUP BY action;
   ```

5. **Storage & Queue Health**:
   - Check `scheduled_jobs` table to ensure no runaway jobs exist (> 1h runtime).

---

## 2. T+72h Operational Inspection Checklist

Repeat all checks from T+24h.
Additionally:
- Review cumulative error rate in Cloudflare Workers Analytics dashboard.
- Verify manual QR payment reconciliation queue in Organizer Dashboard.
- Audit table storage growth in Neon console.
