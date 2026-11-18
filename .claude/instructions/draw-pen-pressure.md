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
- **Tip threshold** (`CFG.PEN_TIP_THRESHOLD`, default 3%). A pen grazing the
  tablet registers clicks at almost no pressure, which left stray dots along the
  hover path. `PEN_segment_begin` sets `TABLET.skipSeg` while raw pressure is
  below the threshold, and `PAINT_on` then draws nothing for that segment.
  `PEN_stroke_empty%` (a pen stroke that never passed the threshold) suppresses
  the undo record in `MOUSE_release_brush`. Strokes with no pen segment (mouse,
  custom brush, smart erase) are never "empty".
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
    darkens light strokes. In an **erasing** stroke (`TABLET.opErase`: Eraser, or
    transparent paint at press), a transparent color erases that share of the
    original alpha. In a **painting** stroke, a transparent resolved color is a
    pattern or gradient hole and leaves the pixel alone, as a plain PSET does.
    (Treating holes as erase made pattern strokes punch holes and flicker.)
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
  `PEN_PRESSURE_CURVE`, plus `PEN_PANEL_VISIBLE/X/Y`. UI: the Pen Control panel
  and Settings → Pen Control (tab 10, `SETTINGS_TAB_PEN`, `SETTINGS_render_pen`) → Pen Tablet.

## Pen Control presets: `GUI/PEN-PRESETS.BI/BM` (`PENPR_`), 2026-11-17

Right-click the panel below its title → the presets menu, shown in the dock's handle menu
(`PENPR_MENU_NEXT` before `DOCK_menu_open`; `DOCK_UI.menuPen` routes build / do to
`PENPR_menu_build` / `PENPR_menu_do`; `DOCK_UI.menuJust` keeps the opening press from
picking a row). Rows: presets A-Z (value 100 + i, ticked = `PENPR_CUR`), Save Preset… (1),
Rename / Delete Preset '<current>'… (2 / 3, disabled with none current), Open Presets
Folder (4, `PATHS_open_in_file_manager%`). A preset = `PATHS_data$("PEN-PRESETS")/<name>.pen`:
two `;` comment lines + `CONFIG_pen_lines$` (CFG/CONFIG.BM - DRAW.cfg's pen block is
printed from the same function via `CONFIG_print_lines`, so a new pen key lands in both).
Never `PEN_PANEL_*`. Current = the preset whose file equals `CONFIG_pen_lines$` now
(`PENPR_scan` on open; `PENPR_LAST` wins a tie), so no cfg key tracks it. Apply =
`CONFIG_apply_key%` per line, `PENC_sync`, `CONFIG_save`. Names go through `PENPR_clean$`.
While any dock menu is open `PENP_mouse_input` ignores the mouse. Test `pen-presets`.

**Example presets** (2026-11-17): `ASSETS/PRESETS/PEN/*.pen` (ten, all 24 keys in
`CONFIG_pen_lines$` order - a key missing or out of order means the tick never matches).
`PENPR_seed_examples` (first `PENPR_scan` of a session) copies any shipped name not yet
listed in `<presets>/.examples-copied` and not already present, then appends it there -
so a deleted / renamed example stays gone and a newly shipped one still arrives. [Linux]
QB64 `PRINT #` writes CRLF there too: the reader strips CR; tests must `tr -d '\r'`.
A new pen cfg key: regenerate the examples (every key, same order). "Raw Pen" = the factory
defaults, so it is ticked on a fresh cfg. User guide: manual Ch. 2 "Pen Control Guide".

## Pen Control tooltips (2026-11-17)

