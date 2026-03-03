---
phase: 02-ios-implementation-scaffolding
plan: "02"
subsystem: ios

tags: [swift, xcode, screentime, familycontrols, deviceactivity, managedsettings, appextension, ios16]

requires:
  - phase: 02-ios-implementation-scaffolding
    plan: "01"
    provides: FreeSocial.xcodeproj with host app target, PolicyStore SPM package with PolicyRepository/BypassEvent/AppGroup, project.pbxproj hand-written with XCLocalSwiftPackageReference

provides:
  - DeviceActivityMonitor extension target (com.freesocial.app.DeviceActivityMonitor) with DeviceActivityMonitor subclass stub
  - ShieldConfiguration extension target (com.freesocial.app.ShieldConfiguration) with ShieldConfigurationDataSource subclass using UIKit struct API
  - ShieldAction extension target (com.freesocial.app.ShieldAction) with ShieldActionDelegate subclass stub
  - All three extensions embedded in host app's Embed Foundation Extensions build phase
  - Each extension has separate entitlements file with family-controls and group.com.freesocial.app
  - eventDidReachThreshold calls PolicyStore.recordBypassEvent in DeviceActivityMonitor stub

affects:
  - 02-03-PLAN (consent UI builds on ConsentManager; not directly affected)
  - 02-04-PLAN (test scaffolding will target extension source files)
  - Phase 3+ enforcement implementation fills in extension stubs

tech-stack:
  added:
    - DeviceActivity framework (imported in DeviceActivityMonitorExtension)
    - ManagedSettings framework (imported in all three extensions)
    - ManagedSettingsUI framework (imported in ShieldConfigurationExtension)
    - UIKit (imported in ShieldConfigurationExtension only; isolated from other extensions)
  patterns:
    - Extension targets as separately signed bundles (productType = com.apple.product-type.app-extension)
    - PBXCopyFilesBuildPhase with dstSubfolderSpec = 13 for Embed Foundation Extensions
    - PBXTargetDependency from host app to each extension ensures build order
    - XCSwiftPackageProductDependency per-target for PolicyStore (DAM and SA extensions share package ref)
    - UIKit isolated to ShieldConfiguration only; DeviceActivityMonitor and ShieldAction import zero UIKit

key-files:
  created:
    - ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift
    - ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements
    - ios/Extensions/DeviceActivityMonitor/Info.plist
    - ios/Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift
    - ios/Extensions/ShieldConfiguration/ShieldConfiguration.entitlements
    - ios/Extensions/ShieldConfiguration/Info.plist
    - ios/Extensions/ShieldAction/ShieldActionExtension.swift
    - ios/Extensions/ShieldAction/ShieldAction.entitlements
    - ios/Extensions/ShieldAction/Info.plist
  modified:
    - ios/FreeSocial.xcodeproj/project.pbxproj

key-decisions:
  - "Hand-wrote extension targets into project.pbxproj (same approach as Plan 01) — no Tuist or XcodeGen, ensures reproducibility without tooling dependencies"
  - "ShieldConfiguration extension uses UIKit struct API only — no SwiftUI, no UIHostingController — per research constraint (ManagedSettingsUI is UIKit-backed)"
  - "All three extension entitlements files carry identical family-controls + group.com.freesocial.app entries — consistent with host app FreeSocial.entitlements"
  - "NSExtensionPointIdentifier values used: com.apple.deviceactivity.monitor-extension, com.apple.ManagedSettings.shield-configuration, com.apple.ManagedSettings.shield-action-service"
  - "xcodebuild BUILD SUCCEEDED cannot be run (Xcode.app not installed); all static structural verifications pass as documented in Issues Encountered"

patterns-established:
  - "Extension entitlements mirror host app entitlements exactly: family-controls + group.com.freesocial.app — never diverge"
  - "UIKit import boundary: only ShieldConfiguration extension imports UIKit; DAM and ShieldAction are UIKit-free"
  - "PolicyStore is the only inter-extension dependency; ShieldConfiguration is fully self-contained"
  - "Extension bundle IDs follow com.freesocial.app.[ExtensionName] convention"

requirements-completed:
  - NB-01
  - NB-02
  - NB-03

duration: 3min
completed: 2026-03-03
---

# Phase 2 Plan 02: App Extension Targets Summary

**Three Screen Time app extension targets (DeviceActivityMonitor, ShieldConfiguration, ShieldAction) with correct NSExtensionPointIdentifiers, separate entitlements files carrying family-controls capability, and PolicyStore SPM linkage — all embedded in host app via Embed Foundation Extensions build phase**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-03T17:08:20Z
- **Completed:** 2026-03-03T17:11:47Z
- **Tasks:** 2
- **Files modified:** 10 (9 created + project.pbxproj rewritten)

## Accomplishments

- Added `DeviceActivityMonitorExtension` subclassing `DeviceActivityMonitor` with `intervalDidStart`, `intervalDidEnd`, and `eventDidReachThreshold` stubs; the threshold callback creates a `BypassEvent` and calls `PolicyRepository.recordBypassEvent` — establishing the Policy -> Event -> Escalation chain
- Added `ShieldConfigurationExtension` subclassing `ShieldConfigurationDataSource` using UIKit struct API only (UIColor, UIImage, ShieldConfiguration.Label) — consistent with research constraint that ManagedSettingsUI is UIKit-backed and cannot use SwiftUI views
- Added `ShieldActionExtension` subclassing `ShieldActionDelegate` with stub `handle(action:for:completionHandler:)` methods completing with `.close` — ready for Phase 3 unlock request flow

