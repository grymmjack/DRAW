# Pen pressure (`INPUT/PEN` + `QB64_GJ_LIB/PRESSURE_DEVICE`)

QB64-PE's GLFW window layer has no pen support. The library
`includes/QB64_GJ_LIB/PRESSURE_DEVICE` (`PD_` prefix) hooks the native window
returned by `_WINDOWHANDLE`:

| OS | Backend |
|---|---|
| Windows | `WM_POINTER` (Windows Ink) through a subclassed window procedure |
| macOS | an `NSWindow sendEvent:` override, through the Objective-C runtime via `dlsym` |
| Linux | XInput2 **raw** motion (`XI_RawMotion`) on the root window, from a second X connection; libX11 and libXi are loaded with `dlopen` |

**[Linux] Never select `XI_Motion` on DRAW's own window.** The X server then
delivers motion there as XI2 to the library *instead of* core `MotionNotify` to
GLFW, so DRAW loses hover movement (dragging still works because the button's
implicit grab routes events to GLFW). The symptom was a brush outline frozen
where the pen left off. Raw events on the root window never take events away.
Raw events carry the device in `deviceid` (their `sourceid` is always 0), and
the master pointer's copies are skipped. Tablets are rescanned on
`XI_HierarchyChanged` (hotplug).

Confirmed on all three with a HUION Inspiroy 2 M: Linux on Wayland/XWayland,
with and without Huion's driver; macOS with Huion's driver app running; Windows
with Windows Ink on. `PD_pressure!` is 1 for a mouse.

## DRAW side: `INPUT/PEN.BI/BM`

The state lives in `TABLET` (a `PEN_OBJ`). The variable is not named `PEN`,
because **`PEN` is a QB64 keyword**; using it fails with "Name already in use".

- **`PEN_init`** runs in `DRAW.BAS` before the main loop, once the window exists.
  It does nothing when `CFG.PEN_PRESSURE` is off; if the setting is switched on
  later, `PEN_poll` starts it lazily.
- **`PEN_poll`** runs every frame, right after `GAMEPAD_poll` and before the mouse
  is handled. Linux drains its XInput2 queue here.
- **`PEN_stroke_begin`** runs in `MOUSE_tool_brush`'s press block. Brush and
  eraser share that block.
- **`PAINT_on`** calls `PEN_segment_begin`, which fixes the pressure at both ends
  of the frame's segment (`segP0`, `segP1`).
  - When `PEN_size_active%` is TRUE (feature and size option on, pen source,
    Brush or Eraser tool, no custom brush, not pixel-perfect, size > 1), it runs
    `PAINT_on_pressure`. That stamps a dab every pixel, each with its own size
    `PEN_scaled_size%(size, lerp(segP0, segP1, t))`, through `PAINT_stamp_size`.
    `PAINT_stamp_brush` now wraps `PAINT_stamp_size`.
  - In every case it finishes with `PEN_segment_end`.
- **Landing and lift filter (`PEN_stroke_pressure!`).** Readings below
  `PEN_MIN_VALID` (0.02) hold the last real value. Pressure reaches zero a moment
  before or after the button changes, which otherwise starts a stroke with a blob
  or ends it with a hairline flick. The curve `PD_curve!(p, PEN_PRESSURE_CURVE/100)`
  is applied after the filter.
- **Mix brush.** `BMIX_apply` uses `PEN_mix_smudge%(CFG.BRUSH_MIX_SMUDGE)`: the
  paint each dab lays is scaled by `PEN_range!(dabP, CFG.PEN_MIX_MIN)`, so a light
  touch smears more.
- **Pressure → opacity** (`CFG.PEN_PRESSURE_OPACITY`, `PEN_MIN_OPACITY`).
  - `PEN_opacity_begin` (brush press, before `STROKE_begin`) snapshots the layer
    (`TABLET.opBakImg` / `TABLET_BAK_MEM`) and allocates a 1-byte-per-pixel mask
    (`TABLET_MASK_MEM`).
  - Every pixel write in `PAINT_pset_with_symmetry`, `PAINT_blend_pixel` (AA
    coverage folds in) and `PAINT_erase_pixel` goes through `PEN_op_write`. That
    keeps the **strongest** opacity reached at each pixel in the mask and
    recomposites the pixel from the snapshot: straight-alpha source-over, done in
    code because `_BLEND` mixes a transparent destination's black RGB in and
    darkens light strokes. A transparent color erases that share of the original
    alpha.
  - Overlaps never compound, and the result shows **live** while drawing.
  - `STROKE_begin` stands aside (`TABLET.opStroke`), and the plain Opacity
    setting is folded into `TABLET.dabOp`.
  - Opacity strokes run through `PAINT_on_pressure`, so they get per-dab
    interpolation even when pressure sizing is off.
  - It does not apply to 1px pixel-perfect, custom brushes or Shift+smart erase.
  - `PEN_opacity_end` runs at release and in the three document resets.
- **Export.** A pressure-sized dab, or any pressure-opacity stroke, ORs
  `HISTORY_FLAG_PAINT_MODE` into `BRUSH_HISTORY_FLAGS`, so the stroke exports as
  raster.
- **Config:** `CFG.PEN_PRESSURE`, `PEN_PRESSURE_SIZE`, `PEN_MIN_SIZE`,
  `PEN_PRESSURE_OPACITY`, `PEN_MIN_OPACITY`, `PEN_PRESSURE_MIX`, `PEN_MIX_MIN`,
  `PEN_PRESSURE_CURVE`, plus `PEN_PANEL_VISIBLE/X/Y`. UI: the Pen Pressure panel
  and Settings → General → Pen Tablet.

## Pen Pressure panel: `GUI/PEN-PANEL.BI/BM` (`PENP`), action 2028

View → Pen Pressure (also in the command palette). It is a floating panel built
on the same frame model as `CS3D`, with these hooks:
- `REGION_PEN_PANEL = 30`;
- the three render sites in `SCREEN.BM`;
- `MOUSE_handle_gui_panels`;
- auto-hide while drawing over it, plus restore;
- F11 toggle-all;
- pan, wheel and double-click exclusions;
- the `POINTER` arrow over it.

Contents:
- a live pressure meter: the bar is raw pressure, the tick is after the curve;
- a checkbox and a "LIGHT" (lightest-touch) slider each for size, opacity and
  mix paint;
- a logarithmic curve slider (25–400, which snaps to 1.00);
- a response graph with the live point.

`PENP_needs_redraw%` keeps frames non-idle while the meter moves. Values save on
slider release and checkbox click.

## Brush outline only over the canvas
`POINTER_draw` skips the brush, spray and custom-brush footprint unless
`POINTER_over_canvas%`. The apron counts only while a button is held, because
it has the background color and looked like "off the canvas" on hover.

## Not done yet
- Pen eraser end → Eraser tool.
- Pressure for Dot, Spray and custom brushes.
