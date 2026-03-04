# Project Research Summary

**Project:** FreeSocial v1.1 Implementation
**Domain:** iOS digital wellbeing — controlled social media client with Screen Time enforcement
**Researched:** 2026-03-04
**Confidence:** HIGH (stack and architecture), MEDIUM (social site WebView behavior, iOS 26 regressions)

## Executive Summary

FreeSocial v1.1 converts a fully-scaffolded iOS skeleton into a working product. The architecture is already proven: four SPM packages (ControlledClient, ScreenTimeEngine, PolicyStore, ConsentManager) communicate through a shared App Group, three app extensions handle Screen Time enforcement, and Apple's FamilyControls/DeviceActivity/ManagedSettings stack manages native app blocking. The v1.1 work is almost entirely stub-filling — implementing real API calls, wiring data flows between components that exist but don't yet talk to each other, and building the onboarding UI that gates users through authorization, consent, and session limit setup.

The recommended build order is: foundations first (PolicyStore + ConsentStore real persistence), then Screen Time engine (AuthorizationManager, ActivityScheduler, ShieldManager real calls), then the WKWebView controlled feed (WebFeedView, WebSessionCoordinator, InterventionView trigger), then onboarding (which calls all of the above in sequence), and finally the dashboard and UAT test pass. This order ensures that by the time the onboarding UI is built, every underlying system it calls is already implemented and independently testable.

The most significant risk in v1.1 is the iOS 26.2 regression where `eventDidReachThreshold` fires prematurely, activating shields at session start. This requires a defensive usage guard in the extension callback. The second major risk is the `FamilyActivityPicker` sheet-inside-sheet crash — the onboarding flow must present the picker from a non-modal root context. Both risks have documented mitigations. All seven remaining implementation gaps from the v1.0 audit are addressable within the existing architecture; no structural changes are needed.

## Key Findings

### Recommended Stack

The v1.0 stack carries forward entirely — no new SPM packages are needed. All v1.1 capabilities are covered by system frameworks already linked: WebKit (WKWebView), FamilyControls, DeviceActivity, ManagedSettings, ManagedSettingsUI, Foundation, and SwiftUI. The one structural addition is a new `DeviceActivityReport` extension target for the usage dashboard. However, this target should be treated as optional for v1.1 given documented instability — the dashboard can use local session counters as a fallback. See [STACK.md](.planning/research/STACK.md) for full API version matrix.

**Core technologies:**
- `UIViewRepresentable` + `WKWebView` (WebKit): controlled feed rendering — only viable path for iOS 16 minimum target
- `AuthorizationCenter.shared.requestAuthorization(for: .individual)` (FamilyControls): runtime permission request — async/await, main app only
- `FamilyActivityPicker` (FamilyControls): system app-token picker — Codable selection persisted to App Group UserDefaults
- `DeviceActivityCenter.startMonitoring` (DeviceActivity): daily schedule + threshold events — drives the enforcement chain
- `ManagedSettingsStore().shield.applications` (ManagedSettings): native app blocking — named store shared between main app and extensions
- `JSONEncoder`/`JSONDecoder` + App Group `UserDefaults`: cross-process data persistence — canonical iOS pattern, no third-party required
- `DeviceActivityReportExtension` (DeviceActivity): usage dashboard — new 4th Xcode target; consider deferring to v1.2 if unstable

### Expected Features

See [FEATURES.md](.planning/research/FEATURES.md) for full feature dependency graph and ordering rationale.

**Must have (table stakes):**
- WKWebView feed loading Instagram and TikTok mobile web — core product premise
- Session timer visible during feed use — required for user trust
- InterventionView triggered when session limit is reached — passive limits fail the product purpose
- FamilyControls authorization request on first launch — required before any enforcement
- Onboarding disclosure of 9 limitation strings — POL-03 stop-ship condition
- Consent capture in onboarding — POL-02 stop-ship condition
- Screen Time shield activating when daily limit is reached — must block native app bypass
- Platform selection via FamilyActivityPicker — user picks which apps to control
- Session limit setup during onboarding — enforcement is meaningless without a user-set quota
- Deauthorization detection with recovery UI — shields must clear when authorization is revoked
- Consent revocation gating `PolicyRepository.recordBypassEvent` — POL-02 compliance

**Should have (differentiators):**
- Countdown timer UX (progress ring) — makes session boundary feel real before it hits
- Escalation state visible in dashboard — users learn bypass costs when they see the level
- Limitation disclosure inside InterventionView — turns frustration into a trust-building moment

