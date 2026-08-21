---
name: hw-cursor-os-plane
description: _MOUSECURSOR is an OS cursor plane above the whole framebuffer, not a QB64PE hardware-image layer — DRAW can drop software-cursor redraw for icon cursors
metadata:
  type: project
---

[Linux/GLFW, verified 2026-08-20] DRAW's "hardware cursor" (`_MOUSECURSOR`, GLFW
PR #701, `$LET HWCURSOR`) is the **OS cursor plane**, NOT a QB64-PE hardware image.
Source: `internal/c/libqb/src/glut-emu.cpp:1355` `MouseSetCustomCursor` →
`glfwCreateCursor(&cursorImage, hotspot)` + `glfwSetCursor(window, cursor)` (→ X11
XcursorImageLoadCursor / Wayland wl_pointer / Win CreateIconIndirect / mac NSCursor).

**Consequences (all confirmed via `DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST.bas`):**
- It sits ABOVE the entire framebuffer — above all four `_DISPLAYORDER` entries
  (`_SOFTWARE, _HARDWARE, _GLRENDER, _HARDWARE1`, which are a per-frame draw order,
  not fixed planes). It is not one of them.
- It does NOT consume a hardware-image slot: a `_COPYIMAGE(...,33)` image and a
  custom `_MOUSECURSOR` coexist with no conflict.
- The compositor moves it, so we NEVER repaint under it — the software dirty-rect
  "erase old / draw new" dance is unnecessary for OS-cursor tools. (Freeze the whole
  render loop; cursor still glides.)
- `_MOUSECURSOR` INSTALL cost is ~16.7ms and PLATFORM-INDEPENDENT: Linux Wayland
  16.75, Linux X11+softGL 16.76, macOS Apple Silicon/NSCursor 16.72 — all ≈ one
  60Hz frame (a QB64PE/GLFW cursor-set sync, ~1 render-thread tick). So the "dedup
  install to icon-change only, never per-frame" guardrail is UNIVERSAL, not a
  Linux/Wayland quirk. Verified via `HW_CURSOR_CROSSPLATFORM.bas` on all three.
- **DRAW's canvas is 100% software surfaces** (`_NEWIMAGE(...,32)`); zero hardware
  images in shipping code (only in `DEV/EXPERIMENTS/*.BAS`). The canvas does NOT need
  to become hardware for the OS cursor to float above it.

**Hard constraint:** an OS cursor is a fixed OS-clamped bitmap + hotspot — it CANNOT
be canvas-aware. Zoom-scaled brush/spray rings, custom-brush stamp, picker loupe,
SHIFT full-canvas crosshair (`GUI/CROSSHAIR.BM`), and color/coord overlays
(`CURSOR.BM:351`) MUST stay software. `POINTER.HW_ICON_ACTIVE%` (`GUI/POINTER.BM:207`)
already draws that line. So the `HARDWARE_CURSOR` A/B toggle can eventually go, but the
software feedback renderer cannot. Migration plan: [[../../PLANS/HW-CURSOR-MIGRATION.md]]
(also `PLANS/HW-CURSOR-BENCHMARK.md`: HW ~2.3× cheaper per canvas move).

**Build gotcha:** `_MOUSECURSOR` needs the GLFW compiler. `~/git/qb64pe-a740g-test/qb64pe`
predates the keyword (committed `qbx.cpp` too old) → bare "Syntax error". Use
`~/git/qb64pe-a740g-test/qb64pe-regen` (re-transpiled). `Makefile` `a740g` target now
points there. See [[../../PLANS/GLFW-PR701-TEST-RESULTS.md]] "Build gotcha".
