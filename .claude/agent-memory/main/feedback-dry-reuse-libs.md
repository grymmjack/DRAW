---
name: feedback-dry-reuse-libs
description: Always prefer DRY + existing reusable library/widget code over hand-rolling; match established patterns for consistency. Before building UI/input/etc., look for a DRAW/QB64_GJ_LIB helper that already does it.
metadata:
  type: feedback
---

Default to **DRY and reuse** — use DRAW's existing reusable libraries/widgets/helpers
instead of hand-rolling, and stay **consistent** with how the codebase already does a
thing. Rick (2026-09-04): "our preference is always DRY and reusable lib stuff if we can,
and we always want to be consistent."

**Why:** hand-rolled duplicates (a manual text caret, a bespoke list scroller, a one-off
key parser) drift from the real widgets, miss features (selection, clipboard, undo, focus,
proper hit-testing), and read as inconsistent. Reuse gets those for free and matches the
rest of the app.

**How to apply — before writing UI/input/dialog/render code, grep for an existing helper:**
- **Text input:** the `TI_*` widget (`includes/QB64_GJ_LIB/TEXT_INPUT/`) — `TI_create%`,
  `TI_set_text`/`TI_get_text$`, `TI_set_focus`, `TI_process_key%`, `TI_process_mouse`,
  `TI_render id,0,0`, `TI_tick`, `TI_inputs(id).theme.*`. Works INSIDE a `DIALOG_CTX` modal
  at dialog-local coords (see `AI/AI-DIALOG.BM` promptTI and `INPUT/API-LOSPEC.BM` search).
  Do NOT hand-roll a filter box + manual caret (caught doing this on the Customize Controls
  FIND box, 2026-09-04 — replaced with TI).
- **Modals:** the shared `DIALOG_CTX` framework (`GUI/DIALOG.BM`): `DIALOG_init`,
  `DIALOG_poll_mouse`, `DIALOG_draw_frame`, `DIALOG_hit%`, `DIALOG_blit`, `DIALOG_cleanup`
  — mirror `SETTINGS_show_dialog` / `AI/AI-DIALOG.BM`, don't invent a new modal loop.
- **Other reusable GJ_LIB widgets:** color picker (`CP_*`), file dialog (`FD_*`), message
  box (`MB_*`). Prefer these over ad-hoc equivalents.
- **Shared helpers:** `SAFE_FREEIMAGE`, `DEST_PUSH/RESTORE`, `SHORTCUTS_keyname$`/`modstr$`,
  etc. Reuse the canonical one rather than a local copy.

When a reusable option genuinely doesn't fit, say why before hand-rolling.

[Linux] Observed on Linux; principle is OS-agnostic. Related: [[feedback-lint-not-build]],
[[feedback-zero-warnings-build]].
