# Tatami iOS — правила

Перед любой работой прочитайте [`WORKFLOW.md`](WORKFLOW.md), затем этот файл,
`docs/BACKLOG.md` и `STATUS.md`.

- Swift/SwiftUI project only; не добавлять server или web code.
- Offline capture и zero data loss важнее декоративных эффектов.
- Сетевые вызовы идут через versioned API contract.
- Секреты, audio и transcripts не коммитить.

## Canonical task-thread routing

This directory is owned by the canonical task thread Tatami-iOS. Continue
that existing project thread for all work in this repository. Before sending
delegated work, verify the thread identity, repository path, branch, and scope.
Use the project thread messaging mechanism; do not replace it with a generic
spawned agent or a nickname-only assignment.

Create a new agent only for a genuinely isolated review, or when this canonical
thread is unavailable and the user explicitly authorizes creating one. If the
correct thread cannot be found, report a blocker and wait. Every handoff must
name the project, ownership boundary, expected checks, documentation and commit
requirements, and expected return format. Verify the returned thread identity
and changed scope before accepting the result.

## Canonical document order

1. `AGENTS.md`
2. `docs/STRUCTURE.md`
3. `STATUS.md`
4. `docs/BACKLOG.md`
5. `WORKFLOW.md`
6. Applicable ADRs and runbooks

Update `STATUS.md` and `docs/history/` on handoff; use `docs/CHANGELOG.md` only for product-visible changes.
