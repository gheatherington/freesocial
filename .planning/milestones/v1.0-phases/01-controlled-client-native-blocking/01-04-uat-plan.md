# 01-04 UAT Plan

## Requirement Trace UAT

| Requirement | Scenario | Evidence | Pass/Fail |
|---|---|---|---|
| CC-01 | User consumes finite batches with no infinite scroll | screen recording of batch boundary interruptions | Pending |
| CC-02 | Supported communication pathway works; unsupported pathway falls back cleanly | pathway matrix + handoff demo | Pending |
| CC-03 | Blocked feed attempts show intervention and cooldown messaging | screenshots + event log | Pending |
| NB-01 | Native app restriction configured via token selection and enforced | config trace + blocked app proof | Pending |
| NB-02 | Escalation states transition correctly after repeated bypass attempts | state-transition log | Pending |
| NB-03 | Bypass telemetry events generated with correct state linkage | telemetry sample export | Pending |
| POL-01 | Public claims shown in product copy match capability matrix | copy audit checklist | Pending |
| POL-02 | Consent capture and consent withdrawal work as specified | revocation test evidence + no-post-revoke writes | Pending |
| POL-03 | Limitation disclosures are visible in onboarding/settings/blocked states | UI screenshots | Pending |

## Negative and Edge Cases

1. Unsupported claims
- Ensure no UI copy implies full native feature-level control.

2. Communication pathway fallback
- If DM parity unavailable, app must route to official app and disclose limitation.

3. Consent withdrawal
- revoke consent and verify telemetry writes stop immediately.

4. Deauthorization regression
- revoke Screen Time authorization externally and verify recovery flow.

## Exit Criteria

- All 9 requirements pass with objective evidence.
- No high-severity compliance or claim mismatch issues open.
