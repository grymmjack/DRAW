# Color Spaces (`QB64_GJ_LIB/COLOR` + `GUI/COLOR-SPACE-3D` + gradient/ramp hooks)

OKLab / CIELAB / XYZ support: the library does the math and the 3D widget, and DRAW
wraps it in three places.

## Library: `includes/QB64_GJ_LIB/COLOR/` (submodule)

| File | Prefix | Role |
|------|--------|------|
| `COLOR-SPACES.BI/BM` | `CLR_` | sRGB ↔ linear ↔ XYZ (D65) ↔ CIELAB/LCh ↔ OKLab/OKLCh; gamut test; OKLCh / CIELAB gamut mapping by chroma reduction (keeps L and h); `CLR_mix_oklab~&` / `CLR_mix_linear~&`; `CLR_oklch_ramp` |
| `COLOR-PIGMENT.BI/BM` | `PGM_` | Pigment (paint) mixing: a Kubelka–Munk port of Spectral.js (MIT, credited in the header + `LICENSE-spectral.js.txt`). 38-band reflectance from 7 base spectra, K/S per color (256-slot cache), concentration = weight² × luminance, Spectral's own gamutMap. `PGM_mix~&(c1, c2, t)`, `PGM_mix_w~&(c1, w1, c2, w2)`. `COLOR-PIGMENT-TEST.BAS` checks 307 mixes against spectral.js output (exact) |
| `COLOR-3D.BI/BM` | `C3D_` | Rotatable 3D gamut picker widget: software z-buffered raster into its own image + a per-pixel **pick buffer** (exact color under each pixel); per-pixel solved slice cap |
| `COLOR.BI/BM` | — | Leaders for standalone programs. **DRAW includes the sub-files directly** (`_ALL.BI`/`_ALL.BM`) — sub-files never include each other (QB64-PE `$INCLUDEONCE` path-normalization; same rule as the other GJ_LIB modules) |
| `COLOR-SPACES-TEST.BAS` | — | Reference-value + round-trip tests (exit code 1 on failure). Run after touching the math |
| `COLOR-3D-TEST.BAS` | — | Interactive demo; `--shot /abs/out.png SPACE VIEW SLICE YAW PITCH` renders one frame headlessly |

