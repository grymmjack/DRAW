---
name: driving-draw-gui-headless-xdotool
description: [Linux] How to drive DRAW's GUI headlessly with xdotool+Xvfb — DRAW polls the mouse per-frame, so instant clicks are missed
metadata:
  type: reference
---

**[Linux] Driving DRAW's GUI with xdotool under Xvfb** (learned 2026-09-05, reproducing/verifying browser bugs).

DRAW polls the mouse once per frame (15 FPS idle, higher when active), so a synthetic `xdotool click` (instant press+release) often falls inside one frame and DRAW never sees the press→release edge. Reliable patterns:

- **Buttons / menu items / checkboxes:** `mousedown 1; sleep 0.2; mouseup 1` (frame-spanning), NOT `click 1`.
- **Menu bar:** a slow click OPENS the dropdown and it STAYS open (click-to-open); then slow-click the item. Or press-drag-release (mousedown on the title, move onto the item, mouseup).
- **Modifier combos** (e.g. Ctrl+, for Settings) are unreliable via `keydown ctrl; key comma; keyup ctrl` — prefer the menu path (Edit ▸ Settings, Edit ▸ Customize Controls, View ▸ Browser).
- **Double-click a file-list row:** two frame-spanning clicks < `FD_DOUBLE_CLICK_MS` (0.4s) apart, e.g. `down;sleep .09;up; sleep .06; down;sleep .09;up`.
- **Vision-guided targeting beats geometry math:** `scrot -o out.png` then read the PNG to find the exact pixel of a row/button, rather than deriving viewport→screen coords (the `_abs()` mapping problem). ImageMagick `import`/xwd-decode were unavailable/broken here; `scrot` worked.
- **Launch detached** so it survives the tool call: run a wrapper script (starts Xvfb :99 + DRAW) as a background Bash task; a bare `&` in a foreground Bash call gets reaped when the call returns. Enable logging via env: `QB64PE_LOG_HANDLERS=file QB64PE_LOG_SCOPES=runtime,qb64 QB64PE_LOG_LEVEL=1 QB64PE_LOG_FILE_PATH=...` then grep the log (add temporary `_LOGINFO "PROBE ..."` at decision points — the fastest way to confirm which branch fired).
- **`--config <path>` makes CONFIG_save write back to THAT path** — point it at a throwaway cfg when testing dialogs that persist (OK/Apply), or you'll dirty the target. `QA/DRAW.qa.cfg` is UNTRACKED (generated), so writing it is harmless to git but still surprising.

Compare with the xdotool-based [[qa-harness-toolkit]] which handles the viewport→screen mapping for scripted tests; the above is for ad-hoc interactive-bug reproduction. For the `-z` lint quirk see [[qb64pe-z-fast-gate]]; for build timing see [[draw-build-speed]].

## [Linux] Dead `$DISPLAY` + live `WAYLAND_DISPLAY` = an alert on Rick's desktop (2026-11-22)
A test launch with `DISPLAY=:77` before Xvfb was up, from a shell that still had
`WAYLAND_DISPLAY=wayland-0` (Claude Code's shell inherits the KDE session), printed
`Runtime error: Failed to initialize window` and put QB64-PE's untrappable **Alert dialog
on Rick's real desktop**. DRAW's no-display guard (`native/display_probe.h`) did not stop
it. Any launch script must `unset WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS XDG_SESSION_TYPE`
and check `xdpyinfo` on the target display before it starts DRAW. Start Xvfb with `setsid`
and poll `xdpyinfo` until it answers, not a fixed `sleep 1`. Open item: should the guard also treat
"DISPLAY dead, Wayland live" as no display?
