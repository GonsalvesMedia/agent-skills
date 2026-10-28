# Execution Lifecycle

Repository-convention-aware. Discover how this repo tracks plans before moving or rewriting files.

## Selection

- User-identified plan wins.
- Lifecycle repos: only start plans in an approved/ready state (or already active if resuming).
- Multiple candidates: ask; never default to oldest silently.
- No lifecycle: treat the user-pointed document as the source of truth and keep status notes in that document if useful.

## Typical transitions (when folders or status fields exist)

1. Approved / ready → Active / in progress when execution begins
2. Active → Awaiting approval after implementation and final verification
3. Awaiting approval → Done after human signoff
4. Obsolete work → Archive (prefer move over delete)

If the repo only uses frontmatter `status` (or similar), update those fields instead of inventing directories.

## Continuous loop rules

- Keep going while the next phase is defined and actionable.
- Update `Status`, `Current Phase`, and `Next Action` (or local equivalents) after each phase when the plan format includes them.
- Record architecture-drift notes in the active plan when shared architecture changes.
- One active document per effort when the repo enforces that invariant.

## Stop conditions (leave the loop)

- Real user decision required
- Glaring blocker makes continued implementation irresponsible
- Plan complete pending human approval
- Explicit user pause

## Stale plan / drift reconciliation

Before implementing a step:

1. Diff plan claims against current source.
2. If the step is obsolete or contradicted by a better current design, update the plan (and architecture anchors when conventions require) before coding the stale step.
3. Do not implement an obviously wrong step solely because it is written down—surface the conflict if judgment is needed.
