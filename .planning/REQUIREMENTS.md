# Requirements: FreeSocial

**Defined:** 2026-03-03
**Core Value:** Users can stay connected without being pulled into compulsive feed consumption.

## v1 Requirements

### Controlled Client

- [x] **CC-01**: User can access a controlled social client experience that omits or blocks infinite-feed surfaces
- [x] **CC-02**: User can access essential communication pathways available to the controlled client
- [x] **CC-03**: User sees explicit reasoned interventions when attempting blocked feed behaviors

### Native Blocking and Anti-Bypass

- [x] **NB-01**: User can configure Instagram/TikTok native app restrictions through iOS-supported controls
- [x] **NB-02**: Native app access is restricted by schedules/quotas/cooldowns to reduce bypass
- [x] **NB-03**: System records bypass attempts and enforces escalation policy

### Policy, Safety, and Trust

- [ ] **POL-01**: App behavior and claims are precise and App Review-safe
- [x] **POL-02**: Privacy posture is explicit, minimal, and user-consented
- [ ] **POL-03**: UX clearly communicates limitations (what is and is not enforceable)

## v2 Requirements

### Expansion

- **EXP-01**: Supervised-device/guardian-managed strict mode
- **EXP-02**: Android parity

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full native Instagram DM + reels-granular control in same native app | Not supported by iOS public API model |
| Private API or undocumented entitlement approaches | High rejection/compliance risk |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CC-01 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| CC-02 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| CC-03 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| NB-01 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| NB-02 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| NB-03 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| POL-01 | Phase 2 | Planned (02-03 preflight) |
| POL-02 | Phase 1-2 | Scaffolded (Phase 2, Plan 02-01) |
| POL-03 | Phase 2 | Planned (02-03 preflight) |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-03*
*Last updated: 2026-03-03 after phase-2 plan-01 execution (iOS scaffolding)*
