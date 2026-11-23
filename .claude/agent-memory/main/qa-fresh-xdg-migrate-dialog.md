---
name: qa-fresh-xdg-migrate-dialog
description: [Linux] QA tests that start DRAW with their own XDG_CONFIG_HOME hang on the "Migrate settings" dialog when the dev checkout has a legacy USER/ dir and no repo-root MIGRATED_TO_NATIVE.txt
metadata:
  type: project
---

[Linux, observed 2026-11-22 on Rick's dev checkout] `PATHS_migrate` (CORE/PATHS.BM) prompts
"Migrate settings" when neither `<config dir>/MIGRATED_TO_NATIVE.txt` nor `_CWD$/MIGRATED_TO_NATIVE.txt`
exists AND `_CWD$/DRAW.cfg` or `_CWD$/USER/` exists. `~/git/DRAW/USER/` (gitignored, May 2026)
is still there; the gitignored repo-root marker vanished around 2026-11-21. ~20 tests set their own
`XDG_CONFIG_HOME` (anim-effect-lanes, anim-blend-lane, anim-blur-lanes, file-anim-*, kit-export-install,
multi-instance-isolation...) and do not seed a marker, so their batch DRAW (`--export-anim`) sat
behind the modal until the test's timeout: empty pixel reads like `invert pixels [   ]`, or a
600 s kill. The harness seeds the marker only in ITS config dir (adapters/draw/manifest.sh).

**Why:** a modal in a batch run hangs automation; farm checkouts have no USER/ so only this
machine is affected.

**How to apply:** when a test's batch / second DRAW produces nothing (empty readouts, timeouts),
screenshot its display first - a dialog is the usual cause. Fix for tonight: `: > ~/git/DRAW/MIGRATED_TO_NATIVE.txt`.
Open question for Rick: seed the marker in those tests, or never prompt in a batch run.
Related: [[wait-loop-self-match]].
