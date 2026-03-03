# 01-03 Consent and Revocation Contract

## Consent Capture

At onboarding and settings update, user must explicitly approve:
- enforcement telemetry collection scope
- retention window
- revocation behavior

## Granted Scope

- enforcement-state events only
- no message body/content/media payload collection

## Revocation Path

- in-app settings toggle: "Stop enforcement analytics"
- immediate status update and event collection stop

## Post-Revocation Behavior

- enforcement may continue if enabled, but no new telemetry events are stored
- user receives confirmation of telemetry stop
- data purge job runs against retention window policy

## Retention Window

- standard: 30 days
- immediate purge option available in settings

## Withdrawn Consent Message

- "Telemetry collection is off. Your enforcement data will no longer be recorded."

## Acceptance Conditions

- revocation can be completed in <= 3 taps
- telemetry writes stop immediately after revocation
- purge confirmation is visible to user

## Requirement Mapping

- POL-02: user-consented, minimal, revocable data collection behavior
