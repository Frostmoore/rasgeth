# Trial plan: incremental CI on a throw-away branch

GitHub cannot be run from an agent, so the coordinator proves it once on a throw-away version branch
(any name matching `p[0-9]+.[0-9]+.[0-9]+`, so `release=true`; a `release-kind.json` with a valid `version` is needed,
copy the current one). Do not tag; do not fast-forward main. Delete the branch afterwards (and its `ci-<version>-<sha>`
images are the nightly cleanup's).

0. Branch `p9.9.9` from this commit, `packaging/release-kind.json` version `9.9.9`. Push = commit A.
1. **Push A, full run.** Expect: CI, OS, App all green; CI's `plan` log says "no earlier run ... built it"; installers,
   mac-app, companion run (~30 min); `release-windows-9.9.9`, `release-mac-9.9.9`, `rasgeth-app-linux-x64` among the
   artifacts. (To also try the failing-test case: make one test fail in A, so A's CI ends red with the packages built;
   then B below is the fix.)
2. **Push B, touching only a test** (e.g. one line in `packages/protocol/test/<any>.test.ts`). Expect:
   - CI `plan`: notice "Packages reused ... run <A's id> (<A sha>)"; job `reuse-packages` green, its summary
     "reused from run N (sha X)"; `installers`, `mac-app`, `companion` **skipped**; `check`, `names` run; run total
     in minutes, conclusion `success`.
   - The run's artifacts list the three names again (copied). Download `release-windows-9.9.9`: `build.json` has
     `sha` = B, `builtSha` = A, `reusedFromRun` = A's run id, `version` 9.9.9.
   - OS: `plan` notice says REUSED / retagged; `images` ran with `from_sha` = A (job "tag" about a minute, no
     `build` matrix); `stack`, `build`, `lxc`, `raspi` skipped; `update-test` runs. Run `success`.
     `docker buildx imagetools inspect ghcr.io/frostmoore/redgiant2:ci-9.9.9-<B sha>` shows the same digest as
     `...:ci-9.9.9-<A sha>`.
   - App (`companion.yml`, only if `apps/companion/test/**` was touched; try with a separate test-only push):
     `check` runs, the five builds skipped, summary names the source run.
   - `rel.sh 9.9.9 <B sha8>` (in a dry way: stop before it merges main, or run it on the throw-away repo only) sees all three
     green on B.
   - Optional, the part that matters: `release.yml` dry run (`workflow_dispatch`, `dry_run`) for B: job `ci-build` must
     decide `reuse` with CI run = B's, `os-plan` must pick A's OS run as `reuse` and `reuse.mjs` accept it (stack digests
     equal to `ci-9.9.9-<B sha>`).
3. **Push C, touching a source** (e.g. a comment in `packages/protocol/src/index.ts`). Expect: CI `plan` log lists the
   non-test changed paths and "more than tests changed"; everything runs (installers, mac-app, companion, check); OS
   plan builds everything (images built, not retagged); same for the App workflow. A `package.json`, lockfile,
   `.github/workflows/*`, `packaging/**` or `docs` change behaves like C.
4. **Fallbacks worth one try each:** (a) push D (test-only) after deleting A's `release-mac-9.9.9` artifact in the UI:
   `plan` finds no usable source (artifact missing) and builds; (b) `workflow_dispatch` of CI with `release_build`: never
   reuses (event is not `push`).

Pass when 1 to 3 behave as written. Anything else, do not merge; the first thing to read is the `plan` log (it prints
why a run was or was not a source).
