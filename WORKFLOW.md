# Local workflow: Tatami iOS

This file is binding for work started inside `Tatami-iOS/`. Run commands from
this directory and do not modify parent or sibling projects unless the task
explicitly includes them.

Before work: read `WORKFLOW.md`, `AGENTS.md`, `TASKS.md`, and `SESSION.md`;
recover an interrupted session; collect due/requested native logs; inspect
status; then plan before implementation.

Implementation always includes implementation, audit, Swift tests/build,
optional device acceptance, documentation, and commits. Close by updating
`TASKS.md` and `SESSION.md`, checking `git diff --check`, and recording the
next action.

When this directory is inside root Tatami, use the detailed runbooks in
`../docs/workflow/` in addition to this local gate.
