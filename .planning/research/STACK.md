# Technology Stack

**Project:** FreeSocial v1.1 Implementation
**Researched:** 2026-03-04
**Scope:** New capabilities only — does not re-document the existing v1.0 stack

---

## What Is Already In Place (Do Not Change)

The following are validated in v1.0 and carry forward unchanged:

- Swift 5.9, SwiftUI, iOS 16.0 minimum deployment target
- 4 SPM packages: ControlledClient, ScreenTimeEngine, PolicyStore, ConsentManager
- 3 App extensions: DeviceActivityMonitor, ShieldConfiguration, ShieldAction
- System frameworks: FamilyControls, DeviceActivity, ManagedSettings, ManagedSettingsUI
- AppGroup: `group.com.freesocial.app` via `AppGroup.suiteName` (PolicyStore)
- project.pbxproj hand-written (no Tuist/XcodeGen)
- XCTest for unit and UAT testing

---

## New Capabilities Required for v1.1

### 1. WKWebView — Controlled Feed

**Framework:** WebKit (system, no SPM dependency)
**Import:** `import WebKit`
**Where:** `ControlledClient` package — `FeedView.swift` and new `WebFeedView.swift`

**Integration pattern:** `UIViewRepresentable` wrapping a `WKWebView` instance. There is no native SwiftUI WebView API at iOS 16.0 minimum; the native `WebView` (SwiftUI) introduced in WWDC 2025 requires iOS 26 as a minimum deployment target. Since the project targets iOS 16.0, `UIViewRepresentable` is the correct and only viable approach.

**Confidence:** HIGH — UIViewRepresentable for WKWebView is the documented, stable pattern for iOS 16.

**Key APIs used in implementation:**
- `WKWebViewConfiguration` — configure content rules, data store, user scripts
- `WKNavigationDelegate` — `webView(_:didFinish:)` for page-load events, used to start session timer
- `WKUserContentController` — inject JavaScript for scroll-depth telemetry or content suppression
- `WKContentRuleListStore.default().compileContentRuleList(forIdentifier:encodedContentRuleList:completionHandler:)` — compile JSON content-blocking rules (same engine as Safari Content Blocker) to suppress recommendations/autoplay
- `WKWebView.estimatedProgress` — KVO-observable for loading progress bar
- `WKWebView.load(URLRequest)` — initial page load

**Session timer:** A `Timer.scheduledTimer` (or `Task.sleep` loop in async context) started in `webView(_:didFinish:)`, cancelled on `InterventionView` appearance. No third-party dependency needed.

**Cookie / authentication:** Instagram and TikTok web sessions are cookie-based. WKWebView operates in a separate process from the app's `HTTPCookieStorage`. Use `WKWebsiteDataStore.default()` (persistent) so cookies survive app restarts. Do not attempt to programmatically inject cookies — let the user authenticate inside the web view on first launch, then persist the session via the data store. This avoids the ITP cross-origin cookie issues documented in WebKit bug tracker.

---

### 2. FamilyControls — Runtime Authorization Request

**Framework:** FamilyControls (system, already imported in ScreenTimeEngine)
**Where:** `ScreenTimeEngine` package — `AuthorizationManager.swift` (stub already written)

**API:** `AuthorizationCenter.shared.requestAuthorization(for: .individual)` — async/await, available iOS 16.0+. The older completion-handler variant `requestAuthorization(completionHandler:)` is deprecated in iOS 16.

**Confidence:** HIGH — confirmed from Apple documentation search results.

**Authorization type:** `.individual` — the user authorizes monitoring of their own device, not a child's device. This is the correct mode for a consumer self-regulation app. Using `.child` would require a second device in the family group and is not applicable here.

**Onboarding placement:** Authorization must be requested before any DeviceActivity monitoring can start. Request it on the first step of the onboarding flow, with a clear rationale screen before the system dialog appears.

**Error handling:** `AuthorizationCenter.authorizationStatus` is an `@Published` property on `AuthorizationCenter.shared`. Observe it with `.onChange` or `Combine` sink. States: `.approved`, `.denied`, `.notDetermined`. A `.denied` state requires the user to go to Settings — there is no programmatic recovery path. Add a deauthorization detection check in `AuthorizationManager` (Phase 3 entry condition from the audit).

**Entitlement note:** `com.apple.developer.family-controls` must be active in the provisioning profile. The `#if canImport(FamilyControls)` guard already in `AuthorizationManager.swift` prevents CI build failures when the entitlement is absent from the signing context.

---

### 3. FamilyActivityPicker — App Token Selection

