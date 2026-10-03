# Pen pressure (`INPUT/PEN` + `QB64_GJ_LIB/PRESSURE_DEVICE`)

QB64-PE's GLFW window layer has no pen support. The library
`includes/QB64_GJ_LIB/PRESSURE_DEVICE` (`PD_` prefix) hooks the native window
returned by `_WINDOWHANDLE`:

| OS | Backend |
|---|---|
| Windows | `WM_POINTER` (Windows Ink) through a subclassed window procedure |
| macOS | an `NSWindow sendEvent:` override, through the Objective-C runtime via `dlsym` |
| Linux | XInput2 on a second X connection; libX11 and libXi are loaded with `dlopen` |

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
- **Mix brush.** `BMIX_apply` uses `PEN_mix_smudge%(CFG.BRUSH_MIX_SMUDGE)`, so a
  light touch smears more (`TABLET.dabP` is the current dab's pressure).
- **Export.** A dab whose size differs from the brush ORs `HISTORY_FLAG_PAINT_MODE`
  into `BRUSH_HISTORY_FLAGS`, so the stroke exports as raster.
- **Config:** `CFG.PEN_PRESSURE`, `PEN_PRESSURE_SIZE`, `PEN_MIN_SIZE`,
  `PEN_PRESSURE_CURVE` and `PEN_PRESSURE_MIX`. Their UI is Settings → General →
  Pen Tablet.

## Not done yet
- Pressure → opacity. This needs a per-stroke coverage mask in `STROKE_commit`,
  because per-dab alpha compounds where dabs overlap.
- Pen eraser end → Eraser tool.
- Pressure for Dot, Spray and custom brushes.
