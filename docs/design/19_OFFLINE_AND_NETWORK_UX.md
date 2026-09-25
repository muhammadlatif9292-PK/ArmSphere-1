# ArmSphere Offline & Network Resilience UX
**Local Caching, Optimistic Synchronization & Network Edge States**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Network Philosophy & Venue Realities

Armwrestling tournaments frequently occur in basements, community sports halls, and rural arenas where 4G/5G cellular coverage is unstable. 

**Rule: Network interruption must never produce an unreadable blank screen or cause lost match scores.**

---

## 2. The 4 Network States

```
┌─────────────────────────────────────────────────────────────────┐
│                     THE 4 NETWORK STATES                        │
├───────┬──────────────────────┬──────────────────────────────────┤
│ State │ Condition            │ UX Behavior & Visual Indicators  │
├───────┼──────────────────────┼──────────────────────────────────┤
│ N1    │ Online / Fast        │ Seamless real-time sync (<800ms) │
│ N2    │ Degraded / High RTT  │ Progress indicators, 30s timeout │
│ N3    │ Offline (Cached)     │ Slim top banner, local Hive data │
│ N4    │ Offline (Uncached)   │ Actionable AppEmptyState + retry │
└───────┴──────────────────────┴──────────────────────────────────┘
```

---

## 3. Offline UI Presentation & Visual Indicators

1. **Non-Intrusive Offline Banner**:
   - A 28dp slim bar smoothly slides down from the AppBar when connection drops:
   ```
   [ ⚡ Offline Mode — Displaying cached tournament schedule ]
   ```
   - Color: `#1E293B` background with 1px amber border (`#F59E0B`). Never blocks navigation or covers interactive buttons.
2. **Stale Data Timestamp**:
   - If cached data is older than 15 minutes, a subtitle beneath the page title displays:
   `"Cached snapshot from 2:15 PM • Pull down to refresh"`.

---

## 4. Optimistic Action Queue (`pendingActions`)

Actions permitted while offline are stored immediately in the local Hive `pendingActions` box and reflected instantly in the UI:

| User Action | Offline Allowed? | Sync Reconciliation Strategy |
| :--- | :---: | :--- |
| **Log Training PR** | **YES** | Assigned local UUID; uploaded upon connection restoration. |
| **Like Community Post**| **YES** | Local counter increments; syncs idempotently. |
| **Follow Competitor** | **YES** | Follow state toggles locally; syncs via background queue. |
| **Record Match Score**| **YES (Refs)** | Scorepad preserved in Hive with signed SHA-256 hash. Replays to server upon reconnection. |
| **Stripe Registration**| **NO** | Disabled. Requires live payment gateway session. |
| **Delete Account** | **NO** | Disabled. Requires server-side identity verification. |
