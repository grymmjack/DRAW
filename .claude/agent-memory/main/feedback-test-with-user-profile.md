---
name: feedback-test-with-user-profile
description: Test with Rick's OWN settings + workspace + scale too, not only the pinned QA factory config - QA_USER_PROFILE=1 (2026-11-06)
metadata:
  type: feedback
---

**Rick, 2026-11-06:** "remember you need to test with my settings, my workspace, etc." - after I reported two dock bugs as "not reproduced" from tests that only ran the factory `DRAW.cfg.default` + `WORKSPACE=default` at the QA 958x514@2 geometry.

**Why:** the QA harness builds `QA/DRAW.qa.cfg` from `DRAW.cfg.default` with pins, so a bug that depends on his config, workspace, bindings or scale never shows. "Can't reproduce" from factory-only tests is not an answer.

**How to apply:** for any bug he reports (and before saying "can't reproduce"), also run the relevant tests in user-profile mode (qa-harness DRAW adapter, added 2026-11-06):

```bash
cd QA && QA_USER_PROFILE=1 QA_USER_SCREEN=1152x648@3 QA_XVFB_RES=3840x2160 ./draw-qa.sh tests/<file>.sh
```

- `QA_USER_PROFILE=1`: the cfg is a copy of `~/.config/DRAW/DRAW.cfg` (only UI_SCALE=0 / scale / screen / sound / FPS pinned) and every launch gets FRESH scratch copies of `~/.config/DRAW` and `~/.local/share/DRAW` as XDG_CONFIG_HOME / XDG_DATA_HOME - his workspaces / bindings / drawer sets are used, his real files are never written. Check: `stat` his `current.workspace` / `DRAW.cfg` mtimes before and after.
- `QA_USER_SCREEN`: [Linux] his desktop is 3840x2160 at `UI_SCALE=3` -> DRAW's viewport 1152x648 @3x (90% of desktop / 3). Re-derive if his UI_SCALE or monitor changes (`DISPLAY=:1 xdpyinfo | grep dimensions`, `grep UI_SCALE ~/.config/DRAW/DRAW.cfg`).
- A test meant for his layout must NOT set `WORKSPACE=default` in QA-OPTIONS (that replaces his workspace). `QA/tests/user-dock-handle-menus.sh` is the pattern: it works from whatever layout the dump shows.
- Plain QA runs (no profile) also read his real `~/.local/share/DRAW` (no XDG override) - a test that changes the dock in a non-Default workspace could write there; prefer profile mode or WORKSPACE=default.

Related: [[feedback-test-scope]], [[qa-harness-toolkit]].
