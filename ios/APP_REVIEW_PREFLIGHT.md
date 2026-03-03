# FreeSocial App Review Preflight Package

**Version:** Phase 2 scaffold
**Last Updated:** 2026-03-03
**Sources:** 01-capability-claims-matrix.md, 01-app-review-constraints.md, 01-02-intervention-ux-copy.md

---

## 1. Purpose

This document is the single pre-submission reference for App Store compliance. Before
submitting any build, every item in Section 6 (Stop-Ship Checklist) must be checked.

This package synthesizes three Phase 1 artifacts into one standalone deliverable. A reviewer
can use this document top-to-bottom without opening any Phase 1 source file.

---

## 2. Capability Claims Matrix

| Claim | Status | Evidence | Notes |
|-------|--------|----------|-------|
| "Blocks selected apps and web domains" | Allowed | FamilyControls/ManagedSettings public APIs | Blocking is app/domain/category-level only |
| "Adds cooldowns and escalation" | Allowed | DeviceActivity + local policy engine | Timing may vary by OS lifecycle conditions |
| "Provides a controlled social client" | Allowed | In-app module design (ControlledClient package) | Not a full replacement of first-party apps |
| "Preserves essential pathways when supported" | Allowed (bounded) | OAuth/scope matrix per provider | Depends on official API scopes |
| "Uses Apple Screen Time technologies" | Allowed | FamilyControls entitlement, public API only | Accurate and verifiable |
| "Blocks Reels/For You internals in native apps" | CANNOT CLAIM | No public iOS API supports in-app surface edits | Use app-level blocking + controlled client instead |
| "Offers full DM parity with first-party apps" | CANNOT CLAIM | APIs/terms generally do not permit parity | Provide fallback handoff only |
| "Works as an invisible monitor" | CANNOT CLAIM | Violates disclosure/compliance posture | All behavior must be user-visible and consented |

---

## 3. Prohibited Copy

The following phrases must NEVER appear in the App Store listing, onboarding, settings,
or any user-facing string:

1. "Blocks all social content everywhere."
2. "Full Instagram/TikTok replacement client."
3. "Directly disables only Reels in native app UI."
4. "Guaranteed full native feature-level blocking."
5. "Undetectable behavior."
6. "Full parity replacement of first-party social clients."

---

## 4. Required Limitation Disclosures

These strings (or semantically equivalent copy) MUST appear in the UI. Specifically:
in onboarding (first launch), in the Settings screen, and in the InterventionView
when a blocked action is attempted.

| Context | Required Copy |
|---------|---------------|
| Onboarding | "FreeSocial is a controlled companion, not a full replacement app." |
| Onboarding | "Some social features depend on provider-approved API access." |
| Blocked feed action | "Session paused: take a 30-second break before loading more." |
| Blocked feed action | "Infinite scrolling is disabled in FreeSocial by design." |
| Unsupported action | "This action is not supported in FreeSocial yet." |
| Unsupported action | "Use the official app for this action." |
| Escalation | "You have reached your current session limit. Next unlock available after cooldown." |
| Escalation | "Repeated bypass attempts increase cooldown duration." |
| Settings / About | "FreeSocial cannot directly edit Instagram/TikTok in-app UI surfaces." |
| Settings / About | "Some communication actions are available only where provider APIs permit." |
| Settings / About | "Unsupported actions route to official app or web experience." |

---

## 5. App Review Note Template

Use this text verbatim (or as a starting draft) in the App Review Notes field:

> FreeSocial reduces compulsive social scrolling using a controlled client combined
> with iOS Screen Time controls. APIs used: FamilyControls, ManagedSettings, DeviceActivity
> (public APIs only). The app does not manipulate third-party native app UI internals.
> All enforcement behavior is user-visible and consented. Screen Time controls require
> the com.apple.developer.family-controls entitlement (applied for separately).

---

## 6. Stop-Ship Conditions

A build MUST NOT be submitted if any of the following are true:

- [ ] Any user-facing string matches a Prohibited Copy item from Section 3.
- [ ] Any capability claim is not listed as "Allowed" in Section 2.
- [ ] Any implemented provider feature lacks documented authorization/scope evidence
      in the per-provider evidence folder.
- [ ] Any hidden behavior (enforcement, telemetry write, data collection) is not
      disclosed in onboarding or settings.
- [ ] Any use of undocumented or private iOS APIs is present in the build.
- [ ] Consent capture and withdrawal are not functional (POL-02 gate).
- [ ] Any required limitation disclosure string from Section 4 is absent from the UI.

---

## 7. Data and Consent Summary (POL-02)

- **Data collected:** Enforcement telemetry only (bypass events, escalation level, timestamps).
- **Data NOT collected:** Message content, post content, browsing history, location.
- **Storage:** App Group shared container (on-device only). No remote telemetry in Phase 2.
- **Consent gate:** User must grant FamilyControls authorization before any enforcement begins.
- **Revocation:** User can revoke consent at any time; telemetry writes must stop immediately on revocation.
- **Audit log:** ConsentManager.AuditLog records grant/revoke actions with timestamps.

---

## 8. Review Packet Checklist

Before any App Store submission, attach the following to the review packet:

- [ ] This document (APP_REVIEW_PREFLIGHT.md) — current version
- [ ] Per-provider evidence folder (API product approvals, terms acceptance, scope list)
- [ ] FamilyControls entitlement approval confirmation from Apple Developer Portal
- [ ] Data use summary (Section 7 of this document)
- [ ] Consent flow screenshots (onboarding + revocation)
- [ ] Limitation disclosure screenshots (InterventionView, Settings)

---

## 9. Requirement Traceability

| Requirement | Section Addressed |
|-------------|------------------|
| POL-01 | 2 (Claims Matrix), 3 (Prohibited Copy), 6 (Stop-Ship) |
| POL-02 | 7 (Data and Consent Summary) |
| POL-03 | 4 (Required Limitation Disclosures), 8 (Review Packet) |
