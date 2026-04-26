# 🎨 Chapter 3 — Color & Palette Mastery

> **What you'll learn:** How DRAW thinks about color, the FG/BG/swap dance, the Color Picker and live Color Mixer, the 56 bundled palettes, and the palette-ops mode that lets you remap entire compositions in seconds.

---

## Color Basics — FG, BG & Palette Strip

> 🎯 **Goal:** Select, swap, and manage colors.

The palette strip across the bottom of the screen is the fastest way to choose colors. **Left-click a swatch** to set the foreground (FG) color; **right-click a swatch** to set the background (BG) color. The active FG and BG swatches are echoed in the status bar.

| Action | Key / mouse |
| --- | --- |
| Swap FG and BG | `X` |
| Reset to white FG / black BG | `Ctrl+D` |
| Set BG to transparent | `Shift+Delete` |
| Scroll the palette strip | Mouse wheel over strip |
| Fast-scroll 32 colors at a time | `Shift` + Mouse wheel |
| Temporary FG eyedropper (any tool) | `Alt`+Left-click on canvas |
| Temporary BG eyedropper (any tool) | `Alt`+Right-click on canvas |

**Paint opacity** — the keys `1` through `9` set strokes to 10–90% opacity, and `0` returns to fully opaque 100%. DRAW uses **per-stroke compositing**, which means a 50% stroke that overlaps itself does not get *more* opaque the way Photoshop's brush would; the stroke is rendered once at the end as a single 50% pass. This makes for predictable, pixel-art-friendly results.

## Color Picker, Color Mixer & Custom RGB

> 🎯 **Goal:** Use the full RGB color picker and the live Color Mixer.

Click either the FG or BG swatch in the status bar to open the **Color Picker**. It supports true 24-bit RGB selection plus a hex input field. The Picker tool (`I`) on the canvas pairs an eyedropper with a **loupe overlay** that magnifies the area under the cursor and prints the RGB and hex values for the pixel you'd sample.

The **Color Mixer panel** is a floating, persistent alternative to the modal picker. Open it from `View → Color Mixer` (or via the Command Palette). It exposes:

- RGB sliders — adjust Red, Green, Blue independently.
- HSV sliders — adjust Hue, Saturation, Value.
- A hex input field — paste any hex value directly.
- FG and BG swatches — click to apply the mixed color.

Because the mixer is non-modal, you can keep it open while drawing and tweak colors live. Its visibility is persisted in `DRAW.cfg`.

> 📸 **Screenshot needed — Color Mixer alongside canvas**
> - **Setup:** Any canvas. Open `View → Color Mixer`. Drag mixer to a tidy position (right side, above status).
> - **Action:** Adjust the H slider mid-range so the swatch is a vivid blue/purple.
> - **Capture:** Full window crop showing canvas and mixer side by side.
> - **Save as:** `images/ch03-color-mixer.png`

## Palette Management — 56 Built-in Palettes

> 🎯 **Goal:** Switch, browse, and manage palettes.

DRAW ships with **56 palettes** in [GIMP's `.gpl` format](https://docs.gimp.org/en/gimp-concepts-palettes.html). They live under `ASSETS/PALETTES/` and include classics — **NES**, **PICO-8**, **Commodore 64**, **Game Boy**, **Endesga 32/64**, **DawnBringer 16/32**, **AAP-64**, **Sweetie 16**, **Resurrect 64**, **CGA**, **EGA**, **VGA**, **Amiga**, **MSX** — plus 40 more.

Click the palette name above the strip to open the dropdown. **Pressing a letter** while the dropdown is open jumps to the next palette starting with that letter — handy when you know the name but not the position.

Palette workflows DRAW supports natively:

- **Download from Lospec** — DRAW can fetch palettes from [Lospec's online database](https://lospec.com/palette-list) directly.
- **Create palette from existing image** — distill the unique colors of any open image into a new palette.
- **Import / Export `.gpl`** — interchange with GIMP, Aseprite, Krita.
- **Remap existing artwork** — recolor a finished piece into a different palette while preserving structure.

## Palette Ops — Edit Colors Directly

> 🎯 **Goal:** Modify palette colors and remap on canvas.

**Palette Ops mode** is one of DRAW's signature features. Toggle it from the Organizer panel. Once active, the palette strip becomes editable *and the canvas is remapped live as you change the palette*.

| Gesture on a palette swatch | Effect |
| --- | --- |
| Double-click | Open color picker; new color is **substituted on the canvas** wherever the old one appeared. |
| Right-click | Place a marker / indicator on the swatch (visual bookmarking). |
| Middle-click | Delete the color and remap matching pixels to the nearest remaining color. |
| `Shift`+Middle-click | Insert a transparent (alpha 0) entry at this index. |
| Drag onto another swatch | Rearrange palette order. |
| Left-click | Magic-wand select all matching pixels on the active layer. |

When you first enter Palette Ops, DRAW automatically creates a **`[DOCUMENT]` palette** that snapshots the current state. This means experimentation is safe — you can hop back to the original palette at any time without losing your remapping.

> 🎨 **Try it — colorway exploration**
> 1. Open a finished sprite.
> 2. Toggle Palette Ops.
> 3. Double-click each palette swatch in turn and shift the hue.
> 4. Compare colorways. When one feels right, exit Palette Ops to bake it in.

---

➡️ Next: [Chapter 4 — Layer System Deep Dive](04-layers.md)
