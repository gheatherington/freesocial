# Feature Landscape

**Domain:** Digital wellbeing — controlled social media client with Screen Time enforcement
**Milestone:** v1.1 Implementation (adding real behavior to v1.0 skeleton)
**Researched:** 2026-03-04
**Overall confidence:** MEDIUM-HIGH — core Apple API patterns are well-documented; social site WKWebView behavior has real-world nuance that must be validated on device.

---

## Table Stakes

Features users expect. Missing = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Existing Dependency |
|---------|--------------|------------|---------------------|
| WKWebView feed loads Instagram/TikTok mobile sites | Core product premise — without this the app has no content | High | `InstagramProvider`, `TikTokProvider` stubs; `FeedView` skeleton |
| Session timer visible during feed use | Users need to know how much time remains to trust the system | Medium | `ActivityScheduler` stub; `PolicyState` / `EscalationLevel` |
| InterventionView shown when session limit hit | The feed must stop — passive limits fail the product's purpose | Medium | `InterventionView` exists; `FeedView` wiring absent (audit gap #7) |
| FamilyControls authorization prompt on first launch | Required by Apple APIs before any Screen Time enforcement | Medium | `AuthorizationManager.requestAuthorization()` stub |
| Onboarding disclosure of limitations | Required by App Store compliance and POL-03 (9/11 strings unplaced) | Medium | `APP_REVIEW_PREFLIGHT.md` Section 4; no onboarding UI yet |
| Consent capture in onboarding | Required by POL-02 — no enforcement until user consents | Medium | `ConsentStore.save()` stub; `ConsentRecord` type exists |
| Screen Time shield activates for native apps when limit is reached | The controlled client is only useful if native app bypass is blocked | High | `ShieldManager`, `DeviceActivityMonitorExtension` wired but stubs |
| Platform selection (Instagram / TikTok) | User needs to pick which platforms to control | Medium | `FamilyActivityPicker` (system UI); `FamilyActivitySelection` type needed |
| Session limit setup during onboarding | Must choose their daily limit before enforcement is meaningful | Low | `ActivityScheduler` stub — no UI |
| Deauthorization detection and graceful degradation | If user revokes Screen Time access, app must detect and surface a recovery path | High | `AuthorizationManager` has no observer — audit gap #6 |
| Consent revocation gating telemetry writes | POL-02 stop-ship condition: writes must stop when consent revoked | Medium | `ConsentStore.revoke()` stub; `PolicyRepository.recordBypassEvent` ungated |

## Differentiators

Features that set the product apart. Not universally expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| WKWebView CSS/JS injection to suppress infinite scroll UI elements | Reduces addictive surface area even within the WKWebView session — goes beyond simple time limits | High | `WKUserScript` + `evaluateJavaScript`; site-specific CSS rules for each platform; must survive site updates |
| Per-platform usage breakdown on dashboard | Users trust data when they can see it per-app, not just a global total | Medium | Requires `DeviceActivityReport` extension (new target) or approximation via local counters |
| Countdown timer UX (not just a number) | Progress ring or countdown makes session boundary feel real before it hits | Low | SwiftUI `TimelineView` or `Timer`-based; display only |
| Escalation state visible in dashboard | Users learn the bypass costs when they can see "you are in cooldown2" explicitly | Low | `PolicyRepository.currentEscalationLevel()` — data exists; no UI |
| Limitation disclosure inside InterventionView | Turns a blocked-state frustration into a trust-building moment | Low | Two required strings already in `InterventionView`; 3 more belong here |
| Audit log display in Settings | Power users want to verify the system is recording correctly | Medium | `AuditLog` stub exists; no read UI |

## Anti-Features

