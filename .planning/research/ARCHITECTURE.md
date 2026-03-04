# Architecture Patterns: FreeSocial v1.1 Integration

**Domain:** iOS Screen Time + controlled WKWebView social feed
**Researched:** 2026-03-04
**Milestone scope:** v1.1 Implementation — filling stubs, adding real components

---

## Current Architecture (v1.0 Baseline)

### Package Dependency Graph

```
Main App (SwiftUI)
  ├── ControlledClient  ──imports──▶  PolicyStore
  ├── ScreenTimeEngine  (independent)
  ├── ConsentManager    (independent)
  └── PolicyStore       (foundation)

Extensions (same App Group: group.com.freesocial.app)
  ├── DeviceActivityMonitor  ──imports──▶  PolicyStore, ManagedSettings, DeviceActivity
  ├── ShieldConfiguration    ──imports──▶  ManagedSettingsUI (UIKit only)
  └── ShieldAction           ──imports──▶  ManagedSettings (UIKit-free)
```

### Dependency Rules (immutable — carry forward to v1.1)

| Rule | Why |
|------|-----|
| ControlledClient MAY import PolicyStore | Feed needs escalation state |
| ScreenTimeEngine MUST NOT import ControlledClient | Circular dep risk |
| ConsentManager MUST NOT import PolicyStore | Package independence; inject suiteName via init |
| Extensions access App Group only via UserDefaults(suiteName:) | No cross-package import across process boundary |
| ShieldConfiguration uses UIKit struct API only | ManagedSettingsUI is UIKit-backed; no SwiftUI |

---

## Recommended Architecture for v1.1

### New Components and Where They Live

| Component | Location | Package/Layer | Rationale |
|-----------|----------|---------------|-----------|
| `WebFeedView` (WKWebView wrapper) | `ControlledClient` package | New file in existing package | FeedView already lives here; this replaces/wraps the List stub |
| `WebSessionCoordinator` | `ControlledClient` package | New class, WKNavigationDelegate | Handles URL allowlist, session timer, InterventionView trigger |
| `OnboardingFlow` | Main app | New SwiftUI view hierarchy | Calls ScreenTimeEngine; not a package — needs @main scope for UI |
| `DashboardView` | Main app | New SwiftUI view | Embeds DeviceActivityReport view; host-only API |
| `DeviceActivityReport` extension | New Xcode target | 4th app extension | Required separate process for sandbox privacy model |
| `FamilyActivitySelection` persistence | `PolicyStore` package | New file | Tokens are PolicyStore data; persist to App Group |
| Deauthorization observer | `ScreenTimeEngine` package | Add to `AuthorizationManager` | Publishes status changes via Combine/async |

### What Is Modified vs What Is New

**Modified (stubs → real implementation):**

| File | Change |
|------|--------|
| `AuthorizationManager.swift` | Add `requestAuthorization(for: .individual)` call + deauthorization observer via `AuthorizationCenter.shared.$authorizationStatus` |
| `ActivityScheduler.swift` | Implement `DeviceActivityCenter().startMonitoring` with `DeviceActivitySchedule` and `DeviceActivityEvent` threshold |
| `ShieldManager.swift` | Implement `ManagedSettingsStore().shield.applications = tokens` with `FamilyActivitySelection.applicationTokens` |
| `PolicyRepository.swift` | Implement real UserDefaults read/write for `EscalationLevel` + consent gate in `recordBypassEvent` |
| `ConsentStore.swift` | Implement `save(_:)`, `loadCurrent()`, `revoke()` with `UserDefaults(suiteName:)` |
| `FeedView.swift` | Replace List stub with `WebFeedView` + session state binding |
| `DeviceActivityMonitorExtension.swift` | Wire real `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()` consent gate; implement `intervalDidStart`/`intervalDidEnd` shield apply/remove |
| `BypassEvent.swift` | Expand schema to add `appTokenHash`, `priorState`, `resultingState`, `cooldownStarted`, `policyEnforced`, `deauthorizationDetected` |
| `FallbackRouter.swift` | Implement URL scheme routing to native Instagram/TikTok apps |

**New (net-new code):**

