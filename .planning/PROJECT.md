# FreeSocial

## What This Is

FreeSocial is an iOS product focused on reducing addictive social scrolling while preserving practical communication use. The product combines a controlled social client experience with strict native-app gating so users can avoid infinite-feed loops.

## Core Value

Users can stay connected without being pulled into compulsive feed consumption.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Controlled client path with feed-level restrictions
- [ ] Native app blocking/gating to prevent bypass
- [ ] Consumer App Store-compatible first release

### Out of Scope

- Android launch in v1 — defer until iOS architecture is proven
- Full Instagram/TikTok feature parity — constrained by third-party APIs/terms

## Context

User requires strict feature-level control and is willing to use a controlled client model if native app internals cannot be modified. Prior research indicates iOS public APIs cannot directly alter internal UI surfaces in third-party native apps.

## Constraints

- **Platform**: iOS public API + App Store policies — required for distribution
- **Legal/Platform Terms**: Third-party social APIs/terms constrain replacement-client scope
- **Enforcement**: Must reduce bypass paths, not just add passive reminders

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Option 1 (Controlled Client + Native Blocking) is planning target | Maximizes enforceability within iOS constraints | — Pending |
| Consumer App Store path is primary | Required market model | — Pending |

---
*Last updated: 2026-03-03 after initial phase planning setup*