Features to explicitly NOT build in v1.1.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full DM / story / post parity in WKWebView | Prohibited in `APP_REVIEW_PREFLIGHT.md` Section 3 ("Full parity replacement") and impractical — sites detect headless clients | Provide `FallbackRouter.routeToNativeApp` for unsupported pathways |
| Blocking Reels/For You in the native Instagram/TikTok apps | CANNOT CLAIM per claims matrix — no public iOS API supports in-app surface edits | Use app-level Screen Time shield blocking the native apps entirely |
| Silent/invisible enforcement | CANNOT CLAIM — violates disclosure posture; App Review rejection risk | All enforcement must be user-visible and consent-gated |
| Persistent login credential storage | Security risk; adds scope to entitlement review; WKWebView session cookies are sufficient | Use WKHTTPCookieStore persistence only; no Keychain for social credentials |
| DeviceActivityReport extension for dashboard | The extension point is known to crash frequently and run unstably; adds another extension target to maintain | Approximate usage with local counters from `ActivityScheduler` for v1.1; defer `DeviceActivityReport` to v1.2 |
| Escalation cooldowns / bypass bypass (v1.1 scope) | Architecture exists but wiring is complex; v1.1 focus is baseline session enforcement only | Escalation is `EscalationLevel` scaffold; wire full chain in v1.2 |
| Remote telemetry | Data policy states on-device only; introduces privacy scope and network requirements | Keep all telemetry in App Group `UserDefaults` only |
| Multi-user / family mode | Requires `.individual` vs `.family` authorization divergence | Use `.individual` only — family mode is a separate product decision |

---

## Feature Dependencies

Dependencies between features, in implementation order.

```
FamilyControls authorization (AuthorizationManager)
  → Platform selection (FamilyActivityPicker)
  → Native app shielding (ShieldManager + ActivityScheduler)
  → DeviceActivityMonitor threshold firing (eventDidReachThreshold)

Consent capture (ConsentStore.save)
  → Consent gate on telemetry writes (PolicyRepository.recordBypassEvent)
  → Consent revocation flow (ConsentStore.revoke → gate stops writes)

WKWebView feed (InstagramProvider / TikTokProvider implementation)
  → Session timer state (clock started on load, read from ActivityScheduler)
  → InterventionView trigger (session timer hits limit → show InterventionView)
  → Fallback routing (unsupported action → FallbackRouter.routeToNativeApp)

Session limit setup (onboarding)
  → ActivityScheduler.schedule() wired to chosen limit
  → DeviceActivityEvent threshold set to match

Onboarding flow (sequential screens)
  1. Limitation disclosures (POL-03 strings 1-9)
  2. Consent capture (POL-02)
  3. FamilyControls authorization request
  4. Platform selection (FamilyActivityPicker)
  5. Session limit setup

Deauthorization detection (AuthorizationManager observer)
  → Recovery UI surface (settings or interstitial)
  → Shield enforcement disabled if not authorized
```

---

## MVP Recommendation for v1.1

The milestone's definition of done is "fully working and testable on simulator." This shapes prioritization: features that require real-device entitlements (FamilyControls, DeviceActivity firing) cannot be fully verified on simulator, but the stub path must be wired.

**Build in this order:**

1. **Onboarding flow (screens + disclosure strings)** — unblocks consent capture and auth request; satisfies POL-02, POL-03 stop-ship conditions; no real-device APIs required for screen rendering.

2. **Consent capture and revocation wiring** — `ConsentStore.save()` / `revoke()` / `loadCurrent()` real implementation; gates `PolicyRepository.recordBypassEvent`; POL-02 completion.

3. **WKWebView feed implementation** — `InstagramProvider` and `TikTokProvider` load mobile web URLs in a `WKWebView`; session timer starts on load; cookie persistence via `WKHTTPCookieStore`; CSS injection suppresses known infinite-scroll selectors.

4. **InterventionView trigger wired to session timer** — `FeedView` monitors elapsed time; shows `InterventionView` at limit; satisfies CC-03.

5. **FamilyControls auth + platform selection** — `AuthorizationManager.requestAuthorization()` real call; `FamilyActivityPicker` sheet in onboarding; `FamilyActivitySelection` persisted; `ActivityScheduler` wired.

6. **Shield enforcement wiring** — `ShieldManager` applies `ManagedSettings` restrictions after `DeviceActivityMonitor.eventDidReachThreshold`; removes shield at reset.

7. **Deauthorization detection** — `AuthorizationCenter.authorizationStatus` observer in `AuthorizationManager`; enforcement disabled + recovery UI shown on `.notDetermined` or `.denied`.

8. **Dashboard UI** — usage summary from local session counters; remaining time display; escalation level indicator.

**Defer to v1.2:**
- CSS/JS injection to suppress specific UI elements within WKWebView (high complexity; site-specific; fragile)
- `DeviceActivityReport` extension for real usage data (crashes frequently per developer forums; not worth the instability for v1.1)
- Escalation chain wiring beyond baseline (cooldown1, cooldown2, lockdown transitions)
- Audit log read UI in Settings
- `BypassEvent` schema expansion (remaining fields: `app_token_hash`, `prior_state`, `resulting_state`)

