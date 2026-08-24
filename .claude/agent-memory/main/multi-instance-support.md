---
name: multi-instance-support
description: How DRAW runs multiple isolated instances with shared clipboard + cross-window layer transfer
metadata:
  type: project
---

DRAW supports running several isolated windows at once (branch `multi-instance`,
2026-08-23). Full deep-dive: `.claude/instructions/draw-multi-instance.md`. Key facts
worth keeping in memory:

- **Preference** `ALLOW_MULTIPLE_INSTANCES` (default FALSE) gates ONLY the in-app
  File > New Window (`Ctrl+Alt+N`, action 213). A manually-launched second copy is
  ALWAYS allowed and auto-isolated — the pref is not a hard single-instance lock.
- **Isolation is real and necessary**: `CONFIG_save` truncate-rewrites the whole
  config (recent-files list included) at ~100 sites during normal use, so two
  instances on one config continuously clobber. Secondary instances (id>1) get a
  seeded `<base>.instance-N.cfg`; id==1 keeps the normal config (backward compatible).
- **No OS primitives to lean on** (this drove the whole design): `LOCK`/`UNLOCK` are
  no-ops on Linux/mac, there is no file-mtime keyword, no FS-watch, no mutex. So:
  liveness = an in-file `heartbeat=<TIMER>` value (reaped when stale); slots are a
  fixed range probed with `_FILEEXISTS` (no directory enumeration); all cross-writer
  handoff uses atomic write-temp-then-`NAME`.
- **Layer transfer** (`TOOLS/LAYERXFER`): clipboard path = `_CLIPBOARDIMAGE` (pixels)
  + `_CLIPBOARD$` (text `DRAWLAYER1|name|opacity|blend`); mailbox path = a blob
  `[MKI$(metaLen)][meta][PNG]` via `_SAVEIMAGE`/`_LOADIMAGE`. NO base64, NO custom
  pixel codec, NO `_MEM` — those were all either uncertain or unproven in this
  codebase. `LAYERXFER_add_layer%` mirrors LAYERS_duplicate's history trick (suppress
  the empty auto layer-add via `HISTORY_IN_PROGRESS%`, record one after the pixel fill)
  so paste/receive is undoable AND redo restores content.
- **No drag-OUT exists in QB64-PE** — layer moves are menu/hotkey-driven, not literal
  mouse-drag between windows. Drag-IN is cross-platform now; see
  [[qb64pe-acceptfiledrop-cross-platform]].
- Action ids: 213 New Window, 715 Copy Layer, 716 Paste Layer, 717 Send Layer to Other
  Window (broadcast to live peers — dynamic per-instance submenu deferred). Plain
  Ctrl+V (305) now OS-clipboard-fallback so it pastes another instance's copy.
- Gotcha hit while building this: `data` and (defensively) `path` fail as parameter
  names — reserved words (gotcha #20). Used `payload` / `filePath`.
