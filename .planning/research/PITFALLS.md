# Domain Pitfalls

**Domain:** iOS Screen Time app — WKWebView feed, FamilyControls, DeviceActivity scheduling, consent persistence
**Researched:** 2026-03-04
**Milestone:** v1.1 Implementation (Phase 3)

---

## Critical Pitfalls

Mistakes that cause rewrites, permanent user-facing failures, or App Store rejections.

---

### Pitfall 1: FamilyControls Authorization Called Outside the Main App Process

**What goes wrong:** Authorization prompts presented from an App Extension target (DeviceActivityMonitor, ShieldConfiguration, ShieldAction) are silently swallowed or crash. Only the main app target can invoke `AuthorizationCenter.shared.requestAuthorization(for:)`.

**Why it happens:** FamilyControls authorization is process-scoped and requires the main application's UI context. Extensions run in background daemon processes with no UI presentation surface.

**Consequences:** Authorization sheet never appears; user onboarding stalls; silent failure with `FamilyControlsError error 3` on simulator.

**Prevention:**
- Call `AuthorizationCenter.shared.requestAuthorization(for: .individual)` only from the main app during onboarding (Phase 3 `AuthorizationManager.requestAuthorization()`).
- Never trigger auth from any extension target.
- Check `AuthorizationCenter.shared.authorizationStatus` before invoking restricted Screen Time APIs anywhere in the call stack.

**Detection:** `FamilyControlsError` with code 3 at runtime; authorization sheet never appears in onboarding.

**Phase:** Phase 3 — Onboarding implementation. Entry condition: entitlement approved.

**Confidence:** HIGH — Apple forum thread (thread/708050), Julius Brussee developer guide.

---

### Pitfall 2: DeviceActivity Premature `eventDidReachThreshold` on iOS 26

