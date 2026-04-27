# Ch. 19  💡 Tips, Tricks & Advanced Techniques

> **What you'll learn:** Ten time-saving tips that experienced DRAW users rely on every day, plus advanced layer techniques for non-destructive workflows.

---

## 10 Time-Saving Tips You Need to Know

> 🎯 **Goal:** Boost productivity with pro tips.

1. **`Alt`+Click is a temporary picker — *with any tool that can drop pixels*.** No need to switch to the Picker tool for a quick eyedrop.
2. **Middle-click drags pan — *with any tool*.** Stop reaching for the Pan tool just to nudge the view.
3. **Hold `E` for a temporary eraser.** Release `E` and you're back to the previous tool. Lifesaving for cleanup mid-stroke.
4. **`Shift`+Right-click draws a connecting line** from the previous click to the current cursor — works in Brush, Dot, Line.
5. **`?` (Command Palette) is faster than menu diving.** If it takes more than two clicks to find a command, you're doing it wrong.
6. **Opacity Lock + a giant brush = instant recolor.** No selection needed. Just lock the layer and slosh.
7. **Custom brush + tiled fill = instant pattern fills.** Capture a small motif as a brush, then flood fill an area.
8. **`Ctrl+Shift+C` is Copy Merged.** Flatten the visible composite to clipboard without merging your actual layers.
9. **Double-middle-click = instant pan/zoom reset.** Get back to a fitting view in one gesture.
10. **`.draw` is a PNG you can open in any viewer.** Show off your art on Discord without exporting first — your project file *is* the preview.

<div class="page-break"></div>

## Advanced Layer Techniques

> 🎯 **Goal:** Push the layer system to its limits.

### Non-destructive color adjustment workflow

Build a stack with the artwork at the bottom, a Multiply layer for shadows above it, a Screen layer for highlights, and a Color-mode layer at the top for the overall colorway. Tweak the upper layers without ever touching the base. When the look is right, optionally merge down — but consider keeping the layers for easy revisions.

### Group opacity for complex transparency

A group's opacity slider acts on the entire group as if it were a single rasterized layer. This is how you fade an entire compound element (e.g., a complete UI panel made of many layers) without losing the per-element relationships.

### Pass Through mode

A group set to **Pass Through** lets each child blend with what's *below the group*, not just within. This is essential for blend-heavy layers (Multiply / Screen / Add) inside a group, where Normal-mode group compositing would otherwise isolate them.

### `Alt`+Drag with the Move tool — clone stamping

Holding `Alt` while dragging with the Move tool clones the dragged content into a new layer at the destination. Your original stays put.

### Solo mode

`Alt`+Click any layer's eye icon to **solo** it — every other layer is hidden. Click again to restore. Indispensable for diagnosing a stack you've lost track of. Also handy is using the Move tool, and `Shift+Click` to select the layer under the pointer. 

### Multi-layer selection for bulk operations

Select multiple layers (`Ctrl`+Click / `Shift`+Click) and run any of: clear, fill, flip, rotate, scale, transform overlay, or alignment. The history records a single composite step.

### Layer alignment for sprite-sheet layout

Align Left / Center / Right and Distribute Horizontally are the fastest way to organize a row of sprites — far faster than nudging by hand even with snap.

---

➡️ Next: [Chapter 20 — Appendix: Quick Reference](20-appendix.md)
