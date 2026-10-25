---
name: document-filename-invariants
description: CURRENT_DRW_FILENAME$ / CURRENT_FILENAME$ are set ONLY via SAVE_set_document_file; save-in-place, sidecar setting, Flatten & Save, Export Again
metadata:
  type: project
---

**Which file is the open document** lives in two globals, and every open/save path
must set them through `SAVE_set_document_file path$` (TOOLS/SAVE.BM, 2026-10-25):

| path ext | `CURRENT_DRW_FILENAME$` (Ctrl+S project target) | `CURRENT_FILENAME$` (image / flatten target) |
|---|---|---|
| `.draw` | path | "" |
| `.png` | path (layers go in the drAw chunk) | path |
| other | "" | path |

Before this, open paths disagreed: Recent Files (menu + Alt+1..0) and the menu-bar
drop set the .draw target to ANY image, so Ctrl+S wrote PNG+drAw data into a `.gif`;
the image browser set no names at all, so Ctrl+S overwrote the PREVIOUS document's
file; Import Image renamed the document after the imported file. All fixed - when
adding a new open path, call the helper after the load (ASE/PSD loaders set the
same values internally).

- **Ctrl+S** on a non-draw/non-png image: `CFG.SAVE_DRAW_SIDECAR` (default TRUE)
  writes `art.draw` beside it; FALSE overwrites the image flattened
  (`SAVE_flat_write%`) when `SAVE_can_write_format%`, else asks.
- **Ctrl+Alt+Shift+S** = Flatten & Save (`SAVE_ACT_FLATTEN` 2218, deferred action 6,
  `SAVE_flattened`): plain image back into `CURRENT_FILENAME$`, no chunk, no .draw.
  Export Selection moved to **Ctrl+Alt+S**.
- **Ctrl+Shift+E** = Export Again (`EXPORT_ACT_REPEAT` 2217): repeats the last
  File > Export As; `EXPORT_forget_last` runs on every document load/create.

Tests: `QA/tests/file-save-passed-in-format.sh`, `QA/tests/file-export-again.sh`.
[Linux] harness: relaunching DRAW right after `draw_quit` can read the window as 0x0
and abort the run on the geometry check - sleep ~1.5s between quit and launch.
