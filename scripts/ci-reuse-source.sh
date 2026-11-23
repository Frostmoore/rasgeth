#!/usr/bin/env bash
# Incremental CI: which earlier run of this workflow may a new push reuse the build of?
#
#   scripts/ci-reuse-source.sh <workflow file> <branch> <job prefixes, comma separated> [<artifact names, comma separated>]
#
# Prints "<run id> <head sha>" and exits 0 when the NEWEST earlier push run of that workflow on
# that branch that built everything asked for
#   - has every job whose name starts with each prefix finished `success` (or `skipped`), at least
#     one of them `success` (the run as a whole may be red: a test failed, the builds were fine),
#   - still has each named artifact (not expired),
#   - is an ancestor of HEAD,
# and when everything changed since its commit is a test file (scripts/ci-test-only.mjs).
# Prints nothing and exits 0 otherwise (the reason goes to stderr): the caller then builds
# everything. Only the newest run that built is asked: an older one has a larger diff.
# Needs: the full history (git fetch-depth 0, blobs not needed), `gh`, node, GH_TOKEN,
# GITHUB_REPOSITORY, optionally GITHUB_RUN_ID (this run, never its own source).
set -uo pipefail

wf=${1:?workflow file}
branch=${2:?branch}
prefixes=${3:?job prefixes}
artifacts=${4:-}
api="repos/$GITHUB_REPOSITORY/actions"
head=$(git rev-parse HEAD)
here=$(dirname "$0")

while read -r id sha; do
  [ -n "$id" ] || continue
  [ "$sha" != "$head" ] || { echo "run $id: the same commit (a re-run, GitHub's own)" >&2; continue; }
  jobs=$(gh api "$api/runs/$id/jobs?per_page=100" --jq '.jobs[] | "\(.name)\t\(.conclusion)"') || { echo "run $id: jobs unreadable" >&2; continue; }
  built=true
  IFS=, read -ra want <<<"$prefixes"
  for p in "${want[@]}"; do
    mine=$(awk -F'\t' -v p="$p" 'index($1, p) == 1 { print $2 }' <<<"$jobs")
    if ! grep -qx success <<<"$mine" || grep -qvxE 'success|skipped' <<<"$mine"; then
      echo "run $id (${sha:0:7}): jobs '$p...' did not all build ($(tr '\n' ' ' <<<"${mine:-none}"))" >&2
      built=false; break
    fi
  done
  [ "$built" = true ] || continue
  if [ -n "$artifacts" ]; then
    have=$(gh api "$api/runs/$id/artifacts?per_page=100" --jq '.artifacts[] | select(.expired | not) | .name') || have=""
    IFS=, read -ra names <<<"$artifacts"
    for a in "${names[@]}"; do
      grep -qxF "$a" <<<"$have" || { echo "run $id (${sha:0:7}): no artifact $a (expired?)" >&2; built=false; break; }
    done
  fi
  [ "$built" = true ] || continue
  # This is the newest run that built: it decides.
  git cat-file -e "$sha^{commit}" 2>/dev/null || { echo "run $id: ${sha:0:7} is not in the history" >&2; exit 0; }
  git merge-base --is-ancestor "$sha" "$head" || { echo "run $id: ${sha:0:7} is not an ancestor of ${head:0:7}" >&2; exit 0; }
  changed=$(git diff --name-only "$sha" "$head") || { echo "run $id: diff failed" >&2; exit 0; }
  if [ "$(node "$here/ci-test-only.mjs" <<<"$changed" 2>/dev/null)" = true ]; then
    echo "run $id (${sha:0:7}) built it, and only tests changed since ($(wc -l <<<"$changed") files)" >&2
    echo "$id $sha"
  else
    echo "run $id (${sha:0:7}) built it, but more than tests changed since:" >&2
    head -10 <<<"$changed" | sed 's/^/  /' >&2
  fi
  exit 0
done < <(gh api "$api/workflows/$wf/runs?branch=$branch&event=push&status=completed&per_page=30" \
  --jq ".workflow_runs[] | select(.id != ${GITHUB_RUN_ID:-0}) | \"\(.id) \(.head_sha)\"")
echo "no earlier run of $wf on $branch built it" >&2
