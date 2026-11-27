# Tatami iOS — правила

Перед любой работой прочитайте [`WORKFLOW.md`](WORKFLOW.md), затем этот файл,
`docs/BACKLOG.md` и `STATUS.md`.

- Swift/SwiftUI project only; не добавлять server или web code.
- Offline capture и zero data loss важнее декоративных эффектов.
- Сетевые вызовы идут через versioned API contract.
- Секреты, audio и transcripts не коммитить.

## Shared routing and workflow

Follow [root AGENTS](../AGENTS.md) for the sole canonical task registry and
reading order. A directory's existence does not create a canonical task.
After ownership reaches the correct task, bounded functional roles may be
spawned under the [execution policy](../docs/agent-execution-policy.md).
The shared [WORKFLOW](../WORKFLOW.md) owns session recovery and closeout;
keep local STATUS short and completed details in docs/history/.
