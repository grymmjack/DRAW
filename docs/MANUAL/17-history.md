# ↩️ Chapter 17 — Undo, Redo & History

> **What you'll learn:** How DRAW's unified history system works, why text-local undo is separate, and why you can experiment fearlessly.

---

## History System — Fearless Experimentation

> 🎯 **Goal:** Understand the unified undo/redo system.

DRAW has **one timeline** for everything you do — drawing, transforms, layer ops, palette ops, even the import overlay. Press `Ctrl+Z` to step backward and `Ctrl+Y` to step forward.

### How history is recorded

History records **on mouse release**, automatically. There is no manual save-state command, and there is a guard against double-recording on the same frame. Each entry carries a human-readable label — *"Brush stroke on Layer 3"*, *"Move 12px on selected layers"*, *"Apply Transform"*, for a future history panel and comments in QB64PE Project Export.

### Multi-layer awareness

When an operation affects multiple layers (a multi-layer select-and-flip, a Smart Erase across visible layers, a group merge, etc.), DRAW records a single composite history step. Smart Erase additionally tracks per-layer erasure so undo / redo behaves intuitively per layer.

### Text-local undo

The text tool has its own 128-state local history while you are editing a text layer. `Ctrl+Z` and `Ctrl+Y` operate on that local history during text entry — typo experiments don't pollute the global timeline. As soon as you commit (`Esc`), the entire edit becomes a single global history entry.

### Try things

The single biggest productivity unlock in DRAW is: **try things**. Symmetry, palette ops, blend modes, custom-brush fills, and transform overlays are all undoable. There is no "save first" anxiety — `Ctrl+Z` always works.

> 💡 **Tip:** When you make a destructive-looking change (palette ops, image adjustments), don't try to remember the parameters. Just `Ctrl+Z` and `Ctrl+Y` to flip-flop and visually compare.

---

➡️ Next: [Chapter 18 — Real-World Pixel Art Workflows](18-workflows.md)
