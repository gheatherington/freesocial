# 01-03 Escalation Policy

## State Transition Table

| State | Trigger | Action | Next |
|---|---|---|---|
| Baseline | app open in restricted window | apply baseline shields | Cooldown-1 |
| Cooldown-1 | first bypass attempt | short lock + rationale prompt | Cooldown-2 |
| Cooldown-2 | repeated bypass | longer lock + disable unlock shortcut | Incident Lockdown |
| Incident Lockdown | excessive bypass in window | strict lock until next reset boundary | Baseline (after reset) |

## Reset Conditions

- reset at daily boundary if no bypass in trailing window
- manual reset only through explicit policy action

## User-Visible Rationale

- Every escalation message explains current state and next unlock condition.

## Requirement Mapping

- NB-02/NB-03: deterministic anti-bypass ladder and measurable enforcement events.
