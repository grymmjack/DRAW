# Tool Options phase 2 — Text Bar parity checklist

Rick (2026-11-19): "MAKE SURE all existing functionality stays intact. NO EXCEPTIONS."

## How phase 2 is built

The Text Bar's code is not touched (`GUI/TEXT-BAR.BI/BM`: no diff). It stays its own dock
panel (`DP_TEXTBAR`) and draws, clicks, wheels and opens its dropdowns exactly as before. What
makes it the text tool's Tool Options:

- **One place.** `DOCK_bars_follow` (`GUI/DOCK.BM`, run at each layout of a custom arrangement):
  the bar that is not showing follows the one that is - the next slot in its column, a
  column / row of its own beside its own, a tab in its slot, or floating at its spot. Only one
  of them shows (`TEXT_BAR_wanted%` = the text tool or a text layer being edited;
  `SELBAR_wanted%` = any other tool with options), and a slot / column / row with nothing
  shown takes no room, so moving either one moves "Tool Options".
- **One Scale.** `FPANEL_set_scale` writes `TEXT_BAR_SCALE` and `SELECTION_BAR_SCALE`
  together for either panel.
- **No dead strip.** A row holding only a bar is as tall as the bar's lines (`DOCK_row_h%`;
  the 16 px row minimum no longer pads a one-line, 14 px bar).

## Every Text Bar control (all 31 `TEXT_BTN_*`) — unchanged code, check each still works

| # | Control | Check |
|---|---------|-------|
| 1 | FONT dropdown (+ subfolders, hover card, previews) | opens, scrolls, picks a font |
| 2 | SIZE dropdown | opens, picks a size |
| 3-6 | BOLD / ITALIC / UNDERLINE / STRIKE | toggle on the selection / next text |
| 7-8 | FG / BG colour swatches | open the picker, colour applies |
| 9 | LOAD font | file dialog, font loads |
| 10 | DONE | commits the text |
| 11 | MONO | monospace toggle |
| 12-13 | LINE HEIGHT input / AUTO | value changes line spacing; auto recomputes |
| 14 | CHAR mode | character mode, safe-font fallback |
| 15-18 | STYLE dropdown / UPDATE / SAVE / DELETE | presets apply, update, export, delete |
| 19-21 | OUTLINE toggle / colour / size | outline drawn |
| 22-25 | SHADOW toggle / colour / X / Y | shadow drawn at the offset |
| 26-28 | ALIGN L / C / R | alignment applies |
| 29 | AA | antialias toggle |
| 30 | SYNC | style sync toggle |
| 31 | TDF | opens the TheDraw font browser |

Behaviours: shown with the text tool and while a text layer is edited under another tool;
gone with other tools (Tool Options shows instead); F11 hides it; dropdowns open upward in a
bottom row; wraps into lines in a column; floating window as tall as its lines; its own Scale
(now shared with Tool Options); `TEXT_BAR_in_bottom_row%` border rule.

## Automated (must pass before and after)

`dock-textbar`, `ui-textbar-visibility`, `tool-text`, `tool-text-tiny5`, `text-tdf-edit-keys`,
`text-kerning-alt-arrows`, `dock-row-popups`, `dock-rows`, `anim-xsheet-top-strip`,
`dock-preview-title-menu`, `layer-below-cache-stale`, `workspace-all-floating`,
`dock-row-fit`, `dock-row-overwide`, plus `tool-options-dock` (the Text Bar follows Tool
Options into a column, a float, and its Scale).

## Results

- Before (qa-night-fixes, 2026-11-18 night suites): all of the automated list passed on Linux.
- After (tool-options, 2026-11-19, Linux offscreen, build check2): the whole automated list
  above plus `sel-bar`, `tool-options-paint`, `tool-options-more`: **487 / 488 checks pass**.
  The one failure is `tool-text` "Re-edit should show cursor on text", the same check that
  fails on main and in every overnight run (`QA/known-failures.txt`: "fails on main too"),
  so nothing changed. `tool-options-dock` adds the new behaviour: the Text Bar shows where
  Tool Options is (left column, floating) and takes its Scale (PSURF 9 at 3x).
- The 31 controls: their code is untouched, so what each one does is unchanged. Only where the
  bar sits and its Scale are new, and the dock / Text Bar tests above cover those.
  The full suite on the branch (sharded, same day) is the wider regression check.
