# DRAW v2.0.2 — bug-bash tracker

Bugs/polish found by Rick testing v2.0.1 (2026-08-31). All confirmed by Rick (not
deferred-for-verification). Batching fixes → one build → full QA pass.

Status key: 🔧 fixing · ✅ fixed (pending build) · 🏗 shipped · ⏸ queued

---

## Cursor / marquee

- 🏗 **BUG-A — Resize-corner cursor never flips on right-side corners.**
  `POINTER.CURSOR_FLIP%` is set per-corner in ~44 places but was **never read**: the OS
  hardware-cursor path (`_MOUSECURSOR CURSORS(id).hw_img&`) used one unflipped image, so
  TR/BL corners showed the ↖↘ diagonal instead of ↗↙. Fix: `POINTER_ensure_flipped%`
  bakes a mirrored copy per `CURSOR_FLIP` (h/v/both), the apply block issues it, and the
  change-detection now includes flip so a corner change re-issues. (GUI/POINTER.BI + BM)

- 🏗 **BUG-B — Marquee: hold SPACE to reposition the in-progress selection** (parity with
  Rect/Ellipse's Space-move-during-drag). Applies to all marquee variants (rect / ellipse
  / freehand / polygon while dragging out the shape).

## Text tool  (cluster — use the fix-text-tool-bug skill / draw-text-tool.md)

