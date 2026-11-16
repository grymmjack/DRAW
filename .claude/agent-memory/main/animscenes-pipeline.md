---
name: animscenes-pipeline
description: How the animated example scenes (SAMPLES/ANIMSCENES) and clip projects (ANIMPROJECTS) are built - Python art + audio, DRAW drives the Move Brush under the QA harness; the gotchas it hit (QA-OPTIONS beat --option, save race, dump cost)
metadata:
  type: project
---

[Linux, 2026-11-12] DEV/animscenes/ builds each scene: `scenes/NAME.py OUT` makes the art (kit.py on
DEV/animbrush-pack/make-pack.py), the AnimBrush pack (.dset + brushes/ strips with drAn), the base
PNG with frames, keys.sh (tint-key pixels) and moves.sh, and the WAVs (audio.py: soundmon CPU
engines + pure-Python synth + a frame-timed mixer). `build.sh NAME...` then runs
run-scene.sh as a QA test so DRAW itself builds the scene: `mv X0 Y0 X1 Y1 key=val` in drive-lib.sh
starts the Move Brush, taps RESET, drags the path, TYPES exact values in the Move boxes, reads
them all back from MVBV and checks the stamp by ANIMC. `publish.sh NAME` copies to SAMPLES.

Gotchas it hit:
- **QA-OPTIONS win over DRAW_EXTRA_ARGS `--option`** (the harness passes them as `--option` after
  yours): a test that needs a different value must leave that key out of QA-OPTIONS.
- **Saving a big sheet is not instant**: DRW_save writes the flat PNG first, then deflates every
  layer into the drAw chunk. A 64-frame 1280x960 sheet with 14 layers takes seconds; quitting
  DRAW after a fixed 2.5 s wait left a flat PNG with no drAw / drAn (and the batch GIF export
  then wrote one still frame). Wait until `pngchunks.py FILE drAw drAn` passes.
- **The per-frame QA dump was O(n^2)** on big sheets (ANIMC string appends + MVB scans): the
  command palette stuck open. Fixed in a705df2b (preallocated, cached on a scene signature).
- The Move Brush press must be inside the frame; an end off-frame is dragged to the edge and the
  exact delta typed after. Values persist between Starts - tap RESET first.
- **Picking a colour leaves the PICKER tool on**: after `fg_key` the next "stamp" clicks just
  picked colours and nothing landed (dungeon run 1). `fg_pick` now presses B after. Put every
  plain stamp before the first Move Brush in a scene script.
- Box limits: EVERY 1-12 (a script asking 20 is rejected), SIZE 1-999, Z -250..5000,
  TURN +-3600, OPACITY / TINT 0-100. The harness kills a test at 600 s unless it has
  `# QA-TIMEOUT: <s>` (run-scene.sh has 7200 since the projects: ~2 min per clip, a 25-clip
  project runs over an hour).
- **GIF over 256 colours** (tints, fades, soft glows): the exporter used to snap every pixel to
  the document palette, so the space planet came out teal / grey. Since 2026-11-12 it builds an
  adaptive median-cut table of the frames' own colours (`ANIM_MC_palette%`, TOOLS/ANIM-EXPORT.BM)
  unless colour cycling is on (then it must stay on the palette). QA: file-anim-gif.sh RMSE check.
- SA3 (GPU audio) on the rtx ComfyUI gives static unless that server runs --force-fp32; the
  scenes use soundmon's CPU engines instead.

**Projects (SAMPLES/ANIMPROJECTS, 2026-11-12, [Linux])** - clip-lib.sh on top of drive-lib.sh drives
clips + lanes through the command palette and the Animation panel's boxes. Learned:
- **Every placed clip gets its OWN source** (CLIP_src_from_ab, no dedupe). "Many clips of one
  source" = switch each later clip with Next Clip Source (`share NAME`), then Remove Unused Clip
  Sources (pj_finish does). Clip SOUNDS live on the source: shared clips share them, so add a
  sound once per source or it doubles.
- **The dock dump can lag one step** behind a palette command: a stepper that reads it right
  away overshoots (lane / modulator / ease cycled past the target, other lanes got modulators).
  `step_cmd CMD STATE-FN` waits until the state changes.
- **[Linux/Xvfb] typed keys get DROPPED under load** (11 of 35 at the harness's 30 ms/key in a
  20-clip project), and the shortened query can still match - ANOTHER command ("clip layer: mode
  on" = Mode Ping-Pong). The dump's `CMDPAL searchLen results hover name` (palette open) lets
  cmd() check searchLen == the query before Enter; drive-lib types at 75 ms and retypes slower.
- CLIPLM `kind shape ...`: noise is kind 2 (shape stale) - test kind, not just shape.
- Make Clip from Selected Frames gives IN..OUT = the made frames: set OUT for a longer life.
- A clip with X / Y keys is keyed by Ctrl+arrows in the lightbox (CLIP_move_by auto-keys).
- Cue / soundtrack paths are absolute but resolve by name beside the .draw (ANIM_SND_resolve$),
  so publish copies every WAV next to it.
- pgrep -f / pkill -f with a pattern that is also in your own command line kills or waits on
  yourself; zsh does not word-split `$P` for kill. Use `[b]uild.sh` greps and explicit PIDs.
- [Linux] If DRAW dies mid-build the driver keeps typing into nothing: every step then FAILs with
  "palette was still open" / a stale dump. Check `ps` for DRAW-swm.run, then
  `/tmp/draw-qa-console.log` (DRAW's stdout: "runtime error N in FILE:LINE", "21 runtime errors --
  not survivable") and the crash report in DRAW-log/DRAW-crash-logs. 2026-11-12 the farm build
  found Bake Clip to Pixels + X-sheet LANES row -> CLIP_INST(0) (fixed 26a9ef92).

See [[qa-driving-draw-reliably]], [[project-animation]].