**Framework:** FamilyControls (system, already imported)
**Where:** Onboarding flow in the main app target (not in ScreenTimeEngine package)

**API:** `.familyActivityPicker(isPresented:selection:)` — SwiftUI view modifier, available iOS 16.0+. Presents the system privacy-preserving picker. No custom UI needed.

**Selection storage:** The result is a `FamilyActivitySelection` struct. It must be stored in the App Group `UserDefaults` suite using `JSONEncoder` / `JSONDecoder` (both `FamilyActivitySelection` and `ApplicationToken` are `Codable`). Store it under a fixed key (e.g., `"freesocial.activitySelection"`). This stored selection is read by the `DeviceActivityMonitor` and `ShieldAction` extensions.

**Confidence:** HIGH — `FamilyActivitySelection` conforming to `Codable` for App Group persistence is the standard documented pattern.

**Known issue:** `ApplicationToken` values returned to extensions can differ from those stored by the main app in some OS versions. Mitigate by storing the full `FamilyActivitySelection` (not individual tokens) and always sourcing tokens from the stored selection when calling `ManagedSettingsStore`.

---

### 4. DeviceActivity — Schedule Setup and Threshold Monitoring

**Framework:** DeviceActivity (system, already imported in ScreenTimeEngine)
**Where:** `ScreenTimeEngine` package — `ActivityScheduler.swift` (stub already written)

**Key APIs:**
- `DeviceActivityCenter()` — entry point for start/stop monitoring
- `DeviceActivityName("freesocial.daily")` — string-keyed identifier for the schedule
- `DeviceActivitySchedule(intervalStart:intervalEnd:repeats:)` — daily window (e.g., midnight to midnight using `DateComponents`)
- `DeviceActivityEvent` — defines a threshold (e.g., `DateComponents(hour: 1)` for 1-hour daily limit) against a `FamilyActivitySelection`
- `DeviceActivityCenter.startMonitoring(_:during:events:)` — registers the schedule and events

**Threshold callback:** When the threshold is reached, the OS calls `eventDidReachThreshold(_:activity:)` on the `DeviceActivityMonitor` extension subclass. That extension then activates shielding via `ManagedSettingsStore`.

**Confidence:** HIGH — the stub in `ActivityScheduler.swift` already contains the correct future implementation comments matching these APIs.

**Named store coordination:** The `ManagedSettingsStore` name must match the `DeviceActivityName` for automatic settings enforcement to work. Use `ManagedSettingsStore(named: ManagedSettingsStore.Name("freesocial.daily"))` consistently in both the main app and the extension.

---

### 5. ManagedSettings — App Shielding

**Framework:** ManagedSettings (system, already imported in ScreenTimeEngine)
**Where:** `ScreenTimeEngine` package — `ShieldManager.swift` (stub already written); also called from `DeviceActivityMonitorExtension`

**Key API:** `ManagedSettingsStore().shield.applications = Set<ApplicationToken>`

**Token source:** Decoded from the stored `FamilyActivitySelection` (see section 3). Access via `selection.applications` which is `Set<ApplicationToken>`.

**Named store:** Starting in iOS 16, named `ManagedSettingsStore` instances are shared between the main app and all app extensions with the same App Group. The extension does not need to read from `UserDefaults` to get the token set — it can apply shielding directly through the named store, or read the persisted `FamilyActivitySelection` from App Group `UserDefaults`.

**Clearing the shield:** Call `ManagedSettingsStore().shield.applications = nil` (or an empty set). This happens when a new session starts (midnight reset by the DeviceActivitySchedule repeating) or when the user taps "Allow" in `ShieldAction`.

**Confidence:** HIGH — matches the stub comments and documented ManagedSettings API.

---

### 6. ShieldConfiguration — Custom Shield UI

**Framework:** ManagedSettingsUI (system, already imported in ShieldConfiguration extension)
**Where:** `ios/Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift` (skeleton exists)
**Constraint:** UIKit only — no SwiftUI in this extension. Already documented in CLAUDE.md and project.pbxproj.

**API:** Override `configuration(shielding application: Application, in context: ConfigurationContext) -> ShieldConfiguration`. Return a `ShieldConfiguration` struct specifying:
- `backgroundBlurStyle: UIBlurEffect.Style` — `.systemUltraThinMaterialDark` for dark-first theme
- `backgroundColor: UIColor` — match app dark background `UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)`
- `title: ShieldConfiguration.Label` — session limit message
- `subtitle: ShieldConfiguration.Label` — remaining reset time
- `primaryButtonLabel: ShieldConfiguration.Label` — "Open FreeSocial" (routes to main app via ShieldAction)
- `secondaryButtonLabel` — optional "Dismiss" for limited bypass acknowledgment