**Defer to v1.2:**
- CSS/JS injection to suppress infinite scroll elements — fragile, site-specific, high complexity
- `DeviceActivityReport` extension for usage data — unstable and crashes frequently on iOS 26
- Full escalation chain wiring (cooldown1/2/lockdown transitions) — architecture exists, complexity deferred
- Audit log read UI in Settings — data is recorded, display deferred
- `BypassEvent` schema expansion (remaining 6 fields) — current fields sufficient for v1.1

**Anti-features (do not build):**
- Full DM/story/post parity in WKWebView — prohibited by APP_REVIEW_PREFLIGHT.md Section 3
- Silent/invisible enforcement — violates disclosure posture; App Review rejection risk
- Persistent login credential storage in Keychain — WKWebView session cookies are sufficient
- Remote telemetry — data policy is on-device only

### Architecture Approach

The existing package/extension separation is correct and must not be violated. The main app calls ScreenTimeEngine (for authorization and scheduling), ConsentManager (for consent state), PolicyStore (for escalation and bypass events), and ControlledClient (for the feed UI). Extensions access shared state only through App Group UserDefaults — no cross-package imports cross the process boundary. The single new architectural element is `WebSessionCoordinator` (a `WKNavigationDelegate` that owns the session timer and URL allowlist), which lives in `ControlledClient` and communicates expiry back to `FeedView` via `@Binding`. See [ARCHITECTURE.md](.planning/research/ARCHITECTURE.md) for component diagrams and all 6 code patterns.

**Major components:**
1. `WebFeedView` + `WebSessionCoordinator` (ControlledClient) — UIViewRepresentable WKWebView wrapper with URL allowlist, session timer, and InterventionView trigger binding
2. `OnboardingView` state machine (main app) — sequential 4-step flow: permissions → consent → limits → done; calls all package APIs in correct order
3. `AuthorizationManager` with deauth observer (ScreenTimeEngine) — Combine publisher surfacing `authorizationStatus` changes; clears shields on deauthorization
4. `ActivityScheduler` real implementation (ScreenTimeEngine) — `DeviceActivityCenter.startMonitoring` with daily schedule and per-platform threshold events
5. `ConsentStore` real implementation (ConsentManager) — save/loadCurrent/revoke via App Group UserDefaults; gating `recordBypassEvent` in DeviceActivityMonitorExtension
6. `PolicyRepository` real implementation (PolicyStore) — EscalationLevel and BypassEvent persistence; `FamilyActivitySelectionStore` for picker tokens
7. `DashboardView` (main app) — session counter display + optional `DeviceActivityReport` view embedding

### Critical Pitfalls

See [PITFALLS.md](.planning/research/PITFALLS.md) for full list with detection steps and phase assignments.

1. **iOS 26.2 premature `eventDidReachThreshold`** — Guard the callback with a minimum usage check (e.g., 30 seconds elapsed) before applying shields; add foreground revalidation as a secondary enforcement trigger. Active OS bug, no Apple fix as of 2026-03-04.

2. **FamilyControls authorization called from an extension** — Call `requestAuthorization(for: .individual)` exclusively from the main app during onboarding; extensions cannot present the auth sheet and will fail silently with `FamilyControlsError error 3`.

3. **WKWebView coordinator retain cycle prevents session timer cleanup** — Make any Coordinator-to-WKWebView back-reference `weak`; implement `dismantleUIView` to cancel the session timer explicitly.

4. **`FamilyActivityPicker` crash when presented inside a sheet** — Present the picker as a `.fullScreenCover` or directly from a non-modal root; nested sheet presentation is a known UIKit-level bug that dismisses the parent.

5. **Deauthorization leaves active shields in ManagedSettings** — Implement `authorizationStatusDidChange` observer; call `ManagedSettingsStore().clearAllSettings()` immediately on deauthorization; this is a Phase 3 entry condition.

6. **Consent state not readable in extension process** — Always initialize `ConsentStore(suiteName: AppGroup.suiteName)` — never use `.standard` defaults in extension targets; the v1.0 stub defaults to `true` must be replaced in Phase 3.

## Implications for Roadmap

The feature dependency graph from FEATURES.md and the build order from ARCHITECTURE.md converge on the same 5-phase structure. All phases are implementation phases (no new design phases needed — architecture is settled).

