# Phase 5 Research: WKWebView Controlled Feed

**Date:** 2026-03-06  
**Phase:** 05-wkwebview-controlled-feed  
**Objective:** What must be true to plan and execute FEED-01/02/03/04 and DASH-02 reliably

## Scope and Fixed Boundaries

Phase 5 is controlled-feed runtime behavior. It is not onboarding, not Screen Time API rework, and not dashboard reporting.

In scope (must satisfy now):
- `FEED-01`: Instagram mobile web feed loads in controlled `WKWebView`
- `FEED-02`: TikTok mobile web feed loads in controlled `WKWebView`
- `FEED-03`: remaining session time is visible and updates during use
- `FEED-04`: feed is replaced by non-dismissible `InterventionView` at expiry
- `DASH-02`: platform switcher allows user to switch between Instagram and TikTok feed

Out of scope (defer):
- `FEED-05` CSS/JS suppression of infinite-scroll UI internals (v1.2)
- onboarding-first persistence UX for session limits/platform choice (Phase 6)
- dashboard aggregation/home metrics (`DASH-01`, Phase 7)

## Locked Decisions (Do Not Re-decide)

From `05-CONTEXT.md`:
- Countdown starts on first feed interaction, not first paint.
- Countdown pauses when app is backgrounded or user is away from feed surface.
- Timer state is per-platform (Instagram and TikTok independent).
- Remaining time display format is `MM:SS`.
- Platform switcher is top segmented control.
- Default selected tab is last-used platform.
- Each platform preserves its own in-memory web state while switching.
- Platform-level expiry is scoped: one platform can lock while the other remains usable.
- At `00:00`, feed is immediately replaced with non-dismissible `InterventionView`.
- Unlock condition is next daily reset boundary for that platform.
- Off-domain URLs are opened externally (Safari).
- New-window requests are opened in same controlled webview only if URL passes allowlist.
- Web cookies/session persist across relaunch by default.
- Intervention/limitation copy must remain compliant with `ios/APP_REVIEW_PREFLIGHT.md`.

## Current Code Reality

Implemented today:
- `ControlledClient.FeedView` is a static SwiftUI list stub.
- `ControlledClient.InterventionView` exists and already includes preflight-aligned copy baseline.
- `InstagramProvider` and `TikTokProvider` exist with stable names.
- `FallbackRouter.routeToNativeApp(for:) -> Bool` exists as unsupported-route contract stub.
- App root (`ios/FreeSocial/ContentView.swift`) is still placeholder text, not feed UI.

Adjacent infrastructure available:
- `ScreenTimeEngine.MonitoredPlatform` (`instagram`/`tiktok`) already exists and should be reused for stable platform identity.
- `PolicyStore.FamilyActivitySelectionStore` exists for selected app tokens (used by Screen Time enforcement).
- Consent and bypass telemetry gates are already wired in extension paths (Phase 3/4 complete).

Implication:
- Phase 5 is mostly ControlledClient architecture + app wiring, with deterministic logic seams for host-testability.

## Requirement-to-Implementation Mapping

### FEED-01 / FEED-02 (Controlled WKWebView per platform)
Must include:
- iOS-only `WKWebView` host via `UIViewRepresentable` in `ControlledClient`.
- One persistent webview instance per platform (do not recreate on tab switch).
- Mobile Safari user-agent override.
- Platform allowlist evaluator (first-party domain family + required subdomains).
- Navigation policy:
  - allowlisted URL -> allow in-webview
  - non-allowlisted URL -> cancel + open in Safari
  - target="_blank" -> in same webview only when allowlisted

### FEED-03 (Visible remaining-time countdown)
Must include:
- Session timer engine with per-platform remaining seconds.
- Start trigger on first interaction event (tap/scroll/navigation) per active platform.
- Foreground-only decrementing (pause on background/inactive feed context).
- `MM:SS` formatter and deterministic zero-floor behavior.

### FEED-04 (Intervention replacement at expiry)
Must include:
- Platform-level state machine: `.active`, `.expired(untilResetBoundary)`.
- Immediate feed replacement on `remaining == 0`.
- No dismiss affordance while expired.
- Eligibility to exit intervention only after reset boundary calculation passes.

### DASH-02 (Platform switcher)
Must include:
- Segmented control bound to active platform.
- Last-used platform persistence read on entry.
- Expired-platform UX scoped per tab (switcher still available).

## Architecture Guidance for Planning

### 1) Separate Pure Logic from Web Runtime
Keep `WKWebView` bridge thin. Move decision logic into testable pure types:
- `FeedPlatform` mapping (`instagram`, `tiktok`) reusing `MonitoredPlatform` raw values
- `PlatformURLPolicy` (allowlist decision engine)
- `SessionTimerEngine` (first-interaction start, pause/resume, per-platform decrement)
- `InterventionGate` (expired vs reset-eligible)

Reason: package `swift test` on macOS cannot exercise live WebKit behavior deterministically.

### 2) Web Container Model
Use a state-holder object (reference type) that owns:
- two `WKWebView` instances
- navigation delegates
- active platform selection
- first-interaction markers per platform

Reason: SwiftUI view recomposition otherwise destroys web state and violates resume-on-switch requirement.

### 3) URL Policy Model (Do Not Embed as Inline Closures)
Define explicit policy outputs:
- `.allowInWebView`
- `.openExternally`
- `.deny`

Reason: makes FEED-01/02 behavior auditable and unit-testable, and avoids accidental domain drift.

### 4) Session Limit Source for Phase 5
Phase 5 needs per-platform limits before onboarding (Phase 6) exists.
Plan with an injectable source:
- `SessionLimitProvider` protocol
- Phase 5 default implementation returns conservative hardcoded limits
- Phase 6 can swap provider to persisted onboarding settings without rewriting feed core