| File/Target | What |
|-------------|------|
| `WebFeedView.swift` | `UIViewRepresentable` wrapping `WKWebView` with URL allowlist |
| `WebSessionCoordinator.swift` | `WKNavigationDelegate` + session timer; published `sessionElapsed` drives InterventionView |
| `OnboardingView.swift` | State machine: `.permissions` → `.consent` → `.limits` → `.done` |
| `DashboardView.swift` | Wraps `DeviceActivityReport` view with `DeviceActivityFilter` for today's usage |
| `DeviceActivityReport` extension target | `DeviceActivityReportExtension` conformer + `DeviceActivityReportScene` |
| `FamilyActivitySelectionStore.swift` | Persists `FamilyActivitySelection` to App Group for use by `ShieldManager` and `ActivityScheduler` |
| `PolicyStore/SelectedApps.swift` | Codable wrapper around `FamilyActivitySelection` token set stored in UserDefaults |

---

## Component Boundaries

### Component Diagram (v1.1)

```
┌──────────────────────────────────────────────────────────────────┐
│  Main App Process                                                  │
│                                                                    │
│  OnboardingView ──calls──▶ AuthorizationManager (ScreenTimeEngine) │
│                 ──calls──▶ ConsentStore (ConsentManager)           │
│                 ──calls──▶ FamilyActivityPicker (system sheet)     │
│                 ──writes─▶ FamilyActivitySelectionStore (PolicyStore)│
│                 ──calls──▶ ActivityScheduler (ScreenTimeEngine)    │
│                                                                    │
│  DashboardView ──embeds──▶ DeviceActivityReport view              │
│                            (renders from DeviceActivityReport ext) │
│                                                                    │
│  FeedView ──contains──▶ WebFeedView (WKWebView via UIViewRep)     │
│           ──reads──────▶ SessionState (@StateObject)               │
│           ──shows──────▶ InterventionView (when session expired)   │
│                                                                    │
│  WebSessionCoordinator (WKNavigationDelegate)                      │
│    - Allows only: instagram.com/*, tiktok.com/*                   │
│    - Timer: session elapsed → InterventionView trigger             │
│    - On limit: calls PolicyRepository.recordBypassEvent            │
└────────────────────────┬─────────────────────────────────────────┘
                         │ App Group: group.com.freesocial.app
          ───────────────┼──────────────────────────────
┌────────────────────────▼─────────────────────────────────────────┐
│  Shared UserDefaults (App Group)                                   │
│   - EscalationLevel (written by PolicyRepository)                 │
│   - ConsentRecord (written by ConsentStore)                       │
│   - FamilyActivitySelection tokens (written by SelectionStore)    │
│   - SessionQuota minutes per platform                             │
└────────────────────────┬─────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│  Extension Processes                                               │
│                                                                    │
│  DeviceActivityMonitor                                             │
│    intervalDidStart ──▶ ShieldManager.shieldApps(tokens)          │
│    intervalDidEnd   ──▶ ShieldManager.clearShields()              │
│    eventDidReachThreshold                                          │
│      ─▶ ConsentStore.loadCurrent() → guard consent                │
│      ─▶ PolicyRepository.recordBypassEvent(BypassEvent)           │
│                                                                    │
│  ShieldConfiguration                                              │
│    Reads App Group → returns ShieldConfiguration for display       │
│                                                                    │
│  ShieldAction                                                      │
│    Handles user tap on shield → routes to FallbackRouter          │
│                                                                    │
│  DeviceActivityReport (NEW 4th extension)                         │
│    Receives DeviceActivityFilter from main app                    │
│    Renders usage summary → embedded in DashboardView              │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow: Onboarding

```
OnboardingView.step = .permissions
  → AuthorizationManager.requestAuthorization()
    → AuthorizationCenter.shared.requestAuthorization(for: .individual)
    → Success → step = .consent

OnboardingView.step = .consent
  → User accepts disclosure strings (9 required from APP_REVIEW_PREFLIGHT)
  → ConsentStore(suiteName: AppGroup.suiteName).save(ConsentRecord(...))
  → step = .limits

OnboardingView.step = .limits
  → FamilyActivityPicker sheet presented
  → User selects Instagram, TikTok tokens
  → FamilyActivitySelectionStore persists to App Group
  → User sets daily session minutes per platform
  → ActivityScheduler.scheduleActivity sets DeviceActivitySchedule + events
  → step = .done

OnboardingView.step = .done
  → ContentView switches to TabView (Dashboard | Feed)
