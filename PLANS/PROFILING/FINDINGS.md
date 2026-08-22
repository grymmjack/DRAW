# DRAW full-suite profiling — empirical findings

**Method:** DRAW built with `-pg` (gprof) via a `g++` wrapper; a `DRAW_GMON` env gate installs
a `SIGTERM→exit(0)` handler so gprof flushes `gmon.out` when the QA harness kills each
instance; `GMON_OUT_PREFIX` gives one profile per process. Ran the **full `draw-qa` suite**
(184 tests, `--rerun-passed`), collected **187 gmon profiles**, merged with `gprof -s`.
Suite result: 1524 passed / 7 failed / 1 skipped. Raw data: `full-suite-flat.txt`,
`full-suite-callgraph.txt`. Reproducible — re-run for any before/after.

This replaces estimation with measurement. Several conclusions overturn earlier hunches.

## Where CPU actually goes (self-time, whole suite)

| self-time | function | class |
|---|---|---|
| **~72%** | `Opal::*` + `OPLPlayer::updateMIDI` | QB64 audio backend's **OPL3 MIDI synth thread** (see caveat) |
| **17.3%** | `sub__putimage` | QB64 blit built-in (render) — dominant DRAW render cost |
| ~3.3% | `qbr_double_to_long` + `qbr_float_to_long` | QB64 `-O0` double→int tax |
| ~2.3% | `qb32_boxfill` | QB64 fill built-in |
| <0.5% each | all DRAW pixel/gradient functions | — |

**Audio caveat (important — do not over-read the 72%):** music is `MUSIC_ENABLED=FALSE`
in both the QA and factory configs, and sound effects are `.wav` samples, not MIDI. The
`Opal`/`OPLPlayer` frames have **no caller** in the graph — they run on QB64-PE's audio
*thread*, which instantiates and updates the OPL3 MIDI synthesizer continuously once the
audio device is initialized, regardless of whether DRAW plays anything. gprof aggregates
all threads by CPU-time, and the QA suite spends most of its wall-time in `wait_for` idle
sleeps (main thread asleep), so the audio thread's *share* is heavily inflated. The real,
testable takeaway is narrower: **QB64's audio backend burns background CPU synthesizing
silence when the device is open** — worth checking whether the device must stay open, or
the MIDI synth can be disabled when unused. It is *not* "72% of DRAW's rendering work," and
it is not a DRAW-code kernel target.

**The pixel-effect kernels already migrated (blur/blend/median/…) are correct for those
operations but a *tiny* fraction of real self-time.** Among DRAW's *own* code, `_PUTIMAGE`
(blits) and the GUI-chrome gradient fills below are the real costs — neither is a
`DECLARE LIBRARY` pixel-kernel candidate.

## Where the CALLS go (exact counts, whole suite)

| calls | function |
|---|---|
| 462,709,883 | `_ALPHA32` |
| 456,226,051 | `_RED32` (≈ same for `_GREEN32`/`_BLUE32`) |
| 236,384,305 | `_RGBA32` |
| **143,812,554** | `GRAD_DEF_EVAL_COLOR` |
| 143,812,554 | `DRAWER_GRADIENT_EVAL_T` |
| 143,812,550 | `GRAD_DEF_EVAL_OPACITY` |
| 143,812,539 | `GRAD_WITH_STOP_ALPHA` |
| 142,425,623 | `DRAWER_GRADIENT_LERP_COLOR` |
| 108,356,974 | `func_sqr` |

**Call-graph trace (corrected — the GUI chrome is NOT gradient-filled; it uses flat
colors).** `GRAD_DEF_EVAL_COLOR`'s 143,812,554 calls come **100% from
`GRAD_DEF_rebuild_preview`** (`GUI/DRAWER.BM:780`), which renders a gradient slot's
**128×128 preview swatch** pixel-by-pixel (16,384 gradient evals per rebuild). 8,778
rebuilds × 16,384 = 143.8M. The rebuilds are driven by `DRAWER_render → DRAWER_ensure_samples`
(`GUI/DRAWER.BM`), whose guard is:

```
colorsChanged% = (DRAWER_GRADIENT_LAST_FG~& <> PAINT_COLOR~&) OR (DRAWER_GRADIENT_LAST_BG~& <> PAINT_BG_COLOR~&)
IF samplesLoaded% AND NOT themeChanged% AND colorsChanged% THEN
    FOR i% = 1 TO DRAWER_SLOT_COUNT : GRAD_DEF_rebuild_preview i% : NEXT   ' rebuilds ALL 16 slots
```

**Root inefficiency:** on *any* FG/BG color change it rebuilds **every** gradient preview
swatch — including slots whose gradient does not reference FG/BG. Color changes are
frequent (every palette click / picker), and the QA suite changes colors constantly, so
this dominates DRAW's call volume. Each pixel calls 5 gradient fns + `_RED32/_GREEN32/
_BLUE32/_ALPHA32`, which is why the channel built-ins reach ~456M calls.

**Fix (algorithmic, not a kernel):** rebuild only the slots whose gradient actually
references FG/BG on a color change (a per-slot `usesFgBg%` flag set when the definition is
built). That removes the large majority of the 143M evals. A C gradient-eval kernel would
also help the remaining rebuilds, but the over-rebuild is the real waste.

## Per-frame render census — "what renders every frame uncached?"

44,378 total render passes. Call counts from the `SCREEN_render` subtree:

| render sub | calls | runs on | note |
|---|---|---|---|
| `RENDER_GUI_ELEMENTS` | 8,650 | ~19% dirty frames | holds the gradient-preview rebuilds |
| `DRAWER_RENDER` | ~4,765 | gated | gradient/brush/pattern drawer |
| `CRT_RENDER` | 8,649 | ~19% dirty frames | bake cached; per-frame overlay composite ~0.75ms |
| `RENDER_LAYERS` | 8,649 | ~19% dirty frames | the composite path (blend kernel lives here) |
| `TRANSPARENCY_RENDER` | 8,649 | ~19% dirty frames | checkerboard |
| `PREVIEW_RENDER` | 44,333 | **every frame** | cheap early-out when closed |
| `POINTER/TOOLTIP/COLORMIXER/REGION_CLEAR/crash-toast` | ~44,377 | **every frame** | cheap early-outs |

**Verdict: the expensive renders are already dirty-gated to ~19% of frames — DRAW's frame
caching is good.** The things that run literally every frame are cheap early-outs. The only
standout waste is the gradient-preview over-rebuild (event-driven, all-slots). `CRT_RENDER`
(largest gated cost) is worth confirming it is a straight overlay blit.

## Data-driven verdict (what to actually do)

The real levers are **architectural**, not more per-pixel kernels:

1. **Sound synthesis is the #1 CPU cost (~72%).** Investigate whether the OPL synth runs
   (and burns CPU) while nothing is audibly playing — `MUSIC_tick` is called every frame
   (`DRAW.BAS:544`). If it synthesizes silence, gating it when idle is the single biggest
   CPU win in the app. Orthogonal to pixels; nothing to do with the kernel work.
2. **Stop over-rebuilding gradient preview swatches** (the biggest DRAW-code call volume).
   `DRAWER_ensure_samples` rebuilds all 16 128×128 preview swatches on every FG/BG color
   change; only slots whose gradient references FG/BG need it. A per-slot `usesFgBg%` flag
   removes most of the ~143M gradient evals + a big share of the ~456M channel-op calls.
   The GUI chrome itself is flat-colored — it is NOT gradient-filled (earlier draft wrong).
3. **`_PUTIMAGE` volume (17%)** is architectural (fewer/smaller/region blits), not kernelizable.
4. The pervasive `-O0` tax (`qbr_*`, `array_check` at ~122M calls, per-pixel `_RED32` etc.)
   only goes away wholesale with a whole-program move to C++/Rust — the earlier discussion.

**Bottom line:** further `DECLARE LIBRARY` pixel kernels have diminishing returns against
real usage. The measured wins are: idle the sound synth, fix the gradient-preview
over-rebuild, reduce `_PUTIMAGE` volume.