This avoids blocking Phase 5 on Phase 6 while keeping forward compatibility.

### 5) Reset Boundary Semantics
Use calendar day boundary in local time:
- `nextReset = Calendar.current.startOfDay(for: now + 1 day)`
- expired platform remains blocked until `now >= nextReset`

Make this logic pure and clock-injected for deterministic tests.

## Platform/Web Constraints and Risks

1. Instagram/TikTok anti-automation behavior in `WKWebView` may vary by runtime.
- Mitigation: early simulator smoke checks for both domains with selected user-agent + cookie persistence.

2. `WKNavigationAction.targetFrame == nil` (new-window/pop-up flows).
- Mitigation: route through allowlist evaluator and load in existing webview only if allowlisted.

3. Over-broad allowlist weakens containment.
- Mitigation: declare explicit domain families in one file and test positive/negative URLs.

4. Timer drift from app lifecycle transitions.
- Mitigation: compute elapsed time from timestamps, not only repeating timer ticks.

5. App Review copy risk.
- Mitigation: do not add claims violating `APP_REVIEW_PREFLIGHT.md` Section 3; reuse approved intervention/disclosure wording.

## Integration Notes and Dependency Sequencing

Recommended execution order to avoid rework:
1. Pure models first (`PlatformURLPolicy`, timer/intervention state logic, formatter) + tests.
2. `WKWebView` bridge + per-platform webview retention.
3. Feed UI composition (switcher, timer chrome, intervention replacement).
4. App entry wiring (`ContentView` uses `FeedView`) and requirement traceability assertions.

File ownership suggestion for planning waves:
- Wave A: `ControlledClient/Sources/...` pure logic + tests only.
- Wave B: `ControlledClient/Sources/...` web bridge + feed UI.
- Wave C: `ios/FreeSocial/ContentView.swift` integration and test updates.

## Testing Strategy the Planner Should Enforce

### A) Package Unit Tests (`ControlledClientTests`)
High-confidence deterministic tests for:
- URL allowlist decisions (allow/deny/external)
- session timer progression (first interaction, pause/resume, per-platform independence)
- expiry gating and reset-boundary unlock semantics
- `MM:SS` formatting edge cases (`0`, `<60`, multi-minute)

### B) App-Level Boundary Tests (`FreeSocialTests`)
- Verify integration seams used by app root and feed state holder.
- Verify intervention replacement decision behavior under expired platform conditions.

### C) Simulator Integration (`xcodebuild test`)
- Ensure full scheme passes on `iPhone 17 / iOS 26.2`.
- Add a manual smoke checklist for actual web load and domain containment behavior, since XCTest host coverage is limited for live social web content.

## Validation Architecture

Validation must prove requirement outcomes, not just that WebKit compiles.

### Validation Layers
1. Compile/structure validation
- `ControlledClient` compiles with iOS-only WebKit bridge and macOS-testable pure logic.
- No module-rule violations (`ControlledClient` may import `PolicyStore`; keep `ConsentManager` and `ScreenTimeEngine` independence intact).

2. Deterministic logic validation
- Unit tests cover timer, expiry gate, platform switching state, and URL policy matrix.
- Tests are clock-injected and lifecycle-injected (no real-time sleeps required).

3. Boundary contract validation
- App root renders feed shell with platform switcher and timer display state.
- Expired platform path renders `InterventionView` and blocks dismissal until reset condition is met.

4. Runtime behavior validation (simulator + manual evidence)
- Instagram and TikTok mobile pages load in controlled webview.
- Off-domain navigation exits to Safari.
- New-window requests follow same allowlist policy.

### Evidence Matrix (Planner should require artifacts)
- FEED-01 evidence: allowlist policy tests + simulator/manual Instagram load proof.
- FEED-02 evidence: allowlist policy tests + simulator/manual TikTok load proof.
- FEED-03 evidence: timer-engine tests proving start/pause/resume/per-platform countdown.
- FEED-04 evidence: state-machine tests proving immediate intervention lock + reset-boundary unlock.
- DASH-02 evidence: switcher tests proving platform selection + last-used restoration.

### Nyquist Planning Constraints
- Every plan must include an automated verify command (no watch mode).
- No 3+ consecutive tasks without automated feedback sampling.
- Keep max feedback latency under ~180s by preferring package tests during implementation and full `xcodebuild test` at wave boundaries.
- Manual-only checks must be explicitly listed with rationale and exact reproduction steps.

## Recommended Plan Slices

1. `05-01`: Feed domain model and pure logic layer (platform state, timer, URL policy, formatter) + deterministic tests.
2. `05-02`: WKWebView bridge (per-platform retained webviews, navigation delegate allowlist enforcement, Safari handoff).
3. `05-03`: Feed UI assembly (switcher, countdown chrome, intervention replacement, last-used platform persistence).
4. `05-04`: Verification pass (requirement trace matrix, simulator test run, manual web smoke evidence, phase verification artifacts).

## Inputs Reviewed

Required:
- `.planning/phases/05-wkwebview-controlled-feed/05-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `CLAUDE.md`

Implementation context:
- `ios/Packages/ControlledClient/Sources/ControlledClient/*`
- `ios/Packages/ControlledClient/Tests/ControlledClientTests/*`
- `ios/FreeSocial/ContentView.swift`
- `ios/Packages/ScreenTimeEngine/Sources/ScreenTimeEngine/*`
- `ios/Packages/PolicyStore/Sources/PolicyStore/*`
- `ios/APP_REVIEW_PREFLIGHT.md`

Skills directory check:
- `.claude/skills/**/SKILL.md`: not present
- `.agents/skills/**/SKILL.md`: not present

## RESEARCH COMPLETE
