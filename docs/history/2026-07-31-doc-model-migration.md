# Control-document model migration

## Goal

Normalize current state, future work, product history and engineering history
without losing the legacy TASKS/SESSION handoff.

## Completed

- Added the YAML-frontmatter `STATUS.md` current-state contract.
- Migrated the full legacy task board to `docs/BACKLOG.md`.
- Preserved the full legacy session in
  `docs/history/legacy-session-migrated-2026-07-31.md`.
- Kept `TASKS.md` and `SESSION.md` as deprecated compatibility redirects.
- Added `docs/STRUCTURE.md`, a product changelog boundary, command reference,
  and the binding session-recovery semantics in `WORKFLOW.md`.
- Updated agent/tool entry points to the canonical document order.

## Verification

- Relative Markdown links checked from the Tatami root.
- `_SESSION.md` inventory checked.
- Repository-scoped `git diff --check` and final statuses are recorded by the
  root handoff/final report.

## Next action

Use the `next_action` field in `STATUS.md`; product/release work was not
performed by this documentation migration.