### Phase 1: Data Layer Foundations
**Rationale:** PolicyStore and ConsentStore are read by every other component including extensions. Nothing else can be wired until these persistence layers are real. No UI required; pure Swift; fully testable on macOS via `swift test`.
**Delivers:** `PolicyRepository` real read/write, `BypassEvent` schema, `FamilyActivitySelectionStore`, `ConsentStore` save/load/revoke, UAT stubs activated for NB-02/NB-03/POL-02
**Addresses:** CC-01 (escalation state), POL-02 (consent gate prerequisite)
**Avoids:** Consent state not readable in extension (Pitfall 5) — get the persistence pattern right before wiring extensions

### Phase 2: Screen Time Engine
**Rationale:** `AuthorizationManager`, `ActivityScheduler`, and `ShieldManager` real implementations depend on PolicyStore data types (tokens, escalation levels). Deauthorization detection is a Phase 3 entry condition and must be wired before onboarding builds on top of it.
**Delivers:** Real `requestAuthorization(for: .individual)`, deauthorization observer via Combine, `DeviceActivityCenter.startMonitoring` with daily schedule and threshold events, `ManagedSettingsStore` shield apply/clear
**Addresses:** NB-01 (Screen Time authorization), NB-02 (scheduling)
**Avoids:** Authorization from wrong process (Critical Pitfall 2), premature threshold firing (Critical Pitfall 1 — add guard here), deauthorization shield bleed (Moderate Pitfall 6)
**Uses:** `#if canImport(FamilyControls)` guards throughout to maintain macOS test compatibility

### Phase 3: WKWebView Controlled Feed
**Rationale:** `WebFeedView` and `WebSessionCoordinator` are architecturally independent of the Screen Time engine — they can be built and tested in parallel with Phase 2 or sequentially after it. `InterventionView` trigger wiring requires `FeedView` state but not active Screen Time enforcement.
**Delivers:** `WebFeedView` (UIViewRepresentable), `WebSessionCoordinator` (URL allowlist + session timer), `FeedView` wired with session expiry binding and InterventionView overlay, `FallbackRouter` URL scheme routing, Mobile Safari user agent
**Addresses:** CC-02 (feed loading), CC-03 (session boundary enforcement)
**Avoids:** Coordinator retain cycle (Critical Pitfall 3), deep link native app escape (Moderate Pitfall 3), cookie set race (Moderate Pitfall 4), user agent gating (Minor Pitfall 4)

### Phase 4: Onboarding Flow
**Rationale:** Onboarding is the integration layer — it calls AuthorizationManager, ConsentStore, FamilyActivityPicker, and ActivityScheduler in sequence. All four must be real implementations before onboarding can be built correctly. This is the last feature phase before testing.
**Delivers:** `OnboardingView` 4-step state machine (permissions → consent → limits → done), all 9 POL-03 limitation disclosure strings placed, consent capture wired to `ConsentStore`, FamilyActivityPicker presenting from correct non-modal context, session limit UI feeding into `ActivityScheduler`
**Addresses:** POL-01 (user-visible enforcement), POL-02 (consent capture), POL-03 (disclosure strings)
**Avoids:** FamilyActivityPicker sheet-inside-sheet crash (Critical Pitfall 4 — use fullScreenCover)

### Phase 5: Dashboard and UAT Test Pass
**Rationale:** Dashboard requires `FamilyActivitySelectionStore` tokens (Phase 1) and is the last user-visible surface. The UAT test pass converts all 9 XCTSkip stubs to real assertions and is only possible when all implementation above is complete.
**Delivers:** `DashboardView` with session counter display and escalation level indicator; optional `DeviceActivityReport` extension (defer if unstable); all 9 UAT test stubs replaced with real assertions (CC-01 through POL-03)
**Addresses:** NB-03 (usage visibility), full test coverage of v1.1 requirements
**Avoids:** DeviceActivityReport sandbox misuse (Moderate Pitfall 5) — use local session counters as primary data source; treat extension as progressive enhancement

### Phase Ordering Rationale

- Phases 1 and 2 are ordered by data dependency: ConsentStore is read by the DeviceActivityMonitor extension, which is wired in Phase 2. PolicyStore types are consumed by ScreenTimeEngine APIs.
- Phase 3 is independent of Screen Time and can be developed in parallel with Phase 2 if needed, but sequential ordering reduces integration complexity.
- Phase 4 (Onboarding) is deliberately last among feature phases because it integrates all prior systems; building it before its dependencies are real would require mocking the entire stack.
- Phase 5 is the natural close: dashboard is additive, and the UAT pass validates the full v1.1 requirement surface.

