#!/usr/bin/env bash
# Publish Tatami-iOS/ from the Tatami monorepo to the public iOS repo (main).
# Author/committer emails are rewritten to the GitHub noreply address, so the
# personal email in monorepo commits is never published. Split + rewrite are
# deterministic, so repeated publishes stay fast-forward.
set -euo pipefail
remote="${1:-ios}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
noreply="$(gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"')"
git branch -D ios-publish >/dev/null 2>&1 || true
git subtree split --prefix=Tatami-iOS -b ios-publish >/dev/null
NOREPLY="$noreply" FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
  --env-filter 'export GIT_AUTHOR_EMAIL="$NOREPLY" GIT_COMMITTER_EMAIL="$NOREPLY"' \
  ios-publish >/dev/null
git push "$remote" "ios-publish:main" "$@"
