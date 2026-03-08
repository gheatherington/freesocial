---
phase: 05
slug: wkwebview-controlled-feed
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest + Swift Package Tests |
| **Config file** | none — xcodebuild/sPM defaults |
| **Quick run command** | `swift test --package-path ios/Packages/ControlledClient` |
| **Full suite command** | `xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --package-path ios/Packages/ControlledClient`
- **After every plan wave:** Run `xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | FEED-01, FEED-02 | unit | `swift test --package-path ios/Packages/ControlledClient` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | FEED-03, FEED-04 | unit | `swift test --package-path ios/Packages/ControlledClient` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 2 | FEED-01, FEED-02 | integration | `xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` | ✅ | ⬜ pending |
| 05-03-01 | 03 | 2 | FEED-03, FEED-04, DASH-02 | integration | `xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` | ✅ | ⬜ pending |
| 05-04-01 | 04 | 3 | FEED-01, FEED-02, FEED-03, FEED-04, DASH-02 | full | `xcodebuild test -project ios/FreeSocial.xcodeproj -scheme FreeSocial -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Instagram web feed loads with mobile UA inside controlled WKWebView | FEED-01 | Live social content + anti-automation variability is not deterministic in unit tests | Launch app on simulator, select Instagram, verify feed renders and remains in embedded webview |
| TikTok web feed loads with same containment policy | FEED-02 | Same runtime variability and content gating constraints | Launch app on simulator, select TikTok, verify feed renders and remains in embedded webview |
| Off-domain navigation opens Safari instead of in-app webview | FEED-01, FEED-02 | Requires runtime navigation behavior observation | Trigger external link from feed, verify app webview cancels and Safari opens |
| target="_blank" requests stay in controlled webview only when allowlisted | FEED-01, FEED-02 | New-window behavior depends on WebKit runtime events | Trigger new-window flow, verify allowlisted URL opens in same webview; otherwise external handoff |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
