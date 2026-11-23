# Incremental CI and `rel.sh`

`rel.sh` needs no change. It finds each run by workflow + branch + sha and waits for its conclusion; with the
incremental plan a run that reuses earlier builds still ends `success` (the reused jobs are simply `skipped`, and the
plan/`reuse-packages` summary says "reused from run N (sha X)"). Its re-run of failed jobs works as before.

What `rel.sh` now sees, per workflow, for a push that changed only test files since the last run that built:

| Workflow | Reused (skipped here)                                | Still runs                                 |
| -------- | ---------------------------------------------------- | ------------------------------------------ |
| CI       | installers (Linux + Windows), mac-app, companion     | plan, reuse-packages, check (4 OS), names  |
| OS       | stack, build, lxc, raspi (images stay the old run's) | plan, images (retag, seconds), update-test |
| App      | android, linux, windows, macos, ios builds           | plan, check (analysis and tests)           |

Notes for the operator:

- If the reuse cannot be proved (anything but tests changed, the old run's jobs not all green, artifacts expired,
  history rewritten) the plan says so in the log and everything runs as before.
- `rel.sh`'s one automatic re-run (`gh run rerun --failed`) is still the right tool for a flaky job on the SAME sha;
  the incremental plan is for a NEW commit (a fixed test).
- Optional improvement, not needed: `rel.sh` could print the plan's notice, e.g.
  `gh run view $id --json jobs -q '.jobs[]|select(.name=="reuse-packages")|.conclusion'`.