```

### Data Flow: WKWebView Session

```
FeedView appears
  → WebFeedView creates WKWebView with WebSessionCoordinator as navigationDelegate
  → Loads platform URL (instagram.com or tiktok.com)
  → WebSessionCoordinator starts session timer

Every navigation action:
  → decidePolicyForNavigationAction checks allowedHosts set
  → Out-of-bounds URL → decisionHandler(.cancel)
  → Allowed URL → decisionHandler(.allow)

Session timer reaches quota:
  → WebSessionCoordinator publishes sessionExpired = true
  → FeedView overlays InterventionView
  → WebFeedView WKWebView.loadHTMLString("") clears content
  → PolicyRepository.recordBypassEvent (if user bypasses intervention)

Cooldown expires:
  → InterventionView dismisses
  → FeedView reloads WebFeedView
```

### Data Flow: Screen Time Enforcement

```
ActivityScheduler.scheduleActivity(name:schedule:)
  → DeviceActivityCenter().startMonitoring(
       DeviceActivityName("freesocial.daily"),
       during: DeviceActivitySchedule(intervalStart:intervalEnd:repeats:),
       events: [
         DeviceActivityEvent.Name("threshold"): DeviceActivityEvent(
           applications: selectedTokens,
           threshold: DateComponents(minute: dailyLimit)
         )
       ]
     )

eventDidReachThreshold fires in DeviceActivityMonitor extension:
  → ConsentStore(suiteName:).loadCurrent() → guard not nil
  → PolicyRepository.recordBypassEvent(...)
  → ShieldManager.shieldApps(selectedTokens)
    → ManagedSettingsStore().shield.applications = applicationTokens

intervalDidEnd fires (daily reset):
  → ShieldManager.clearShields()
  → ManagedSettingsStore().shield.applications = nil
```

### Data Flow: Dashboard Reporting

```
DashboardView appears
  → DeviceActivityReport(
       context: .init(stringLiteral: "freesocial.summary"),
       filter: DeviceActivityFilter(
         segment: .daily(during: DateInterval(start:end:)),
         users: .all,
         devices: .main,
         applications: selectedTokens
       )
     )

System passes filter to DeviceActivityReport extension process:
  → Extension renders SwiftUI view with usage data
  → View is embedded back into DashboardView (sandboxed rendering)
  → No usage data crosses process boundary directly — privacy preserved
```

---

## Patterns to Follow

### Pattern 1: UIViewRepresentable for WKWebView

Wrap WKWebView in a `UIViewRepresentable`. Store the coordinator reference strongly to prevent delegate deallocation (a documented gotcha with UIViewRepresentable + WKNavigationDelegate).

```swift
// In ControlledClient package
public struct WebFeedView: UIViewRepresentable {
    let platform: SocialPlatform
    @Binding var sessionExpired: Bool

    public func makeCoordinator() -> WebSessionCoordinator {
        WebSessionCoordinator(platform: platform, sessionExpired: $sessionExpired)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        if !context.coordinator.hasLoaded {
            webView.load(URLRequest(url: platform.startURL))
            context.coordinator.hasLoaded = true
        }
    }
}
```

**Why:** `makeCoordinator()` is called before `makeUIView` — assigning `context.coordinator` as delegate keeps it alive. The coordinator owns the session timer. `@Binding var sessionExpired` communicates expiry back to `FeedView` without ControlledClient knowing about SwiftUI's view hierarchy.

### Pattern 2: URL Allowlist in WKNavigationDelegate

```swift
// In WebSessionCoordinator (WKNavigationDelegate)
let allowedHosts: Set<String> = ["www.instagram.com", "instagram.com",
                                  "www.tiktok.com", "tiktok.com"]

func webView(_ webView: WKWebView,
             decidePolicyFor action: WKNavigationAction,
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let host = action.request.url?.host,
          allowedHosts.contains(host) else {
        decisionHandler(.cancel)
        return
    }
    decisionHandler(.allow)
}
```

**Why:** This is the primary content-restriction surface for the controlled client. It enforces the finite-surface model at the navigation layer, not at the content layer, which avoids injection/script dependencies.

### Pattern 3: Onboarding State Machine via Enum

```swift
// In main app (not a package — needs @main access)
enum OnboardingStep {
    case permissions
    case consent
    case limits
    case done
}

