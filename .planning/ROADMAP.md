# Roadmap: FreeSocial

## Milestones

- ✅ **v1.0 Foundation** — Phases 1–2 (shipped 2026-03-03)
- 🚧 **v1.1 Implementation** — Phases 3–7 (in progress)

## Phases

<details>
<summary>✅ v1.0 Foundation (Phases 1–2) — SHIPPED 2026-03-03</summary>

- [x] Phase 1: Controlled Client + Native Blocking (4/4 plans) — completed 2026-03-03
- [x] Phase 2: iOS Implementation Scaffolding (4/4 plans) — completed 2026-03-03

See full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### 🚧 v1.1 Implementation (In Progress)

**Milestone Goal:** Convert scaffolded skeleton into a working app — real persistence, real Screen Time enforcement, a live WKWebView feed, onboarding that gates through authorization and consent, and a UAT test pass that proves every v1.1 requirement is met.

- [ ] **Phase 3: Data Layer Foundations** — Real persistence for ConsentStore and PolicyRepository across app and extension processes
- [ ] **Phase 4: Screen Time Engine** — Real FamilyControls authorization, scheduling, and shield enforcement
- [ ] **Phase 5: WKWebView Controlled Feed** — Live Instagram and TikTok feed with session timer and InterventionView trigger
- [ ] **Phase 6: Onboarding Flow** — Sequential 4-step integration: auth request, consent/disclosure, platform selection, session limit setup
- [ ] **Phase 7: Dashboard and UAT Test Pass** — Usage summary home screen and all 9 XCTest stubs replaced with real assertions

## Phase Details

### Phase 3: Data Layer Foundations
**Goal**: Consent status and bypass events are correctly persisted to and read from the shared App Group by all processes — app, extensions, and test targets — so every downstream component has a reliable data layer to build on.
**Depends on**: Phase 2 (v1.0 infrastructure)
**Requirements**: DATA-01, DATA-02, DATA-03
**Success Criteria** (what must be TRUE):
  1. ConsentStore.save(), loadCurrent(), and revoke() correctly read and write to the App Group UserDefaults container accessible to extension processes
  2. DeviceActivityMonitorExtension reads consent state from ConsentStore and blocks recordBypassEvent when consent is revoked
  3. PolicyRepository persists EscalationLevel and BypassEvent structs via JSONEncoder to App Group UserDefaults, readable in swift test on macOS
  4. FamilyActivitySelectionStore persists and retrieves the FamilyActivitySelection token set used for platform targeting
**Plans**: TBD

### Phase 4: Screen Time Engine
**Goal**: The app can request FamilyControls authorization from the user, schedule daily activity monitoring with per-platform session thresholds, apply and clear shields in ManagedSettings, and detect deauthorization with a recovery path — all callable from the main app.
**Depends on**: Phase 3
**Requirements**: ENFC-01
**Success Criteria** (what must be TRUE):
  1. User sees the system FamilyControls authorization sheet on first launch when AuthorizationManager.requestAuthorization() is called
  2. AuthorizationManager detects deauthorization via Combine publisher and calls ManagedSettingsStore().clearAllSettings() immediately
  3. ActivityScheduler.startMonitoring() registers a daily schedule and per-platform threshold event that fires via DeviceActivityCenter without premature activation (usage guard applied)
  4. When the daily limit threshold event fires, ShieldManager applies shields to the correct ManagedApplicationTokens in ManagedSettingsStore
**Plans**: TBD

### Phase 5: WKWebView Controlled Feed
**Goal**: Users can open the app, tap to Instagram or TikTok, see the real mobile web feed in a WKWebView, watch a countdown timer during their session, and be shown InterventionView when the session limit expires — all within the controlled client.
**Depends on**: Phase 3
**Requirements**: FEED-01, FEED-02, FEED-03, FEED-04, DASH-02
**Success Criteria** (what must be TRUE):
  1. User can load the Instagram mobile web feed (instagram.com) inside a WKWebView with mobile Safari user agent, with off-domain navigation blocked by the URL allowlist
  2. User can load the TikTok mobile web feed (tiktok.com) inside a WKWebView with the same session controls applied
  3. User sees a countdown timer (remaining session time) displayed during feed use, updated in real time
  4. User sees InterventionView replace the feed when session time reaches zero, with no way to dismiss it without the session resetting
  5. User can switch between Instagram and TikTok feeds via a platform switcher control in the feed view
**Plans**: TBD

### Phase 6: Onboarding Flow
**Goal**: A first-launch user can complete the entire onboarding sequence — FamilyControls authorization, all 9 limitation disclosures, explicit consent capture, platform selection via FamilyActivityPicker, and daily session limit setup — before enforcement is active, with all inputs wired to the underlying systems built in Phases 3–4.
**Depends on**: Phase 4, Phase 5
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05
**Success Criteria** (what must be TRUE):
  1. User is shown the FamilyControls system authorization sheet on first launch and the app proceeds only after authorization is granted
  2. User can read all 9 limitation disclosure strings in the onboarding flow before the consent step is reached
  3. User must explicitly tap an accept control to provide consent, which is persisted via ConsentStore before enforcement is enabled
  4. User can open FamilyActivityPicker as a fullScreenCover (not a nested sheet) and select Instagram and TikTok tokens, with the selection persisted to FamilyActivitySelectionStore
  5. User can set a daily session time limit per platform via a UI control, with the limit passed to ActivityScheduler.startMonitoring() before onboarding completes
**Plans**: TBD

### Phase 7: Dashboard and UAT Test Pass
**Goal**: The app home screen shows per-platform usage summary and remaining time drawn from local session counters, and all 9 XCTest UAT stubs that were created in v1.0 are replaced with real assertions that verify the implemented behavior of every v1.1 requirement.
**Depends on**: Phase 6
**Requirements**: DASH-01, TEST-01
**Success Criteria** (what must be TRUE):
  1. User sees a dashboard home screen with time used and remaining per platform, sourced from local session counters (not DeviceActivityReport extension)
  2. All 9 XCTest UAT stubs (CC-01, CC-02, CC-03, NB-01, NB-02, NB-03, POL-01, POL-02, POL-03) are replaced with real assertions that pass on the iOS 26.2 simulator
  3. xcodebuild test succeeds with zero skipped tests and zero failures after the UAT pass
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 3 → 4 → 5 → 6 → 7

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Controlled Client + Native Blocking | v1.0 | 4/4 | Complete | 2026-03-03 |
| 2. iOS Implementation Scaffolding | v1.0 | 4/4 | Complete | 2026-03-03 |
| 3. Data Layer Foundations | v1.1 | 0/? | Not started | — |
| 4. Screen Time Engine | v1.1 | 0/? | Not started | — |
| 5. WKWebView Controlled Feed | v1.1 | 0/? | Not started | — |
| 6. Onboarding Flow | v1.1 | 0/? | Not started | — |
| 7. Dashboard and UAT Test Pass | v1.1 | 0/? | Not started | — |
