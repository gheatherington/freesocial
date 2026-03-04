# Phase 3: Data Layer Foundations - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the concrete persistence logic for all data layer stubs — ConsentStore, PolicyRepository, AuditLog, and DeviceActivityMonitor consent gate — and create FamilyActivitySelectionStore from scratch. This is pure infrastructure; nothing visible to the user, but all downstream phases (4–7) depend on it being correct and testable.

</domain>

<decisions>
## Implementation Decisions

### FamilyActivitySelectionStore placement
- Lives in the `PolicyStore` package alongside PolicyRepository, BypassEvent, EscalationLevel, and AppGroup
- All UserDefaults-backed persistence is co-located in PolicyStore — consistent model
- ControlledClient may import PolicyStore per module rules; ScreenTimeEngine and ConsentManager stay independent
- Pattern: `FamilyActivitySelectionStore` backed by App Group UserDefaults via JSONEncoder (same as PolicyRepository)

### Revocation semantics
- `loadCurrent()` returns the most recent `ConsentRecord` even if it is revoked — it does NOT return nil on revocation
- `nil` means "never consented"; a revoked record means "consented then revoked" — these must be distinguishable for audit purposes
- Callers check `loadCurrent()?.isRevoked == false` to determine if consent is currently active
- Update the DeviceActivityMonitor TODO stub accordingly: check `isRevoked` flag, not nil-ness
- `revoke()` sets `isRevoked = true` and `revokedAt = Date()` on the current record, then persists it

### AuditLog storage
- UserDefaults with an encoded array of `AuditEntry` objects (JSONEncoder) — consistent with ConsentStore and PolicyRepository
- File-based append (as the stub comment suggests) would require NSFileCoordinator for cross-process safety — out of scope for this phase
- Key: a namespaced string in App Group UserDefaults (e.g., `"com.freesocial.auditLog"`)
- `append()` reads the current array, appends the new entry, re-encodes, and writes back

### BypassEvent schema
- Keep as-is: `id`, `occurredAt`, `escalationLevelAtTime`
- "Phase 1 telemetry spec" is not defined in the codebase — nothing to expand against
- Escalation progression is deferred to v1.2; no new fields are needed now
- If expansion is needed, it will surface in Phase 7 UAT pass when assertions are written

### Claude's Discretion
- JSONEncoder/Decoder key strategy (defaulting to property names)
- UserDefaults key naming conventions (namespaced strings under `com.freesocial.*`)
- In-memory fallback behavior when App Group is unavailable (assertionFailure + .standard already established)
- Test injection pattern for macOS `swift test` (App Group unavailable → `.standard` fallback, test encoding/decoding logic only)

</decisions>

<specifics>
## Specific Ideas

No specific references from discussion — all decisions are at Claude's discretion.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ConsentStore.init(suiteName:)`: UserDefaults init pattern with assertionFailure guard — replicate in FamilyActivitySelectionStore
- `PolicyRepository.init()`: same assertionFailure + .standard fallback — same pattern
- `ConsentRecord`: already `Codable, Identifiable` — ready for JSONEncoder persistence
- `BypassEvent`: already `Codable` — ready for JSONEncoder persistence
- `EscalationLevel`: already `Codable, RawRepresentable` — can be stored as raw string or encoded

### Established Patterns
- App Group UserDefaults via `UserDefaults(suiteName:)` — project-wide pattern for shared state
- `assertionFailure` + `.standard` fallback when App Group unavailable — used in both PolicyRepository and ConsentStore
- `AppGroup.suiteName` defined only in `PolicyStore/Sources/PolicyStore/AppGroup.swift` — never hardcode
- JSONEncoder for `Codable` persistence — roadmap success criteria explicitly calls this out for PolicyRepository

### Integration Points
- `DeviceActivityMonitorExtension.eventDidReachThreshold`: replace `let consentIsGranted: Bool = true` with `ConsentStore(suiteName: AppGroup.suiteName).loadCurrent()?.isRevoked == false`
- `PolicyRepository.recordBypassEvent`: implement JSONEncoder persistence to App Group UserDefaults
- `PolicyRepository.currentEscalationLevel`: read persisted EscalationLevel (or return .baseline if none)
- Phase 6 will call `FamilyActivitySelectionStore` to persist the FamilyActivityPicker selection
- Phase 4 `ActivityScheduler` will read from `FamilyActivitySelectionStore` to know which tokens to schedule

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-data-layer-foundations*
*Context gathered: 2026-03-04*
