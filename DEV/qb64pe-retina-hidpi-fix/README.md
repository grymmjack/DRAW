# QB64-PE Retina/HiDPI fix for modern macOS

**TL;DR** — DRAW (and *every* QB64-PE graphics program) renders blurry on Retina Macs
running anything **newer than macOS Catalina**. The bug is in QB64-PE's runtime
(`internal/c/libqb.cpp`), not in DRAW. This folder contains the one-line-logic fix as
an apply-able patch, plus the full investigation below so the QB64-PE (Phoenix) team has
everything in one place.

- **Patch:** [`retina-hidpi-modern-macos.patch`](retina-hidpi-modern-macos.patch)
  — applies to the **QB64-PE** repo (`internal/c/libqb.cpp`), *not* DRAW.
- **Scope:** upstream QB64-PE runtime → affects all QB64-PE graphics programs on macOS.
- **Platform observed:** `[macOS]` MacBook Pro, Liquid Retina XDR, macOS 26.5.1
  (Darwin `kern.osrelease 25.5.0`). Untested on Linux/Windows (the changed code is
  inside `#ifdef QB64_MACOSX`, so those platforms are unaffected by design).

> **Note on DRAW-side sizing:** the patch below is the only change being shared. An
> attempt to also auto-adjust DRAW's display/toolbar scale on Retina was abandoned —
> it exposed a separate DRAW chrome-render bug at `displayScale=1` (left toolbar /
> brushes / palette draw black) and was fully reverted. Only the upstream libqb
> crispness fix is recommended here.

---

## Symptom

On a Retina Mac the whole program window looks soft/blurry. The tell: the **native
macOS title bar is razor-sharp**, while the program's own content (menu text, toolbar
icons, pixel art) immediately below it is **fuzzy**. That means the OpenGL content is
being drawn at *logical* resolution and then bilinear-stretched by the macOS window
server up to the 2× Retina backing store.

Catalina (macOS 10.15) was, by accident, the *only* version that rendered crisply.

---

## How we found it (investigation trail)

### 1. Establish the display facts

`system_profiler SPDisplaysDataType` reported the panel as **3456 × 2234 Retina**.

