# Phase 5: WKWebView Controlled Feed - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the in-app controlled feed experience for Instagram and TikTok using WKWebView, including per-platform session countdown display, platform switching, and hard intervention handoff when a platform session expires. This phase clarifies feed behavior within the existing v1.1 scope; it does not add new social capabilities.

</domain>

<decisions>
## Implementation Decisions

### Session timing model
- Session countdown starts on first feed interaction, not on initial page visibility.
- Countdown pauses while the app is backgrounded or user is away from the feed.
- Session time is tracked separately per platform (Instagram and TikTok each have independent remaining-time state).
- Remaining time is displayed as `MM:SS` for the full session.

### Platform switcher behavior
- Feed view uses a top segmented control to switch between Instagram and TikTok.
- Default selected platform on entry is the last-used platform.
- Each platform keeps its own in-memory web state while active (resume behavior on switch).
- If one platform expires, switcher remains available and only the expired platform is blocked.

### Navigation containment and web behavior
- URL allowlist is platform-domain-family based (core domain plus required first-party subdomains for normal auth/navigation).
- Off-domain links are handed off to Safari externally.
- New-window requests are opened in the same controlled WKWebView only when target URL passes allowlist checks.
- Platform web sessions/cookies persist across app relaunches by default.

### Expiry and intervention behavior
- At `00:00` remaining time for a platform, the feed is immediately replaced by a non-dismissible `InterventionView` for that platform.
- Valid reset condition for leaving intervention is the next daily reset boundary for that platform.
- While intervention is active, the expired platform webview is unmounted.
- Intervention copy reuses existing approved strings from `APP_REVIEW_PREFLIGHT.md`.

### Carry-forward constraints
- Keep dark-first, minimal visual direction established in Phase 2.
- Maintain limitation transparency posture from POL-03 and preflight copy constraints.
- Do not introduce claims or UX language that implies full first-party app parity.

### Claude's Discretion
- Exact segmented-control styling, spacing, and typography.
- Exact first-interaction signal used to begin countdown (tap/scroll/navigation event details).
- Transition animation polish (if any) while preserving immediate lock semantics.
- Exact in-app messaging treatment for external Safari handoff events.

</decisions>

<specifics>
## Specific Ideas

- Prioritize continuity when switching platforms (resume each platform's prior in-memory state).
- Keep intervention flow strict on dismissal but scoped per-platform (one platform can lock while the other remains usable if time remains).

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FeedView` and `InterventionView` exist as stubs in `ControlledClient` and should be evolved rather than replaced.
- `InstagramProvider` and `TikTokProvider` already exist with stable provider identity names.
- `FallbackRouter.routeToNativeApp(for:) -> Bool` already defines unsupported-route contract shape.
- `InterventionView` already includes preflight-aligned escalation copy baseline.

### Established Patterns
- `ControlledClient` imports `PolicyStore`; shared persisted state should be read through package boundaries rather than duplicated.
- Project uses dark-first SwiftUI surfaces and explicit App Review limitation copy discipline.
- Cross-platform host testability uses deterministic seams and avoids requiring iOS runtime for all logic.

### Integration Points
- Feed timer behavior should align with per-platform scheduling model established by `ScreenTimeEngine.MonitoredPlatform` and ActivityScheduler event names.
- Platform selection and gating state can integrate with `PolicyStore` persistence patterns if per-platform session state needs persistence.
- Phase 5 behavior must remain compatible with Phase 6 onboarding outputs (selected platforms and configured limits) without changing Phase 5 scope.

</code_context>

<deferred>
## Deferred Ideas

- None — discussion stayed within Phase 5 scope.

</deferred>

---

*Phase: 05-wkwebview-controlled-feed*
*Context gathered: 2026-03-06*
