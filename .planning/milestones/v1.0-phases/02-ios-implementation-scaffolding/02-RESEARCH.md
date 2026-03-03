# Phase 2: iOS Implementation Scaffolding - Research

**Researched:** 2026-03-03
**Domain:** iOS / Swift Package Manager / Screen Time API / XCTest scaffolding
**Confidence:** HIGH (core SPM and Screen Time patterns); MEDIUM (extension NSExtensionPointIdentifier specifics)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Swift Package Manager-first structure: each major module is a local SPM package
- Single Xcode project (`ios/FreeSocial.xcodeproj`) orchestrates packages and app target
- No third-party project generators (Tuist, XcodeGen) — keep tooling minimal
- SwiftUI throughout — all screens, interventions, onboarding, and settings
- No UIKit unless a specific Screen Time API forces it (DeviceActivity/ShieldConfiguration views may require UIViewController wrappers — Claude's discretion)
- Dark theme as the default and primary visual mode
- Clean, minimalist aesthetic — generous whitespace, no decorative chrome
- Restrained typography and iconography — nothing competes with content
- Skeleton views should feel like the real thing visually, even if they're just placeholder layouts
- Separate local SPM packages per module boundary:
  - `ControlledClient` — finite feed, intervention UX, fallback router
  - `ScreenTimeEngine` — FamilyControls, ManagedSettings, DeviceActivity wrappers
  - `PolicyStore` — App Group state, escalation levels, cooldown counters
  - `ConsentManager` — consent capture, revocation, audit log
- Host app target imports packages; extensions link only what they need
- Skeleton stubs both Instagram and TikTok providers behind a generic `SocialProvider` protocol
- XCTest unit tests per package (named by scenario e.g. `testCooldownEscalatesAfterRepeatedBypass`)
- Stub one XCUITest target — no actual UI tests in Phase 2
- UAT scenarios from `01-04-uat-plan.md` mapped to named `XCTestCase` stubs (failing/skipped)
- Assemble App Review preflight from Phase 1 artifacts into `APP_REVIEW_PREFLIGHT.md`

### Claude's Discretion
- Exact folder layout within each SPM package
- Specific SwiftUI view names and file organization within `ControlledClient`
- UIViewController wrapper approach for Screen Time extension views if needed
- CI/build script setup (can be added later)

### Deferred Ideas (OUT OF SCOPE)
- CI/CD pipeline setup — future phase
- Supervised-device / MDM strict mode — v2
- Android — out of scope for v1
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CC-01 | User can access a controlled social client experience that omits/blocks infinite-feed surfaces | ControlledClient skeleton with SocialProvider protocol and finite-feed boundary stub |
| CC-02 | User can access essential communication pathways available to the controlled client | SocialProvider protocol's communication pathway stub; fallback router skeleton |
| CC-03 | User sees explicit reasoned interventions when attempted blocked feed behaviors | InterventionView placeholder in ControlledClient; XCTest stub for testCooldownEscalatesAfterRepeatedBypass |
| NB-01 | User can configure Instagram/TikTok restrictions through iOS-supported controls | ScreenTimeEngine skeleton wrapping FamilyControls token selection |
| NB-02 | Native app access restricted by schedules/quotas/cooldowns | PolicyStore escalation state skeleton; DeviceActivityMonitor extension stub |
| NB-03 | System records bypass attempts and enforces escalation policy | PolicyStore bypass counter skeleton; XCTest stub for telemetry scenarios |
| POL-01 | App behavior and claims are precise and App Review-safe | APP_REVIEW_PREFLIGHT.md assembled from Phase 1 artifacts |
| POL-02 | Privacy posture is explicit, minimal, and user-consented | ConsentManager skeleton with consent/revocation/audit-log stubs |
| POL-03 | UX clearly communicates limitations | Limitation disclosure views in ControlledClient and onboarding stubs |
</phase_requirements>

---

## Summary

Phase 2 creates the physical project foundation that all future implementation phases will build on. The core challenge is not writing logic — it is establishing correct structural boundaries so that nothing needs to be re-architected later: local SPM packages with right-sized dependency graphs, three App Extension targets wired to the correct NSExtensionPointIdentifiers, an App Group shared container that every relevant target can access, and a test target per package with named-but-skipped stubs that make every UAT scenario trackable from day one.

The Screen Time stack (FamilyControls + ManagedSettings + DeviceActivity) imposes the most non-obvious constraints. Every App Extension that uses these frameworks must declare the `com.apple.developer.family-controls` entitlement independently — not just the host app. The App Group identifier must appear in every extension's entitlements file identically, or SharedUserDefaults between PolicyStore and extensions will silently fail. The `ScreenTimeEngine` local SPM package can wrap these system frameworks safely since it does not need to be its own signed bundle, but the extensions that embed it must individually carry the entitlements.

Dark-first SwiftUI is straightforward: apply `.preferredColorScheme(.dark)` at the root `WindowGroup` scene modifier, define semantic colors in `Assets.xcassets` Color Sets with Dark appearance only (no Light variant in v1), and use `Color.primary`/`Color.secondary` for text to stay semantic. Skeleton views that look like the real thing require only a dark background color, proper spacing, and placeholder shapes — no production logic.

**Primary recommendation:** Build the Xcode project and all SPM packages first (Wave 1), then wire entitlements and extension targets (Wave 2), then create test targets and UAT stubs (Wave 3), then assemble the preflight doc (Wave 4). Do not attempt extensions before the SPM graph is stable or the `Package.swift` minimum deployment target mismatch will block compilation.

---

## Standard Stack

### Core
| Library / Framework | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| Swift | 5.9+ (Xcode 15+) | Language | Current stable; async/await support needed for API calls |
| SwiftUI | iOS 16+ | All UI surfaces | Locked decision; minimizes boilerplate for skeleton views |
| XCTest | Xcode-bundled | Unit and UITest stubs | Apple-native, no extra dependency, XCTSkip API is stable |
| Swift Package Manager | Xcode-integrated | Local module management | Locked decision; no Tuist/XcodeGen |
| FamilyControls | iOS 16+ | Authorization for Screen Time controls | Only public API for app/domain selection tokens |
| ManagedSettings | iOS 15+, needed ≥16 for FamilyControls | Shield enforcement | Only public API for programmatic app shielding |
| DeviceActivity | iOS 15+, practical ≥16 | Schedule/threshold callbacks | Only public API for time-window enforcement |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation / UserDefaults (App Group suite) | iOS 16+ | PolicyStore cross-target persistence | Shared container between host and extensions; upgrade to Core Data in later phase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local SPM packages | Single monolithic target | Monolith: faster to set up, impossible to enforce dependency boundaries |
| Local SPM packages | Tuist/XcodeGen | Generators: consistent at scale but locked-out per CONTEXT.md |
| XCTest | Swift Testing (Xcode 16) | Swift Testing is newer and less boilerplate, but XCTest is required for XCUITest target; mixing is allowed but adds complexity for a skeleton phase |
| UserDefaults App Group | Core Data + shared container | Core Data is correct long-term but overkill for scaffold |

**Installation:** No `npm install` equivalent. Frameworks are system-provided. Local packages are created via `File → New → Swift Package` in Xcode and dragged/added to the project, then linked in each target's "Frameworks, Libraries, and Embedded Content."

---

## Architecture Patterns

### Recommended Project Structure

```
ios/
├── FreeSocial.xcodeproj/
├── FreeSocial/                         # Host app target sources
│   ├── FreeSocialApp.swift             # @main, WindowGroup, dark scheme
│   ├── ContentView.swift               # Root router shell
│   ├── Assets.xcassets/                # Color sets (Dark only in v1)
│   └── FreeSocial.entitlements         # com.apple.developer.family-controls + App Groups
├── Packages/                           # Local SPM packages (sibling to .xcodeproj)
│   ├── ControlledClient/
│   │   ├── Package.swift
│   │   └── Sources/ControlledClient/
│   │       ├── SocialProvider.swift    # Protocol definition
│   │       ├── InstagramProvider.swift # Stub conformance
│   │       ├── TikTokProvider.swift    # Stub conformance
│   │       ├── FeedView.swift          # Skeleton SwiftUI view
│   │       ├── InterventionView.swift  # Skeleton intervention UI
│   │       └── FallbackRouter.swift    # Skeleton handoff router
│   ├── ScreenTimeEngine/
│   │   ├── Package.swift
│   │   └── Sources/ScreenTimeEngine/
│   │       ├── AuthorizationManager.swift  # FamilyControls.AuthorizationCenter wrapper stub
│   │       ├── ShieldManager.swift         # ManagedSettings store stub
│   │       └── ActivityScheduler.swift     # DeviceActivity schedule stub
│   ├── PolicyStore/
│   │   ├── Package.swift
│   │   └── Sources/PolicyStore/
│   │       ├── PolicyState.swift       # Escalation enum (Baseline/Cooldown1/Cooldown2/Lockdown)
│   │       ├── PolicyRepository.swift  # App Group UserDefaults read/write stub
│   │       └── BypassEvent.swift       # Telemetry event value type stub
│   └── ConsentManager/
│       ├── Package.swift
│       └── Sources/ConsentManager/
│           ├── ConsentRecord.swift     # Value type for consent state
│           ├── ConsentStore.swift      # Persistence stub
│           └── AuditLog.swift          # Append-only log stub
├── Extensions/
│   ├── DeviceActivityMonitor/
│   │   ├── DeviceActivityMonitorExtension.swift   # Subclass DeviceActivityMonitor
│   │   └── DeviceActivityMonitor.entitlements     # family-controls + App Groups
│   ├── ShieldConfiguration/
│   │   ├── ShieldConfigurationExtension.swift     # Subclass ShieldConfigurationDataSource
│   │   └── ShieldConfiguration.entitlements       # family-controls + App Groups
│   └── ShieldAction/
│       ├── ShieldActionExtension.swift            # Subclass ShieldActionDelegate
│       └── ShieldAction.entitlements              # family-controls + App Groups
└── Tests/                              # XCUITest bundle target (stub only)
    └── FreeSocialUITests/
        └── FreeSocialUITests.swift     # Empty XCUITestCase class, no tests yet
```

> Each `Packages/*/Sources/*/` directory also gets a `Tests/` folder co-located in the package for XCTest unit test targets.

### Pattern 1: Local SPM Package with Deployment Target

Each `Package.swift` must declare `platforms` at iOS 16 or higher to match the host app and avoid "package minimum deployment target higher than consumer" errors.

```swift
// Source: https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html
// Example: Packages/PolicyStore/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PolicyStore",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "PolicyStore", targets: ["PolicyStore"])
    ],
    targets: [
        .target(
            name: "PolicyStore",
            path: "Sources/PolicyStore"
        ),
        .testTarget(
            name: "PolicyStoreTests",
            dependencies: ["PolicyStore"],
            path: "Tests/PolicyStoreTests"
        )
    ]
)
```

Inter-package dependency (ScreenTimeEngine imports nothing from other local packages at scaffold stage; ControlledClient will import PolicyStore when business logic is added):

```swift
// ControlledClient/Package.swift — declaring dependency on PolicyStore
dependencies: [
    .package(path: "../PolicyStore")
],
targets: [
    .target(name: "ControlledClient", dependencies: ["PolicyStore"])
]
```

### Pattern 2: Extension Target Configuration

All three extension targets are added via `File → New → Target` in Xcode (not in SPM). Each extension is a separate signed bundle.

**DeviceActivityMonitor extension:**
- Principal class must subclass `DeviceActivityMonitor`
- `NSExtensionPointIdentifier` in Info.plist: `com.apple.deviceactivity.monitor-extension`
- Frameworks to link: `DeviceActivity`, `ManagedSettings`
- Entitlements required: `com.apple.developer.family-controls`, `com.apple.security.application-groups`
- Must be embedded in host app's "Embed Foundation Extensions" build phase

**ShieldConfiguration extension:**
- Principal class must subclass `ShieldConfigurationDataSource`
- `NSExtensionPointIdentifier`: `com.apple.ManagedSettings.shield-configuration`
- Frameworks: `ManagedSettings`, `ManagedSettingsUI`
- Entitlements: `com.apple.developer.family-controls`, `com.apple.security.application-groups`

**ShieldAction extension:**
- Principal class must subclass `ShieldActionDelegate`
- `NSExtensionPointIdentifier`: `com.apple.ManagedSettings.shield-action-service`
- Frameworks: `ManagedSettings`
- Entitlements: `com.apple.developer.family-controls`, `com.apple.security.application-groups`

### Pattern 3: App Group Shared Container

The App Group identifier format is: `group.<reverse-domain>.<app-name>` — e.g., `group.com.freesocial.app`.

This identifier must be:
1. Registered in the Apple Developer Portal under App Groups
2. Added to every target that needs cross-process reads/writes: host app, DeviceActivityMonitor, ShieldAction

PolicyStore uses this to read/write escalation state and cooldown counters across extension boundaries:

```swift
// Source: Apple Developer Forums (multiple), community consensus
// Packages/PolicyStore/Sources/PolicyStore/PolicyRepository.swift

public struct PolicyRepository {
    static let suiteName = "group.com.freesocial.app"
    private let defaults: UserDefaults

    public init() {
        // Failable in tests; fail gracefully to .standard
        self.defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
    }

    // MARK: - Stub placeholder methods
    public func currentEscalationLevel() -> EscalationLevel { .baseline }
    public func recordBypassEvent(_ event: BypassEvent) { /* stub */ }
    public func resetToBaseline() { /* stub */ }
}
```

### Pattern 4: Dark-First SwiftUI Root

Force dark scheme at the scene level; do not rely on system setting:

```swift
// Source: Apple Developer Documentation - ColorScheme, community pattern
// FreeSocial/FreeSocialApp.swift
import SwiftUI

@main
struct FreeSocialApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
```

Semantic color palette in `Assets.xcassets`: create a Color Set named `Background` with only a Dark Appearance value (e.g., `#0A0A0A`). Reference as `Color("Background")` in views. Use `Color.primary` / `Color.secondary` for text — these invert automatically but will read as near-white on a dark canvas.

### Pattern 5: XCTest UAT Stub

Use `XCTSkip` to mark UAT stubs as tracked-but-pending. Each test class maps to one UAT requirement. The scenario name in the test method name creates a live audit trail.

```swift
// Source: Apple Developer Documentation - XCTSkip, Methods for Skipping Tests
// Packages/PolicyStore/Tests/PolicyStoreTests/EscalationPolicyTests.swift
import XCTest
@testable import PolicyStore

final class EscalationPolicyTests: XCTestCase {
    // UAT: NB-02 — Escalation states transition correctly after repeated bypass
    func testCooldownEscalatesAfterRepeatedBypass() throws {
        throw XCTSkip("UAT stub: NB-02 — implement when PolicyStore logic is complete")
    }

    // UAT: NB-03 — Bypass telemetry events generated with correct state linkage
    func testBypassTelemetryEventRecordedWithEscalationState() throws {
        throw XCTSkip("UAT stub: NB-03 — implement when telemetry recording is wired")
    }
}
```

### Pattern 6: SocialProvider Protocol Stub

```swift
// Packages/ControlledClient/Sources/ControlledClient/SocialProvider.swift
import Foundation

/// Protocol defining the minimal surface any social provider must expose.
/// Concrete providers (InstagramProvider, TikTokProvider) stub-conform in Phase 2.
public protocol SocialProvider {
    var name: String { get }
    /// Finite batch of content items — never unbounded.
    func fetchBatch(after cursor: String?) async throws -> ContentBatch
    /// Communication pathways this provider supports via its OAuth scopes.
    var supportedPathways: [CommunicationPathway] { get }
}

public struct ContentBatch {
    public let items: [ContentItem]
    public let nextCursor: String?
    public init(items: [ContentItem], nextCursor: String?) {
        self.items = items; self.nextCursor = nextCursor
    }
}

public struct ContentItem: Identifiable {
    public let id: String
    public let body: String
    public init(id: String, body: String) { self.id = id; self.body = body }
}

public enum CommunicationPathway { case directMessage, story, comment }
```

### Anti-Patterns to Avoid

- **Monolith first, modularize later:** Do not start with a single target and plan to extract later. Extract now — the SPM boundaries are the deliverable of this phase.
- **Extensions importing ControlledClient:** Extensions (ShieldAction, DeviceActivityMonitor) must not import ControlledClient — they only need ScreenTimeEngine and PolicyStore. Over-linked extensions bloat the bundle and risk App Review rejection for claiming unneeded capabilities.
- **Hardcoded App Group string:** Define `group.com.freesocial.app` in exactly one place (e.g., a `Constants.swift` in PolicyStore or a shared `AppGroup.swift`) and import that constant everywhere. String drift between targets causes silent data isolation bugs.
- **ShieldConfigurationDataSource producing SwiftUI views directly:** The ShieldConfiguration extension uses `UIKit`-backed `ShieldConfiguration` struct (title, icon, primaryButtonLabel). It is not a SwiftUI view host. Do not attempt to return a `UIHostingController` from ShieldConfigurationDataSource — use the provided struct API only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| App shielding | Custom overlay or process-kill | `ManagedSettings.ManagedSettingsStore` | Apple's store is the only permitted blocking mechanism; custom overlays are rejected by App Review |
| App selection token UI | Custom app-picker | `FamilyActivityPicker` (SwiftUI) | Required token type; no public API to construct `ApplicationToken` values manually |
| Activity schedule callbacks | Background timer | `DeviceActivityMonitor` extension | Only extension receives the OS-managed callbacks; timers in main app are not reliable for enforcement |
| Cross-extension data | NSXPCConnection / Distributed Notifications | App Group `UserDefaults` / shared container | XPC between third-party app extensions is not supported; App Groups is the intended mechanism |
| Test skips | `continueAfterFailure = false` + empty body | `throw XCTSkip("reason")` | XCTSkip marks the test as *skipped* (yellow) not *failed* (red) — makes UAT tracking visible in Xcode |

**Key insight:** Every "enforcement" mechanism that feels like it could be custom-built has a specific Apple API that is the only valid path. Deviating from any of them causes App Review rejection, not just runtime failure.

---

## Common Pitfalls

### Pitfall 1: Entitlement Not Applied to Extension Targets
**What goes wrong:** Host app has `com.apple.developer.family-controls` but extensions do not. FamilyControls calls succeed in the host app but `DeviceActivitySchedule` callbacks never fire, and shields cannot be set from the extension.
**Why it happens:** Developers assume the host app entitlement propagates to embedded extensions. It does not — each target has its own entitlements file and its own provisioning profile.
**How to avoid:** Create a separate `.entitlements` file for each extension target (DeviceActivityMonitor, ShieldConfiguration, ShieldAction). Apply `com.apple.developer.family-controls` and `com.apple.security.application-groups` to each. Apply separately for the entitlement in the Apple Developer Portal for each App ID.
**Warning signs:** Extension builds successfully but DeviceActivity callbacks are never received at runtime; ManagedSettingsStore operations appear to succeed but shields never appear.

### Pitfall 2: App Group Identifier Mismatch Between Targets
**What goes wrong:** PolicyStore reads an empty/default state even though the host app wrote data. Escalation counters reset on every launch.
**Why it happens:** App Group identifier has a typo or differs between the host app and extension entitlements files. `UserDefaults(suiteName:)` silently falls back to `.standard` (process-local) when the group is not found.
**How to avoid:** Define the App Group string constant in one place. Verify it matches identically in: host app entitlements, each extension entitlements, and the Apple Developer Portal App Group registration.
**Warning signs:** `UserDefaults(suiteName: "group.com.freesocial.app")` returns non-nil (it always does even if the group doesn't exist at runtime), but data written in one process is not visible in another.

### Pitfall 3: SPM Deployment Target Below Extension Minimum
**What goes wrong:** Extension target (iOS 16.0) imports a local SPM package whose `Package.swift` declares `platforms: [.iOS(.v15)]`. Xcode warns or fails to resolve the package for the extension target.
**Why it happens:** SPM packages must declare a minimum deployment target equal to or lower than the consumer, but the effective minimum for FamilyControls/Screen Time is iOS 16. If the package declares `.v15`, it will build but may expose unavailable APIs without compile-time guards.
**How to avoid:** Set `platforms: [.iOS(.v16)]` in every `Package.swift` in this project. This matches the host app and all extension targets.
**Warning signs:** "Unsupported Swift platform" or deprecation warnings about iOS 15-era APIs in extension builds.

### Pitfall 4: ShieldConfiguration Extension Not Embedded in Host
**What goes wrong:** App compiles and runs but shielded apps show the default iOS lock screen instead of the custom shield.
**Why it happens:** ShieldConfiguration and ShieldAction extensions must be in the host app's "Embed Foundation Extensions" build phase. Forgetting to add them there means they are not bundled.
**How to avoid:** After creating each extension target, verify it appears in the host app target's Build Phases → Embed Foundation Extensions list. This is not done automatically.
**Warning signs:** Custom shield UI never appears at runtime; no crash — just falls back to system default silently.

### Pitfall 5: FamilyActivityPicker Cannot Be Used in a SPM Package Without Entitlement at Build Time
**What goes wrong:** `ScreenTimeEngine` package imports `FamilyControls` and references `FamilyActivityPicker`. The package builds fine, but the app crashes at runtime with an authorization error if the entitlement is missing at the provisioning level — even with the capability added in Xcode.
**Why it happens:** `FamilyControls` requires the entitlement to be granted by Apple (not just claimed in Xcode). In development without the approved entitlement, the API behaves as if unauthorized.
**How to avoid:** Apply for the `com.apple.developer.family-controls` entitlement from Apple's developer portal before writing any FamilyControls code. In the scaffolding phase, stub `AuthorizationManager` without calling `AuthorizationCenter.shared.requestAuthorization()` — call it only when the entitlement is granted.
**Warning signs:** Authorization request throws immediately; `AuthorizationStatus` is `.notDetermined` and never advances.

### Pitfall 6: SocialProvider Conformances in Same Module as Protocol
**What goes wrong:** `InstagramProvider` and `TikTokProvider` defined in `ControlledClient` module — if the module ever splits, the concrete types must move and callers break.
**How to avoid:** Protocols live in `ControlledClient`; stub conformances live in `ControlledClient` for Phase 2 (acceptable for scaffold). Document that concrete providers will be extracted to `InstagramClient` / `TikTokClient` packages in a future phase.
**Warning signs:** Not a compile-time error — a design debt marker.

---

## Code Examples

Verified patterns from official sources and community consensus:

### DeviceActivityMonitor Extension Skeleton

```swift
// Source: Apple Developer Documentation - DeviceActivityMonitor
// Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift
import DeviceActivity
import ManagedSettings
import PolicyStore  // Link this package to the extension target

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        // Stub: apply baseline shields via PolicyStore
        super.intervalDidStart(for: activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Stub: remove or adjust shields
        super.intervalDidEnd(for: activity)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        // Stub: record bypass event; escalate policy
        super.eventDidReachThreshold(event, activity: activity)
    }
}
```

### ShieldConfiguration Extension Skeleton

```swift
// Source: Apple Developer Documentation - ShieldConfigurationDataSource
// Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift
import ManagedSettings
import ManagedSettingsUI
import UIKit

// ShieldConfiguration is UIKit-backed — no SwiftUI here
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "eye.slash"),
            title: ShieldConfiguration.Label(
                text: "FreeSocial", color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is restricted", color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK", color: .white
            ),
            primaryButtonBackgroundColor: .systemIndigo
        )
    }
}
```

### XCTest UAT Stub Pattern

```swift
// Source: Apple Developer Documentation - XCTSkip
// All 9 UAT scenarios mapped; example shows CC and NB requirements
import XCTest
@testable import ControlledClient

final class ControlledClientUATStubs: XCTestCase {

    // CC-01: User consumes finite batches with no infinite scroll
    func testFiniteBatchBoundaryInterruptsScrolling() throws {
        throw XCTSkip("UAT stub: CC-01 — pending FeedView implementation")
    }

    // CC-02: Supported communication pathway works; unsupported falls back
    func testUnsupportedPathwayFallsBackCleanly() throws {
        throw XCTSkip("UAT stub: CC-02 — pending SocialProvider pathway matrix")
    }

    // CC-03: Blocked feed attempts show intervention and cooldown messaging
    func testBlockedFeedShowsInterventionWithCooldown() throws {
        throw XCTSkip("UAT stub: CC-03 — pending InterventionView implementation")
    }
}
```

### Full UAT→XCTestCase Mapping (9 Requirements)

| Requirement | XCTestCase class | Method name | Host package |
|-------------|-----------------|-------------|--------------|
| CC-01 | ControlledClientUATStubs | testFiniteBatchBoundaryInterruptsScrolling | ControlledClientTests |
| CC-02 | ControlledClientUATStubs | testUnsupportedPathwayFallsBackCleanly | ControlledClientTests |
| CC-03 | ControlledClientUATStubs | testBlockedFeedShowsInterventionWithCooldown | ControlledClientTests |
| NB-01 | ScreenTimeEngineUATStubs | testNativeAppRestrictionConfiguredViaTokenSelection | ScreenTimeEngineTests |
| NB-02 | PolicyStoreUATStubs | testEscalationStatesTransitionCorrectlyAfterRepeatedBypass | PolicyStoreTests |
| NB-03 | PolicyStoreUATStubs | testBypassTelemetryEventRecordedWithEscalationState | PolicyStoreTests |
| POL-01 | AppReviewPreflightTests | testPublicClaimsMatchCapabilityMatrix | FreeSocialTests (host) |
| POL-02 | ConsentManagerUATStubs | testConsentCaptureAndWithdrawalWork | ConsentManagerTests |
| POL-03 | ControlledClientUATStubs | testLimitationDisclosuresVisibleInOnboardingAndBlockedState | ControlledClientTests |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSUserDefaults for cross-extension state | App Group UserDefaults suite (`suiteName:`) | iOS 8 (stable) | Still the correct lightweight approach; Core Data over App Group container is the upgrade path |
| UIKit ViewControllers for all UI | SwiftUI with `preferredColorScheme` | iOS 14+ stable | Extensions (ShieldConfiguration, ShieldAction) are still UIKit-principal-class APIs — the shield UI struct is not a SwiftUI view host |
| Single fat target app | Local SPM packages per module | Xcode 11+ (stable) | The project creation pattern via `File → New → Swift Package` is the current recommended Apple approach |
| XCTest for all test types | XCTest (unit) + Swift Testing (unit, Xcode 16+) | Xcode 16 / 2024 | Swift Testing cannot yet drive XCUITest targets; XCTest remains required for UITest bundles. Both can coexist in the same project |

**Deprecated/outdated:**
- `DeviceActivityReport` extension: a fourth extension type for usage dashboards — not needed in Phase 2 but exists as an extension point. Do not create it in this phase.
- `FamilyControls.AuthorizationCenter.shared.requestAuthorization(completionHandler:)` callback form: the async/await form `requestAuthorization()` is current for Swift Concurrency. Use the async form.

---

## Open Questions

1. **FamilyControls entitlement approval timing**
   - What we know: Apple requires a portal application for `com.apple.developer.family-controls` before any FamilyControls code works on device. Simulator does not require the entitlement.
   - What's unclear: Whether scaffolding compilation without the approved entitlement on a real device will allow testing the non-FamilyControls paths (PolicyStore, ControlledClient, ConsentManager).
   - Recommendation: Scaffold with stub guards (`#if DEBUG`) so that ScreenTimeEngine can be imported without triggering authorization requests. Submit the entitlement application before Phase 3 (implementation) begins.

2. **ShieldConfigurationDataSource — UIKit only or SwiftUI possible?**
   - What we know: The `ShieldConfiguration` struct API is UIKit-based. Multiple developer forum threads (MEDIUM confidence) report that you cannot embed a SwiftUI view directly in a ShieldConfiguration extension.
   - What's unclear: Whether `UIHostingController` wrapping inside the extension principal class is feasible (Claude's discretion per CONTEXT.md).
   - Recommendation: Implement ShieldConfigurationExtension using the UIKit struct API as documented. Research UIHostingController viability in Phase 3 when the actual shield design is needed.

3. **Local package resolution in CI (future)**
   - What we know: CI/CD is deferred per CONTEXT.md.
   - What's unclear: Whether Xcode Cloud or GitHub Actions can resolve local (path-based) packages without a workspace-level `Package.swift`.
   - Recommendation: Document that a workspace file (`FreeSocial.xcworkspace`) embedding the project and the `Packages/` directory is the standard pattern Apple recommends; this will matter when CI is set up.

---

## Validation Architecture

> `workflow.nyquist_validation` status: `.planning/config.json` does not exist in this project. Treating validation architecture as applicable given the UAT→XCTest mapping is a core deliverable of this phase.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode-bundled, current) |
| Config file | None — standard Xcode test targets embedded in project |
| Quick run command | `xcodebuild test -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing FreeSocialTests` |
| Full suite command | `xcodebuild test -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 16'` |

