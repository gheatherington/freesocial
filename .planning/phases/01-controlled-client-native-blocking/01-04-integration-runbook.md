# 01-04 Integration Runbook

## End-to-End Flow

1. Onboarding
- show capability boundaries and limitation disclosures
- capture consent choices
- initialize policy state

2. OAuth Connection
- connect provider via official login
- persist granted scopes and unsupported-action map

3. Controlled Session
- render finite content batches
- enforce cooldown gates between batches
- show intervention copy on blocked feed attempts

4. Native Restriction Lifecycle
- apply baseline shields
- evaluate schedule and escalation state
- reassert on foreground and DeviceActivity callback

5. Bypass Escalation
- record bypass event
- move state via policy table
- show user rationale and unlock conditions

6. Deauthorization Recovery
- detect auth revoked
- disable telemetry writes if consent revoked
- guide user through reauthorization path

## Sequence (Markdown)

User -> App: Onboard + consent
App -> PolicyStore: Save settings
User -> OAuth Provider: Authorize scopes
App -> ControlledClient: Start finite session
User -> Native App: Attempt bypass
App -> ScreenTimeStack: Apply escalation policy
ScreenTimeStack -> App: Callback state update
App -> User: Show current state and next unlock time

## Integration Checks

- restriction lifecycle documented
- bypass escalation linked to telemetry events
- deauthorization recovery flow documented
- consent withdrawal behavior documented
