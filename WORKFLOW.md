# Tatami iOS workflow contract

**Status:** binding

## Commands

1. **Проверить состояние** — read-only diagnosis. Inspect Git, STATUS.md,
   docs/BACKLOG.md, relevant evidence and due/requested logs. Do not open or
   mutate a session.
2. **Открыть сессию** — recover state, then start or continue work. If the
   previous session is open, inspect Git and evidence before classifying it:
   record interrupted, recover and close it as ecovered-and-closed, or
   explicitly continue the same session. A sudden stop itself leaves open.
3. **Запросить план / Составить план** — produce a reviewable plan from the
   current status and backlog. Planning alone does not authorize implementation.
4. **Начать работу / Вести работу** — perform the authorized implementation or
   audit, targeted tests, optional explicitly authorized manual acceptance,
   documentation updates and repository-scoped commits.
5. **Сделать бэкап** — create and verify the backup type named by the user.
   Source bundles, database backups and runtime-data backups are distinct.
6. **Откатить** — inspect the exact target and approved rollback procedure,
   preserve evidence, then perform only the authorized reversible rollback.
7. **Задеплоить** — deploy an exact verified artifact through the applicable
   environment gates; this does not imply a release.
8. **Подготовить релиз / Выпустить релиз** — preparation validates readiness;
   release changes the approved distribution/production state. These are
   separate commands.
9. **Поставить на паузу** — preserve an open handoff with reason, blockers and
   exact next action; do not claim completion.
10. **Закрыть сессию** — verify the outcome, update STATUS.md,
    docs/BACKLOG.md, docs/CHANGELOG.md when product-visible, and
    docs/history/; record commits and remaining work.

## Required reading

Read AGENTS.md, docs/STRUCTURE.md, STATUS.md, docs/BACKLOG.md, and this
contract. Read only applicable ADRs/runbooks. Detailed shared runbooks are in
`../docs/workflow/`;
local detailed runbooks may live in docs/workflow/.

## Repository and safety boundary

Work only in the repository placed in scope. Android, Web and Windows are
independent gitlink repositories: commit there first, then update the root
gitlink separately. Never include unrelated local changes, secrets, raw logs,
audio, transcripts, tokens or identifiers.

## Status contract

STATUS.md is the short current-state contract. Allowed active states are
open, paused, locked, and closed. interrupted and
ecovered-and-closed are classifications recorded in history for the
previous session, not guesses made at the moment of failure.
