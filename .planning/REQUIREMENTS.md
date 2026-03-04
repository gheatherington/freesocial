# Requirements: FreeSocial

**Defined:** 2026-03-04
**Core Value:** Users can stay connected without being pulled into compulsive feed consumption.

## v1.1 Requirements

Requirements for the Implementation milestone. Each maps to roadmap phases.

### Onboarding (ONBD)

- [ ] **ONBD-01**: User can complete FamilyControls authorization request on first launch
- [ ] **ONBD-02**: User is shown all 9 limitation disclosure strings during onboarding
- [ ] **ONBD-03**: User can provide explicit consent before enforcement is enabled
- [ ] **ONBD-04**: User can select platforms to control (Instagram, TikTok) via FamilyActivityPicker
- [ ] **ONBD-05**: User can set a daily session time limit per platform during onboarding

### Feed (FEED)

- [ ] **FEED-01**: User can view Instagram mobile feed in a controlled in-app WKWebView
- [ ] **FEED-02**: User can view TikTok mobile feed in a controlled in-app WKWebView
- [ ] **FEED-03**: User can see remaining session time displayed during feed use
- [ ] **FEED-04**: User sees InterventionView when session time expires

### Enforcement (ENFC)

- [ ] **ENFC-01**: User is blocked from native Instagram/TikTok by Screen Time shield when daily limit is reached

### Data Layer (DATA)

- [ ] **DATA-01**: User consent status is persisted and accessible across app and extension processes via App Group
- [ ] **DATA-02**: User can revoke consent, which blocks further bypass event telemetry writes
- [ ] **DATA-03**: Bypass events and escalation state are persisted via PolicyRepository to App Group

### Dashboard (DASH)

- [ ] **DASH-01**: User can see time used and remaining per platform on a dashboard home screen
- [ ] **DASH-02**: User can switch between Instagram and TikTok feed via a platform switcher in the feed view

### Testing (TEST)

- [ ] **TEST-01**: All 9 v1.0 XCTest UAT stubs replaced with real assertions that verify implemented behavior

## v1.2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enforcement

- **ENFC-02**: User experiences escalating cooldown periods after repeated bypass attempts (4-state EscalationLevel)
- **ENFC-03**: App detects FamilyControls deauthorization and clears shields with recovery UI

### Feed

- **FEED-05**: CSS/JS injection suppresses infinite-scroll UI elements (Reels rail, Stories bar)

### Dashboard

- **DASH-03**: DeviceActivityReport extension shows system-level usage statistics

### Settings

- **SETT-01**: User can view audit log of bypass events in Settings UI
- **SETT-02**: User can adjust session limits after initial onboarding

## Out of Scope

| Feature | Reason |
|---------|--------|
| Android launch | Defer until iOS architecture is proven in production |
| Full Instagram/TikTok feature parity (DM, Stories, posting) | APP_REVIEW_PREFLIGHT.md Section 3 prohibited copy; API/terms restrictions |
| ConsentManager importing PolicyStore | Architecture decision: dependency injection via init(suiteName:) instead |
| Remote telemetry / analytics | Data policy: on-device only |
| Persistent Keychain login credentials | WKWebView session cookies are sufficient; Keychain adds attack surface |
| Real-device FamilyControls entitlement | v1.1 targets simulator; real-device provisioning deferred to v1.2 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 3 | Pending |
| DATA-02 | Phase 3 | Pending |
| DATA-03 | Phase 3 | Pending |
| ENFC-01 | Phase 4 | Pending |
| FEED-01 | Phase 5 | Pending |
| FEED-02 | Phase 5 | Pending |
| FEED-03 | Phase 5 | Pending |
| FEED-04 | Phase 5 | Pending |
| DASH-02 | Phase 5 | Pending |
| ONBD-01 | Phase 6 | Pending |
| ONBD-02 | Phase 6 | Pending |
| ONBD-03 | Phase 6 | Pending |
| ONBD-04 | Phase 6 | Pending |
| ONBD-05 | Phase 6 | Pending |
| DASH-01 | Phase 7 | Pending |
| TEST-01 | Phase 7 | Pending |

**Coverage:**
- v1.1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-04*
*Last updated: 2026-03-04 — traceability updated after roadmap creation*