### Research Flags

Phases needing defensive implementation (known bugs/instability):
- **Phase 2:** iOS 26.2 `eventDidReachThreshold` OS regression — add usage guard, watch for iOS 26.3+ fix; file FB report
- **Phase 3:** Instagram/TikTok mobile web anti-automation behavior — validate user agent and cookie persistence on simulator before building further; this is a real-device validation gap
- **Phase 5:** `DeviceActivityReport` extension instability — treat as optional; have local counter fallback ready before attempting extension integration

Phases with well-documented standard patterns (skip additional research):
- **Phase 1:** `JSONEncoder` + App Group UserDefaults is canonical iOS persistence — no research needed
- **Phase 4:** `TabView(.page)` onboarding with `@AppStorage` completion flag is established iOS 16+ pattern

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs are system frameworks with official Apple documentation; no third-party dependencies introduced |
| Features | HIGH | Requirements are traced to APP_REVIEW_PREFLIGHT.md requirement IDs; anti-features are explicitly documented |
| Architecture | HIGH | Package boundaries are settled from v1.0; data flow patterns confirmed against Apple docs; 6 concrete code patterns provided |
| Pitfalls | HIGH (critical), MEDIUM (moderate) | Critical pitfalls backed by Apple Developer Forums threads and official docs; moderate pitfalls backed by multiple community reports |

**Overall confidence:** HIGH for implementation approach; MEDIUM for iOS 26.2-specific runtime behavior (active OS regressions)

### Gaps to Address

- **Instagram/TikTok WKWebView anti-automation behavior** — Exact user agent string and cookie handling must be validated on simulator during Phase 3 before committing to the WKWebView approach. The fallback (`FallbackRouter.routeToNativeApp`) must be ready before WKWebView implementation starts.
- **iOS 26.2 threshold firing regression** — No Apple fix as of research date. The usage guard mitigation is the current best practice from the community. Watch iOS 26.3+ point release notes during development. Real-device validation is deferred to v1.2.
- **FamilyControls entitlement approval timeline** — All Screen Time enforcement code paths are simulator-only until Apple approves the entitlement. Phase 2 and 4 features can be built and tested structurally on simulator, but enforcement behavior requires the entitlement. Track separately.
- **`DeviceActivityReport` extension reliability on iOS 26.2** — Multiple developer reports of instability corroborate the decision to build the dashboard primarily on local session counters. If the extension is attempted in Phase 5, treat it as an independent spike with a clear fallback decision point.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — AuthorizationCenter, requestAuthorization, FamilyActivityPicker, DeviceActivitySchedule, DeviceActivityCenter, DeviceActivityReport, ShieldConfigurationDataSource, WKWebView
- Apple Developer Forums thread/811305 — iOS 26.2 DeviceActivityMonitor premature threshold firing
- Apple Developer Forums thread/809410 — iOS 26.2 RC DeviceActivityMonitor events
- Internal: `ios/APP_REVIEW_PREFLIGHT.md` — stop-ship gate with POL-01/02/03 traces
- Internal: `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — Phase 3 entry conditions
- Internal: `ios/Packages/*/Sources/**/*.swift` — v1.0 stub code with documented TODOs
- WWDC22 — What's New in Screen Time API — named ManagedSettingsStore, DeviceActivityReport extension

### Secondary (MEDIUM confidence)
- Julius Brussee — A Developer's Guide to Apple's Screen Time APIs
- riedel.wtf — State of the Screen Time API 2024
- letvar Medium series — DeviceActivityReport extension setup and limitations
- Josh Hrach — UIViewRepresentable delegates in SwiftUI (2024)
- Crunchybagel — Monitoring App Usage with Screen Time Framework
- Apple Developer Forums — DeviceActivitySchedule DateComponents silent failure (thread/729841)
- Apple Developer Forums — WKWebView cookie store async race (thread/97194, thread/131931)
- Apple Developer Forums — FamilyActivityPicker sheet-inside-sheet bug (riedel.wtf corroboration)

### Tertiary (LOW confidence)
- Hacker News thread/32517029 — WKWebView Instagram/TikTok anti-automation observations (community, needs real-device validation)
- Mobbin — Opal onboarding flow analysis (UI reference only, not technical)

---
*Research completed: 2026-03-04*
*Ready for roadmap: yes*
