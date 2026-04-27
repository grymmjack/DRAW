# Ch. 15  🖼️ Reference Image & Import

> **What you'll learn:** How to load a reference image for tracing or study, and how to import oversized images with interactive placement, rotation, and flipping.

---

## Reference Image — Tracing Made Easy

> 🎯 **Goal:** Use reference images for tracing and study.

Press `Ctrl+R` to toggle a reference image. The reference renders **behind every layer** with adjustable opacity, so it never interferes with the artwork you're producing.

| Action | Shortcut |
| --- | --- |
| Toggle reference image | `Ctrl+R` |
| Adjust reference opacity | `Ctrl+Shift`+Wheel (5–100%) |
| Reposition / zoom / nudge | Reference toolbar buttons |

Reference image state is persisted in the `.draw` file along with its opacity, position, and zoom — so a project's tracing setup is never lost.

> 🎨 **Try it — pixel art from a photo**
> 1. Load a photo as a reference image.
> 2. Set opacity to 50%.
> 3. Pick a limited palette (e.g., Endesga 32).
> 4. Trace key shapes on a layer above with the line and polygon tools.
> 5. Fill regions with flood fill.
> 6. Hide the reference (`Ctrl+R`) to evaluate the standalone result.

<div class="page-break"></div>

## Image Import — Oversized Placement & Transform

> 🎯 **Goal:** Import and position external images.

`File → Import Image` is different from `File → Open Image`. Open *replaces* your canvas; Import places the incoming image as a **floating overlay** that you position interactively before it commits as a layer.

While in import mode:

- Pan and zoom *inside* the imported image to crop tightly.
- Rotate 90° CW / CCW with the import toolbar buttons.
- Flip horizontal / vertical.
- Drag the destination box's resize handles to scale the placement.
- Live preview reflects every transform.

This is the cleanest way to bring an external sprite into a project at the right size and orientation, without permanent destructive resampling.

### Aseprite & Photoshop

DRAW reads `.ase` / `.aseprite` and `.psd` files directly via `File → Open Aseprite` and `File → Open Photoshop`. Layers are preserved (where they map cleanly to DRAW's blend mode set) and re-exposed as native DRAW layers.

> 📸 **Screenshot needed — Import Image with rotated overlay**
> - **Setup:** Existing 256×256 canvas. Import a photo larger than the canvas.
> - **Action:** Rotate the import 90° CW; pan inside the image so an interesting region is in the destination box.
> - **Capture:** Full canvas with import overlay and toolbar visible.
> - **Save as:** `images/ch15-import.png`

---

➡️ Next: [Chapter 16 — Keyboard Shortcuts & Command Palette](16-shortcuts.md)