## Task Commits

Each task was committed atomically:

1. **Task 1: Create DeviceActivityMonitor extension target** - `336c07f` (feat)
2. **Task 2: Create ShieldConfiguration and ShieldAction extension targets** - `1e37dc0` (feat)

**Plan metadata:** (docs commit created after summary)

## Files Created

- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` - DeviceActivityMonitor subclass importing PolicyStore; eventDidReachThreshold calls recordBypassEvent
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements` - com.apple.developer.family-controls + group.com.freesocial.app
- `ios/Extensions/DeviceActivityMonitor/Info.plist` - NSExtensionPointIdentifier: com.apple.deviceactivity.monitor-extension
- `ios/Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift` - ShieldConfigurationDataSource subclass with UIKit-only API; FreeSocial-branded shield UI
- `ios/Extensions/ShieldConfiguration/ShieldConfiguration.entitlements` - com.apple.developer.family-controls + group.com.freesocial.app
- `ios/Extensions/ShieldConfiguration/Info.plist` - NSExtensionPointIdentifier: com.apple.ManagedSettings.shield-configuration
- `ios/Extensions/ShieldAction/ShieldActionExtension.swift` - ShieldActionDelegate subclass with stub handlers returning .close
- `ios/Extensions/ShieldAction/ShieldAction.entitlements` - com.apple.developer.family-controls + group.com.freesocial.app
- `ios/Extensions/ShieldAction/Info.plist` - NSExtensionPointIdentifier: com.apple.ManagedSettings.shield-action-service

## Files Modified

- `ios/FreeSocial.xcodeproj/project.pbxproj` - Added three extension targets, PBXCopyFilesBuildPhase (Embed Foundation Extensions), PBXTargetDependency entries, build configurations, and XCSwiftPackageProductDependency references for PolicyStore per extension

## Decisions Made

- Wrote extension targets directly into `project.pbxproj` by hand, continuing the approach from Plan 02-01 (no Tuist or XcodeGen).
- ShieldConfiguration extension uses UIKit struct API only. The `ShieldConfiguration(backgroundBlurStyle:backgroundColor:icon:title:...)` initializer takes `UIColor`, `UIImage`, and `ShieldConfiguration.Label` — no UIHostingController pattern allowed per research constraint.
- App Group identifier `group.com.freesocial.app` appears in all four entitlements files (host app + 3 extensions) — verified identical across all by structural check.
- PolicyStore is linked to DeviceActivityMonitor and ShieldAction extension targets via separate `XCSwiftPackageProductDependency` entries pointing to the same `XCLocalSwiftPackageReference`. ShieldConfiguration extension does not need PolicyStore.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**xcodebuild verification not runnable in this environment.** Same constraint as Plan 02-01: `xcodebuild` requires Xcode.app (not installed, only CLT). Static structural verifications run instead:

1. App Group consistency — all four entitlements files show `group.com.freesocial.app` identically — PASS
2. NSExtensionPointIdentifier values — three distinct identifiers confirmed in three Info.plist files — PASS
3. Embed Foundation Extensions — all three .appex targets present in PBXCopyFilesBuildPhase — PASS
4. UIKit isolation — no `import UIKit` in DeviceActivityMonitor or ShieldAction extensions — PASS
5. ShieldConfigurationDataSource subclass confirmed — PASS
6. ShieldActionDelegate subclass confirmed — PASS
7. PolicyStore import and recordBypassEvent call in DeviceActivityMonitorExtension.swift — PASS

The `xcodebuild BUILD SUCCEEDED` check must be run when Xcode.app is available (or in CI with a macOS runner).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Extension target structure is locked. Bundle IDs, entitlement structure, NSExtensionPointIdentifier values, and SPM linkage are established and should not be changed without updating provisioning profiles.
- Phase 3 implementation will replace stub bodies in all three extension principal classes.
- The `eventDidReachThreshold` -> `recordBypassEvent` chain is the critical enforcement path; Phase 3 must implement the full escalation logic here.
- ShieldConfiguration extension is ready for Phase 3 to add dynamic configuration based on current escalation level from PolicyStore.

## Self-Check: PASSED

Files verified to exist:
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` — FOUND
- `ios/Extensions/DeviceActivityMonitor/DeviceActivityMonitor.entitlements` — FOUND
- `ios/Extensions/DeviceActivityMonitor/Info.plist` — FOUND
- `ios/Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift` — FOUND
- `ios/Extensions/ShieldConfiguration/ShieldConfiguration.entitlements` — FOUND
- `ios/Extensions/ShieldConfiguration/Info.plist` — FOUND
- `ios/Extensions/ShieldAction/ShieldActionExtension.swift` — FOUND
- `ios/Extensions/ShieldAction/ShieldAction.entitlements` — FOUND
- `ios/Extensions/ShieldAction/Info.plist` — FOUND

Commits verified to exist:
- `336c07f` — FOUND (Task 1: DeviceActivityMonitor extension)
- `1e37dc0` — FOUND (Task 2: ShieldConfiguration and ShieldAction extensions)

---
*Phase: 02-ios-implementation-scaffolding*
*Completed: 2026-03-03*
