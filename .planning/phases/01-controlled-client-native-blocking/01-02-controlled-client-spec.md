# 01-02 Controlled Client Spec

## Purpose

Provide a constrained companion client that suppresses addictive feed patterns while keeping supported social pathways accessible.

## User Journeys

1. Connect
- User selects provider and completes official OAuth.
- App displays granted scopes and unsupported actions.

2. Consume
- Content loads in finite batches only.
- Autoplay off by default.
- Scrolling halts at batch end.

3. Intervene
- "Load more" requires friction gate (delay + intent prompt).
- Cooldown grows after repeated bypass attempts.

4. Recover
- User can return to dashboard or open fallback for unsupported actions.
- Limitations are always visible.

## Core Behavior

- no infinite scroll
- autoplay off
- finite batch size (default 10)
- mandatory inter-batch cooldown (default 30s, escalating)
- blocked-state component for unsupported experiences

## Acceptance Criteria

- User cannot continuously scroll without interruption.
- Every batch boundary has explicit decision point.
- Unsupported actions show limitation copy + fallback route.

## Requirement Mapping

- CC-01: controlled finite-feed experience
- CC-03: explicit intervention and blocked states
- POL-03: limitation transparency
