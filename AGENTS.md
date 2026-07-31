# Tatami iOS — правила

Перед любой работой прочитайте [`WORKFLOW.md`](WORKFLOW.md), затем этот файл,
`docs/BACKLOG.md` и `STATUS.md`.

- Swift/SwiftUI project only; не добавлять server или web code.
- Offline capture и zero data loss важнее декоративных эффектов.
- Сетевые вызовы идут через versioned API contract.
- Секреты, audio и transcripts не коммитить.

## Canonical document order

1. `AGENTS.md`
2. `docs/STRUCTURE.md`
3. `STATUS.md`
4. `docs/BACKLOG.md`
5. `WORKFLOW.md`
6. Applicable ADRs and runbooks

Update `STATUS.md` and `docs/history/` on handoff; use `docs/CHANGELOG.md` only for product-visible changes.