`PENP_tip$(ctl, sg)` is the ONE text per control - "WHAT - does" LF "behaves" LF "TRY: example";
mode rows / the tab strip have one per segment, and non-control areas use `PENP_TIP_*`
(40 meter, 41 RESPONSE graph, 42 speed graph, 43 NOW/AVG/TOP readout, 44 hint box).
`PENP_tip_at%` (only when `REGION_hit_test%` = `REGION_PEN_PANEL`, never on the title bar /
dock handle, not while dragging) returns `ctl * 10 + sg + 1` -> `TOOLTIP_SRC_PEN_PANEL` (14),
text in `TOOLTIP.DYNAMIC_TEXT$`, drawn as three lines. Settings > Pen Control sets
`SW_TOOLTIP$ = PENP_tip$(...)` too (`SW_draw_tooltip` splits on LF; `SW_TIP.text` is a
variable-length STRING now - it was `* 200` and cut long tips). Settings-only wording where
the units differ (curve / speed gains x100). `seg` is a QB64 keyword (DEF SEG) - hence `sg`.
Test `pen-control-tooltips` (TIP dump line: -1 14 idx).

## Pen Control panel: `GUI/PEN-PANEL.BI/BM` (`PENP`), action 2028

Was "Pen Pressure" until 2026-11-17, when it took on the stroke filters. View →
Pen Control (also in the command palette). The cfg keys, dock id `pen` and
action 2028 kept their names. It is a floating panel built on the same frame
model as `CS3D`, with these hooks:
- `REGION_PEN_PANEL = 30`;
- the three render sites in `SCREEN.BM`;
- `MOUSE_handle_gui_panels`;
- auto-hide while drawing over it, plus restore;
- F11 toggle-all;
- pan, wheel and double-click exclusions;
- the `POINTER` arrow over it.

**Tabs** (`CFG.PEN_PANEL_TAB`: 0 PRESSURE, 1 SMOOTHING, 2 SPEED). The tab strip
(`PENP_CTL_TABS`) sits in what was the status row. The backend status moved to
the title bar, or to the bottom of the response graph when the title bar is too
narrow. Every control has a tab in `PENP_ctlTab()` (-1 = every tab), and
`PENP_hit%` skips the other tabs' controls. The SMOOTHING and SPEED rows are
laid out in `PENP_layout_tabs` inside the PRESSURE tab's height, so switching
tabs never resizes the panel or its dock slot.
- **PRESSURE:**
  - a live pressure meter: the bar is raw pressure, the tick is after the curve;
  - a checkbox and a "LIGHT" (lightest-touch) slider each for size, opacity
    and mix paint;
  - a logarithmic curve slider (25–400, which snaps to 1.00), and TIP;
  - a response graph with the live point.
- **SMOOTHING:**
  - SMOOTH POSITION, a mode chip row (`PENP_draw_segs`), AMOUNT, CATCH UP,
    GUIDE LINE and GUIDE CURSOR;
  - SMOOTH PRESSURE, a mode chip row and AMOUNT;
  - a word-wrapped hint for the current mode (`PENP_wrap`).
- **SPEED:**
  - SPEED SCALING, then SLOW / FAST (gain ×100), SPEED (px/s) and SMOOTH;
  - a NOW / AVG / TOP readout;
  - the speed→gain graph (`PENP_render_speed`). It calls `PENC_sync` to plot
    CFG's gains, and marks the last stroke's avg (dashed) and top (red)
    speeds and the live point.

**Docked in a top / bottom row** (`PENP.inRow`), every tab uses the five group
columns:
- column 0 is the tab strip, then a checkbox, then the meter's slot;
- the hint and the graph go in the graph column.

Mode chips use the full labels when they all fit, else the short ones, else
first letters. Disabled chips get a `CP_bg` wash at alpha 150.

`PENP_needs_redraw%` keeps frames non-idle while the meter moves. On the SPEED
tab it does the same while the speed or the last top speed changes. Values
save on slider release and on checkbox / chip / tab click.

QA dumps (DOCK_DUMP):
- `PENPL inRow panelW panelH gx0 gx1 yGraph graphH`;
- `PENPC ctl x0 x1 y tx0 tx1`, for all 24 ctls;
- `PENPT tab tabH hint(x0 y0 x1 y1) graph(x0 y0 x1 y1) readout(x y x1) subX pad`.

The tests are `pen-control-panel.sh`, `dock-row-pen.sh` and
`dock-native-pen.sh`.

