# Repository Guidelines

## Project Structure & Module Organization

v1.0 milestone shipped. Repository now contains planning archives and iOS skeleton code.

- `.planning/` — primary project artifacts.
  - `PROJECT.md`, `ROADMAP.md`, `MILESTONES.md`, `STATE.md`, `RETROSPECTIVE.md`
  - `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md`, `milestones/v1.0-MILESTONE-AUDIT.md`
  - `milestones/v1.0-phases/` — archived Phase 1 and Phase 2 execution artifacts
- iOS skeleton code:
  - `ios/FreeSocial.xcodeproj` — hand-written pbxproj, iOS 16.0 deployment target, dark-first SwiftUI
  - `ios/Packages/ControlledClient/` — SocialProvider protocol, FeedView, InterventionView, FallbackRouter stubs
  - `ios/Packages/ScreenTimeEngine/` — AuthorizationManager, ShieldManager, ActivityScheduler stubs
  - `ios/Packages/PolicyStore/` — AppGroup (single suiteName), EscalationLevel (4 states), PolicyRepository, BypassEvent
  - `ios/Packages/ConsentManager/` — ConsentRecord, ConsentStore, AuditLog stubs
  - `ios/Extensions/DeviceActivityMonitor/` — DeviceActivityMonitor subclass with recordBypassEvent chain
  - `ios/Extensions/ShieldConfiguration/` — ShieldConfigurationDataSource, UIKit struct API only
  - `ios/Extensions/ShieldAction/` — ShieldActionDelegate stub
  - `ios/APP_REVIEW_PREFLIGHT.md` — canonical stop-ship gate (8 claims, 7 blocking conditions, POL-01/02/03 traced)

## Build, Test, and Development Commands

**Requires Xcode.app** (not installed on dev machine — only CLT available):

```bash
# Build
xcodebuild -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Test (expect: 9 skipped UAT stubs, 1 passed AppReviewPreflightTests, 0 failed)
xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Planning/GSD commands:
```bash
rg --files .planning                                          # list planning artifacts
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze   # phase completion status
```

## Coding Style & Naming Conventions

For iOS code:
- Swift 5.9, SwiftUI, iOS 16.0 minimum deployment target.
- Module dependency rule: `ControlledClient` may import `PolicyStore`; `ScreenTimeEngine` and `ConsentManager` are independent of each other and of `ControlledClient`.
- `AppGroup.suiteName` is the single source of truth for `group.com.freesocial.app` — never hardcode this string elsewhere in Swift.
- Use `#if canImport(FamilyControls)` guards where FamilyControls/DeviceActivity APIs would break non-Xcode builds.
- Extension targets use UIKit only in ShieldConfiguration; DeviceActivityMonitor and ShieldAction are UIKit-free.
- `project.pbxproj` is hand-written — no Tuist or XcodeGen.

For planning artifacts:
- Use Markdown with short sections, explicit requirement IDs (`CC-01`, `NB-02`, `POL-03`), and clear acceptance criteria.
- Phase files follow `NN-xx-NAME.md` patterns (example: `03-01-feed-implementation.md`).

## Testing Guidelines

XCTest targets exist with UAT stubs (Phase 3 fills them in):
- `ControlledClientTests` — CC-01, CC-02, CC-03, POL-03 stubs
- `ScreenTimeEngineTests` — NB-01 stub
- `PolicyStoreTests` — NB-02, NB-03 stubs
- `ConsentManagerTests` — POL-02 stub
- `FreeSocialTests` — `AppReviewPreflightTests.testPublicClaimsMatchCapabilityMatrix` (active, not a stub — verifies `ios/APP_REVIEW_PREFLIGHT.md` exists)
- `FreeSocialUITests` — empty placeholder for Phase 3+ UI automation

Stub pattern: `func testName() throws { throw XCTSkip("UAT stub: REQ-ID — pending Module implementation") }`

When implementing tests in Phase 3:
- Replace XCTSkip with real assertions.
- Name tests by behavior: `testCooldownEscalatesAfterRepeatedBypass`.
- Keep requirement ID in test name or doc comment for traceability.

## Commit & Pull Request Guidelines

Git repo is live at `github.com/gheatherington/freesocial`.

- Scoped conventional commits: `feat(controlled-client): implement SocialProvider fetch`, `fix(policy-store): correct escalation reset logic`.
- Keep commits atomic — one plan task per commit.
- Never hardcode `group.com.freesocial.app` in Swift; always use `AppGroup.suiteName`.
- PRs should include: requirement IDs impacted, verification evidence, screenshots for UI changes.

## Security & Configuration Tips

- Do not claim unsupported platform capabilities in docs or UI copy — see `ios/APP_REVIEW_PREFLIGHT.md` Section 3 (prohibited copy) and Section 2 (cannot-claim rows).
- Use official iOS APIs only (FamilyControls, DeviceActivity, ManagedSettings) — no private/reverse-engineered integrations.
- Treat consent, revocation, and data minimization as release blockers — `APP_REVIEW_PREFLIGHT.md` Section 6 stop-ship checklist must pass before any submission.
- `ConsentStore` must gate `PolicyRepository.recordBypassEvent` on consent state — not yet wired (Phase 3 entry condition).

## Current Project Status (GSD)

- **Milestone:** v1.0 Foundation — SHIPPED 2026-03-03
- **Stage:** Planning next milestone (v1.1 Implementation)
- **Git tag:** `v1.0`
- **All v1 requirements:** scaffolded and verified (9/9)

## What To Do Next

**Resolve before Phase 3 begins:**
1. Decide ConsentManager AppGroup access pattern — options: inject `suiteName` via init, add PolicyStore as a ConsentManager dependency, or create a shared Foundation package. This blocks POL-02 end-to-end implementation.
2. Set up CI with Xcode.app to confirm `xcodebuild BUILD SUCCEEDED` — all static checks pass but runtime build has not been verified.

**Start next milestone:**
```
/gsd:new-milestone
```
Then `/clear` first for a fresh context window.

**Phase 3 entry conditions (from v1.0 audit):**
- Implement consent-to-write gating in `PolicyRepository.recordBypassEvent`
- Add deauthorization detection path in `AuthorizationManager`
- Wire `InterventionView` into `FeedView` session boundary logic
- Expand `BypassEvent` schema to match Phase 1 telemetry spec
- Add 9 remaining limitation disclosure strings to onboarding/Settings UI