---

## Platform and API Constraints

These are not design decisions — they are hard constraints that shape every feature above.

| Constraint | Impact | Source |
|------------|--------|--------|
| Instagram and TikTok mobile sites detect automation and may throttle or redirect | WKWebView feed may require custom User-Agent; login may need manual user entry; persistent cookies are essential | MEDIUM confidence — observed in community (Hacker News threads) |
| `FamilyActivityPicker` is prone to crashing when browsing large app categories | Add fallback state + error recovery around picker presentation | MEDIUM confidence — multiple developer forum reports |
| `DeviceActivityMonitor.eventDidReachThreshold` fires prematurely on iOS 26.x beta | Shield may trigger at 0 minutes of usage; workaround is re-granting Screen Time permissions; Apple investigating | HIGH confidence — Apple Developer Forums thread 811305 confirms iOS 26.2 regression |
| `DeviceActivityReport` extension is unstable and crashes frequently | Do not build dashboard on this; use local counters instead for v1.1 | MEDIUM confidence — multiple developer reports corroborated |
| FamilyControls entitlement must be approved by Apple separately before real-device testing | All FamilyControls code paths are simulator-only until entitlement arrives; use `#if canImport(FamilyControls)` guards | HIGH confidence — Apple Developer Documentation |
| Cookie storage is not automatically shared between `HTTPCookieStorage` and `WKCookieStore` | Must implement `cookiesDidChange` persistence manually to survive app restarts | HIGH confidence — Apple Developer Forums, WebKit architecture |
| WKWebView runs out-of-process (separate memory space) | CSS/JS injection via `WKUserScript` is the correct channel — not DOM manipulation from Swift | HIGH confidence — WebKit architecture documentation |
| All enforcement must be user-visible and consent-gated | No silent background action allowed; every enforcement event needs a disclosure path | HIGH confidence — APP_REVIEW_PREFLIGHT.md POL-01/POL-02/POL-03 |

---

## Sources

- [A Developer's Guide to Apple's Screen Time APIs](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7) — MEDIUM confidence (community, verified against Apple docs)
- [Apple DevForums: iOS 26.2 DeviceActivityMonitor premature threshold firing](https://developer.apple.com/forums/thread/811305) — HIGH confidence (Apple Developer Forums, first-party)
- [Apple DevForums: iOS 26.2 RC DeviceActivityMonitor](https://developer.apple.com/forums/thread/809410) — HIGH confidence
- [FamilyControls — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols) — HIGH confidence (official)
- [AuthorizationCenter — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols/authorizationcenter) — HIGH confidence (official)
- [requestAuthorization — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:)) — HIGH confidence (official)
- [revokeAuthorization — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols/authorizationcenter/revokeauthorization(completionhandler:)) — HIGH confidence (official)
- [Screen Time API overview — Apple Developer Documentation](https://developer.apple.com/documentation/screentimeapidocumentation) — HIGH confidence (official)
- [State of the Screen Time API 2024](https://riedel.wtf/state-of-the-screen-time-api-2024/) — MEDIUM confidence (community audit, recent)
- [WKWebView JavaScript injection — Swift Senpai](https://swiftsenpai.com/development/web-view-javascript-injection/) — MEDIUM confidence (community, verified against Apple API)
- [Persisting cookies in WKWebView 2024](https://medium.com/@leonp1991/persisting-cookies-in-a-uikit-ios-application-in-2024-8cb922ffa66e) — MEDIUM confidence (community)
- [DeviceActivityReport extension — Medium series](https://letvar.medium.com/time-after-screen-time-part-2-the-device-activity-report-extension-10eeeb595fbd) — MEDIUM confidence (community)
- [Opal onboarding flow analysis](https://mobbin.com/explore/flows/7b6dc8e9-56e3-4db3-a898-cfdddc9b1e8a) — LOW confidence (UI analysis, not technical)
- [Hacker News: WKWebView lockdown concerns for Instagram/TikTok](https://news.ycombinator.com/item?id=32517029) — LOW confidence (community discussion)
- Internal: `ios/APP_REVIEW_PREFLIGHT.md` — HIGH confidence (project artifact, canonical)
- Internal: `ios/Packages/*/Sources/**/*.swift` — HIGH confidence (project code, verified)
- Internal: `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — HIGH confidence (project artifact)