@AppStorage("onboardingComplete") var onboardingComplete = false
@State var step: OnboardingStep = .permissions
```

**Why:** `@AppStorage` persists completion across launches without a separate persistence layer. The enum makes each step testable in isolation. Decouple step logic from view code by keeping transitions in a coordinator or view model, not in button actions.

### Pattern 4: AuthorizationCenter Status Publisher

```swift
// In AuthorizationManager (ScreenTimeEngine package)
#if canImport(FamilyControls)
import FamilyControls
import Combine

public final class AuthorizationManager: ObservableObject {
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined

    private var cancellables = Set<AnyCancellable>()

    public init() {
        AuthorizationCenter.shared.$authorizationStatus
            .receive(on: RunLoop.main)
            .assign(to: \.authorizationStatus, on: self)
            .store(in: &cancellables)
    }

    public func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}
#endif
```

**Why:** Publishing `authorizationStatus` via Combine lets the main app and `OnboardingView` reactively detect deauthorization without polling. This satisfies the deauthorization detection entry condition from the v1.0 audit.

### Pattern 5: DeviceActivityReport Extension

The report extension is a **fourth separate Xcode target** (beyond the three existing extensions). It conforms to `DeviceActivityReportExtension` and defines `DeviceActivityReportScene` implementations. The main app instantiates `DeviceActivityReport(context:filter:)` as a SwiftUI view — the system embeds the extension's rendered output.

**Critical constraint:** The extension process is sandboxed. It cannot make network requests or write to App Group. Data flows only inward from the system. Do not attempt to pass custom data into the extension via App Group — the filter is the only entry point.

```swift
// In DeviceActivityReport extension target (separate process)
@main struct ReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { activityReport in
            UsageSummaryView(report: activityReport)
        }
    }
}