A tiny QB64-PE probe (created a known 800×500 window, then printed the runtime's view)
returned:

```
requested window : 800 x 500
_WIDTH(0)        = 800       <- QB64 reports LOGICAL pixels, not the 1600 backing
_HEIGHT(0)       = 500
_PIXELSIZE       = 4
_DESKTOPWIDTH    = 1728      <- exactly HALF of the 3456 physical panel
_DESKTOPHEIGHT   = 1117      <- exactly HALF of 2234
```

**Conclusion:** on macOS Retina, QB64-PE works entirely in *logical points* (1728×1117
= the panel ÷ 2). It never sees physical pixels. So crisp rendering depends on the
runtime telling OpenGL to draw into the 2× backing store — which is exactly the code
path that turned out to be broken.

### 2. Prove the blur with a native-pixel capture

A screenshot of a running QB64-PE app was captured at the true backing resolution
(`3424 × 1984` physical px). Cropping a 1:1 region of the top-left:

- the macOS-drawn title bar text was **crisp**;
- the program's own menu text and toolbar icons directly beneath were **visibly blurry**.

That side-by-side (sharp native chrome vs. fuzzy GL content in the same image) is the
signature of a logical-resolution render stretched to a 2× backing.

### 3. Locate the cause in the QB64-PE runtime

The blur happens below the BASIC layer, in `libqb`'s 2D OpenGL viewport setup
(`internal/c/libqb.cpp`, in the `render_state.dest_handle == 0` / `VIEW_MODE__2D`
branch):

```cpp
glViewport(0, 0, dst_w * scale_factor, dst_h * scale_factor);
```

On a 2× Retina display the default framebuffer's backing is `2*dst_w × 2*dst_h` physical
pixels, so `scale_factor` must be `2` for GL to fill it 1:1. The detection code only set
it when:

```cpp
std::string sz_osrelease(str);          // str = kern.osrelease, e.g. "25.5.0"
if (sz_osrelease.rfind("19.") == 0)     // matches Darwin 19.x == Catalina ONLY
    scale_factor = 2;
```

`kern.osrelease` major numbers per macOS:

| macOS | name | Darwin `kern.osrelease` | matches `"19."`? |
|------:|------|:-----------------------:|:----------------:|
| 10.15 | Catalina | 19.x | ✅ (crisp) |
| 11 | Big Sur | 20.x | ❌ blurry |
| 12 | Monterey | 21.x | ❌ blurry |
| 13 | Ventura | 22.x | ❌ blurry |
| 14 | Sonoma | 23.x | ❌ blurry |
| 15 | Sequoia | 24.x | ❌ blurry |
| 26 | Tahoe | 25.x | ❌ blurry |

On the test machine (`25.5.0`) the test is false → `scale_factor` stays `1` → GL renders
into the logical-sized region → window server stretches it 2× → blur. Confirmed directly:

```
$ sysctl -n kern.osrelease      # -> 25.5.0
$ case "$(sysctl -n kern.osrelease)" in 19.*) echo crisp;; *) echo BLURRY;; esac
BLURRY
```

### 4. Two latent bugs spotted in the same block

- `bool b_isRetina, b_is5k;` are **read uninitialized** (undefined behavior) — they are
  only assigned inside `if (!b_isRetina)` / `if (!b_is5k)` guards.
- `int ret = sysctlbyname(...)` — `ret` is unused.

---

## The fix

See [`retina-hidpi-modern-macos.patch`](retina-hidpi-modern-macos.patch). Logic change:

```cpp
bool b_isRetina = false, b_is5k = false;   // initialize (was UB)
...
sysctlbyname("kern.osrelease", str, &size, NULL, 0);   // drop unused `ret`
if (atoi(str) >= 19)                        // Catalina-AND-NEWER, not Catalina-only
    scale_factor = 2;
```

### Why hardcode `2` instead of computing physical ÷ logical?

macOS `backingScaleFactor` is `2.0` on **every** current Retina Mac — that is precisely
what the GL drawable uses, independent of the user's "scaled resolution" choice. In a
"More Space" mode (e.g. a 3456 panel set to "looks like 1496"), macOS still renders at
2× logical and GPU-downscales to the panel; the backing scale is still 2.0. Computing
`physical(3456) ÷ logical(1496) = 2.31` would therefore *over*-scale the viewport and be
wrong. `2` is correct. A maximally general implementation would read the window's actual
`backingScaleFactor` via Cocoa (`[[window screen] backingScaleFactor]`), which is more
robust for multi-display / window-move and any future non-2× panels, but is far more
invasive and yields the same `2` on all hardware tested here.

### Known limitation (pre-existing — not addressed by this patch)

`scale_factor` is computed once (`static`, guarded by `scale_factor == 0`). Drag the
window onto a non-Retina external display (backing scale 1.0) and it will not re-detect,
so content would render into the top-left quarter. This was already true in the
Catalina-only code; fixing it requires re-querying the backing scale on display/move
events — a larger change worth a separate issue.

---

## How to apply, rebuild, and verify

The patch targets the **QB64-PE** checkout (e.g. `~/git/qb64pe`), not DRAW.

```bash
# 1. Apply to the QB64-PE repo
cd ~/git/qb64pe
git apply /path/to/DRAW/DEV/qb64pe-retina-hidpi-fix/retina-hidpi-modern-macos.patch
#   (or:  patch -p1 < .../retina-hidpi-modern-macos.patch)

# 2. Rebuild QB64-PE's C runtime (regenerates the cached libqb object).
./setup_osx.command norun        # make OS=osx clean + full rebuild, no IDE launch

# 3. Rebuild your program with a purge so the patched libqb is linked in:
qb64pe -w -x -p -o myprog myprog.bas

# 4. Verify: run a graphics program, screen-capture at native backing resolution,
#    crop 1:1. Program text/icons/pixel art should now be as sharp as the macOS
#    title bar (no bilinear softening).
```

**Expected result after the fix:** `scale_factor = 2`, `glViewport` covers the full
`2*dst_w × 2*dst_h` backing, GL renders 1:1 into physical pixels, and the OS no longer
stretches the frame — crisp on all macOS ≥ Catalina.

---

## Recommendation for the Phoenix team

This is an upstream QB64-PE runtime bug affecting **all** QB64-PE graphics programs on
modern macOS, not just DRAW. Worth landing in QB64-PE proper, and ideally replacing the
`system_profiler` popen + `kern.osrelease` heuristic with a real Cocoa
`backingScaleFactor` query that also handles multi-display / window-move.