**Confidence:** HIGH — extension skeleton exists; UIKit-only constraint is already locked in.

---

### 7. DeviceActivityReport Extension — Usage Dashboard

**Framework:** DeviceActivity (system)
**New Xcode target required:** Device Activity Report Extension
**Where:** New extension target `DeviceActivityReportExtension` in the main Xcode project

**This is the one new Xcode target v1.1 needs beyond what exists in v1.0.**

**Setup:**
1. Add target: File > New > Target > iOS > Device Activity Report Extension. Embed in FreeSocial app.
2. Extension implements `DeviceActivityReportExtension` protocol with `body` property returning a `Scene` that conforms to `DeviceActivityReportScene`.
3. Define a `DeviceActivityReport.Context` (a `RawRepresentable` string type) to identify the view type — e.g., `extension DeviceActivityReport.Context { static let dailySummary = Self("dailySummary") }`.
4. In the main app dashboard view, embed `DeviceActivityReport(.dailySummary, filter: filter)` where `filter` is a `DeviceActivityFilter` specifying the date interval (today) and the `FamilyActivitySelection`.

**Data flow:** The extension receives aggregated usage data from the OS in a privacy-preserving way — the main app never sees raw app usage; it only sees the rendered SwiftUI view returned by the extension.

**Confidence:** MEDIUM — extension template and API are confirmed; the pbxproj hand-wiring for a new extension target will need care (follows the same pattern as the existing 3 extensions, but the DeviceActivityReport extension has different plist keys: `DeviceActivityReportExtensionCategories`).

**Info.plist keys required:**
- `NSExtension.NSExtensionPointIdentifier`: `com.apple.deviceactivity.report`
- `NSExtension.NSExtensionPrincipalClass`: `$(PRODUCT_MODULE_NAME).ReportExtension`
- Standard bundle keys (same set as existing extensions to avoid simulator install failures)

---

### 8. Onboarding UI — SwiftUI Patterns

**No new frameworks or SPM packages needed.**
**Where:** Main app target, new `Onboarding/` view group

**Pattern:** `TabView` with `.tabViewStyle(.page(indexDisplayMode: .always))` — the stable iOS 14+ paging carousel. Forward-only progression is enforced by only enabling the "Next" button (not free swiping) — this is implemented by disabling swipe with a custom `DragGesture` mask or by using a programmatic `selection` binding that only advances.

**State persistence:** `@AppStorage("onboarding.completed")` as a `Bool` to gate the onboarding gate on first launch. Set to `true` after the FamilyControls authorization step succeeds.

**Disclosure strings:** 9 limitation disclosure strings required (from the v1.0 audit). These are plain `Text` views with no special framework. They must appear before the FamilyControls authorization request.

**Confidence:** HIGH — TabView with PageTabViewStyle is the established iOS 16-compatible pattern. No external dependency warranted.

---

### 9. Consent Persistence — ConsentStore Implementation

**No new frameworks needed.** ConsentStore uses `UserDefaults` (App Group suite) with `JSONEncoder`/`JSONDecoder`.
**Where:** `ConsentManager` package — `ConsentStore.swift` (stub to be filled in)

**Pattern:**
```swift
// Save
let data = try JSONEncoder().encode(record)
defaults.set(data, forKey: "freesocial.consent.current")

// Load
guard let data = defaults.data(forKey: "freesocial.consent.current") else { return nil }
return try? JSONDecoder().decode(ConsentRecord.self, from: data)

// Revoke
var record = loadCurrent()
record?.revokedAt = Date()
// re-save
```

`ConsentRecord` already exists as a struct in `ConsentManager`. Add `Codable` conformance if not already present.

**Confidence:** HIGH — `JSONEncoder`/`JSONDecoder` + App Group `UserDefaults` is the canonical pattern for cross-extension data sharing on iOS.

---

## New SPM Dependencies: None

All capabilities needed for v1.1 are covered by:
- System frameworks already linked (WebKit, FamilyControls, DeviceActivity, ManagedSettings, ManagedSettingsUI)
- Swift standard library (`Foundation`, `Combine`)
- SwiftUI (already used throughout)

No third-party SPM packages are needed or recommended. Adding external dependencies would create App Store review surface, entitlement conflicts, or maintenance burden without benefit given that all required APIs exist in the system SDK.

---

## New Xcode Target: DeviceActivityReportExtension

This is the only structural addition to the Xcode project in v1.1.