**What goes wrong:** On iOS 26.x (including the project's target runtime iOS 26.2), `eventDidReachThreshold` fires immediately (within seconds) even when actual Screen Time usage is 0 minutes. This causes the shield to activate the moment monitoring starts, blocking apps before any usage has occurred.

**Why it happens:** Confirmed regression in the DeviceActivity framework on iOS 26. The trigger appears correlated with the device charging while locked after a period of idle time. Apple has not released a fix as of 2026-03-04. Reports of intermittent behavior — some days no occurrence, other days multiple in a row.

**Consequences:** Shield activates at session start, blocking native apps immediately. Users experience the intervention screen at session start. Effectively breaks the enforcement model.

**Prevention:**
- Add a guard in `eventDidReachThreshold` that reads cumulative usage from a persisted baseline and suppresses shield activation if elapsed usage is below a minimum threshold (e.g., 30 seconds).
- Consider delaying `ManagedSettingsStore` shield application by one polling cycle after receiving the callback, and re-verifying with DeviceActivity data before applying.
- File FB report to track Apple fix. Watch iOS 26.x point releases during Phase 3 development.

**Detection:** Shield activates with 0 Screen Time minutes visible; `eventDidReachThreshold` fires seconds after `startMonitoring` call.

**Phase:** Phase 3 — Screen Time enforcement implementation. High-priority test case.

**Confidence:** HIGH — Apple Developer Forum thread/811305, thread/809410. Multiple developers reporting same behavior on iOS 26.2.

---

### Pitfall 3: WKWebView Coordinator Retain Cycle Prevents Session Timer Cleanup

**What goes wrong:** WKWebView holds a strong reference to its `navigationDelegate`. If the Coordinator (which implements `WKNavigationDelegate`) holds a strong back-reference to the `WKWebView` instance, a retain cycle forms. The session timer fires even after the view is dismissed, continuing to consume time budget in the background.

**Why it happens:** SwiftUI's `UIViewRepresentable` pattern creates a Coordinator that acts as the delegate. Developers commonly store a reference to the web view in the coordinator for convenience, inadvertently creating a cycle: `WKWebView → Coordinator (via delegate) → WKWebView`.

**Consequences:** Session timer persists after navigation away. User is charged time that wasn't visibly consumed. Memory leaks accumulate across multiple sessions.

**Prevention:**
- Make any Coordinator-to-WKWebView reference `weak`.
- Alternatively, implement `UIViewRepresentable.dismantleUIView(_:coordinator:)` to explicitly nil out the delegate and stop the session timer.
- Session timer must be cancelled on `webViewDidFinish` (normal close) and in `dismantleUIView`.

**Detection:** Timer callbacks arriving after view dismissed; Instruments showing WKWebView instances not released after navigation.

**Phase:** Phase 3 — WKWebView controlled feed implementation.

**Confidence:** HIGH — Apple Developer Forums thread/733355, Josh Hrach UIViewRepresentable delegate guide 2024.

---

### Pitfall 4: ApplicationToken Mutation Breaks Shield Context Identification

**What goes wrong:** iOS sometimes mutates the opaque `ApplicationToken` values it provides to `ShieldConfigurationDataSource` and `ShieldActionDelegate`. Tokens stored in App Group by the main app no longer match what the extension receives, making it impossible to determine which app triggered the shield or what intervention state to display.

**Why it happens:** This is a documented framework-level bug, not a code error. iOS changes tokens without notice, typically after OS updates or after extended periods. Multiple production Screen Time apps (ScreenZen, Jomo, Opal) have reported this.

**Consequences:** Shield extension displays generic UI instead of context-specific intervention screen. `ShieldActionDelegate` cannot identify the correct `ManagedSettingsStore` to clear. Shield removal may fail silently.

**Prevention:**
- Design `ShieldConfigurationExtension` to fall back to a generic intervention UI when token lookup fails rather than crashing.
- Store a fallback "current escalation level" in App Group UserDefaults (already present via `PolicyRepository`) so the extension can render meaningful UI even without token match.
- Do not rely solely on token identity for any critical flow path.

**Detection:** Shield shows wrong or empty content; `ShieldActionDelegate` handle function receives unknown token; policy state lookup returns nil.

**Phase:** Phase 3 — Shield configuration and action delegate implementation.

**Confidence:** HIGH — Apple Developer Forums (Screen Time tags), riedel.wtf Screen Time API analysis 2024, multiple developer reports.

---

### Pitfall 5: Consent State Not Readable in Extension Process

**What goes wrong:** `ConsentStore.loadCurrent()` returns nil in the DeviceActivityMonitor extension because the extension runs in a separate process that cannot access the main app's in-memory state. If `ConsentStore` is initialized with `.standard` UserDefaults instead of the App Group suite, extension reads return nil even when consent was granted in the main app.

**Why it happens:** Extension processes have separate UserDefaults namespaces from the main app. Only the App Group suite name (`group.com.freesocial.app`) creates a shared backing store. The v1.0 stub defaults to `true` (issue #3 fix); Phase 3 must wire real reads.

**Consequences:** Consent gate in `DeviceActivityMonitorExtension.eventDidReachThreshold` bypasses consent check silently (fails open or fails closed depending on implementation). Bypass events recorded without consent if guard fails open.

**Prevention:**
- Phase 3 wiring of `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()` is the only safe path — already documented in `DeviceActivityMonitorExtension.swift` TODO.
- Never use `ConsentStore()` with `.standard` defaults in any extension target.
- Add assertion in `ConsentStore.init` (already present from v1.0) — ensure it fires in debug builds during extension integration testing.

**Detection:** Consent revoked in main app but bypass events still record; `assertionFailure` fires in extension logs.

**Phase:** Phase 3 — ConsentStore wiring. Listed as entry condition in v1.0 audit.

**Confidence:** HIGH — App Group IPC architecture confirmed in project design decisions; v1.0 stub code explicitly documents the gap.

---

## Moderate Pitfalls

### Pitfall 1: DeviceActivitySchedule DateComponents Format Causes Silent Callback Failure

**What goes wrong:** `intervalDidStart` and `intervalDidEnd` callbacks are not triggered depending on how `DateComponents` are specified for the schedule's start and end times.

**Known broken patterns:**
- Start has time components only, end has date + time components → `intervalDidStart` never fires.
- Start has date + time components, end has time components only → `intervalDidEnd` never fires.
- Both have time components only → neither callback fires.

**Prevention:** Use **only** `hour`, `minute`, and `second` components for both `intervalStart` and `intervalEnd` in `DeviceActivitySchedule`. Do not mix date and time component types.

**Detection:** Monitor extension callbacks never received; test by scheduling a 1-minute window and verifying callback timing.

**Phase:** Phase 3 — ActivityScheduler implementation in ScreenTimeEngine.

**Confidence:** HIGH — Apple Developer Forums thread/729841, Crunchybagel DeviceActivity tutorial.

---

### Pitfall 2: DeviceActivitySchedule Name Collision Stops Earlier Schedule

**What goes wrong:** If two `startMonitoring` calls use the same `DeviceActivityName` for overlapping time windows, the earlier schedule stops working. The second call silently replaces the first.

**Prevention:**
- Use distinct `DeviceActivityName` values per logical monitoring purpose (e.g., `DeviceActivityName("daily-session")` vs `DeviceActivityName("cooldown-window")`).
- Keep `DeviceActivityEvent.Name` values distinct per threshold event within the same activity.
- Document a name registry in `ActivityScheduler` to prevent accidental collision.
- Maximum 20 distinct activity names per app — do not generate names dynamically per-session.

**Detection:** One of two concurrent schedules stops firing; callbacks arrive for wrong activity name.

**Phase:** Phase 3 — ActivityScheduler in ScreenTimeEngine.

**Confidence:** HIGH — Apple Developer Forums thread/742131, developer guide (Brussee).

---

### Pitfall 3: WKWebView Deep Links Launch Native Instagram/TikTok App

**What goes wrong:** When Instagram or TikTok's mobile website detects it's running in a WKWebView (via user agent or feature detection), it may inject redirects to `instagram://` or `tiktok://` universal links. iOS intercepts these and opens the native app, circumventing the controlled session.

**Why it happens:** Instagram and TikTok serve different content to their own in-app browser vs Safari vs third-party WebView. Universal link taps in a WKWebView are handled by iOS — even if the app is uninstalled, the behavior can trigger unexpected navigation.

**Consequences:** User exits WKWebView session entirely, using native app without session time tracking. Session timer continues but no time is consumed in the controlled view. Screen Time shield is not active during native app time.

**Prevention:**
- In `WKNavigationDelegate.decidePolicyFor(navigationAction:)`, inspect `navigationAction.request.url` and cancel any navigation to `instagram://`, `tiktok://`, or other registered URL schemes.
- Set a custom user agent string that presents as a generic mobile browser rather than a WKWebView to reduce redirect targeting.
- Consider `WKAppBoundDomains` entitlement (iOS 14+) to limit navigation to declared domains only.

**Detection:** Native Instagram/TikTok app opens during WKWebView session; navigation policy delegate receives non-https scheme URLs.

**Phase:** Phase 3 — SocialProvider / WKWebView feed implementation.

**Confidence:** MEDIUM — Apple Developer Forums thread/670042; WKAppBoundDomains confirmed in Apple documentation.

---

### Pitfall 4: WKWebView Cookie Set Race on First Load

**What goes wrong:** If session cookies are set via `WKHTTPCookieStore.setCookie(_:completionHandler:)` and a page load is initiated before all `setCookie` callbacks have completed, the web page loads without the intended cookies. Session is dropped on first navigation.

**Why it happens:** `WKHTTPCookieStore` cookie operations are asynchronous. `WKWebView` runs in a separate process from the app. There is no synchronous confirmation that cookies are available to the renderer before `load(_:)` is called.

**Consequences:** First page load arrives without auth cookies. User is shown a logged-out state or login prompt instead of their feed.

**Prevention:**
- Chain `load(_:)` inside the `completionHandler` of the final `setCookie` call (not in a fire-and-forget `Task`).
- If multiple cookies are needed, use `DispatchGroup` or an async sequence to await all completions before loading.
- Verify cookie presence with `WKHTTPCookieStore.getAllCookies` before initiating navigation.

**Detection:** Web view shows login page on first load only; subsequent navigations work correctly.

**Phase:** Phase 3 — SocialProvider / WKWebView session initialization.

**Confidence:** HIGH — Apple Developer Forums thread/97194, thread/131931, Brave Location WKWebView cookie fix write-up.

---

### Pitfall 5: DeviceActivityReport Extension Severe Sandbox Restrictions

**What goes wrong:** Developers attempt to use Core Data, print statements, notifications, or network calls inside the `DeviceActivityReport` extension to surface usage data to the main app — all silently fail. The extension is designed as a one-way rendering surface only.

**Why it happens:** The DeviceActivityReport extension runs in an extreme sandbox for privacy. No data can escape outward. It cannot communicate back to the host app.

**Consequences:** Dashboard implementation strategy that relies on extracting data from the extension cannot work. Attempting background fetch workarounds results in App Review rejection if they circumvent Screen Time privacy design.

**Prevention:**
- The extension renders SwiftUI views in-place. The main app embeds it via `DeviceActivityReport` view.
- If summary statistics (e.g., "42 minutes today") are needed in native UI outside the extension, they must come from a separate source (e.g., the app's own session timer stored in App Group, not from Screen Time data).
- Accept that Screen Time usage data cannot be extracted to a custom data model.

**Detection:** Extension renders blank or crashes; print output never visible; Core Data save calls return without error but data is absent.

**Phase:** Phase 3 — Dashboard UI implementation.

**Confidence:** HIGH — Apple Developer Forums thread/708444, letvar Medium series on DeviceActivityReport extension, iOS Screen Time API guide (Brussee).

---

### Pitfall 6: Deauthorization Leaves Active Shields in ManagedSettings

**What goes wrong:** If the user revokes FamilyControls authorization (via Settings > Screen Time), shields applied via `ManagedSettingsStore` may remain active. The main app receives a deauthorization event but if it does not explicitly clear all shield settings, the user's native apps remain blocked indefinitely.

**Why it happens:** `ManagedSettingsStore` state is persistent, not automatically cleared on deauthorization. The app is responsible for detecting the deauthorization event and calling `clearAllSettings()`.

**Consequences:** User revokes authorization but native apps remain shielded. User loses access to apps they unblocked themselves. High App Review risk — reviewers interpret this as deceptive behavior.

**Prevention:**
- Implement `authorizationStatusDidChange` observer in `AuthorizationManager`.
- On deauthorization: call `ManagedSettingsStore().clearAllSettings()`, stop all `DeviceActivityCenter` monitoring, and reset `PolicyRepository` to baseline.
- This is the "deauthorization detection and recovery path" listed as a Phase 3 entry condition.
- Test explicitly: revoke Screen Time permission while shields are active, verify all apps become accessible.

**Detection:** Native apps remain shielded after Screen Time permission revoke in Settings.

**Phase:** Phase 3 — AuthorizationManager deauthorization path. Explicitly listed as entry condition.

**Confidence:** MEDIUM — Inferred from ManagedSettings persistence model and Screen Time API developer guide; deauthorization cleanup pattern consistent with framework design.

---

## Minor Pitfalls

### Pitfall 1: Simulator Does Not Reliably Trigger Background DeviceActivity Callbacks

**What goes wrong:** On iOS Simulator, `intervalDidStart`, `intervalDidEnd`, and `eventDidReachThreshold` callbacks are frequently not delivered at all, or arrive with significant delay. Background wakeup simulation that used to work no longer does in current simulator runtimes.

**Prevention:**
- Use simulator only to verify extension code compiles and App Group reads succeed.
- Manual testing of enforcement flow requires a physical device with approved FamilyControls entitlement (deferred to v1.2 per project constraints).
- Write unit tests that call extension methods directly rather than relying on system-delivered callbacks in simulator.

**Phase:** Phase 3 — all enforcement testing. Set expectations early.

**Confidence:** MEDIUM — Apple Developer Forums (Device Activity tags), multiple developer reports of simulator unreliability.

---

### Pitfall 2: WKWebView `WKProcessPool` Not Shared Across Platform Instances

**What goes wrong:** If `FeedView` creates separate `WKWebView` instances for Instagram and TikTok without sharing a `WKProcessPool`, session cookies and local storage are isolated between them as expected — but if the user switches platforms, a new WKWebView process is spawned with no cached state, causing slower loads and re-authentication.

**Prevention:**
- Decide at architecture time whether Instagram and TikTok sessions should share a process pool or be isolated.
- For this app's controlled-session model, isolation is correct (prevents cross-platform session bleed). Document this as an intentional design choice, not a bug, so it is not "fixed" accidentally.
- Use separate `WKWebsiteDataStore` instances per platform for true isolation.

**Phase:** Phase 3 — SocialProvider / FeedView platform switcher implementation.

**Confidence:** MEDIUM — WKProcessPool shared-session behavior confirmed in Apple Developer Forums and iOS WebView documentation.

---

### Pitfall 3: `DeviceActivityCenter.startMonitoring` Crashes on Invalid Schedule

**What goes wrong:** `startMonitoring(_:during:events:)` throws `DeviceActivityCenter.Error.excessiveActivities` if more than 20 activities are registered. In some SDK versions it can also crash (not throw) on invalid `DateComponents` values.

**Prevention:**
- Enforce a maximum of 1–2 named activities for v1.1 (daily session + optional cooldown).
- Wrap `startMonitoring` in a `do-catch` and log the error before falling through.
- Validate `DateComponents` before constructing `DeviceActivitySchedule`.

**Phase:** Phase 3 — ActivityScheduler implementation.

**Confidence:** MEDIUM — Apple Developer Forums thread/770223.

---

### Pitfall 4: Instagram/TikTok Mobile Web Requires Specific User Agent to Show Feed

**What goes wrong:** Instagram's mobile web (`instagram.com`) may redirect to a download page or show a degraded view if the user agent string signals a non-mobile environment or an unrecognized browser. TikTok similarly gates some content behind login or redirects to app download.

**Prevention:**
- Set `WKWebView.customUserAgent` to a standard Mobile Safari string, e.g. `"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"`.
- Test feed load on simulator after setting user agent before implementing any further WKWebView logic.

**Phase:** Phase 3 — SocialProvider initial WKWebView load. First implementation step.

**Confidence:** MEDIUM — Developer forum reports about WKWebView user-agent detection by social media sites; standard practice in WKWebView apps.

---

### Pitfall 5: `#if canImport(FamilyControls)` Guard Must Stay for Swift Package Tests

**What goes wrong:** Removing the `#if canImport(FamilyControls)` guard in `AuthorizationManager` would break `swift test` runs for `ControlledClient` on macOS CI runners that lack the FamilyControls framework. This was established as a key pattern in v1.0.

**Prevention:**
- Keep all FamilyControls imports behind `#if canImport(FamilyControls)` guards in SPM package targets.
- When implementing real authorization logic in Phase 3, put the entire implementation block inside the guard, with a stub no-op in the `#else` branch.

**Phase:** Phase 3 — AuthorizationManager implementation.

**Confidence:** HIGH — v1.0 decision explicitly recorded in CLAUDE.md and project.pbxproj notes.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Onboarding: FamilyControls auth | Auth called from wrong process | Auth only from main app; check status before UI progression |
| Screen Time scheduling | DateComponents format causes silent callback failure | Use time-only components (hour/minute/second) in both start and end |
| Screen Time scheduling | iOS 26 premature `eventDidReachThreshold` | Guard callback with usage check; watch iOS 26.x point releases |
| Screen Time enforcement | Token mutation breaks shield context | Fallback to generic UI + App Group escalation level read |
| Screen Time enforcement | Deauthorization leaves shields active | Observe deauthorization; call `clearAllSettings()` immediately |
| WKWebView feed | Coordinator retain cycle | Weak Coordinator-to-WebView reference; cancel timer in dismantleUIView |
| WKWebView feed | Deep link opens native app | Cancel non-https URL schemes in `decidePolicyFor` |
| WKWebView feed | Cookie set race on first load | Chain `load(_:)` in `setCookie` completion handler |
| WKWebView feed | Mobile web gating by user agent | Set Mobile Safari user agent string before first load |
| Consent wiring | Extension reads `.standard` defaults | Always pass `AppGroup.suiteName`; assertionFailure guards presence |
| Dashboard | DeviceActivityReport data extraction attempt | Extension is one-way; use own session timer for native statistics |
| Testing enforcement | Simulator doesn't deliver callbacks | Unit-test extension methods directly; flag real-device testing for v1.2 |

---

## Sources

- Apple Developer Forums — FamilyControls authorization on Simulator: https://developer.apple.com/forums/thread/708050
- Apple Developer Forums — iOS 26.2 DeviceActivityMonitor premature eventDidReachThreshold: https://developer.apple.com/forums/thread/811305
- Apple Developer Forums — iOS 26.2 RC DeviceActivityMonitor events: https://developer.apple.com/forums/thread/809410
- Apple Developer Forums — DeviceActivitySchedule DateComponents format issue: https://developer.apple.com/forums/thread/729841
- Apple Developer Forums — Multiple DeviceActivity schedules conflict: https://developer.apple.com/forums/thread/742131
- Apple Developer Forums — DeviceActivityCenter startMonitoring crash: https://developer.apple.com/forums/thread/770223
- Apple Developer Forums — WKWebView cookies not syncing: https://developer.apple.com/forums/thread/131931
- Apple Developer Forums — WKWebView cookie store async: https://developer.apple.com/forums/thread/97194
- Apple Developer Forums — WKWebView opening Instagram app: https://developer.apple.com/forums/thread/670042
- Apple Developer Forums — WebView UIViewRepresentable navigation delegate: https://developer.apple.com/forums/thread/733355
- Apple Developer Forums — DeviceActivityReport continuous issues: https://developer.apple.com/forums/thread/742109
- Apple Developer Forums — Screen Time API completely unreliable: https://developer.apple.com/forums/thread/750623
- Julius Brussee — Developer Guide to Screen Time APIs (FamilyControls, ManagedSettings, DeviceActivity): https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7
- riedel.wtf — State of the Screen Time API 2024: https://riedel.wtf/state-of-the-screen-time-api-2024/
- letvar Medium — DeviceActivityReport extension: https://letvar.medium.com/time-after-screen-time-part-2-the-device-activity-report-extension-10eeeb595fbd
- Crunchybagel — Monitoring App Usage with Screen Time Framework: https://crunchybagel.com/monitoring-app-usage-using-the-screen-time-api/
- Josh Hrach — UIViewRepresentable delegates in SwiftUI (2024): https://www.joshspadd.com/2024/01/swiftui-view-representable-delegates/
- Brave Location — WKWebView session cookie fix: https://bravelocation.com/Fixed-issue-with-WkWebViews-session-cookies
- Apple Developer Documentation — DeviceActivitySchedule: https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule
- Apple Developer Documentation — FamilyControls: https://developer.apple.com/documentation/familycontrols
- Apple Developer Documentation — DeviceActivityReport: https://developer.apple.com/documentation/deviceactivity/deviceactivityreport
