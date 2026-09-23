# ArmSphere Production Runbook

Authoritative operational runbook for the ArmSphere production platform.

All operational procedures in this document are strictly categorized by their verification status:
- **[DEMONSTRATED]**: Verified by direct empirical command, automated test, live HTTP probe, or system drill.
- **[DOCUMENTED]**: Defined in architecture specifications and verified by codebase inspection.
- **[ASSUMED]**: Inferred from platform defaults; requires manual verification before relying on it during an emergency.
- **[NOT AVAILABLE]**: Capability not supported on current zero-cost tier or environment.

---

## 1. System Topology & Architecture [DEMONSTRATED]

The ArmSphere production deployment routes traffic through a zero-cost, private origin architecture:

```
[Public Internet / Mobile Clients]
                │
                ▼ (HTTPS :443)
┌─────────────────────────────────────────────────────────────┐
│ Cloudflare Worker Edge Gateway                              │
│ Host: armsphere-api-gateway.armsphere.workers.dev           │
│ Logic: Thin reverse proxy, duplex streaming, zero auth      │
└─────────────────────────────────────────────────────────────┘
                │
                ▼ (Workers VPC Service Binding)
┌─────────────────────────────────────────────────────────────┐
│ Cloudflare Zero Trust Tunnel                                │
│ Process: cloudflared.exe (Windows Service: cloudflared)     │
│ Protocol: QUIC / outbound TLS tunnel                        │
└─────────────────────────────────────────────────────────────┘
                │
                ▼ (Loopback TCP 127.0.0.1:4000)
┌─────────────────────────────────────────────────────────────┐
│ ArmSphere API Engine (Windows Service: ArmSphereAPI)        │
│ Supervisor: NSSM 2.24 (LocalSystem)                         │
│ Runtime: Node.js v22.14.0                                   │
│ App Entry: E:\ArmSphere\apps\api\dist\server.js             │
│ Env Config: C:\ProgramData\ArmSphere\production.env         │
└─────────────────────────────────────────────────────────────┘
                │
                ▼ (TLS encrypted outbound connection)
┌─────────────────────────────────────────────────────────────┐
│ Neon Serverless PostgreSQL                                  │
│ Endpoint: ep-round-glitter-a1l0g1d2-pooler.ap-southeast-1  │
│ Database: neondb (58 tables, 86 foreign keys)               │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Host Services & Runtime Management [DEMONSTRATED]

### Service Inventory
| Service Name | Display Name | Process | Account | Start Type | Failure Action |
| --- | --- | --- | --- | --- | --- |
| `ArmSphereAPI` | ArmSphere Production API Engine | `nssm.exe` → `node.exe` | LocalSystem | Automatic | Restart after 5000ms |
| `cloudflared` | Cloudflared agent | `cloudflared.exe` | LocalSystem | Automatic | Restart after 20000ms |

### Starting and Stopping Services (Administrator PowerShell)
```powershell
# Check service health
Get-Service -Name "ArmSphereAPI", "cloudflared"

# Restart API Service
Restart-Service -Name "ArmSphereAPI"

# Restart Tunnel Service
Restart-Service -Name "cloudflared"
```
*Note: Due to Windows Security Architecture, modifying or terminating LocalSystem services requires an elevated Administrator command prompt.*

### Service Logs and Rotation [DEMONSTRATED]
- **Standard Output**: `C:\ProgramData\ArmSphere\api.log`
- **Standard Error**: `C:\ProgramData\ArmSphere\api_error.log`
- **Log Rotation**: Configured via NSSM with `AppRotateBytes = 0xa00000` (10 MB per file, online rotation enabled).

---

## 3. Production Health Probes [DEMONSTRATED]

Verify production gateway health from any authorized terminal:

```bash
# Gateway Liveness Check (In-memory edge probe)
curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/health
# Expected: HTTP 200 OK, Body: "OK"

# Comprehensive Dependency Health Check (Probes Neon DB ping)
curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/api/health
# Expected: HTTP 200 OK, Body contains: "status":"healthy","database":"healthy"

# Traffic Readiness Probe (Checks DB connectivity & fallback state)
curl -s -i https://armsphere-api-gateway.armsphere.workers.dev/api/ready
# Expected: HTTP 200 OK, Body contains: "status":"ready","ready":true
```

---

## 4. Payment Operations: MANUAL_QR Routing [DOCUMENTED]

Due to payment processing constraints (Stripe Pakistan regional availability limitations), `MANUAL_QR` is configured as a first-class payment rail alongside Stripe:

### Workflow
1. **Initiation**: Athlete selects entry fee payment via `MANUAL_QR`.
2. **Display**: Client renders official tournament operator QR code (Raast / EasyPaisa / JazzCash / Bank IBAN).
3. **Submission**: Athlete uploads payment reference / transaction ID or receipt screenshot.
4. **Pending Verification**: Registration state transitions to `PAYMENT_PENDING_APPROVAL`.
5. **Operator Reconciliation**: Tournament Director or Organizer reviews incoming funds against the reference code in Organizer Dashboard.
6. **Approval**: Operator approves payment; registration status transitions to `CONFIRMED`.
7. **Audit**: Action logged under `audit_logs` table (`PAYMENT_MANUAL_VERIFIED`).

---

## 5. Secret & Credential Handling [DEMONSTRATED]

- Production credentials are kept exclusively in `C:\ProgramData\ArmSphere\production.env`.
- No credentials exist in Git repositories, commit messages, or public pull requests.
- All secrets are excluded via `.gitignore`.
- When rotating credentials, update `C:\ProgramData\ArmSphere\production.env` and restart the `ArmSphereAPI` service.

---

## 6. Emergency Operations [DOCUMENTED]

### Emergency API Halt
To immediately suspend traffic without dropping cloud infrastructure:
```powershell
# Run from Administrator PowerShell
Stop-Service -Name "ArmSphereAPI"
```
Cloudflare Worker will return HTTP 502 Bad Gateway to incoming requests while origin is halted.

### Emergency Host Recovery
If the host encounters an unhandled system fault:
1. Boot Windows host.
2. `ArmSphereAPI` and `cloudflared` start automatically via Windows Service Control Manager.
3. Verify public gateway probe responds HTTP 200.
