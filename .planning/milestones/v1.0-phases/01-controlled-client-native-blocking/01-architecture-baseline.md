# 01 Architecture Baseline

## Public API Only

FreeSocial uses only documented iOS APIs and approved entitlements. No private frameworks, no runtime injection, and no cross-app UI manipulation.

## Trust Boundaries

1. Controlled Client Boundary
- Handles OAuth-authorized, officially exposed platform surfaces only.
- Provides finite-session social consumption UX with intentional friction.

2. Native App Boundary
- Instagram/TikTok native apps are managed only through Screen Time stack:
  - `FamilyControls`
  - `ManagedSettings`
  - `DeviceActivity`
- No attempt to modify native in-app UI surfaces (e.g., Reels tab internals).

3. Compliance Boundary
- All user-facing claims must map to capability evidence in claims matrix.
- Unsupported features must have explicit fallback and limitation disclosure.

## Allowed Controls

- App/domain/category shielding via ManagedSettings.
- Schedule/threshold enforcement and reassertion via DeviceActivity.
- Controlled-client finite-batch content flows.
- Intervention UX (cooldowns, delays, blocked state messages).

## Disallowed Controls

- Private APIs or reverse-engineered app control.
- Claims of DM/feed parity where APIs do not allow it.
- Hidden monitoring or undisclosed behavior.

## Architecture Components

- iOS Host App
  - Policy editor, auth state, user controls
  - OAuth integration manager (official providers only)
- App Group Policy Store
  - Selected app/domain/category tokens
  - Escalation state and cooldown counters
- Extensions
  - DeviceActivityMonitor extension
  - ShieldConfiguration extension
  - ShieldAction extension
- Controlled Client Module
  - Finite feed renderer
  - Fallback handoff router

## Anti-Bypass Objective

Make bypass meaningfully harder while staying inside public API limits:
- Layered shielding and category safety net
- Deterministic escalation policy
- Deauthorization detection + recovery path

## Requirement Traceability

- CC-01: Controlled client exists with enforced finite-feed model.
- NB-01: Native restrictions defined through Screen Time APIs.
- POL-01/POL-03: Baseline includes claims boundaries and explicit limitations.
