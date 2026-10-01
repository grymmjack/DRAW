# Color Spaces (`QB64_GJ_LIB/COLOR` + `GUI/COLOR-SPACE-3D` + gradient/ramp hooks)

OKLab / CIELAB / XYZ support: the library does the math and the 3D widget, and DRAW
wraps it in three places.

## Library: `includes/QB64_GJ_LIB/COLOR/` (submodule)

| File | Prefix | Role |
|------|--------|------|
| `COLOR-SPACES.BI/BM` | `CLR_` | sRGB ↔ linear ↔ XYZ (D65) ↔ CIELAB/LCh ↔ OKLab/OKLCh; gamut test; OKLCh / CIELAB gamut mapping by chroma reduction (keeps L and h); `CLR_mix_oklab~&` / `CLR_mix_linear~&`; `CLR_oklch_ramp` |
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
(default)**, 2 = linear light. Modes 1 and 2 quantize t to 1/1023 and memoize
results in `DRAWER_BLEND_*` (8192-entry direct-mapped cache keyed on c1, c2, t and
space): about 0.13 s per 1M pixels. Gradient paint mode already forces raster BAS
export, so exports are unaffected.

## OKLCh ramps: action 2025 → `PALETTE_LOADER_create_oklch_ramp` (`GUI/PALETTE-LOADER.BM`)

`CLR_oklch_ramp` of the FG color using `CFG.RAMP_{STEPS,L_MIN,L_MAX,HUE_SHIFT,CHROMA_END}`.
Writes `PATHS_data$("PALETTES/CREATED/") + "Ramp RRGGBB.gpl"`, rescans the palette
lists and selects it (the same flow as ADVCP's Create Palette).

All options are in **Settings → Panels → Color Blending + Ramps** (dropdown id 62),
following the standing rule that panel options live in Settings.
