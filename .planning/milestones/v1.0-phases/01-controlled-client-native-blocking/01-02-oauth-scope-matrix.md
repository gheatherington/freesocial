# 01-02 OAuth and Scope Matrix

## CC-02 Minimum Communication Pathways

| Pathway | Status | Provider Scope Basis | Fallback |
|---|---|---|---|
| Account identity/profile context | Supported | official auth/profile scopes | N/A |
| Provider-approved interactions surfaced via official endpoints | Fallback | varies by provider and account type | open official app/web for unsupported interactions |
| Direct messaging parity with first-party apps | Not supported | no v1 parity guarantee from official public scope set | handoff to official app |

## Provider Matrix

### Instagram

| Feature | Status | Scope/Endpoint | Notes |
|---|---|---|---|
| OAuth login | Supported | official login flow | account-type dependent |
| Professional publishing/actions | Fallback | professional-only APIs | not universal across user types |
| Consumer feed parity | Not supported | no parity scope | explicit limitation required |
| Full DM parity | Not supported | unsupported in v1 plan | fallback required |

### TikTok

| Feature | Status | Scope/Endpoint | Notes |
|---|---|---|---|
| OAuth login | Supported | Login Kit | user consent required |
| Basic profile/video surfaces | Supported | official display scopes | constrained fields/endpoints |
| Full For You parity | Not supported | not exposed for third-party parity | explicit limitation required |
| Full DM parity | Not supported | not supported in v1 plan | fallback required |

## Rules

- Only official scopes/endpoints allowed.
- Any unsupported feature is blocked from product claims.
- Every fallback action must have user-facing disclosure.

## Requirement Mapping

- CC-02: communication pathways and fallback states are explicit.
- POL-01/POL-03: feature claims are scope-bound and limitation-aware.
