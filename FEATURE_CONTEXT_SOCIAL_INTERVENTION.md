# Phase X: Feature-Level Social Intervention - Context

**Gathered:** 2026-03-03
**Status:** Ready for research/planning

<domain>
## Phase Boundary

Explore viable ways to prevent doomscrolling behaviors (e.g., Instagram Reels / TikTok For You) while preserving useful communication behavior, under iOS platform constraints.

Goal is enforcement-first. If native-app feature-level control is impossible, evaluate replacement-client/wrapper paths and combined fallback controls.

</domain>

<decisions>
## Implementation Decisions

### Distribution model
- v1 must be consumer App Store compatible.
- Enterprise-only or supervised-device-only deployment is not the primary path.

### Enforcement priority
- Prioritize strongest enforceability over preserving exact native UX.
- If needed, allow a custom client/wrapper-style experience to gain control.

### Native-app coexistence requirement
- User still wants restrictions around primary native apps so users cannot trivially bypass controls.
- Preferred outcome is both: strong controls in native path + stronger controls in controlled client path.

### Feature-level intent
- Core target behavior is blocking specific feed surfaces (Reels/For You), while preserving messaging/utility behaviors where possible.

### Claude's Discretion
- Decide final architecture split (pure native-control vs hybrid controlled client + native gating).
- Decide sequencing for MVP vs later phases.

</decisions>

<specifics>
## Specific Ideas

- "Strictly block features such as reels while still allowing messages."
- "Could we make an app wrapper so we can directly interact with what the user is using?"
- "Also enforce whatever restrictions we can around the primary app so users can't just switch to it."

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No app code present yet in repository (research docs only).

### Established Patterns
- N/A (project scaffold not initialized with `.planning` or implementation files).

### Integration Points
- Current research baseline: `IOS_SOCIAL_SCROLL_INTERVENTION_RESEARCH.md`.

</code_context>

<deferred>
## Deferred Ideas

- Supervised-device / MDM-enhanced enforcement track as optional future phase.
- Cross-platform expansion (Android) where feature-level intervention may be more feasible.

</deferred>
