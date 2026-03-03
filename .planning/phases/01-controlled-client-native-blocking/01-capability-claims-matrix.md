# 01 Capability Claims Matrix

| Claim | Status | Evidence | Limitation Disclosure | Fallback Behavior |
|---|---|---|---|---|
| "We block selected apps and web domains" | Allowed | FamilyControls/ManagedSettings docs | Blocking is app/domain/category-level | If blocked action needed, user sees controlled unlock path |
| "We add cooldowns and escalation" | Allowed | DeviceActivity + local policy engine | Timing may vary by OS lifecycle conditions | Reassert policy on foreground and callbacks |
| "We provide a controlled social client" | Allowed | In-app module design | Not a full replacement of first-party apps | Deep link to native/web for unsupported actions |
| "We preserve essential pathways when supported" | Allowed (bounded) | OAuth/scope matrix | Depends on official API scopes | Mark pathway as fallback/not supported |
| "We block Reels/For You internals in native apps" | cannot claim | No public iOS API supports in-app surface edits | Native in-app surface targeting unsupported | Use app-level blocking + controlled client |
| "We offer full DM parity with first-party apps" | cannot claim | APIs/terms generally do not permit parity | Messaging parity unsupported in v1 | Provide fallback handoff only |
| "We work as an invisible monitor" | cannot claim | Violates disclosure/compliance posture | All behavior must be user-visible and consented | Disable enforcement until user acknowledges |

## Prohibited Claim Set

1. "Blocks all social content everywhere."
2. "Full Instagram/TikTok replacement client."
3. "Directly disables only Reels in native app UI."

## Required Limitation Copy

- "FreeSocial cannot directly edit Instagram/TikTok in-app UI surfaces."
- "Some communication actions are available only where provider APIs permit."
- "Unsupported actions route to official app or web experience."

## Requirement Traceability

- POL-01: Claims are accurate and evidence-linked.
- POL-03: Limitations are explicit and user-facing.
