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

- `BMIX_begin_stroke` (in `MOUSE_tool_brush`'s press block): `_COPYIMAGE`s the layer
  (`BMIX.snap` plus a `_MEMIMAGE` view) and fills the reservoir with `DRAW_COLOR`.
  It also ORs `HISTORY_FLAG_PAINT_MODE` into the brush history flags, which forces
  raster BAS/QB64 export.
- **Hook** at the top of `DRAWER_resolve_paint_color~&`, after the alpha-0 early-out
  and guarded by `BMIX.active AND CURRENT_TOOL = TOOL_BRUSH AND NOT BMIX.inResolve`:
  - resolve the paint normally (gradient and pattern still work);
  - then `BMIX_apply` mixes it with the **snapshot** pixel at canvas+apron.
  - Mixing against the pre-stroke snapshot rather than the live layer keeps
    overlapping dabs from compounding.
  - Weight: `100 - CFG.BRUSH_MIX_STRENGTH` scaled by the pixel's alpha. An empty
    pixel gets the plain paint.
  - The paint's alpha is kept, so opacity and AA are unchanged.
  - Results are memoized in `BMIX_C_*` (4096 entries).
- **Pickup** (`CFG.BRUSH_MIX_PICKUP`, solid paint only): `BMIX_pickup_path` at the
  top of `PAINT_on` walks the frame's segment every `size/2` px. At each step it
  mixes `pickup%` of the snapshot color into the reservoir; the reservoir then
  replaces the paint in `BMIX_apply`.
  - Pickup is per frame, so a fast stroke smears in short bands.
- `BMIX_end_stroke`: `MOUSE_release_brush`, after pixel-perfect cleanup. Also called
  at the next begin and in all three document resets (`TOOLS/DRW.BM`).
- Undo is the brush's normal before-image.

### Pigment mix palette: action 2027 → `PALETTE_LOADER_create_pigment_mix`

`CFG.RAMP_STEPS` colors `PGM_mix(FG, BG, i/(n-1))` → `Mix RRGGBB-RRGGBB.gpl` in
PALETTES/CREATED, then selected. FG and BG must both be opaque.
