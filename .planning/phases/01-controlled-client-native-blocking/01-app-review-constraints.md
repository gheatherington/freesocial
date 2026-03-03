# 01 App Review Constraints

## App Review Note Template

- App purpose: reduce compulsive social scrolling using controlled client + iOS Screen Time controls.
- APIs used: FamilyControls, ManagedSettings, DeviceActivity (public APIs only).
- Non-capabilities: no direct manipulation of third-party native app UI internals.
- User transparency: clear in-app disclosures and limitation messaging.

## Third-Party Authorization Evidence

Maintain a per-provider evidence folder with:
- API product access approvals
- Terms acceptance snapshot
- Scope list used in app
- Feature-to-scope mapping

## Claim and Metadata Rules

Allowed messaging:
- "Blocks selected apps and websites"
- "Uses Apple Screen Time technologies"
- "Controlled client with intentional feed limits"

Disallowed messaging:
- "Guaranteed full native feature-level blocking"
- "Undetectable behavior"
- "Full parity replacement of first-party social clients"

## Data and Disclosure Constraints

- Collect minimal enforcement telemetry only.
- No message/content payload collection.
- Explicit consent and withdrawal behavior documented in execution artifacts.

## Stop-Ship Conditions

1. Any user-facing claim not present in claims matrix as Allowed.
2. Any implemented provider feature without documented authorization/scope evidence.
3. Any hidden behavior not disclosed in onboarding/settings.
4. Any use of undocumented/private iOS APIs.

## Review Packet Checklist

- Capability claims matrix attached.
- Known limitations attached.
- Data use + consent summary attached.
- Third-party authorization evidence attached.

## Requirement Traceability

- POL-01: claim accuracy and review-safe positioning.
- POL-03: explicit limitation disclosure and transparent behavior.
