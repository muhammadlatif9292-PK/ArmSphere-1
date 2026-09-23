# ArmSphere Incident Response Protocol

Standard Operating Procedure for triaging, mitigating, and resolving operational and security incidents on the ArmSphere platform.

---

## 1. Incident Severity Classification [DOCUMENTED]

| Severity | Definition | Target Response | Target Resolution | Examples |
| --- | --- | --- | --- | --- |
| **SEV-1 (Critical)** | Core production system is unavailable; users cannot authenticate; database down. | < 15 minutes | < 1 hour | Gateway returning 502/504; Neon connection exhaustion; Host down. |
| **SEV-2 (Major)** | Major functionality impaired; workaround available; security alert triggered. | < 30 minutes | < 4 hours | Token reuse alert; manual QR payment uploads failing; queue processing delayed. |
| **SEV-3 (Minor)** | Non-critical bug; performance degradation within acceptable bounds; cosmetic issue. | < 4 hours | < 24 hours | Non-blocking UI glitch; localized ranking calculation discrepancy. |

---

## 2. Operational Failure Playbooks [DEMONSTRATED]

### Playbook A: Gateway Returning HTTP 502 Bad Gateway / 504 Timeout
**Root Cause**: Private Windows API origin is offline or Cloudflare tunnel is disconnected.

**Triage Steps**:
1. Check Cloudflare Tunnel Service on host:
   ```powershell
   Get-Service -Name "cloudflared"
   ```
   If stopped:
   ```powershell
   Start-Service -Name "cloudflared"
   ```
2. Check ArmSphere API Service on host:
   ```powershell
   Get-Service -Name "ArmSphereAPI"
   ```
   If stopped:
   ```powershell
   Start-Service -Name "ArmSphereAPI"
   ```
3. Test local loopback binding:
   ```powershell
   curl -I http://127.0.0.1:4000/health
   ```
   If local responds HTTP 200, tunnel routing is re-synchronizing. Wait 10-15 seconds and re-check public gateway.

---

### Playbook B: Database Connection Errors / Health Check Degraded
**Root Cause**: Neon connection pool exhausted, network partition to Neon cloud, or cold-start timeout.

**Triage Steps**:
1. Probe `/api/health`:
   ```bash
   curl -s https://armsphere-api-gateway.armsphere.workers.dev/api/health
   ```
2. Inspect `C:\ProgramData\ArmSphere\api_error.log` for PgBouncer / Neon error codes.
3. Check pool metrics via administrative query:
   - Ensure idle client connections have not leaked.
   - Max connection pool is bounded to 10 in production (`config/db.ts`).
4. If Neon compute branch is suspended or undergoing maintenance:
   - Wait 5-10 seconds for Neon auto-resume.
   - The application pool auto-reconnects on next request (`pool.on("error")`).

---

### Playbook C: Security Alert / Token Reuse Incident
**Root Cause**: A refresh token was reused or an adversarial token forgery was detected (`AUTH_TOKEN_REUSE_ALERT`).

**Triage Steps**:
1. Check `audit_logs` table for recent alerts:
   ```sql
   SELECT * FROM audit_logs WHERE action IN ('AUTH_TOKEN_REUSE_ALERT', 'ACCOUNT_LOCKOUT_TRIGGERED') ORDER BY created_at DESC LIMIT 10;
   ```
2. Identify affected `userId` and `tokenFamily`.
3. Revoke all active sessions for the compromised user:
   ```sql
   UPDATE user_sessions SET is_revoked = true WHERE user_id = '<COMPROMISED_USER_ID>';
   ```
4. If malicious IP is detected, apply IP block rule at Cloudflare Zero Trust / WAF level.

---

## 3. Communication & Escalation [DOCUMENTED]

- **Lead Operator Email**: `Muhammadhamadlatif94747@gmail.com`
- **Zero Trust Alerts**: Cloudflare dashboard notifications dispatched to operator email upon tunnel status change.
