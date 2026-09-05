# Hardware cursor — render benchmark

Measures the CPU/render win of the OS hardware cursor (`_MOUSECURSOR`, feature
`feat(cursor)` on branch `glfw-tests`) vs the software cursor, for a mouse-move
over the canvas.

## Why an in-app benchmark

GUI automation (xdotool) proved **unreliable** for this: on the GLFW backend,
key chords like `Ctrl+Shift+N` misfire as `Ctrl+N`, opening the **New Canvas**
modal, which then captures every subsequent keystroke — so tools never switch,
layers aren't added, and the measured state is garbage (an early xdotool run
reported a bogus "43×"). Screenshots of a GLFW window are also unreliable.

So the benchmark runs **in-process**: it builds the scene by calling
`LAYERS_new%()` directly (no dialogs) and times the actual render paths. Fully
deterministic, no GUI driving.

## Running it

Built with a `_MOUSECURSOR`/`_UPTIME`-capable compiler (GLFW build, PR #701; the
code is behind `$LET HWCURSOR`). Runs offscreen — the numbers are render-path
timings, not cursor visuals.

```bash
# N = number of semi-transparent content layers (default 20)
xvfb-run -a -s "-screen 0 1600x1000x24" ./DRAW.run --config QA/DRAW.qa.cfg --bench-render 20
```

It stacks N content layers, warms the caches, then times 300 iterations of each
render path a canvas mouse-move can take and prints to the console:

- **[soft]** software-cursor move — full path (`SCENE_DIRTY=TRUE`, as forced by
  [DRAW.BAS:606](../DRAW.BAS#L606)); layer merge cached.
- **[hw]** hardware-cursor move — cached skip (`SCENE_DIRTY=FALSE`, the
  `SkipToPointer` re-blit that `POINTER.HW_ICON_ACTIVE%` enables).
- **[full]** worst case — forced full layer re-merge (`COMPOSITE_RESULT_VALID=FALSE`).

Implementation: `BENCH_render_run` in [CORE/PERF.BM](../CORE/PERF.BM), invoked from
[DRAW.BAS](../DRAW.BAS) when `--bench-render` is present.

## Results (2026-08-19, Linux/GLFW build, Xvfb 1600×1000)

```
=== 20 content layers, 300 iters/path ===
  [soft] software-cursor move (full path, merge cached): 11ms   (89 fps)
  [hw]   hardware-cursor move (cached skip)            : 4.8ms  (206 fps)
  [full] worst case, forced full layer re-merge        : 11ms   (89 fps)
  --> hardware vs software per move: 2.32x   saves 6.3ms/frame
```

Sweep across scene weight:

| Layers | 1 | 10 | 20 | 40 | 80 |
|--------|-----|-----|-----|-----|-----|
| hw vs soft | 2.36× | 2.32× | 2.32× | 2.39× | 2.25× |
| saved/frame | 6.6ms | 6.4ms | 6.3ms | 6.6ms | 6.3ms |

### Interpretation

- **~2.3× cheaper per canvas mouse-move (11ms → 4.8ms), a flat ~6.5ms/frame saved.**
- The win is **constant, not layer-scaled**: `[soft]` == `[full]` (both ~11ms)
  shows the layer merge is already cached across cursor-only moves — the saving is
  the fixed full-path overhead (GUI recomposite + scene-cache save + present) that
  the hardware path skips.
- At the 240 fps cursor rate, that ~6.5ms/frame is real CPU: the software cursor
  keeps a core busy just to reposition a pointer; the hardware cursor hands that to
  the compositor.

### Further headroom (not yet implemented)

The current change keeps rendering the cheap cached path at the cursor FPS cap on
every move. A larger win is possible by **reducing the frame rate itself** on
hardware-cursor moves (the OS moves the cursor, so 240 fps isn't needed) — e.g.
dropping to the idle rate. That trades live status-bar coordinate updates for a
much larger CPU drop, and is a follow-up worth discussing.
