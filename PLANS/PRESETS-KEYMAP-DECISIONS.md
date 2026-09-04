# Preset keymap decisions (Phase 5)

Status: **analysis + safe additions autonomous; letter-key remaps need Rick's call.**

The preset system (`--load-preset <name>`, `CFG/BINDINGS.BM`, `ASSETS/PRESETS/*.bindings`)
is shipped and working. The four app presets (aseprite / photoshop / gimp / deluxepaint)
are **starters** — format docs, no binding rows yet. This doc records why, and exactly
which rows are safe to ship vs. which are judgment calls only Rick should make.

Row format: `actionId keycode requireMods forbidMods`  (mods bits: 1=Ctrl 2=Shift 4=Alt).
Keycodes for letters are lowercase ASCII (a=97 … z=122); the `_KEYHIT` character for a
shifted key already encodes the shift (so `Ctrl+J` = `301 106 1 0`, not a separate shift bit).

## Why most differences can't be auto-filled

DRAW already matches the pixel-art convention these apps share, so the tools that would
"just port" are **already identical** and need no row:

| Function | DRAW | Aseprite | Photoshop | GIMP |
|----------|:----:|:--------:|:---------:|:----:|
| Brush/Pencil | B | B | B | (N/P) |
| Eraser | E | E | E | (Shift+E) |
| Marquee/Rect-select | M | M | M | R |
| Move | V | — | V | M |
| Magic Wand | W | — | W | U |
| Eyedropper/Picker | I | I | I | — |
| Text | T | — | T | T |
| Zoom | Z | Z | Z | Z |
| Line | L | L | — | — |

The **genuine** differences all land on a key DRAW already uses — usually a **chord
initiator** (`G` grid, `M` selection-expand-held, `Z` zoom-held, `E`/`F`/`W` held,
`Space` pan) — so porting them is a *tradeoff*, not a translation:

| App shortcut | App function | Collides with DRAW | Tradeoff for Rick |
|--------------|--------------|--------------------|-------------------|
| **G** | Paint Bucket / Gradient (Aseprite, PS, GIMP-ish) | `G` = grid chord initiator | remap Fill(103) to G ⇒ lose the G-grid chords, or keep DRAW's F |
| **C** | Crop (Photoshop) | `C` = Ellipse tool (110) | give C to crop ⇒ ellipse needs a new home |
| **L** | Lasso / Free-select (Photoshop, GIMP F) | `L` = Line tool (105) | give L to freehand-select(119) ⇒ line needs a new home |
| **P** | Pen (Photoshop) | `P` = Polygon tool (106) | PS pen ≈ Bezier(122); repoint P ⇒ polygon needs a home |
| **R** | Rectangle-select (GIMP) | `R` = Rectangle tool (108) | select-vs-draw meaning flip |
| **M** | Move (GIMP) | `M` = Marquee (112) | direct meaning clash |
| **H** | Hand/Pan (Aseprite, PS) | `H` = Flip-Horizontal (315) | pan is a mouse behavior (see Phase 2B.2), not a clean key action |

**Guidance applied:** per the build-loop rule, a colliding foreign key is *left out* and
listed here rather than guessed — shipping a *wrong* famous-app keymap is worse than an
honest starter. Rick picks the tradeoffs (which DRAW default each app is allowed to
displace); those rows get added in a follow-up.

## How overrides actually behave (important)

A preset row **remaps** an action's existing key — `BINDINGS_apply` re-points the first
dispatched keyboard binding of that action to the new trigger. It does **not** add a second
"alias" binding: the DRAW default key for that action stops working while the preset is
active. So a row only belongs here when the app uses a **different key for the same action**
than DRAW does, and the app genuinely drops DRAW's key.

Two consequences found while scoping:
- **Do not** remap Undo to `Ctrl+Alt+Z` — Photoshop keeps `Ctrl+Z` as undo, and the remap
  would remove it. Leave undo alone.
- **`Ctrl+Shift+Z` = Redo is already a DRAW default** (registered dispatched=TRUE, action
  302). No preset row needed for it.

A remap is conflict-free **by construction** when its target key is otherwise unused in
DRAW (nothing else can clash). That is the bar for an autonomous add; anything landing on
an already-used key goes to the collision table for Rick.

## Safe additions (target key unused in DRAW ⇒ provably conflict-free)

### photoshop.bindings
- `321 106 1 0` — **Ctrl+J** = Copy to New Layer (PS "Layer via Copy"). DRAW's default is
  `Ctrl+Alt+C`; keycode 106 (`j`) is otherwise unbound, so this cannot conflict. **Added.**

### aseprite / gimp / deluxepaint
- No provably-safe remap identified. Aseprite/PS/GIMP's distinctive keys (G bucket, H hand,
  GIMP R/E/F/M select-tools, C crop, L lasso, P pen) all target keys DRAW already uses for
  a draw-tool or chord — every one is a Rick tradeoff in the collision table above.
  DeluxePaint's classic keymap needs a dedicated retro-lore pass with Rick.

## What Rick needs to decide

1. For each app: **may the preset displace a DRAW default?** (e.g. Aseprite/PS `G`→Fill,
   giving up the G-grid chords while that preset is active.) Yes/no per key from the
   collision table.
2. For displaced DRAW tools (ellipse/line/polygon if C/L/P are reassigned): **new home or
   leave unbound** in that preset.
3. Whether pan-on-`H`/`Space` belongs in presets at all or is purely a **Phase 2B.2 mouse**
   behavior.

Once decided, the colliding rows are added and re-verified against the audit the same way.
