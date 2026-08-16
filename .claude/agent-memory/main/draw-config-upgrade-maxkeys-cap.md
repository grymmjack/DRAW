---
name: draw-config-upgrade-maxkeys-cap
description: CONFIG_upgrade re-appended the same trailing keys every run because MAX_KEYS (200) was smaller than the real key count (211+)
metadata:
  type: project
---

`CONFIG_upgrade` (CFG/CONFIG.BM) adds keys the user's config is missing vs. the
current defaults. Step 1 records the user's existing keys into a **fixed array**
`existingKeys(1 TO MAX_KEYS)`; Step 3 appends any default key not found there.

**Bug (fixed 2026-08-16):** `CONST MAX_KEYS = 200`, but a full config is ~211
CONFIG_save keys **plus** RECENT_FILE_* (10) and RECENT_PREVIEW_FILE_* (10),
which Step 1 counts too (Step 3 skips *appending* them, but they still consume
slots). Every key parsed past #200 never landed in `existingKeys()`, so Step 3
saw the trailing keys (FONT_PREVIEW_*, TEXT_SYNC_STYLE, SMART_GUIDES_*,
OPACITY_WARN_THRESHOLD, TOOLTIPS_DISABLED) as "missing" and **re-appended them on
every `--config-upgrade` run**. Symptom the user reported: "config-upgrade runs
multiple times / never takes / doesn't detect my updated config." (The file
didn't visibly bloat because the normal save-on-exit rewrites it canonically and
dedupes — but each fresh run re-showed the "N settings added" dialog.)

**Fix:** bumped `MAX_KEYS` to 1024 (generous headroom — config grows every
release) and added an `_LOGWARN` in the else-branch so a future overflow is loud
instead of silently re-adding keys. Verified headless (Xvfb + `--config <copy>
--config-upgrade`): a full config now converges (0 keys added on a complete
config; exactly 1 added when 1 is removed).

**Answered while here:** new keys ARE written with their **defaults** —
`CONFIG_load` calls `CONFIG_set_defaults` before reading the file, so a key
absent from the user file holds its compiled-in default in `CFG`; the temp
"fresh defaults" file (Step 2) is `CONFIG_save` of that `CFG`, so the appended
value is the default. Note it's `CONFIG_save` output, NOT a parse of
`DRAW.cfg.default` — a key added to DRAW.cfg.default but not to the CFG type /
CONFIG_set_defaults / CONFIG_save will never be offered by the upgrade.

Also (changed 2026-08-16): `--config-upgrade` is now **console-only +
reconcile-and-exit** — it `PRINT`s the result to the console and `SYSTEM`s instead
of showing a `DRAW_alert` modal and launching the editor. See
[[draw-cli-console-only-screenhide]] for the `$SCREENHIDE` mechanism that keeps all
CLI ops windowless.