Command palette actions 2030-2035 (`PENP_ACT_*`, handled by `PENP_command`):
- Toggle Smoothing;
- Next Smoothing Mode (it also turns smoothing on);
- More / Less Smoothing (±5);
- Toggle Pressure Smoothing;
- Toggle Speed Scaling.

They save the cfg and `STATUS_flash` the new state.

## Stroke filters: `INPUT/STABILIZER.BI/BM` (Lazy Nezumi-style, 2026-11-17)

This is pure math with no DRAW globals: `QA/unit/stab-unit.bas` runs it
headless (39 checks). It is time-based (`TIMER(.001)`), so it behaves the same
at any frame rate.

**`STAB_` position smoothing.** The input is float canvas coords. `MOUSE.FX/FY`
is the sub-pixel position; when grid snap moved `MOUSE.X`, the snapped pixel
centre is used instead (`PENC_fx#/fy#`).
- **Pulled String:** the string is Amount screen px long, so it is
  Amount / zoom canvas px. The point moves only when the string goes taut.
- **Moving Average:** the window is 0.006 s × Amount, measured from the newest
  sample, so the line stays put at rest when Catch Up is off. The ring buffer
  holds 128 samples.
- **EMA:** tau = (Amount/100)² s, with k = 1 − e^(−dt/tau).
- **Inertia:** a damped spring, 14·(1−a)^1.6 + 0.9 Hz with damping 0.55, run in
  1 ms substeps (stable on a 0.25 s frame).
- **Catch Up (MA / EMA only):**
  - while resting, samples are pushed every frame;
  - on lift, `STAB_catch_step%` steps 16 ms at a time (at most 400 steps), and
    `MOUSE_brush_catch_up` paints each new integer point and then the pointer
    pixel.

**`PPROC_` pressure processing.** Applied in `PEN_stroke_pressure!` after the
lift filter and before the curve.
- **Fixed:** Amount %.
- **Sample & Hold:** the mean of the first 1 + Amount\5 samples, then held.
- **MA:** the window is 0.004 × Amount s.
- **EMA:** the same tau as above.

**`PSPD_` speed scaling.**
- The gain is a smoothstep from slowGain to fastGain over 0..fastSpeed, in
  viewport px/s.
- The speed is an EMA with tau = 0.5 × smooth s.
- The gain multiplies pressure, which is then clamped to [PEN_MIN_VALID, 1].
- `PSPD_end` keeps the stroke's avg and top speed for the panel.

**Glue in `INPUT/PEN.BM`** (`PENC_*`):
- `PENC_sync` copies CFG into STAB / PPROC / PSPD.
- `PENC_stroke_begin` runs on a Brush / Eraser press. A Shift smart erase is
  never smoothed.
- `PENC_stroke_step` runs each held frame. It gives the smoothed int point and
  keeps frames live while the point lags.
- `PENC_stroke_end` runs on release, and also in all three document reset
  paths in `DRW.BM`.

In `MOUSE_tool_brush`, a smoothed stroke calls `MOUSE_brush_paint_to sx, sy`.
That sets `MOUSE.OLD_X/Y` from `TABLET.stabDX/DY` and `MOUSE.X/Y` to the point,
runs `PAINT_on`, then restores them, so every brush path (custom, mix, pressure
dabs, symmetry) works unchanged. During catch-up, `PEN_segment_begin` holds the
last pressure and skips the tip threshold.

**Guides.** These are drawn in `SCREEN_render` after `SkipToPointer:` (the
`pcg*` vars):
- a line from the point to `MOUSE.RAW_X/Y`, plus a ring;
- the color is `CFG.PEN_STAB_GUIDE_COLOR`;
- they are drawn only while `PENC_stab_stroke%`.

**Config:**
- `PEN_STAB`, `PEN_STAB_MODE` (1-4), `PEN_STAB_AMOUNT`, `PEN_STAB_CATCHUP`,
  `PEN_STAB_GUIDE_LINE`, `PEN_STAB_GUIDE_CURSOR`, `PEN_STAB_GUIDE_COLOR`;
