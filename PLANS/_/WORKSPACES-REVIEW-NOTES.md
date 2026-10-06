# Workspaces + screenshot capture: review notes

Branch `workspaces`, pushed; **no PR yet**. Plan: `PLANS/_/WORKSPACES-AND-CAPTURE-PLAN.md`.
User docs: `docs/MANUAL/22-workspaces-capture.md`. Dev notes: `.claude/instructions/draw-workspaces.md`.

## What's in it, by phase

| Phase | What you get | Commit |
| --- | --- | --- |
| W1a | `.workspace` files: built-in + yours (yours win), `BASED_ON`, unit test 37/37 | f22f30e5 |
| W1b | The overlay: switch in, everything back out, `DRAW.cfg` untouched; F11 reveal; `[START]` | 776465f5 |
| W1c | View → Workspace, `Ctrl+Shift+W` switcher, `[WS: name]` badge, `--workspace` / `--workspaces` / `--dir-workspaces` | 3e99080b |
| C1 | Capture Screen (`Ctrl+Shift+P`, File menu, `--capture`), per-OS backends, Settings rows | dc410bf2 |
| C2 | Region picker (box, handles, loupe, Space / Enter / Esc), > 4096 scale-or-crop | aed805e7 |
| W2 | Toolbox from `BUTTONS=` / `COLUMNS=` / `ICON.x`; organizer + drawer as hideable elements | 9966f2b4 |
| W3 | Edit bar / advanced bar / organizer widgets by name; palette strip independent of the status bar | 9f6f95a3 |
| W4 | `[MENUS] ROOTS=` / `HIDE_ITEMS=` | 6ba38874 |
| W5 | `[KEYS]` overlay (wins over DRAW's keys only while active), relabeled hotkeys | 2854286a |
| W6 | Configurator dialog (6 tabs, New / Duplicate / Rename / Delete-Reset / Save / Use / Close) | c5f44fb3 |
| C3 | Arrow, Highlighter, Redact, Numbered callout, Quick Save, Done (`Ctrl+Enter`) | f05c2073 |
| C4 | `DRAW --capture` hands off to a running DRAW (no second window) | 1705fa19 |
| D1 | Manual ch. 22, SHORTCUTS, instructions file, CLAUDE.md, these notes | (this) |

## Where it differs from the plan

- **Module location:** the file layer is `CFG/WORKSPACE`, not `GUI/`. `--workspaces` runs at include time and needs its arrays before `CFG/CLI-QUERY.BI`.
- **User folder** is `<data>/WORKSPACES`, upper case like `DRAWER-SETS` and `PALETTES`.
- **Switcher** is the command palette pre-filtered to `Workspace:`, not a new popup. It already has arrows, Enter and type-to-filter, and it works when a workspace hides every bar.
- **Configurator:** edits apply on SAVE / USE. There is no live preview while the dialog is open (the UI behind a modal doesn't repaint). CLOSE discards.
- **New annotate tools are keys and menu items, not toolbox buttons.** Arrow, highlighter, redact and callout reuse existing tools and modes, so they have no `TB_*` button or icon. Annotate's toolbox lists the 8 real buttons.
- **Arrow:** the line tool with a sticky arrowhead. No "thicker default stroke"; it uses the current line settings.
- **Highlighter:** a yellow brush on a Multiply layer named "Highlight", not a brush preset.
- **Redact** and **Callout** are armed modes on the marquee / null tool, polled after each frame, not new `TOOL_*` tools.
- **Done** returns to the previous document by saving it to the cache when the capture starts. This also replaces the "discard unsaved changes?" question for captures.

## Fixes found along the way (outside the feature)

- `--option KEY=VALUE` was written into the config by the first `CONFIG_save`. It is now this run only, as documented. This also leaked a test's `QA-OPTIONS` into the later tests of a QA run.
- Command palette: running a command now closes the palette first. Settings used to open over a palette still on screen (the "palette lingers behind Settings" issue), and Workspace Switcher run from the palette closed itself.
- `GUI_TB(29)` (Smart Shapes) was never freed at shutdown.
- The AUDIO menu's Random Track cascade checked a stale literal root `10`.
- Doc drift: `MENU_MAX_*` values, advanced bar slot count.

## Known limits

- Toggles you make inside a workspace (open the mixer, change "visible at startup" in Settings) last for the session. Leaving restores the state from when you entered. Settings shows the workspace's values for panels it controls.
- `[OPTIONS]` keys belong to the workspace while it is active. Changing one in Settings then is not kept.
- The region picker uses DRAW's window; it does not go fullscreen. On a small window the frozen screen is scaled down, so precise picking is easier maximized.
- Ctrl+C in Annotate is Copy Merged (the selection or the whole picture), not copy-from-layer.
- README "New in" text is left for the release (create-release skill).

## Tested

- **QA (Xvfb):** ws-unit 37/37; workspace-annotate-f11, workspace-switch-restore, workspace-keys, workspace-configurator, workspace-simple, capture-screen-fake, capture-handoff, annotate-tools. Also regression: smoke, calibration, drawer, tooltip, crop, marquee, line, line caps, ellipse, cheat sheet, command palette, settings open/close, effect settings.
- **[Linux] real Plasma 6.3 Wayland (XWayland):** `--capture` with AUTO picks spectacle and grabs 3840×2160. DRAW's window unmaps during the delay and comes back.

## Please try by hand

1. **Plasma global shortcut:** System Settings → Shortcuts → Add New → Command: `…/DRAW.run --capture`, bound to e.g. `Meta+Shift+S`. Test with DRAW running (it hands off) and not running (it starts DRAW).
2. **Capture → annotate on a real screenshot:** region picker feel on 4K; loupe size; `X` redact on text; `N` callouts; `H` highlighter; `Ctrl+Enter` returning to an unsaved drawing.
3. **Configurator:** build a workspace from DUPLICATE; try each tab; USE; F11; `Ctrl+Shift+W` back to Default.
4. **Simple workspace:** is the 2-column toolbox above a 4-column organizer acceptable, or should the toolbar center or stretch?
5. **Windows:** `_SCREENIMAGE` capture (multi-monitor grabs the primary only); `Ctrl+Shift+P`. **macOS:** `screencapture` permission prompt.
6. **GNOME / sway / X11** backends (untested here).
