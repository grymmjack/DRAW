# DRAW on macOS — notes

## Signing (first launch / "damaged" or "unidentified developer")

After you download and extract DRAW, change to the directory you extracted to and then run:

```sh
xattr -dr com.apple.quarantine ./DRAW
codesign --force --deep --sign - ./DRAW
```

## Mouse: Option/Ctrl + Click and FreeGLUT "Button Emulation"

DRAW is built with **QB64-PE**, which renders through **FreeGLUT** on macOS. FreeGLUT
has a built-in **"Button Emulation"** feature that is **ON by default when it detects a
one-button pointing device** — which includes the **built-in trackpad**. With it on,
GLUT rewrites modified clicks into other mouse buttons *before DRAW ever sees them*:

| You do | GLUT delivers to DRAW |
|--------|------------------------|
| **Control + Click** | Right button (button 2) |
| **Option (⌥) + Click** | **Middle button (button 3)** |

That second row breaks any DRAW feature that expects **Option (Alt) + *left*-click**,
most visibly the **eyedropper that samples the FOREGROUND colour** (Alt+click on the
canvas, or Alt+click on the GUI to match a theme colour). Because GLUT turns your
Option+left-click into a *middle* click, DRAW's foreground pick never fires. (Alt +
*right*-click for the **background** colour still works, because right stays right.)

DRAW can't tell an *emulated* middle-click from a *real* one, so this is fixed in the
GLUT setting, not in DRAW:

### How to fix it

1. Open DRAW's **GLUT Preferences** dialog (the QB64-PE/FreeGLUT settings window,
   reachable from the app's menu while DRAW is running).
2. Go to the **Mouse** tab. You'll see **"Enable Button Emulation"** checked, with
   **Right Button Modifier: Control** and **Middle Button Modifier: Option**.
3. **Uncheck "Enable Button Emulation"** (or, if you rely on Ctrl+Click→right, just
   change **Middle Button Modifier** away from *Option*), then **OK**.

After that, Option+left-click reaches DRAW as a normal left-click and the foreground
eyedropper works. This setting is remembered by FreeGLUT, so it's a one-time change.

> If you use an external multi-button mouse, GLUT usually reports it as a real
> multi-button device and does **not** enable emulation — so this only tends to bite
> on the trackpad.

## Parallels / VMs

Under Parallels (or other VMs) the trackpad is often presented as a one-button device
too, so the same FreeGLUT "Button Emulation" note above applies.
