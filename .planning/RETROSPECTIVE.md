# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.0 — Foundation

**Shipped:** 2026-03-03
**Phases:** 2 | **Plans:** 8 | **Sessions:** 1 day

### What Was Built

- Architecture and compliance baseline: controlled client spec, App Review claims matrix, native blocking design with Screen Time API, escalation policy (4 states), and consent/revocation contract
- iOS implementation scaffold: Xcode project + 4 SPM packages (ControlledClient, ScreenTimeEngine, PolicyStore, ConsentManager) + 3 Screen Time app extensions
- App Review preflight package: single assembled document with 8 claims, 7 stop-ship conditions, 11 required disclosure strings, POL-01/02/03 traceability
- UAT test harness: 9 XCTest stubs (one per v1 requirement) + active AppReviewPreflightTests gate as living audit trail

### What Worked

- Phase 1 planning-first approach made Phase 2 execution fast — architecture decisions were pre-made, no ambiguity when writing code
- Hand-writing project.pbxproj gave complete control and reproducibility without Tuist/XcodeGen tooling dependencies
- Milestone-audit before complete-milestone caught the ConsentManager AppGroup gap before it became a Phase 3 surprise
- APP_REVIEW_PREFLIGHT.md as a single assembled document (not cross-references to multiple Phase 1 artifacts) made it immediately usable as a submission checklist

### What Was Inefficient

- Xcode.app not installed on dev machine created a persistent block on runtime verification — every plan had to document BUILD SUCCEEDED as a human-gated item; should configure CI earlier
- ROADMAP.md plan checkboxes for Phase 2 plans 02-02, 02-03, 02-04 were not updated during execution, creating a tracking inconsistency (gsd-tools disk_status correctly showed complete via SUMMARY.md presence, but ROADMAP.md showed unchecked boxes)
- ConsentManager AppGroup access was left unresolved — should have been identified and decided in Phase 2 rather than deferred; it's a design gap that blocks POL-02 implementation

### Patterns Established

- `project.pbxproj` hand-written approach (no tooling) — consistent across Phase 2 plans, should continue into Phase 3
- `AppGroup.suiteName` single source of truth — grep verified across all Swift files; maintain this invariant
- `#if canImport(FamilyControls)` guard pattern — prevents CI failures in non-Xcode environments
- XCTSkip UAT stubs as requirement traceability — each requirement ID maps to a named test method from day one
- APP_REVIEW_PREFLIGHT.md as pre-submission gate — all 7 stop-ship conditions must pass before any submission action

### Key Lessons

1. **Architecture-first pays off quickly.** Having Phase 1 artifacts (controlled-client-spec, escalation-policy, capability-claims-matrix) as fully resolved inputs to Phase 2 made module design decisions fast and conflict-free. Do this every milestone.
2. **Scaffold gaps are fine; undocumented gaps are not.** All Phase 2 stubs were intentional and documented in SUMMARY.md and VERIFICATION.md. The milestone audit confirmed each gap was a known Phase 3 entry condition, not a forgotten requirement.
3. **Set up CI before Phase 3.** The xcodebuild BUILD SUCCEEDED gate was human-gated throughout all of Phase 2 because Xcode.app was not installed. Phase 3 implementation cannot proceed safely without a CI build gate.
4. **Resolve package architecture decisions before implementation.** The ConsentManager AppGroup access pattern is an inter-package dependency decision that should have been made in Phase 2. It blocks POL-02 end-to-end implementation.

### Cost Observations

- Model: claude-sonnet-4-6 (single model throughout)
- Sessions: 1 day, 2 phases executed sequentially
- Notable: Planning phase (Phase 1) was faster than implementation scaffold (Phase 2) — architecture documents are cheaper to produce than compilable code

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 1 day | 2 | Initial — planning-first approach established |

### Cumulative Quality

| Milestone | Tests | Coverage | Notes |
|-----------|-------|----------|-------|
| v1.0 | 9 UAT stubs + 1 active | N/A (stubs) | All requirements traceable from test navigator |

### Top Lessons (Verified Across Milestones)

1. Architecture-first planning makes implementation faster.
2. Document every scaffold gap explicitly — undocumented gaps are the dangerous ones.
