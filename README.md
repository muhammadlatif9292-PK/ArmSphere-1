# ArmSphere Monorepo

ArmSphere is a competitive armwrestling platform featuring a Flutter mobile app, an Express API backend, an admin Web console, and shared workspace packages.

## Monorepo Architecture

```
armsphere/
├── apps/
│   ├── mobile/         # Flutter mobile & web app (Dart / Riverpod)
│   ├── api/            # Express API server (TypeScript / Drizzle ORM / PostgreSQL)
│   └── admin-web/      # Admin Operations Dashboard (React / Vite / Tailwind)
└── packages/
    ├── core/           # Shared core business logic
    ├── cryptography/   # Shared cryptographic utilities
    ├── db-schema/      # Shared Drizzle database schema
    ├── types/          # Shared TypeScript type definitions
    ├── sdk-typescript/ # Generated TypeScript API client SDK
    └── sdk-dart/       # Generated Dart API client SDK
```

## Prerequisites

- **Node.js**: v18+ or v20+
- **Flutter SDK**: 3.22+ (for `apps/mobile`)
- **PostgreSQL**: Local PostgreSQL 15+ for development, or Neon PostgreSQL for production database hosting

## Quick Start

### 1. Workspace Dependencies

Install dependencies across all npm workspace packages:

```bash
npm install
```

### 2. Running the Backend API (`apps/api`)

1. Set up your environment variables in `apps/api/.env`:
   ```env
   PORT=3000
   DATABASE_URL=postgresql://user:password@localhost:5432/armsphere
   JWT_SECRET=your-secret-key
   ```

2. Start the development server:
   ```bash
   npm run dev:api
   ```

3. Run API unit & integration tests:
   ```bash
   npm run test
   ```

### 3. Running the Admin Web Dashboard (`apps/admin-web`)

Start the Vite development server:

```bash
npm run dev:admin
```

### 4. Running the Flutter Mobile App (`apps/mobile`)

1. Install Flutter dependencies:
   ```bash
   cd apps/mobile
   flutter pub get
   ```

2. Run on connected mobile device or web:
   ```bash
   flutter run
   ```

## Development Commands

- `npm install` - Installs root and workspace dependencies.
- `npm run dev:admin` - Starts the React Admin Web dashboard dev server on port 3000.
- `npm run dev:api` - Starts the Node.js API dev server.
- `npm run test` - Runs backend tests in `apps/api`.
- `npm run build` - Builds workspace packages and static web dists.
