---
name: macos-glut-button-emulation
description: macOS Alt/Ctrl+click reaches DRAW as a DIFFERENT mouse button — Apple-GLUT "Button Emulation", not a DRAW bug
metadata:
  type: reference
---

**[macOS]** QB64-PE renders through **Apple's GLUT.framework** on macOS (the
Preferences dialog with Initialization/Mouse/Joystick/Spaceball tabs is Apple-GLUT's,
not the FreeGLUT QB64-PE bundles for Linux/Windows). Apple GLUT's **"Button Emulation"**
is **ON by default for a one-button device** (the built-in trackpad, and VMs/Parallels
that present the trackpad as one-button). With it on, GLUT rewrites modified clicks
into other buttons *before DRAW ever sees them*:

- **Control + Click → Right button (B2)**
- **Option (⌥) + Click → Middle button (B3)**

So `Option+LEFT-click` arrives at DRAW as **button 3**, and any Alt+left feature — most
visibly the **foreground eyedropper** (Alt+click on canvas or GUI) — silently fails.
Alt+RIGHT still works (right stays B2 → background). This is deterministic (confirmed
via `DEV/_/test-alt-click.bas`: no-Option left=1/right=2; Option left=**3**/right=2,
with Option itself detected fine).

**Diagnostic shortcut:** if a macOS user reports "Alt+left-click does nothing / picks
the wrong thing" but Alt+right works, it's this — check DRAW's **GLUT Preferences → Mouse
→ Enable Button Emulation** first. Don't go spelunking in MOUSE.BM; the modifier and the
code are fine, the button was remapped upstream.

**Fix = a GLUT setting, not DRAW code.** Uncheck "Enable Button Emulation" (or change
Middle Button Modifier off Option). DRAW cannot tell an emulated middle-click from a real
one, and GLUT reads the pref at `glutInit` (before BASIC runs, no QB64-PE hook), so DRAW
can't flip it at runtime. It IS a per-user macOS plist preference, so a `defaults write`
pre-seed in `install-mac.command` could disable it by default *if* the exact domain/key
is captured on a Mac. Documented for users in `INSTALL/MAC-USERS-README.md`.
Related: [[qb64pe-reserved-words]] (probe file `line`/`key` gotchas).
