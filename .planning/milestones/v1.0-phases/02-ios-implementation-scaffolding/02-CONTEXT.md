# Phase 2: iOS Implementation Scaffolding - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Initialize the iOS Xcode project with all module boundaries established, create skeleton implementations for the controlled client, Screen Time enforcement engine, and policy/consent state manager, convert UAT requirements into executable XCTest stubs, and produce the App Review preflight package. No production logic in this phase — compilable skeletons with correct boundaries only.

</domain>

<decisions>
## Implementation Decisions

### Project setup
- Swift Package Manager-first structure: each major module is a local SPM package
- Single Xcode project (`ios/FreeSocial.xcodeproj`) orchestrates packages and app target
- No third-party project generators (Tuist, XcodeGen) — keep tooling minimal for now

### UI framework
- SwiftUI throughout — all screens, interventions, onboarding, and settings
- No UIKit unless a specific Screen Time API forces it (DeviceActivity/ShieldConfiguration views may require UIViewController wrappers — Claude's discretion)

### Visual design direction
- Dark theme as the default and primary visual mode
- Clean, minimalist aesthetic — generous whitespace, no decorative chrome
- Restrained typography and iconography — nothing competes with content
- This applies to all skeleton views: even placeholder screens should reflect the dark/minimal palette

### Module separation
- Separate local SPM packages per module boundary (matches Phase 1 architecture):
  - `ControlledClient` — finite feed, intervention UX, fallback router
  - `ScreenTimeEngine` — FamilyControls, ManagedSettings, DeviceActivity wrappers
  - `PolicyStore` — App Group state, escalation levels, cooldown counters
  - `ConsentManager` — consent capture, revocation, audit log
- Host app target imports these packages; extensions (DeviceActivityMonitor, ShieldConfiguration, ShieldAction) link only what they need

### Provider scope
- Skeleton stubs both Instagram and TikTok providers behind a generic `SocialProvider` protocol
- Keeps v1 focused on Instagram but avoids a rewrite when TikTok is added

### Test structure
- XCTest unit tests per package (behavioral, named by scenario e.g. `testCooldownEscalatesAfterRepeatedBypass`)
- Stub one XCUITest target for future UI automation — no actual UI tests in Phase 2
- UAT scenarios from `01-04-uat-plan.md` mapped to named `XCTestCase` stubs (failing/skipped) so they're trackable

### App Review preflight
- Assemble from Phase 1 artifacts: `01-capability-claims-matrix.md`, `01-app-review-constraints.md`, `01-02-intervention-ux-copy.md`
- Output: a single `APP_REVIEW_PREFLIGHT.md` doc with capability claims, limitation disclosures, and a stop-ship checklist

### Claude's Discretion
- Exact folder layout within each SPM package
- Specific SwiftUI view names and file organization within `ControlledClient`
- UIViewController wrapper approach for Screen Time extension views if needed
- CI/build script setup (can be added later)

</decisions>

<specifics>
## Specific Ideas

- Dark theme is primary, not a toggle — design for dark from the start
- Minimalist means: no gradients, no heavy shadows, no decorative elements — let the enforcement UX speak for itself
- Skeleton views should feel like the real thing visually, even if they're just placeholder layouts

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No application code exists yet — this phase creates the foundation

### Established Patterns
- Phase 1 architecture defines the module boundaries and component names (treat as canonical)
- Screen Time stack: FamilyControls + ManagedSettings + DeviceActivity (all documented, public APIs)

### Integration Points
- App Group shared container: PolicyStore writes, extensions read
- OAuth integration manager lives in host app, ControlledClient module consumes tokens
- Extensions (DeviceActivityMonitor, ShieldConfiguration, ShieldAction) are separate targets, linked to ScreenTimeEngine package

</code_context>

<deferred>
## Deferred Ideas

- CI/CD pipeline setup — future phase
- Supervised-device / MDM strict mode — v2 (noted in Phase 1)
- Android — out of scope for v1

</deferred>

---

*Phase: 02-ios-implementation-scaffolding*
*Context gathered: 2026-03-03*
