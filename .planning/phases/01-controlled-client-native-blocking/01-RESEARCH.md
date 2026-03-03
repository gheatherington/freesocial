# Phase 1: Controlled Client + Native Blocking - Research

**Date:** 2026-03-03
**Phase:** 1

## Standard Stack

- iOS app targets:
  - Main app
  - `DeviceActivityMonitor` extension
  - `ShieldConfiguration` extension
  - `ShieldAction` extension
  - Optional `DeviceActivityReport` extension
- Core frameworks:
  - `FamilyControls`
  - `ManagedSettings`
  - `DeviceActivity`
- Shared state:
  - App Group storage for policy snapshots and selected tokens
- Optional controlled client layer:
  - OAuth-based official SDK/API integrations only (TikTok/Meta where permitted)
  - Strictly finite content session UX (no infinite feed)

## Architecture Patterns

### Pattern A: Layered Native Blocking (enforcement backbone)
- Use token-based app/domain/category selection via `FamilyActivityPicker`.
- Apply shields via named `ManagedSettingsStore` layers:
  - `baseline_social`
  - `policy_schedule`
  - `incident_lockdown`
- Reassert policy from app lifecycle + monitor callbacks to handle drift.
- Treat deauthorization status as first-class state transition.

### Pattern B: Controlled Client as Constrained Companion
- Build a distinct client experience with strict feed suppression mechanics.
- Use official OAuth/API scopes only.
- Explicitly avoid parity claims with first-party native apps.
- Handoff unsupported actions via deep links to web/native where policy permits.

### Pattern C: Anti-Bypass Escalation Ladder
- Base restrictions (selected apps/domains).
- Category catch-all protections.
- Time/threshold cooldown and lock windows.
- Escalation after repeated bypass attempts.
- User-facing transparency for why access changed.

## Capability Boundaries (Critical)

### Feasible (high confidence)
- App/domain/category-level shielding and timed interventions in native apps.
- Strong suppression UX in your own controlled client (finite batch, autoplay off, cooldowns).
- Limited API-powered data/actions where official platform scopes allow.

### Not Feasible / High-Risk
- Directly modifying Instagram/TikTok native in-app UI surfaces (Reels-only off, DM-only on).
- Full consumer parity replacement client for Instagram/TikTok.
- Unofficial scraping/reverse-engineered APIs.

## Compliance and Policy Findings

- App Review-safe path exists if claims are bounded and implementation uses approved APIs.
- Highest rejection vectors:
  - misleading capability claims
  - hidden behavior
  - private/undocumented APIs
  - unauthorized third-party content integration
- Must present clear user-facing limitation disclosures and review notes.
- Apple Guideline 5.2.2 risk is central for third-party service access.

## Don't Hand-Roll

- Do not build unsupported UI hooks into third-party native apps.
- Do not build scraping clients for Instagram/TikTok content or messaging.
- Do not rely on brittle endpoint-level feed filtering as primary consumer path.

## Common Pitfalls

- Assuming `.individual` auth has parental-grade anti-removal guarantees.
- Over-promising DM/feed parity unavailable via official APIs.
- Relying on single callback timing semantics in `DeviceActivity`.
- Missing deauthorization recovery path and policy reassertion loop.

## Recommended MVP Scope

1. Controlled Client MVP
- OAuth connect where available
- finite-feed session UX
- no DM parity promises
- strict “not full replacement” positioning

2. Native Blocking MVP
- Token selection (apps/domains/categories)
- schedule + threshold enforcement
- cooldown + escalation ladder
- deauth detection and recovery UX

3. Compliance MVP
- explicit claim matrix (what is guaranteed vs not)
- App Review notes package
- third-party API authorization evidence tracking

## Sources

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Configuring Family Controls: https://developer.apple.com/documentation/xcode/configuring-family-controls
- FamilyActivityPicker: https://developer.apple.com/documentation/familycontrols/familyactivitypicker
- ManagedSettings ShieldSettings: https://developer.apple.com/documentation/managedsettings/shieldsettings
- DeviceActivity monitoring API: https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/startmonitoring(_:during:events:)
- WWDC 2021 Screen Time API: https://developer.apple.com/videos/play/wwdc2021/10123/
- WWDC 2022 Screen Time API updates: https://developer.apple.com/videos/play/wwdc2022/110336/
- TikTok Login Kit: https://developers.tiktok.com/doc/login-kit-overview
- TikTok Display API: https://developers.tiktok.com/doc/display-api-overview
- TikTok API scopes: https://developers.tiktok.com/doc/tiktok-api-scopes/
- TikTok Terms: https://www.tiktok.com/legal/page/us/terms-of-service/en
- Meta/Instagram official Postman docs: https://www.postman.com/meta/instagram/documentation/6yqw8pt/instagram-api

## Confidence

- High: native in-app surface control is unavailable via public iOS APIs.
- High: controlled client + native blocking hybrid is feasible with strict boundaries.
- Medium: exact third-party endpoint capabilities and partner access can shift; verify during implementation.
