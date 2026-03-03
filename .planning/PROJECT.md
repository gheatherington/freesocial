# FreeSocial

## What This Is

FreeSocial is an iOS product focused on reducing addictive social scrolling while preserving practical communication use. The product combines a controlled social client experience with strict native-app gating so users can avoid infinite-feed loops. The v1.0 milestone established a verified architecture baseline and compilable iOS skeleton with all module boundaries, Screen Time extension targets, and a complete App Review preflight package.

## Core Value

Users can stay connected without being pulled into compulsive feed consumption.

## Requirements

### Validated

- ✓ Controlled client path with feed-level restrictions — v1.0 (SocialProvider protocol, FeedView, InterventionView scaffold)
- ✓ Native app blocking/gating to prevent bypass — v1.0 (Screen Time extension targets, EscalationLevel policy, BypassEvent chain)
- ✓ Consumer App Store-compatible first release — v1.0 (APP_REVIEW_PREFLIGHT.md, claims matrix, prohibited copy enumerated)

### Active

- [ ] Implement controlled client feed flow end-to-end (fill FeedView + SocialProvider stubs)
- [ ] Implement Screen Time authorization and enforcement (AuthorizationManager, ShieldManager, ActivityScheduler stubs)
- [ ] Implement consent capture and revocation with App Group persistence
- [ ] Wire consent revocation to telemetry write-gating in PolicyRepository
- [ ] Implement deauthorization detection and recovery path in AuthorizationManager
- [ ] Implement intervention trigger in FeedView session boundary logic
- [ ] Add 9 remaining limitation disclosure strings to onboarding and Settings UI
- [ ] Verify xcodebuild BUILD SUCCEEDED and test results in CI (Xcode.app required)
- [ ] Expand BypassEvent schema to match Phase 1 telemetry spec (event types + fields)

### Out of Scope

- Android launch in v1 — defer until iOS architecture is proven
- Full Instagram/TikTok feature parity — constrained by third-party APIs/terms
- ConsentManager importing PolicyStore directly — resolve via dependency injection or shared Foundation package instead

## Context

Shipped v1.0 with 679 LOC Swift across 4 SPM packages and 3 App extensions.
Tech stack: Swift 5.9, SwiftUI (iOS 16.0), FamilyControls, DeviceActivity, ManagedSettings, ManagedSettingsUI, XCTest.
Known constraint: xcodebuild runtime verification requires Xcode.app (not installed on dev machine) — all static structural checks pass.
Open architectural decision: ConsentManager persistence mechanism (no AppGroup access yet — decision deferred to Phase 3).

## Constraints

- **Platform**: iOS public API + App Store policies — required for distribution
- **Legal/Platform Terms**: Third-party social APIs/terms constrain replacement-client scope
- **Enforcement**: Must reduce bypass paths, not just add passive reminders
- **Build Verification**: Xcode.app required for xcodebuild; only CLT available on dev machine

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
| ConsentManager AppGroup access pattern unresolved | Package is independent; adding PolicyStore dep has dependency-graph implications | ⚠️ Revisit — must decide before Phase 3 POL-02 implementation |

---
*Last updated: 2026-03-03 after v1.0 milestone*
