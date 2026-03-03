# Repository Guidelines

## Project Structure & Module Organization
This repository is currently planning-first.

- `.planning/` — primary project artifacts.
  - `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`
  - `phases/01-controlled-client-native-blocking/` — phase plans, research, summaries, and verification docs.
- Root research/context docs:
  - `IOS_SOCIAL_SCROLL_INTERVENTION_RESEARCH.md`
  - `FEATURE_CONTEXT_SOCIAL_INTERVENTION.md`

When implementation begins, place app code under `app/` (or `ios/`) and tests under `tests/` with mirrored module structure.

## Build, Test, and Development Commands
No runtime/build toolchain is committed yet. Current workflow is document-driven execution.

Useful commands now:
- `rg --files .planning` — list planning artifacts quickly.
- `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" phase-plan-index "1"` — inspect plan wave/completion state.
- `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" init execute-phase "1"` — view phase execution metadata.

Once code exists, add explicit commands here (e.g., `xcodebuild test`, `swift test`, lint scripts).

## Coding Style & Naming Conventions
For planning artifacts:
- Use Markdown with short sections, explicit requirement IDs (`CC-01`, `NB-02`, `POL-03`), and clear acceptance criteria.
- Phase files follow `NN-xx-NAME.md` patterns (example: `01-03-escalation-policy.md`).

For future code:
- Prefer clear, descriptive names over abbreviations.
- Keep modules aligned to capability boundaries (controlled client, native blocking, compliance).

## Testing Guidelines
Current verification is artifact-based:
- Each plan must produce a `NN-xx-SUMMARY.md`.
- Phase completion requires `NN-VERIFICATION.md` with `status: passed`.

For future app tests:
- Mirror source paths in `tests/`.
- Name tests by behavior (example: `testCooldownEscalatesAfterRepeatedBypass`).
- Include requirement traceability in test docs where feasible.

## Commit & Pull Request Guidelines
This workspace may not be a git repo yet; when git is enabled:
- Use scoped, conventional commits (example: `docs(phase-01): add consent and revocation contract`).
- Keep commits atomic and tied to one plan task.
- PRs should include:
  - summary of changed files
  - requirement IDs impacted
  - verification evidence (links to summary/verification docs)
  - screenshots only when UI changes are introduced

## Security & Configuration Tips
- Do not claim unsupported platform capabilities in docs or UI copy.
- Use official APIs only; avoid private/reverse-engineered integrations.
- Treat consent, revocation, and data minimization as release blockers, not polish items.