- 🏗 **BUG-C — Per-character selection ignores baseline offset.** When a glyph has an
  adjusted baseline (raised/lowered), the edit selection highlight stays at the default
  baseline — it renders *below* the glyph instead of hugging it. Should follow the glyph's
  baseline (only cover the "5" in Rick's repro). Screenshot 104811.

- 🏗 **BUG-D — Underline / strikethrough don't scale with font size.** At size 28 the
  line stays ~1px (position and thickness). Both decorations should scale with the font
  size. Screenshot 104640.

- ⏸ **BUG-E — Text font-edit loses undo history.** Undo text back to before a font change
  (canvas + rendered text look correct), then click the text to edit it → the font undo
  steps are lost; the editor shows the pre-undo (non-undone) font state. The text layer's
  own edit-session state desyncs from the document-level undo. Screenshots imply the
  per-layer text data isn't re-synced from the current (undone) history state on re-edit.

## Effects

- ⏸ **BUG-F (master) — Shared Inside/Outside masking for ALL applicable effects.**
  Rick: every effect that can influence pixels *inside* AND *outside* the opaque silhouette
  should expose `[x] Inside` `[x] Outside` (both on = whole layer; Inside-only = clip to the
  silhouette; Outside-only = clip to the transparent region). Build ONE shared masking
  mechanism (a mask derived from the layer's alpha at the effect-apply boundary + the
  matching preview mask via `IMAGE_ADJ_mask_preview`, so preview == apply) and wire every
  applicable effect through it — not per-effect code. Known instances so far: **Extrude**
  (Pixelate; today Inside-only — screenshot 105124), **Wind** (Stylize), **Wave Ripple**
  (Distort — BUG-L). Sweep all effects and enable the toggle wherever it's meaningful
  (blur, displacement, extrude, wind, ripple, etc.); effects that are inherently whole-layer
  or color-only can omit it. Preserve current default behavior per effect.

- ⏸ **BUG-G — Wind Inside/Outside** — instance of BUG-F (Effects → Stylize → Wind).

- ⏸ **BUG-I — Running an effect on a text layer must rasterize it first.** Text layers are
  non-destructive (re-rendered from TEXT_LAYER_DATA every frame), so a pixel effect either
  no-ops or gets clobbered on the next text re-render. When an effect is applied to a
  LAYER_TYPE_TEXT layer, auto-rasterize it to LAYER_TYPE_IMAGE first (reuse the existing
  Rasterize Text path / HISTORY_KIND_RASTERIZE), then apply. Group both into one undo step
  so a single Ctrl+Z restores the editable text. Likely a shared guard at the effect-apply
  entry point (IMAGE-ADJ / EFFECTS) rather than per-effect.

- ⏸ **BUG-L — Wave Ripple inner/outer + preview mismatch.** Effects → Distort → Wave Ripple:
  the PREVIEW only shows displacement of non-transparent pixels, but on APPLY it also moves
  pixels outside the opaque silhouette (Rick wants the outside behavior — it's good). Two
  parts: (1) make the preview match the apply (preview should show the outside effect too,
  like BUG-71's anchor fix); (2) add `[x] Inside` `[x] Outside` options. Same inner/outer
  masking as F (Extrude) and G (Wind) → build ONE shared effect inner/outer masking helper
  and wire Extrude / Wind / Wave Ripple (and future effects) through it.

- ⏸ **BUG-J — "Isolate onto new layer" from Blend-Last-Effect renders nothing.**
  Ctrl+Shift+F (blend/fade last effect) with the isolate-to-new-layer option: clicking the
  button creates the new layer but the effect isn't rendered onto it at all — the new layer
  is empty. The isolate path isn't compositing the effect result into the new layer.

- ⏸ **BUG-K — Every effect remembers its settings: 3 preset slots per effect.** Each effect
  keeps three parameter sets, keyed BY EFFECT:
  1. **Defaults** — factory values; **RESET** restores these (already exists).
  2. **Last Set** — the params the user last configured/left in the dialog; **restored when
     the dialog reopens** (today it reopens at defaults).
  3. **Last Applied** — the params of the last OK/commit; used by **Recall Last Effect**
     (Ctrl+Alt+F) so recall replays *that effect's* last-applied settings, not a global one.
  Design as a shared per-effect param store (id → {defaults, lastSet, lastApplied}) so every
  effect gets all three uniformly rather than bespoke per-dialog code. Ties into F/G/I/J
  (same effect-apply path) and the last-effect memory hook at IMAGE-ADJ.BM:458.


- ⏸ **BUG-M — Wrong preview offset for Crystallize (and a few other effects).** The effect
  preview thumbnail renders at the wrong position in the dialog — shoved to the top-left,
  overhanging the pane edge, not aligned/centered in the preview area. Likely effects whose
  result image is a different SIZE than the source (crystallize resamples), so the
  DIALOG_draw_preview / IMAGE_ADJ preview blit centering math is off. Sweep which effects
  return an off-size thumb and fix the preview positioning (probably in the shared
  IMAGE_ADJ_setup_preview / DIALOG_draw_preview path). Screenshot 111106.
  **KEY CLUE (Rick): the offset is 100% tied to the canvas ZOOM depth** — so the preview
  source is being sampled in zoom/pan-relative (screen) coords instead of the raw layer
  buffer. Fix: IMAGE_ADJ_setup_preview must grab the thumb from the layer's imgHandle at
  native resolution (independent of SCRN zoom/pan/offset), not from the zoomed viewport.


- ⏸ **BUG-N — Add Noise → Monochrome draws noise pixels 2× too tall.** Effects → Add Noise
  in Monochrome mode renders each noise pixel at 2px height instead of 1px (vertical
  doubling). Likely a y-step / row-loop error in the monochrome noise path. Screenshots
  111319 / 111343. (Per-effect bug, folded into the effects-cluster pass.)


- ⏸ **BUG-O — Redo Last Effect (Ctrl+F) must apply silently with last settings.** Today it
  reopens the dialog; it should re-apply the last-applied params of that effect with NO
  dialog (Ctrl+Alt+F = Recall, which re-opens the dialog pre-filled). Directly depends on
  BUG-K's "Last Applied" slot — Redo replays it, no UI.


- ⏸ **BUG-P — Render Grid → Perspective should be a full synthwave/Miami-Vice grid.**
  Effects → Render → Grid with PERSPECTIVE on currently renders a "weird horizon line" and
  the lines stop short (clipped by a rectangle calc). Rick wants a proper vanishing-point
  perspective grid: complete `/` and `\` distance lines running all the way through the
  whole visible area to the horizon (classic 80s synthwave floor grid), not a truncated box.
  Rework the perspective grid generator (IMAGE_ADJ grid/render path). Screenshot 111744.


- ⏸ **BUG-Q — Effects → Shape → Backlight previews but does not apply.** The backlight
  effect shows correctly in the dialog preview, but clicking OK renders nothing to the layer
  (same class as BUG-J). Suspect the apply branch doesn't write the result back / uses the
  wrong source, or the result handle is dropped. Logic bug in the backlight apply path.


- ⏸ **BUG-R — Shape/Texture effects don't honor an active selection; the two "EFFECTS:"
  toggles live in the wrong menu and are unexplained.** (1) With a selection active, shape
  and texture effects apply to the whole layer instead of respecting it. (2) UX: the Select
  menu has "EFFECTS: CLIP TO SELECTION" and "EFFECTS: SELECTION AS SHAPE" — Rick finds these
  confusing and misplaced. Move them into the Effects menu (or expose per-effect in the
  dialog), label them clearly, and make effects actually honor the selection when set.
  Ties into the F master (masking) + the IMGADJ_sel_active% / sel-as-shape code paths.

## UI-wide

- ⏸ **BUG-H — Angle dials: double-click to type a value.** Everywhere there's an angle
  dial (effect dialogs, etc.), double-clicking it should open a direct numeric entry for
  the angle instead of only drag-to-set. One shared dial widget → fix once.

---

## Also this session (already shipped to main, not part of 2.0.2 batch)
- QA harness fix: source-guard tests must not `exit` (aborted the whole suite at test 18) — f756143f.
