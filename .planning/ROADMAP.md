# Roadmap: FreeSocial

## Overview

Build an iOS-first product that enforces reduced addictive social consumption through a controlled client plus strict native-app gating.

## Phases

- [x] **Phase 1: Controlled Client + Native Blocking** - Build and validate enforceable v1 architecture
- [ ] **Phase 2: iOS Implementation Scaffolding** - Stand up the iOS project with module skeletons, test harness, and App Review preflight package

## Phase Details

### Phase 1: Controlled Client + Native Blocking
**Goal:** Deliver a production-ready architecture and implementation plan for a controlled social client combined with strict native app blocking/gating, with clear App Store compliance strategy.
**Depends on:** Nothing (first phase)
**Requirements:** [CC-01, CC-02, CC-03, NB-01, NB-02, NB-03, POL-01, POL-02, POL-03]
**Success Criteria** (what must be TRUE):
  1. Controlled client approach is specified with explicit capability boundaries.
  2. Native blocking architecture and anti-bypass rules are fully defined with iOS-supported controls.
  3. Plan includes App Store risk controls and user-facing limitation disclosures.
  4. Implementation tasks are decomposed into executable plans with dependencies and verification criteria.
**Plans:** 4 plans

Plans:
- [x] 01-01: Architecture and legal/compliance baseline
- [x] 01-02: Controlled client product and technical design
- [x] 01-03: Native blocking enforcement and anti-bypass system
- [x] 01-04: Integration, telemetry, UAT, and launch readiness

### Phase 2: iOS Implementation Scaffolding
**Goal:** Initialize the iOS project with module boundaries from Phase 1, create skeleton implementations for the controlled client, Screen Time enforcement engine, and policy/consent state manager, convert UAT requirements into executable XCTest cases, and produce the App Review preflight package.
**Depends on:** Phase 1
**Requirements:** [CC-01, CC-02, CC-03, NB-01, NB-02, NB-03, POL-01, POL-02, POL-03]
**Success Criteria** (what must be TRUE):
  1. iOS project compiles and runs with all module boundaries established.
  2. Skeleton modules exist for: controlled client flow, Screen Time enforcement, policy/consent state.
  3. XCTest cases exist for every UAT requirement from 01-04-uat-plan.md.
  4. App Review preflight package is assembled (capability claims matrix, limitation disclosures, stop-ship checklist).
**Plans:** 2/4 plans executed

Plans:
- [x] 02-01-PLAN.md — Xcode project + four SPM package skeletons with module boundary stubs
- [ ] 02-02-PLAN.md — Three App Extension targets with entitlements and Screen Time base class stubs
- [ ] 02-03-PLAN.md — Assemble APP_REVIEW_PREFLIGHT.md from Phase 1 artifacts
- [ ] 02-04-PLAN.md — XCTest targets and all 9 UAT stubs (one per requirement CC-01 through POL-03)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Controlled Client + Native Blocking | 4/4 | Complete | 2026-03-03 |
| 2. iOS Implementation Scaffolding | 2/4 | In Progress|  |