- `PEN_PROC`, `PEN_PROC_MODE` (1-4), `PEN_PROC_AMOUNT`;
- `PEN_SPEED`, `PEN_SPEED_SLOW` / `PEN_SPEED_FAST` (gain ×100),
  `PEN_SPEED_FAST_AT`, `PEN_SPEED_SMOOTH`;
- `PEN_PANEL_TAB`.

All of them are workspace keys (`WS_panel_keys$`, which raised `WS_MAX_OPTS`
to 384), and all are on Settings → Pen Control (tab 10, `SETTINGS_render_pen` in GUI/SETTINGS-TABS.BM; moved out of General 2026-11-17): sections Pen Tablet, Position Smoothing, Pressure Processing, Speed Scaling. `SETTINGS_jump_mark "Pen Control"` sits at the top of the tab, so `SETTINGS_open_at SETTINGS_TAB_PEN, "Pen Control"` (or `"Position Smoothing"`) opens it there.

**Tests:**
- `pen-smoothing.sh`: Xvfb's pointer drives smoothing, since it works for the
  mouse;
- `pen-control-panel.sh`;
- stab-unit.

Pressure processing and speed scaling need a real pen to judge by feel.

## Brush outline only over the canvas
`POINTER_draw` skips the brush, spray and custom-brush footprint unless
`POINTER_over_canvas%`. The apron counts only while a button is held, because
it has the background color and looked like "off the canvas" on hover.

## Not done yet
- Pen eraser end → Eraser tool.
- Pressure for Dot, Spray and custom brushes.

## Antialiased pen strokes (2026-11-17)

Rick: with AA on, pressure sizes jumped 1 -> 3 -> 5 (whole-pixel circles: radius = size \ 2 around a
pixel center can only be odd) and the 1px tail was a hard PSET line. Now `PEN_opacity_begin` also
starts the per-pixel mask stroke when `CFG.ANTIALIAS%` and a round brush (not the mix brush):
`TABLET.aaPen` / `TABLET.opByP` (opacity follows pressure, else `PEN_dab_op!` = plain Opacity).
`PAINT_on_pressure` then stamps `PAINT_draw_disc_aa` at the dab's fractional center with
`PEN_size_frac!` (any size >= 1; coverage = r + 0.5 - dist) and the mask keeps max coverage, so
soft dabs never compound. This also routes a 1px AA pen stroke through `PAINT_on_pressure`
(the `TABLET.opStroke` branch), which is what makes it soft. AA off keeps the old crisp
odd-size circles. (Mouse strokes too since "AA quality" below.)


## Every pointer event is a stroke point (2026-11-17)

Rick: fast pen strokes came out polygonal. DRAW read the pointer once a frame (the
`_MOUSEINPUT` drain kept only the last position), so a stroke faster than the frame rate
was straight chords between frames - and heavy AA dabs lower the frame rate, making it worse.
Now both drains (`MOUSE_drain_update_state` and DRAW.BAS's late drain) `MOUSE_smp_add` each
event's viewport position; `MOUSE_smp_map` (end of the coordinate block, same zoom / pan /
grid + charmap snap / clamp as `MOUSE.X`; none in pattern-tile or crop) gives the frame's
canvas points `MOUSE_SMP_X/Y/FX/FY/N`, minus repeats and the final point. `MOUSE_tool_brush`
calls `MOUSE_brush_samples` before its final segment (cleared on the press frame): each point
is drawn via `MOUSE_brush_paint_to`; with smoothing on, each goes through `STAB_step` at a time
spread between `TABLET.stepT` and now. Pressure is read once per frame and shared over the
pieces (`TABLET.subN / subK / subFrom / subTo` in `PEN_segment_begin`). Brush / Eraser only
(mouse too). Speed-ups: `PEN_op_write` returns early when the mask already has that coverage
(most of every overlapping dab); AA pen dabs step 0.63 x sqrt(radius) (>= 0.5px).
Test `brush-fast-stroke` (a 72-point circle burst at FPS_LIMIT=6: the old build drew a triangle).


