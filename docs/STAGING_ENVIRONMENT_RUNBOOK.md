# ArmSphere Isolated Staging Environment Runbook & Architecture

## 1. Staging Architecture Overview & Selection Rationale

ArmSphere uses **Neon Serverless PostgreSQL** with connection pooling (`pg.Pool` with Neon PgBouncer).
To guarantee 100% database isolation without risking production data or creating synthetic records in production:

- **Selected Architecture**: **Dedicated Neon Staging Branch (`NEON_BRANCH=staging`)**
- **Configuration Pattern**: `.env.staging` (strictly gitignored, with `.env.staging.example` template)
- **Hard Safety Invariant**: Automated guard (`apps/api/src/config/databaseGuard.ts`) that programmatically blocks any mutation or test run if the database target matches production signatures.

### Why this option was chosen:
1. **True Cryptographic & Compute Isolation**: A Neon branch is a separate copy-on-write or schema-isolated PostgreSQL cluster with its own unique endpoint (`ep-staging-*.neon.tech`). Mutations, table drops, or resets in `staging` can never touch `main`.
2. **Native to ArmSphere Stack**: Directly compatible with `@armsphere/db-schema`, Drizzle migrations (`apps/api/migrations`), and serverless connection limits.
3. **Reproducible in CI**: The exact same schema and migration path run in GitHub Actions using an isolated `postgres:16-alpine` service container.

---

## 2. Manual Prerequisites (Neon Console Setup)

Because Neon API keys are intentionally not tracked in this repository, the initial staging branch must be created in the Neon Web Console:

1. **Log into Neon Console**: Navigate to [https://console.neon.tech](https://console.neon.tech).
2. **Select ArmSphere Project**: Open the active project (containing database `neondb`).
3. **Create Staging Branch**:
   - In the left sidebar, click **Branches**.
   - Click the **New Branch** button.
   - Set **Branch Name**: `staging`.
   - Set **Parent Branch**: `main` (or create an empty branch to test migrations from scratch).
   - Click **Create Branch**.
4. **Copy Connection Details**:
   - In the branch dashboard, locate the **Connection Details** widget.
   - Ensure the database is `neondb` and role is `neondb_owner` (or create a dedicated `staging_owner` role).
   - Copy the **Pooled connection string** (e.g., `postgresql://...ep-staging-...-pooler...neon.tech/neondb?sslmode=require`).
   - Copy the **Direct (Unpooled) connection string** (e.g., `postgresql://...ep-staging-...neon.tech/neondb?sslmode=require`).

---

## 3. Local Setup & Configuration

1. In the repository root, create your local `.env.staging` file from the template:
   ```bash
   cp .env.staging.example .env.staging
   ```
2. Open `.env.staging` and update the database URLs with your new staging branch endpoint:
   ```env
   NODE_ENV=staging
   NEON_BRANCH=staging
   PORT=4000
   DATABASE_URL=postgresql://staging_user:PASSWORD@ep-staging-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require
   DATABASE_URL_UNPOOLED=postgresql://staging_user:PASSWORD@ep-staging-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
3. The `.gitignore` configuration guarantees that `.env.staging` will never be committed to Git.

---

## 4. Migration & Staging Operations

Run the following commands from the repository root or `apps/api`:

### 1. Apply Schema Migrations
```bash
npm --prefix apps/api run db:migrate
```
*Applies all 23 Drizzle migrations (0000 through 0022) to the isolated staging database.*

### 2. Seed Approved Staging Fixtures
```bash
npm --prefix apps/api run db:seed:staging
```
*Seeds low-privilege test users, profiles, and an isolated staging event. All emails use `@armsphere.staging`.*

### 3. Safe Staging Reset
```bash
npm --prefix apps/api run db:reset:staging
```
*Wipes and re-migrates ONLY the staging database. Blocked by automated guard if pointed at production.*

---

## 5. Hard Production-Safety Invariant Guard

The module `apps/api/src/config/databaseGuard.ts` implements automated protection:

```typescript
assertIsolatedStagingDatabase(actionName: string): void
```

### Invariant Rules Enforced:
- **Rule 1**: If `NEON_BRANCH` is `main`, `production`, or `master`, the operation immediately throws `SafetyGuardError` (`PRODUCTION_DATABASE_MUTATION_BLOCKED`) and exits with code 1.
- **Rule 2**: If the connection string host matches known production clusters (`ep-orange-hat-b5myi34s`), it aborts before sending any query.
- **Rule 3**: If `NODE_ENV === "production"`, test and staging mutations are rejected.
- **Rule 4**: If the database URL cannot be positively identified as staging, test, or localhost, execution is refused.

---

## 6. Approved Staging Fixture Inventory

| Identity | Role | Province | Email | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Staging Admin** | `SUPER_ADMIN` | National | `admin@armsphere.staging` | Full administrative control in staging |
| **Punjab Director** | `PROVINCIAL_HEAD` | Punjab | `punjab.director@armsphere.staging` | Provincial jurisdiction testing |
| **Senior Referee** | `REFEREE` | Punjab | `referee.official@armsphere.staging` | Table refereeing & scorepad testing |
| **Alpha Athlete** | `ATHLETE` | Punjab | `athlete.alpha@armsphere.staging` | Right Arm 75kg competitor (Seed 1) |
| **Beta Athlete** | `ATHLETE` | Punjab | `athlete.beta@armsphere.staging` | Right Arm 75kg competitor (Seed 2) |

**Staging Event**: `"ArmSphere Staging Invitational 2026"`
- Bracket: Senior Men Right 75kg (Double Elimination)
- Table: Table 1 (Arena Stage)
- Status: `PUBLISHED` / `ACTIVE`