Units: OKLab L 0..1; CIELAB L 0..100; XYZ Y = 1 for white; hue in degrees. Outputs
are BYREF SINGLE and inputs are copied first, so in/out may alias (gotcha #13 safe).

## Panel: `GUI/COLOR-SPACE-3D.BI/BM` (`CS3D`)

Same two-layer rule as the Advanced Color Picker: **all picker behavior lives in the
widget** (`C3D_`), and the wrapper only frames it.

- **Action 2024** (View menu item + command palette; no default key) → `CS3D_toggle`.
- `REGION_COLOR_SPACE_3D = 29`, `ZORDER_FLOATING`. Rendered after `ADVCP_render` at
  all three `SCREEN.BM` overlay sites.
- **Mouse** (`MOUSE_handle_gui_panels`): called while over the panel, or while the
  panel or widget owns a drag. The wrapper forwards buttons to the widget **only
  as a press made over the panel** (or during a drag the widget already owns), so
  a canvas stroke dragged into the panel can never pick a color. The wheel zooms
  (consumed in the canvas wheel chain via `CS3D_active_hit%`). Middle-drag is
  excluded from canvas pan over the panel, because it spins the view.
- **Auto-hide while drawing over it**, plus restore, in the same hooks as ADVCP.
  **F11 toggle-all** hides it and restores it only if toggle-all hid it
  (`CS3D.hiddenByToggleAll%`). Both are verified under Xvfb.
- **FG sync** is one-way in (`CS3D_sync_from_paint` → `C3D_set_rgb` moves the
  marker); a pick pushes out to `PAINT_COLOR~&` / `DRAW_COLOR~&`.
- **Config**: `CFG.COLOR_SPACE_3D_{VISIBLE,X,Y,SPACE,VIEW,SLICE_ON,SLICE,YAW,PITCH,ZOOM}`,
  written back whenever the widget re-rasterizes after input.
- **Theme**: `THEME.CP_*` colors; active buttons use `THEME.DIALOG_toggle_sel_bg`.
- Opens auto-placed on the left of the work area (ADVCP takes the right).

## Gradient blending: `DRAWER_gradient_lerp_color~&` (`GUI/DRAWER.BM`)

Every gradient sample in DRAW goes through this function (57 call sites).
`CFG.GRADIENT_BLEND_SPACE`: 0 = sRGB (the old math, byte-for-byte), **1 = OKLab
(default)**, 2 = linear light, 3 = pigment (`PGM_mix~&`). Modes 1–3 quantize t to 1/1023 and memoize
results in `DRAWER_BLEND_*` (8192-entry direct-mapped cache keyed on c1, c2, t and
space): about 0.13 s per 1M pixels. Gradient paint mode already forces raster BAS
export, so exports are unaffected.

## OKLCh ramps: action 2025 → `PALETTE_LOADER_create_oklch_ramp` (`GUI/PALETTE-LOADER.BM`)

`CLR_oklch_ramp` of the FG color using `CFG.RAMP_{STEPS,L_MIN,L_MAX,HUE_SHIFT,CHROMA_END}`.
Writes `PATHS_data$("PALETTES/CREATED/") + "Ramp RRGGBB.gpl"`, rescans the palette
lists and selects it (the same flow as ADVCP's Create Palette).

All options are in **Settings → Panels → Color Blending + Ramps** (dropdown id 62),
following the standing rule that panel options live in Settings.

## Pigment mixing (`PGM_`)

### Mix brush: `TOOLS/BRUSH-MIX.BI/BM` (`BMIX`), action 2026

`CFG.BRUSH_MIX` (Brush menu checkbox, command palette, Settings). Only the plain
Brush tool mixes: not the eraser, a custom brush, or transparent paint.

The smudge model follows libmypaint (ISC). The brush carries one **smudge color**
(`BMIX.smudge`); each dab is drawn in
`PGM_mix(smudge, paint)` with `CFG.BRUSH_MIX_SMUDGE`% smudge.

- `BMIX_begin_stroke` (in `MOUSE_tool_brush`'s press block, before `STROKE_begin`)
  `_COPYIMAGE`s the layer (`BMIX.snapImg` plus a `_MEMIMAGE` view, buffer coords
  including the apron). It also ORs `HISTORY_FLAG_PAINT_MODE` into the brush
  history flags, which forces raster BAS/QB64 export.
- `BMIX_dab x, y` runs **before every dab** in `PAINT_on`'s four loops: the
  pixel-perfect path, the 1px Bresenham path, the size-3 plus, and the larger
  shapes.
  - It acts only after the brush has moved `size/4` px since the last sample,
    which is libmypaint's default of 2 dabs per radius. That keeps the result
    independent of FPS and stroke speed.
  - It takes an alpha-weighted, linear-light average of the **snapshot** over a
    disc of `CFG.BRUSH_MIX_RADIUS`% of the brush radius.
  - The first sample becomes the smudge color. After that,
    `smudge = PGM_mix_w(smudge, keep, sample, (1-keep)*sampleAlpha)` with
    `keep = CFG.BRUSH_MIX_LENGTH/100`, so 100 keeps the first pickup.
  - Empty areas pick up nothing.
- **Why the snapshot and not the live layer** (libmypaint samples live): MyPaint's
  dabs are soft and translucent, so the canvas shows through. A hard pixel dab
  re-samples mostly its own fresh paint, and the brush turns back into plain paint
  within a few pixels. This was tried and seen under Xvfb.
- **Hook** at the top of `DRAWER_resolve_paint_color~&`, after the alpha-0 early-out
  and guarded by `BMIX.active AND CURRENT_TOOL = TOOL_BRUSH AND NOT BMIX.inResolve`:
  - it resolves the paint normally (gradient and pattern still work);
  - then `BMIX_apply` mixes it with the smudge color, memoized in `BMIX_C_*`;
  - the paint's alpha is kept, so opacity and AA apply as usual;
  - before the first pickup it returns plain paint.
- **Pixel perfect** restores the layer and redraws the filtered path at release.
  `MOUSE_release_brush` calls `BMIX_begin_replay` first, which copies the finished
  stroke. In replay mode `BMIX_apply` returns each pixel's own stroke color;
  without it, the whole stroke would recolor to the final smudge color (verified
  under Xvfb).
- `BMIX_end_stroke`: `MOUSE_release_brush`, after pixel-perfect cleanup. Also called
  at the next begin and in all three document resets (`TOOLS/DRW.BM`).
- Undo is the brush's normal before-image.

### Pigment mix palette: action 2027 → `PALETTE_LOADER_create_pigment_mix`

`CFG.RAMP_STEPS` colors `PGM_mix(FG, BG, i/(n-1))` → `Mix RRGGBB-RRGGBB.gpl` in
PALETTES/CREATED, then selected. FG and BG must both be opaque.
