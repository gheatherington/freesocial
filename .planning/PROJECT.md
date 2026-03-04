# FreeSocial

## Current Milestone: v1.1 Implementation

**Goal:** Build a fully working app with controlled WKWebView feed, Screen Time enforcement, and onboarding so the core experience is usable and testable on simulator.

**Target features:**
- Onboarding: FamilyControls authorization, consent/disclosure, session limit setup, platform selection
- Controlled feed: WKWebView for Instagram + TikTok with session time tracking
- Screen Time enforcement: Shield blocks native apps when daily limit is reached
- Dashboard + Feed UI: usage summary home screen, feed tab with platform switcher
- Consent persistence and revocation with App Group, wired to telemetry write-gating

## What This Is

FreeSocial is an iOS product focused on reducing addictive social scrolling while preserving practical communication use. The product combines a controlled WKWebView feed (Instagram/TikTok) with Screen Time native-app blocking, gating users to timed sessions. The v1.0 milestone established the architecture baseline; v1.1 fills all stubs with real implementation.

## Core Value

Users can stay connected without being pulled into compulsive feed consumption.

## Requirements

### Validated

- ✓ Controlled client path with feed-level restrictions — v1.0 (SocialProvider protocol, FeedView, InterventionView scaffold)
- ✓ Native app blocking/gating to prevent bypass — v1.0 (Screen Time extension targets, EscalationLevel policy, BypassEvent chain)
- ✓ Consumer App Store-compatible first release — v1.0 (APP_REVIEW_PREFLIGHT.md, claims matrix, prohibited copy enumerated)

### Active

- [ ] Onboarding flow: FamilyControls auth request, consent/disclosure, session limit setup, platform selection
- [ ] Controlled WKWebView feed for Instagram and TikTok with session timer
- [ ] Screen Time shield enforcement when daily session limit is reached
- [ ] Dashboard UI showing per-platform usage summary and remaining time
- [ ] Consent capture and revocation with App Group persistence (ConsentStore wired)
- [ ] PolicyRepository write-gating: recordBypassEvent blocked when consent revoked
- [ ] Deauthorization detection and recovery path in AuthorizationManager
- [ ] BypassEvent schema expansion to match Phase 1 telemetry spec
- [ ] 9 limitation disclosure strings in onboarding and Settings UI
- [ ] XCTest UAT stubs replaced with real assertions (all 9 requirements)

### Out of Scope

- Android launch in v1 — defer until iOS architecture is proven
- Full Instagram/TikTok feature parity — constrained by third-party APIs/terms
- ConsentManager importing PolicyStore directly — resolve via dependency injection or shared Foundation package instead

## Context

Shipped v1.0 with 679 LOC Swift across 4 SPM packages and 3 App extensions.
Tech stack: Swift 5.9, SwiftUI (iOS 16.0), FamilyControls, DeviceActivity, ManagedSettings, ManagedSettingsUI, XCTest.
Build verified on Xcode.app — xcodebuild BUILD SUCCEEDED on iOS 26.2 simulator (iPhone 17) as of 2026-03-04.
ConsentManager AppGroup access pattern resolved: inject suiteName via ConsentStore.init; callers pass AppGroup.suiteName.

## Constraints

- **Platform**: iOS public API + App Store policies — required for distribution
- **Legal/Platform Terms**: Third-party social APIs/terms constrain replacement-client scope
- **Enforcement**: Must reduce bypass paths, not just add passive reminders
- **Simulator target**: v1.1 targets iOS Simulator (iPhone 17 / iOS 26.2) — real-device FamilyControls entitlements deferred to v1.2

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Option 1 (Controlled Client + Native Blocking) is planning target | Maximizes enforceability within iOS constraints | ✓ Good — shipped as v1.0 architecture and scaffold |
| Consumer App Store path is primary | Required market model | ✓ Good — APP_REVIEW_PREFLIGHT.md assembled as submission gate |
| project.pbxproj hand-written (no Tuist/XcodeGen) | Reproducibility without tooling dependencies | ✓ Good — consistent across Plans 02-01 and 02-02 |
| #if canImport(FamilyControls) guard in AuthorizationManager | Prevent CI failures without Xcode.app | ✓ Good — structural checks pass; runtime gate deferred to CI |
| AppGroup.suiteName defined in exactly one file (PolicyStore.AppGroup) | Single source of truth, never hardcoded elsewhere | ✓ Good — verified by grep across all Swift files |
| ShieldConfiguration extension uses UIKit struct API only | ManagedSettingsUI is UIKit-backed; no SwiftUI in extensions | ✓ Good — correct per ManagedSettings framework constraint |
| APP_REVIEW_PREFLIGHT.md is the canonical stop-ship gate | Single assembled document; no cross-file lookup required at submission | ✓ Good — 7 blocking conditions, POL-01/02/03 traced |
| ConsentManager AppGroup access: inject suiteName via ConsentStore.init | Package independence preserved; callers pass AppGroup.suiteName | ✓ Good — resolved 2026-03-04 |
| WKWebView controlled feed (not public API) | Instagram/TikTok public APIs too limited; terms restrict replacement clients | ✓ Good — web view gives session control without API dependency |
| Screen Time shield-only blocking (no escalation in v1.1) | Simpler flow for initial implementation; escalation deferred to v1.2 | — Pending |

---
*Last updated: 2026-03-04 after v1.1 milestone start*
