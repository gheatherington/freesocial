# Phase 1: Controlled Client + Native Blocking - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Design and plan a strict-enforcement iOS product path where users primarily use a controlled social client and are prevented from easy bypass via native Instagram/TikTok usage.

</domain>

<decisions>
## Implementation Decisions

### Distribution and model
- Consumer App Store path is required for v1.
- Enforcement strength is prioritized over preserving full native UX parity.

### Product strategy
- Controlled client path is allowed and preferred if it improves enforceability.
- Native Instagram/TikTok must still be restricted so users cannot trivially switch and bypass.

### Control objective
- Strictly block addictive feed behavior (Reels/For You-style consumption) in the user's daily flow.
- Preserve practical communication pathways where possible, with explicit disclosure where parity is not possible.

### Claude's Discretion
- Final decomposition into plans/waves and implementation task granularity.
- Exact anti-bypass escalation policy tuning.

</decisions>

<specifics>
## Specific Ideas

- User wants strict feature-level control and is open to wrapper/client approach.
- User still wants restrictions around native apps to prevent fallback bypass.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No application code exists yet.

### Established Patterns
- Planning/research-first workflow in use.

### Integration Points
- Prior research: IOS_SOCIAL_SCROLL_INTERVENTION_RESEARCH.md.

</code_context>

<deferred>
## Deferred Ideas

- Supervised-device / MDM-only strict mode as future expansion track.
- Android platform strategy after iOS model is proven.

</deferred>
