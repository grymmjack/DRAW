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
eyedropper works. This setting is remembered by GLUT, so it's a one-time change.

> If you use an external multi-button mouse, GLUT usually reports it as a real
> multi-button device and does **not** enable emulation — so this only tends to bite
> on the trackpad.

### Disabling it without the dialog (scriptable)

The setting is stored in a per-user macOS **preference (plist)**, so it can be turned
off from the command line — handy for scripting or for baking into a setup step. GLUT
reads the preference at startup, so change it **while DRAW is not running**, then
relaunch.

First find the exact preference domain + key on your system (toggle the setting once in
the dialog so the key exists, quit DRAW, then):

```sh
defaults find Emulation
defaults find ButtonEmulation
```

That prints the `domain` and `key` holding the emulation flag. Turn it off with:

```sh
defaults write <domain> <key> -bool false
```

(Substitute the real domain/key from the `defaults find` output.) Because GLUT reads
this at `glutInit` — before DRAW's own code runs — DRAW cannot flip it for you at
runtime; a `defaults write` (e.g. added to your own install/setup script) is the only
way to have it **off by default** without opening the dialog.

> **Note:** DRAW itself cannot distinguish an *emulated* middle-click from a *real*
> one, so it can't "just fix this in code" — the correct fix is this GLUT setting.
> The truly upstream fix would be in QB64-PE (disabling Apple-GLUT button emulation at
> init, or moving macOS off the deprecated GLUT framework).

## Parallels / VMs

Under Parallels (or other VMs) the trackpad is often presented as a one-button device
too, so the same FreeGLUT "Button Emulation" note above applies.
