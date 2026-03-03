# 01-03 Native Blocking Architecture

## Core APIs

- FamilyControls: user-selected app/domain/category tokens
- ManagedSettings: shield enforcement stores
- DeviceActivity: schedule/threshold triggers and policy reassertion

## Policy Stores

- `baseline_social`: default shields
- `policy_schedule`: time-window rules
- `incident_lockdown`: escalation lock state

## State Model (App Group)

- selected tokens
- current escalation level
- cooldown timers
- authorization status
- last policy sync timestamp

## Lifecycle

1. On launch/foreground, evaluate auth state and policy drift.
2. If authorized, reapply shields from current policy state.
3. On DeviceActivity callbacks, recompute and reassert enforcement.
4. On deauthorization, disable enforcement pipeline and present recovery flow.

## Failure Modes

- extension callback delays
- timezone shifts affecting schedules
- authorization revoked outside app

## Requirement Mapping

- NB-01/NB-02: enforce native restrictions via iOS-supported controls.
- POL-03: no unsupported native in-app feature claims.