## AA quality: mouse strokes, sub-pixel path, straight-alpha blend, thick lines (2026-11-17)

Rick: "our anti aliasing algorithm is pretty shitty". Four faults, measured with
`QA/tests/brush-aa-quality.sh` (coverage map = (after - before) / (1 - before) from white
paint over the checkerboard; the old build's soft-pixel count was a third of the new one's):
1. **Mouse AA strokes stacked soft circles** (`PAINT_draw_filled_circle_aa` with `_BLEND` at
   every pixel along the stroke): rims built up into a hard edge. `PEN_opacity_begin` now starts
   the mask stroke for AA without a pen (`aa% = 0 _ANDALSO NOT PEN_active%` exits), so mouse
   strokes take the `aaPen` path too (dabOp = plain Opacity; 1px non-pixel-perfect = soft line).
2. **Whole-pixel path**: stroke points were `MOUSE.X` integers. Now the exact point rides along:
   `PEN_aa_target fx, fy` (MOUSE.FX terms; stored minus 0.5 = pixel-centre coords) set before
   every `MOUSE_brush_paint_to` / `PAINT_on` in the brush hold path, samples and catch-up
   (`STAB.x` when smoothing, `MOUSE_SMP_FX`, `PENC_fx#`); `PAINT_aa_segment` uses it (cleared
   on use, in `PEN_segment_end`, on a tip-threshold skip and under CONSTRAIN_X/Y). Samples and
   `MOUSE.FX` now keep window-pixel precision: `MOUSE_smp_add` takes `_MOUSEX` (window px), and
   `MOUSE.FX = ((WIN_X + .5) / displayScale - dx) / zoom` when WIN_X \ ds = rawX - at display
   scale 2 a canvas px at 100% has 2 positions per axis.
   Path smoothing: midpoint quadratics (`PAINT_aa_segment` -> `PAINT_aa_curve`): last point P,
   drawn-to point M; a new point Q draws M -> ctrl P -> (P+Q)/2. Stroke start = a single dab;
   a segment whose start is > 1.5px from P restarts. `PAINT_aa_finish` (MOUSE_release_brush,
   after catch-up, before PEN_opacity_end) draws the last half M -> P. Dab step uses the curve's
   max speed 2*max(|C-P0|, |P1-C|).
   `PAINT_draw_disc_aa` reads the mask before calling `PAINT_blend_pixel_sym` (no symmetry):
   pixels the stroke already covers as strongly are skipped.
3. **QB64 `_BLEND` darkens on a transparent pixel**: half-coverage white over (0,0,0,0) gives
   (127,127,127,128) - every soft edge on an empty layer got a dark fringe (probe, Linux).
   `PAINT_blend_pixel`'s partial-coverage branch now does straight-alpha source-over in
   `PAINT_cover_over` (POINT + `_DONTBLEND` PSET). Affects every AA write: Wu lines, ellipse,
   poly-fill edges, stamps. Full coverage and AA-off stay the verbatim PSET; a transparent
   color's partial write is unchanged.
4. **Thick AA shapes** stamped soft circles along Bresenham (stair steps in the edge, rims
   compounding). `LINE_draw_brushed` and `SS_stroke_line` draw `PAINT_aa_capsule` when
   `PAINT_aa_thick_line%(col)` (AA, round, size > 1, visible color, no custom brush): exact
   distance-to-segment coverage, r = size / 2. Soft stamps (`PAINT_AAM_USE`: the capsule and
   `PAINT_stamp_size` / `PAINT_on`'s AA circles) go through `PAINT_aam_write`, a per-frame
   coverage mask (`PAINT_AAM_*` in BRUSH.BI, freed by `PAINT_aam_end` at LOOP_start): with m the
   coverage already laid there this frame and e the new, it composites the share
   (e - m) / (1 - m), so a rectangle's sides / a polyline's pieces join without rims adding.
