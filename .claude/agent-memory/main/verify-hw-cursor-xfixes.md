---
name: verify-hw-cursor-xfixes
description: How to check DRAW's on-screen pointer in automated tests — screenshots never contain the hardware cursor; read it with XFixes (curprobe)
metadata:
  type: reference
---

[Linux] DRAW's pointer is an OS hardware cursor (`_MOUSECURSOR` / `_MOUSESHOW`), so `xwd` / `import` screenshots **never contain it**. A "pointer missing / wrong after X" bug can't be seen in screenshots under Xvfb.

Read the live cursor with XFixes instead. The source is `.claude/tools/curprobe.c`; build it with `gcc -O1 -o curprobe curprobe.c -lX11 -lXfixes`. Run it with `DISPLAY` set to the Xvfb display. It prints the size, hotspot, number of visible (alpha > 0) pixels, and the name.
- In the QA config, the brush tool's cursor over the canvas reads `18x26 hot=0,0 visible_px=252 name=`.
- The plain system arrow reads `24x24 ... name=left_ptr`.
- A hidden cursor reads `visible_px=0`.

Used 2026-10-06 to reproduce and verify the after-dialog pointer bug (commit `55c917cf`). Before the fix, Settings > Cancel left `left_ptr` over the canvas. Move the mouse a little before probing, because DRAW applies the cursor on the next rendered frame.

Related: [[hw-cursor-os-plane]], [[draw-modal-cursor-before-first-render]].