| Property | Value |
|----------|-------|
| Target type | Device Activity Report Extension |
| Bundle ID | `com.freesocial.app.DeviceActivityReport` |
| Deployment target | iOS 16.0 |
| App Groups | `group.com.freesocial.app` (same as existing extensions) |
| Info.plist key | `NSExtensionPointIdentifier: com.apple.deviceactivity.report` |
| pbxproj pattern | Follow existing extension targets in `project.pbxproj` |
| Framework | DeviceActivity (already in project) |
| Note | Hand-wire in pbxproj; no Tuist/XcodeGen |

---

## API Versions Summary

| API | Framework | Available Since | Confidence |
|-----|-----------|-----------------|------------|
| `UIViewRepresentable` + `WKWebView` | WebKit + SwiftUI | iOS 13.0 | HIGH |
| `WKContentRuleListStore.compileContentRuleList` | WebKit | iOS 11.0 | HIGH |
| `AuthorizationCenter.shared.requestAuthorization(for: .individual)` | FamilyControls | iOS 16.0 | HIGH |
| `FamilyActivityPicker` (SwiftUI modifier) | FamilyControls | iOS 16.0 | HIGH |
| `FamilyActivitySelection` (Codable) | FamilyControls | iOS 15.0 | HIGH |
| `DeviceActivityCenter.startMonitoring(_:during:events:)` | DeviceActivity | iOS 15.0 | HIGH |
| `ManagedSettingsStore(named:).shield.applications` | ManagedSettings | iOS 16.0 | HIGH |
| `DeviceActivityReport` SwiftUI view | DeviceActivity | iOS 16.0 | MEDIUM |
| `DeviceActivityReportExtension` protocol | DeviceActivity | iOS 16.0 | MEDIUM |
| `ShieldConfigurationDataSource` override | ManagedSettingsUI | iOS 15.0 | HIGH |
| `TabView(.page)` onboarding | SwiftUI | iOS 14.0 | HIGH |
| `JSONEncoder` + App Group UserDefaults | Foundation | iOS 8.0 | HIGH |

---

## What Not To Add

| Candidate | Why Not |
|-----------|---------|
| `WebView` (SwiftUI native, iOS 26) | Requires iOS 26 minimum; breaks iOS 16 deployment target |
| `SFSafariViewController` | Cannot inject session timer, content rules, or intercept navigation |
| Any third-party web view library | No benefit over `UIViewRepresentable` + `WKWebView`; adds review risk |
| `Combine` publishers as new dependency | Already available as a system framework; no SPM package needed |
| `Charts` framework | Not needed; DeviceActivityReport extension provides the usage view |
| `SwiftData` | No complex relational data; UserDefaults is sufficient for all v1.1 persistence |
| Third-party analytics SDK | Out of scope; conflicts with data minimization consent obligations |

---

## Sources

- Apple Developer Documentation — [AuthorizationCenter](https://developer.apple.com/documentation/familycontrols/authorizationcenter), [requestAuthorization(for:)](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:))
- Apple Developer Documentation — [FamilyActivityPicker](https://developer.apple.com/documentation/familycontrols/familyactivitypicker), [familyActivityPicker modifier](https://developer.apple.com/documentation/swiftui/view/familyactivitypicker(ispresented:selection:))
- Apple Developer Documentation — [DeviceActivitySchedule](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule), [DeviceActivityCenter](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter)
- Apple Developer Documentation — [DeviceActivityReport](https://developer.apple.com/documentation/deviceactivity/deviceactivityreport), [DeviceActivityReportExtension](https://developer.apple.com/documentation/deviceactivity/deviceactivityreportextension)
- Apple Developer Documentation — [ShieldConfigurationDataSource.configuration(shielding:)](https://developer.apple.com/documentation/managedsettingsui/shieldconfigurationdatasource/configuration(shielding:)-5uqm1)
- Apple Developer Documentation — [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)
- WWDC22 — [What's New in Screen Time API](https://developer.apple.com/videos/play/wwdc2022/110336/) — iOS 16 named ManagedSettingsStore sharing, DeviceActivityReport extension
- WebSearch (MEDIUM confidence) — DeviceActivityReport extension target setup: [DeviceActivityReport extension setup article](https://letvar.medium.com/time-after-screen-time-part-2-the-device-activity-report-extension-10eeeb595fbd)
- WebSearch (MEDIUM confidence) — WKWebView UIViewRepresentable patterns: [swiftyplace.com](https://www.swiftyplace.com/blog/loading-a-web-view-in-swiftui-with-wkwebview)
- v1.0 planning artifacts — `.planning/milestones/v1.0-MILESTONE-AUDIT.md`, `.planning/PROJECT.md`