> Note: No build toolchain is committed yet. Commands above will be valid once the Xcode project exists. All tests in Phase 2 will `XCTSkip` — the suite will pass with 9 skipped tests, 0 failures.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command (future) | File Exists? |
|--------|----------|-----------|---------------------------|-------------|
| CC-01 | Finite batch boundary interrupts scroll | unit (stub) | ControlledClientTests | Wave 0 |
| CC-02 | Unsupported pathway falls back cleanly | unit (stub) | ControlledClientTests | Wave 0 |
| CC-03 | Blocked feed shows intervention + cooldown | unit (stub) | ControlledClientTests | Wave 0 |
| NB-01 | App restriction configured via token selection | unit (stub) | ScreenTimeEngineTests | Wave 0 |
| NB-02 | Escalation transitions correctly after bypass | unit (stub) | PolicyStoreTests | Wave 0 |
| NB-03 | Bypass telemetry event has correct state linkage | unit (stub) | PolicyStoreTests | Wave 0 |
| POL-01 | Public claims match capability matrix | manual + doc | FreeSocialTests | Wave 0 |
| POL-02 | Consent capture and withdrawal work | unit (stub) | ConsentManagerTests | Wave 0 |
| POL-03 | Limitation disclosures visible in onboarding/blocked | unit (stub) | ControlledClientTests | Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme FreeSocial` (compile check only — no logic yet)
- **Per wave merge:** Full test suite (expect 9 skipped, 0 failed)
- **Phase gate:** Zero build errors, zero test failures (skipped is acceptable), `APP_REVIEW_PREFLIGHT.md` assembled

### Wave 0 Gaps
- [ ] `Packages/ControlledClient/Tests/ControlledClientTests/ControlledClientUATStubs.swift` — CC-01, CC-02, CC-03, POL-03
- [ ] `Packages/ScreenTimeEngine/Tests/ScreenTimeEngineTests/ScreenTimeEngineUATStubs.swift` — NB-01
- [ ] `Packages/PolicyStore/Tests/PolicyStoreTests/PolicyStoreUATStubs.swift` — NB-02, NB-03
- [ ] `Packages/ConsentManager/Tests/ConsentManagerTests/ConsentManagerUATStubs.swift` — POL-02
- [ ] `FreeSocial/Tests/FreeSocialTests/AppReviewPreflightTests.swift` — POL-01 (doc reference test)
- [ ] `Tests/FreeSocialUITests/FreeSocialUITests.swift` — XCUITest stub target class (empty)
- [ ] All `Package.swift` files — one per local package
- [ ] `ios/FreeSocial.xcodeproj` — project file itself (this is the Wave 1 deliverable)

---

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation — DeviceActivityMonitor](https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor)
- [Apple Developer Documentation — ManagedSettings](https://developer.apple.com/documentation/managedsettings)
- [Apple Developer Documentation — FamilyControls](https://developer.apple.com/documentation/familycontrols)
- [Apple Developer Documentation — XCTSkip](https://developer.apple.com/documentation/xctest/xctskip-swift.struct) — skip pattern for UAT stubs
- [Apple Developer Documentation — Methods for Skipping Tests](https://developer.apple.com/documentation/xctest/methods-for-skipping-tests)
- [Apple Developer Documentation — Swift Packages](https://developer.apple.com/documentation/xcode/swift-packages)
- [Apple Developer Documentation — Organizing your code with local packages](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages)
- [Swift Package Manager PackageDescription docs](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html) — `platforms:` parameter
- Phase 1 artifacts (canonical for this project): `01-architecture-baseline.md`, `01-03-native-blocking-architecture.md`, `01-02-controlled-client-spec.md`, `01-03-escalation-policy.md`

### Secondary (MEDIUM confidence)
- [Apple Developer Forums — NSExtensionPointIdentifier for Device Activity](https://developer.apple.com/forums/thread/681963) — NSExtensionPointIdentifier values for extensions
- [Apple Developer Forums — Shield Action Extension](https://developer.apple.com/forums/thread/814945) — `com.apple.ManagedSettings.shield-action-service` confirmed
- [pedroesli.com — Screen Time API](http://pedroesli.com/2023-11-13-screen-time-api/) — App Groups format, three extension targets pattern
- [Apple Developer Documentation — Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement) — portal application requirement
- [Apple Developer Documentation — Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)

### Tertiary (LOW confidence, flag for validation)
- NSExtensionPointIdentifier value for ShieldConfiguration (`com.apple.ManagedSettings.shield-configuration`) — inferred from template naming convention and forum references; validate against Xcode's extension template when creating the target
- UIHostingController feasibility inside ShieldConfigurationDataSource — multiple forum posts suggest it does not work cleanly; needs hands-on validation in Phase 3

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Apple frameworks are the only option; SPM is locked decision
- Architecture patterns: HIGH for project structure and App Group patterns; MEDIUM for exact NSExtensionPointIdentifier values
- Pitfalls: HIGH — all documented from verified community/Apple forum sources
- Test patterns: HIGH — XCTSkip is documented Apple API

**Research date:** 2026-03-03
**Valid until:** 2026-06-03 (Screen Time API is stable; SPM local package pattern is stable; check Xcode release notes for any extension template changes)
