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

**Requires Xcode.app.** Installed and verified working 2026-03-04.

Installed simulator runtime: **iOS 26.2**. Use `iPhone 17` as the target device.

```bash
# Build
xcodebuild -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build

# Test (current baseline: FreeSocialTests passes; UI test target present but empty)
xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'

# Run on simulator (raw app install works as of 2026-03-04 after plist metadata fixes)
DERIVED="/Users/gavin/Library/Developer/Xcode/DerivedData/FreeSocial-gjbgihqsoeillafxqsdobzpijlbm"
APP_SRC="$DERIVED/Build/Products/Debug-iphonesimulator/FreeSocial.app"
xcrun simctl boot 15796420-57AA-4732-BE47-5AB2F98B7626  # iPhone 17
open -a Simulator
xcrun simctl install booted "$APP_SRC"
xcrun simctl launch booted com.freesocial.app
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

## iOS 26 SDK Compatibility Notes

The skeleton was written targeting iOS 16.0 but the available simulator runtime is iOS 26.2. Several fixes were required:

- **`project.pbxproj`**: Added `SDKROOT = iphoneos` to project-level Debug and Release configs — without it xcodebuild defaults to macOS and shows no iOS simulator destinations.
- **`ShieldActionExtension.swift`**: Updated `handle(for:)` overrides from `Application`/`WebDomain` to `ApplicationToken`/`WebDomainToken` — iOS 26 SDK changed `ShieldActionDelegate` to use opaque token types.
- **`DeviceActivityMonitorExtension.swift`**: Added `import Foundation` — `UUID` and `Date` are not implicitly available without it.
- **`InterventionView.swift`**: Inlined the default string in the public `init` — Swift 5.9+ disallows `private` (or `internal`) static properties as default argument values in `public` initializers across module boundaries.
- **Extension `Info.plist` files** (all 3): Added required metadata keys for simulator install compatibility: `CFBundleIdentifier`, `CFBundleExecutable`, `CFBundleName`, `CFBundleVersion`, `CFBundleShortVersionString`, plus standard bundle keys. Without these, simulator install fails with `Invalid placeholder attributes`, `MissingBundleExecutable`, or `MissingBundleNameString`.
- **Simulator status (updated 2026-03-04)**: After plist normalization, raw simulator install/launch of the full app bundle (including `.appex`) succeeds and `xcodebuild test` passes.

## Session Updates (2026-03-04)

- Fixed `FreeSocialTests` target path wiring in `project.pbxproj`:
  - `Tests (FreeSocial)` group path changed from `Tests` to `FreeSocial/Tests`.
  - Resolved missing file error for `AppReviewPreflightTests.swift`.
- Restored testability for simulator and package workflows:
  - `xcodebuild test` now succeeds on `iPhone 17 / iOS 26.2`.
  - `swift test` for `ios/Packages/ControlledClient` now succeeds after adding `.macOS(.v13)` to `Package.swift` platforms.
- GitHub issue lifecycle from this session:
  - Closed: `#1` (test path miswire), `#2` (extension plist metadata), `#5` (ControlledClient host testability).
  - Closed (2026-03-04, follow-up): `#3`, `#4`, `#6`, `#7` — see Session Updates below.

## Session Updates (2026-03-04, follow-up)