// In DashboardView (main app)
DeviceActivityReport(
    .init("freesocial.summary"),
    filter: DeviceActivityFilter(
        segment: .daily(during: todayInterval),
        applications: storedSelection.applicationTokens
    )
)
```

### Pattern 6: Consent Gate in DeviceActivityMonitor

Replace the Phase 2 `let consentIsGranted: Bool = true` stub:

```swift
// Replace stub with real call
let consent = ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()
guard consent != nil else { return }
```

**Why:** `ConsentStore.init(suiteName:)` is the resolved architecture (2026-03-04). The extension process can access the shared UserDefaults container using the same App Group identifier. `AppGroup.suiteName` is imported from `PolicyStore` which `DeviceActivityMonitorExtension` already imports.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Storing WKNavigationDelegate in a Local Variable

**What goes wrong:** Assigning `webView.navigationDelegate = MyCoordinator()` inline creates a coordinator that immediately deallocates, because `WKWebView` holds a weak reference to its delegate.

**Why bad:** Silent failure — the web view loads content but navigation policy decisions are never called.

**Instead:** Use `UIViewRepresentable.makeCoordinator()` which the SwiftUI lifecycle retains for the view's lifetime.

### Anti-Pattern 2: Importing PolicyStore in ConsentManager

**What goes wrong:** Adding `import PolicyStore` to `ConsentManager/Package.swift` to access `AppGroup.suiteName`.

**Why bad:** Violates the established independence rule. Creates a diamond dependency risk as both ControlledClient and the new ConsentManager would then depend on PolicyStore, and future packages depending on ConsentManager would transitively pull in PolicyStore.

**Instead:** Inject `suiteName: String` via `ConsentStore.init(suiteName:)` — already the resolved architecture.

### Anti-Pattern 3: Calling DeviceActivityCenter from an Extension

**What goes wrong:** Calling `DeviceActivityCenter().startMonitoring()` from a `DeviceActivityMonitor` extension callback.

**Why bad:** `startMonitoring` is a main-app-only API. The extension cannot initiate new monitoring sessions — it only receives callbacks. Attempting this causes a silent no-op or crash.

**Instead:** Call `startMonitoring` exclusively from the main app process during onboarding setup and on foreground revalidation.

### Anti-Pattern 4: Using DeviceActivityReport for Custom Data Passthrough

**What goes wrong:** Writing arbitrary app data to App Group and reading it in the `DeviceActivityReportExtension` to display alongside usage data.

**Why bad:** The extension is severely sandboxed — it cannot read from App Group or make network calls. Only data from the `DeviceActivityFilter` flows in. Apple intentionally designed this privacy boundary.

**Instead:** For custom data alongside usage, render native SwiftUI views in `DashboardView` using App Group data, and place the `DeviceActivityReport` view only where you need the system-provided usage summary.

### Anti-Pattern 5: Using FamilyActivityPicker as a Sheet Inside a Sheet

**What goes wrong:** Presenting `FamilyActivityPicker` inside an already-presented sheet (e.g., inside an `OnboardingView` presented modally).

**Why bad:** Known UIKit-level bug: `FamilyActivityPicker` dismisses its parent sheet when it appears. Reported by multiple developers in 2025.

**Instead:** Present `FamilyActivityPicker` as a `.sheet` directly from a non-modal root view, or use `.fullScreenCover`, or restructure onboarding so the picker step is full-screen, not nested.

### Anti-Pattern 6: eventDidReachThreshold as the Sole Enforcement Trigger

**What goes wrong:** Relying exclusively on `eventDidReachThreshold` to apply shields.

**Why bad:** On iOS 26.2 (the target simulator runtime), `eventDidReachThreshold` fires incorrectly — immediately on session start, or intermittently when Screen Time reports 0 minutes (confirmed Apple Developer Forums thread FB18061981, FB21450954). This is an active OS bug.

**Instead:** Add a defensive revalidation pass on foreground (`scenePhase` transition to `.active`) that checks whether shields should be applied based on stored quota state, independent of the callback. Use `eventDidReachThreshold` as a trigger but not as the single source of truth. Emit a confidence: LOW annotation for any timing-dependent test that depends on threshold callbacks in simulator.

---

## Scalability Considerations

This is a single-user iOS app. The scalability concern is not concurrency at scale — it is extension process coordination and UserDefaults write conflicts.

| Concern | At v1.1 (simulator) | At v1.2 (real device) |
|---------|--------------------|-----------------------|
| App Group write contention | Low risk — one writer per domain | Same — each key has one owner |
| DeviceActivity threshold callback timing | HIGH RISK on iOS 26.2 (known OS bug) | May resolve in iOS 26.3+ |
| WKWebView memory under long sessions | Monitor — WKWebView is out-of-process | Same behavior on device |
| FamilyActivityPicker in sheet | HIGH RISK — known UIKit bug | Same behavior |
| onAuthorizationStatus change latency | <1s in practice | Same |

---

## Build Order for v1.1 (Suggested)

This order respects dependency boundaries and validates integration gates before adding complexity.

1. **PolicyStore impl** — `PolicyRepository` real read/write, `BypassEvent` schema expansion, `FamilyActivitySelectionStore`. No UI, no extensions. Foundation for everything else.

2. **ConsentStore impl** — `ConsentStore` real `save/loadCurrent/revoke`. Independent of PolicyStore impl order but must complete before DeviceActivityMonitor wiring.

3. **ScreenTimeEngine impl** — `AuthorizationManager` with deauth observer, `ActivityScheduler` real `startMonitoring`, `ShieldManager` real `shieldApps`. Depends on PolicyStore data types for token handling.

4. **DeviceActivityMonitor wiring** — Replace consent stub, implement `intervalDidStart`/`intervalDidEnd` shield apply/remove. Depends on ConsentStore and ShieldManager being real.

5. **ControlledClient: WebFeedView** — `WebFeedView` + `WebSessionCoordinator` (URL allowlist, session timer). `InterventionView` trigger wired into `FeedView`. Independent of Screen Time impl.

6. **Main app: Onboarding** — `OnboardingView` state machine. Calls AuthorizationManager, ConsentStore, FamilyActivityPicker, ActivityScheduler in sequence. Depends on steps 1-4.

7. **DeviceActivityReport extension** — New Xcode target. `DeviceActivityReportExtension` + usage summary view. `DashboardView` in main app. Depends on FamilyActivitySelectionStore having tokens.

8. **UAT stub → real assertion pass** — Replace all 9 `XCTSkip` stubs with real assertions. Depends on all implementation above.

---

## Integration Points: New vs Modified Summary

| Integration Point | Status | Package/Target | Notes |
|-------------------|--------|----------------|-------|
| `PolicyRepository` → UserDefaults | Modified | PolicyStore | Real read/write replaces stubs |
| `BypassEvent` schema | Modified | PolicyStore | 6 fields to add |
| `FamilyActivitySelectionStore` | New | PolicyStore | Persists picker tokens |
| `ConsentStore` → UserDefaults | Modified | ConsentManager | Real persistence |
| `AuthorizationManager` + deauth observer | Modified | ScreenTimeEngine | Add Combine publisher |
| `ActivityScheduler` → DeviceActivityCenter | Modified | ScreenTimeEngine | Real startMonitoring |
| `ShieldManager` → ManagedSettingsStore | Modified | ScreenTimeEngine | Real shield.applications |
| `WebFeedView` (WKWebView wrapper) | New | ControlledClient | UIViewRepresentable |
| `WebSessionCoordinator` (delegate + timer) | New | ControlledClient | WKNavigationDelegate |
| `FeedView` → WebFeedView + InterventionView | Modified | ControlledClient | Wire session boundary |
| `DeviceActivityMonitorExtension` consent gate | Modified | Extension target | Replace `true` stub |
| `DeviceActivityMonitorExtension` interval callbacks | Modified | Extension target | Implement shield apply/remove |
| `FallbackRouter` URL scheme routing | Modified | ControlledClient | Implement return `Bool` |
| `OnboardingView` state machine | New | Main app | 4 steps, @AppStorage flag |
| `DashboardView` + `DeviceActivityReport` | New | Main app + new extension | 4th extension target |
| `ContentView` → TabView (Dashboard/Feed) | Modified | Main app | Replace placeholder |

---

## Sources

- [DeviceActivityReport — Apple Developer Documentation](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport)
- [DeviceActivityReportExtension — Apple Developer Documentation](https://developer.apple.com/documentation/deviceactivity/deviceactivityreportextension)
- [DeviceActivityCenter — Apple Developer Documentation](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter)
- [AuthorizationCenter — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols/authorizationcenter)
- [requestAuthorization(for:) — Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:))
- [eventDidReachThreshold — Apple Developer Documentation](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor/eventdidreachthreshold(_:activity:))
- [iOS 26.2 DeviceActivityMonitor.eventDidReachThreshold bug — Apple Developer Forums](https://developer.apple.com/forums/thread/809410) — MEDIUM confidence (active forum thread, not official KB)
- [iOS 26.2 (23C55) DeviceActivity bug thread](https://developer.apple.com/forums/thread/811305) — MEDIUM confidence
- [WKWebView NavigationDelegate delegate lifetime — Hacking with Swift](https://www.hackingwithswift.com/articles/112/the-ultimate-guide-to-wkwebview) — HIGH confidence (authoritative community reference, consistent with Apple docs)
- [FamilyActivityPicker sheet-inside-sheet bug — riedel.wtf Screen Time API issues](https://riedel.wtf/state-of-the-screen-time-api-2024/) — MEDIUM confidence (community report, corroborated by multiple dev forum threads)
- [SwiftUI: Report Device Activity — Level Up Coding (Jan 2026)](https://levelup.gitconnected.com/swiftui-report-device-activity-graphically-visually-73f4d76f5039) — MEDIUM confidence (recent, independently corroborates Apple docs pattern)
- [Exploring WebView and WebPage in SwiftUI for iOS 26 — AppCoda](https://www.appcoda.com/swiftui-webview/) — LOW confidence (iOS 26 native WebView is beta; UIViewRepresentable approach is safer for v1.1)

### Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| WKWebView UIViewRepresentable pattern | HIGH | Stable, well-documented, v1.1 iOS 16+ minimum |
| FamilyControls auth flow | HIGH | Official Apple docs confirm API shape |
| DeviceActivity startMonitoring + events | HIGH | Official docs + multiple dev guides agree |
| DeviceActivityReport extension architecture | HIGH | Official docs + corroborated pattern |
| iOS 26.2 eventDidReachThreshold bug | MEDIUM | Multiple dev forum reports, no official Apple KB yet |
| FamilyActivityPicker sheet-inside-sheet bug | MEDIUM | Community-reported, not in official changelogs |
| Native SwiftUI WebView (iOS 26+) | LOW | Still beta; UIViewRepresentable is the safe v1.1 choice |
