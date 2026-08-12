---
name: qa-relaunch-offscreen-trap
description: layer-group-auto-layer offscreen failure — FIXED via openbox-in-Xvfb + opt-in draw_settle (mid-relaunch + no WM + no _NET_WM_PID)
metadata:
  type: project
---

[Linux] **FIXED 2026-08-12** (qa-harness `8b863b4`). The QA test
`layer-group-auto-layer` (a mid-file `draw_quit; draw_launch` that relaunches
with a BLANK doc) failed offscreen (Xvfb) but passed onscreen. Full write-up in
qa-harness `ARCHITECTURE.md` ("No window manager offscreen — the
mid-test-relaunch trap").

**The fix (two parts):**
1. `driver_run_offscreen` starts **openbox inside the Xvfb** (bundled undecorated
   `drivers/linux-x11/openbox-rc.xml` keeps geometry pixel-identical). Supplies
   focus like a real desktop. Toggle `QA_OFFSCREEN_WM=none`.
2. New adapter helper **`draw_settle`** (blocks until no "DRAW v" window remains).
   The blank-relaunch test calls `draw_quit; draw_settle; draw_launch` — DRAW-side
   change in `QA/tests/layer-group-auto-layer.sh`. Opt-in, NOT baked into
   `draw_quit`: forcing every quit to wait breaks `file-draw-roundtrip`'s Ctrl+S
   (DRAW startup is sensitive to the quit→launch overlap; a file-loading relaunch
   is slow enough not to need the settle and must keep the overlap).

**Mechanism:** `xvfb-run` runs a bare X server with **no window manager**, so a
dying DRAW window is not reaped promptly. DRAW/SDL2 sets **no `_NET_WM_PID`**, so
`xdotool search --pid <PID> --name "DRAW v"` silently does NOT filter (a bogus
pid still matches — verified with pid 999999). So a mid-test relaunch's title
search can bind the **previous instance's still-mapped window** (stale wid →
mis-parked dead window → every click/key misses the canvas → "regions are
identical"). It's a **race**: slow relaunches (loading a file, e.g.
`file-draw-roundtrip`) let the old window die first and bind correctly; fast
blank relaunches (`layer-group-auto-layer`) race the dying window and bind stale.

**Why it can't be fixed at the harness level:** every fix that forces the old
window gone before the relaunch (draw_quit SIGTERM-wait, SIGKILL, fixed sleep,
config re-assert, draw_launch new-window-id detection, windowunmap) **fixes
layer-group but deterministically breaks `file-draw-roundtrip`'s Ctrl+S save**
(baseline 3/3 pass → change 3/3 fail). Ruled out as the roundtrip cause: config
clobber (re-assert didn't help), keyboard focus (correct: getwindowfocus ==
DRAW_WID), window binding (load+edit succeed). DRAW's own startup is **sensitive
to instance-death timing** — the incoming instance's first Ctrl+S needs the
outgoing instance to still be alive during startup. The two relaunch tests want
opposite things from the quit→launch overlap. Adapter left at committed baseline.

**Confirmed harness fact:** DRAW's `CONFIG_save` on graceful exit (ctrl+q →
action 212 → `MAIN_shutdown`, [DRAW.BAS:914]) **rewrites the whole `--config`
file** (737-line commented default → ~290 canonical lines). This is why
`adapter_ensure_config` must re-assert on every launch, and a confound when
reasoning about relaunch config state.

**Clean fixes (future):** (a) run a lightweight WM (`openbox &`) inside the Xvfb
session — none installed on this box as of 2026-08-12; or (b) QB64/SDL2 set
`_NET_WM_PID`. Until then: **run these tests with `--onscreen`** (real WM reaps
the dying window instantly — which is why the pre-toolkit harness passed them
10/0). See [[qa-harness-toolkit]], [[deliver-viewables-as-artifacts]].
