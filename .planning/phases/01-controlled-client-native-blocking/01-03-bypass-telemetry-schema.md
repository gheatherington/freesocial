# 01-03 Bypass Telemetry Schema

## Principles

- data minimization
- consent required
- no content payload collection

## Event Types

1. `policy_enforced`
- fields: timestamp, policy_state, source

2. `bypass_attempted`
- fields: timestamp, app_token_hash, prior_state, resulting_state

3. `cooldown_started`
- fields: timestamp, duration_seconds, reason_code

4. `deauthorization_detected`
- fields: timestamp, previous_auth_state, current_auth_state

## Retention

- default retention window: 30 days
- purge on consent withdrawal per consent contract

## Requirement Mapping

- NB-03: bypass and enforcement observability
- POL-02: minimal/consented telemetry controls