Closed all remaining open GitHub issues (#3, #4, #6, #7). Resolved ConsentManager AppGroup architecture decision. All pre-Phase-3 blockers cleared.

**Issue fixes (commit `7f21b92`):**
- **#7 — FallbackRouter failure contract**: Changed `routeToNativeApp(for:)` return type from `Void` to `@discardableResult Bool`. Stub returns `false` until URL routing is implemented.
- **#6 — Background color asset warning**: Replaced `Color("Background")` asset lookup with programmatic `Color(red: 0.039, green: 0.039, blue: 0.039)` in `FeedView` and `InterventionView`. Also added universal (light-mode) fallback entry to `Background.colorset`.
- **#4 — PolicyRepository .standard fallback**: Replaced silent `?? .standard` with `assertionFailure` — fires in debug builds when App Group is unavailable. `.standard` fallback retained for release builds.
- **#3 — Consent gate stub**: Added consent guard to `eventDidReachThreshold` in `DeviceActivityMonitorExtension`. Defaults to `true` pending Phase 3 `ConsentStore` wiring.

**ConsentManager AppGroup decision (commit `a0b248b`):**
- Resolved: inject `suiteName: String` via `ConsentStore.init`. ConsentManager stays independent of PolicyStore.
- `ConsentStore` now wires shared `UserDefaults` and uses the same `assertionFailure` pattern as `PolicyRepository`.
- Phase 3 call pattern: `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()`.

## Session Updates (2026-03-04, Phase 3 planning)

Created Phase 3 planning artifacts. All architectural decisions for the data layer captured.

**Phase 3 context decisions (commit `1a5d174`):**
- **FamilyActivitySelectionStore placement**: Lives in `PolicyStore` package — co-located with all UserDefaults-backed persistence (PolicyRepository, BypassEvent, EscalationLevel). ControlledClient may import PolicyStore per module rules.
- **Revocation semantics**: `loadCurrent()` returns the `ConsentRecord` even when revoked — callers check `?.isRevoked == false`. Returning nil is reserved for "never consented." `revoke()` sets `isRevoked = true` and `revokedAt = Date()` and persists. DeviceActivityMonitor TODO updated to check `isRevoked` flag, not nil-ness.
- **AuditLog storage**: UserDefaults with JSONEncoder'd array of `AuditEntry` — consistent with ConsentStore and PolicyRepository. File-based append deferred (would require NSFileCoordinator for cross-process safety).
- **BypassEvent schema**: Keep as-is (`id`, `occurredAt`, `escalationLevelAtTime`). "Phase 1 telemetry spec" undefined in codebase; escalation deferred to v1.2. No expansion needed now.

**Artifacts created:**
- `.planning/phases/03-data-layer-foundations/` — phase directory
- `.planning/phases/03-data-layer-foundations/03-CONTEXT.md` — implementation decisions

## Security & Configuration Tips

- Do not claim unsupported platform capabilities in docs or UI copy — see `ios/APP_REVIEW_PREFLIGHT.md` Section 3 (prohibited copy) and Section 2 (cannot-claim rows).
- Use official iOS APIs only (FamilyControls, DeviceActivity, ManagedSettings) — no private/reverse-engineered integrations.
- Treat consent, revocation, and data minimization as release blockers — `APP_REVIEW_PREFLIGHT.md` Section 6 stop-ship checklist must pass before any submission.
- `ConsentStore` must gate `PolicyRepository.recordBypassEvent` on consent state — stub guard added in `DeviceActivityMonitorExtension` (defaults `true`); real wiring is a Phase 3 entry condition. Use `ConsentStore(suiteName: AppGroup.suiteName)` — architecture decision resolved 2026-03-04.

## Current Project Status (GSD)

- **Milestone:** v1.1 Implementation — IN PROGRESS
- **Stage:** Phase 3 context captured — ready to plan
- **Git tag:** `v1.0` (last shipped)
- **Phase 3 context:** `.planning/phases/03-data-layer-foundations/03-CONTEXT.md`

## What To Do Next

**Plan Phase 3:**
```
/gsd:plan-phase 3
```
Then `/clear` first for a fresh context window.

**Phase 3 implementation decisions (from 03-CONTEXT.md):**
- `FamilyActivitySelectionStore` → new type in `PolicyStore` package
- `ConsentStore.loadCurrent()` returns record even when revoked; callers check `?.isRevoked == false`
- `AuditLog` persists to App Group UserDefaults via JSONEncoder (not a file)
- `BypassEvent` schema unchanged — no expansion needed for v1.1
