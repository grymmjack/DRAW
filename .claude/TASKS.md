# Effect Parameterization Pass — branch `more-image-effects`

Goal (from Rick, 2026-08-15): make the Eye Candy effects **richer / more properly
parameterized like Photoshop's Layer Style dialogs** (the Bevel & Emboss dialog he
sent has Style/Technique/Depth/Direction/Size/Soften/Angle/Altitude/Opacity + a
**Reset to Default** button), and follow the manual's adjustment conventions
(live preview ✓, mouse-wheel sliders ✓, alpha preserved ✓, single-Ctrl+Z undo ✓ —
already followed). Also **document the EFFECTS menu in the manual**.

Widget system (GUI/DIALOG.BM): sliders (`DIALOG_slider_drag%/_wheel%/_draw_slider`),
toggles (`DIALOG_draw_toggle` + `DIALOG_hit%`), buttons (`DIALOG_draw_button`),
labels, dividers. No native color-picker/angle-dial/dropdown — use extra sliders
(ANGLE 0-359, ALTITUDE 0-90), toggles (DIRECTION up/down), and FG/BG colours
(`PAINT_COLOR~&` / `PAINT_BG_COLOR~&`). Taller dialogs: bump `DIALOG_init`
height and use `IMGDLG_track_y%(ctx, idx)` for idx 2,3.

Each box = engine/dialog change → build clean (0 warnings) → QA guard (dialog title
+ region differs) → commit. Grep action IDs before allocating (gotcha #17; SHAPE
2230-2260, TEXTURE 2270-2299, EXPORT 2201-2216, ACTION_SETTINGS 2100 are taken).

## 🔨 NOW — doing right now

(nothing in progress)

## Wave P1 — Reset-to-Default button (universal, Rick boxed it)

- [x] **RESET infra** — shared `IMGDLG_RESET_CLICKED%` flag + "RESET" button in the
      OK/RESET/CANCEL bar (`IMGDLG_draw_ok_cancel` + hit-test in `IMGDLG_check_ok_cancel`),
      helpers `IMGDLG_reset1/2/3/4`, flag cleared on every dialog open in setup_preview
      (no cross-dialog leak). Verified: RESET button renders on all dialogs (Fire shot);
      restores defaults on Bevel.
- [ ] **Wire RESET into every effect dialog** — for each `IMAGE_ADJ_*_dialog`, add
      `DIM dN : dN% = <default>` beside each param and one `IMGDLG_resetN` call in the
      loop. Do it in batches by file region; re-run the full effect QA suite after.

## Wave P2 — Relief / light effects get an ANGLE (Photoshop-authentic)

- [x] **Bevel** — added LIGHT ANGLE (0-359, 8-direction, default 135) + DIRECTION (Up/Down)
      toggle + RESET. Engine `IMAGE_ADJ_bevel&(...,angleDeg,direction)` derives the light
      neighbour offset from cos/sin; Direction flips relief. Dialog verified via SHAPE path
      (shape-bevel-dialog: HEIGHT/STRENGTH/LIGHT ANGLE/DIRECTION/RESET all render).
      NOTE: effect-bevel.sh (open_effect 2 2) FALSE-PASSES — low-category harness nav flake
      (child click misses the flyout). Bevel navigates fine via SHAPE child 3. Harness nav
      for categories 0-6 needs the same caty audit as the title-assert follow-up.
- [x] **Emboss** — added LIGHT ANGLE (0-359, 8-direction, default 135) + RESET; engine derives the luminance-gradient neighbour from the angle. Same verified pattern as Bevel (only in STYLIZE cat 1 so QA is build-clean; low-cat harness nav flaky).
- [x] **Chrome** — SKIPPED: Chrome's metallic look is a RADIAL distance-to-edge |sin| band map, not a directional lit surface, so a light angle doesn't fit the algorithm naturally. Left as DEPTH + FG/BG ramp.
- [x] **Drop Shadow** — Photoshop trio done: DISTANCE (0-30) + ANGLE (0-359, default 315
      = down-right) + SOFTNESS (0-8) + OPACITY (0-100) + RESET. Engine offsets the
      silhouette by cos/sin(angle)*distance and scales its alpha by opacity. Dialog
      verified via SHAPE child 8 (probe: all 4 sliders + RESET render).
- [x] **Perspective / Long Shadow** — added CAST ANGLE (0-359, default 315 = down-right)
      + RESET; engine scans back along -cast (cos/sin(angle)) instead of the fixed up-left
      diagonal, with full bounds checking. Dialog retitled "PERSPECTIVE SHADOW". SHAPE child 9.

## Wave P3 — Texture / overlay effects get a MIX (blend with original)

- [x] **MIX slider on 8 texture effects** — Wood, Marble, Brick Wall, Brushed Metal,
      Weave, Stone Wall, Reptile Skin, Diamond Plate gained a MIX slider (0-100,
      default 100) + RESET. Implemented via reusable post-blend IMAGE_ADJ_mix_result&
      (lerp fx over original, preserve alpha) — NO engine changes. Verified: Wood
      applies 2480px at MIX=100. (Rust deferred — its dialog isn't the p1/p2 pattern.)
      ALSO FIXED a harness regression this caused: the menu-box count fix made the
      EFFECTS dropdown correctly narrower, shifting flyouts left so open_effect's
      fixed child-x=560 overshot narrow flyouts (TEXTURE) → silent 0-diff. Fixed the
      qa-harness DRAW adapter to click children at x=490 (flyout left edge). 22/22 green.

## Wave P4 — Manual

- [x] **Document the EFFECTS menu in docs/MANUAL** — added a full "EFFECTS Menu" section
      to ch06 with all 8 flyout categories + the complete SHAPE (20) + TEXTURE (15) Eye
      Candy submenus, the ORIG/ADJ loupe + wheel + OK/RESET/CANCEL + single-undo
      conventions, the new Angle/Direction/MIX params, and tips on transparent layers /
      FG-BG colours. (PDF rebuild left as a separate step — it's a ~5MB tracked binary.)

## Wave P5 — Wrap-up

- [ ] Full effect QA suite green (`cd QA && ./draw-qa.sh tests/effect-*.sh`), final
      clean 0-warning build, commit, push `more-image-effects`.

## Done earlier this session (context)

- [x] Both Eye Candy categories COMPLETE — SHAPE (20) + TEXTURE (15), 22 new engines.
- [x] Fixed 3 critical action-ID/flyout bugs that were false-passing QA (flyout
      child-index numbering ×4 walks; SHAPE↔EXPORT 2201/2204 collision; Gamma↔Settings
      2100 collision). Memory: draw-effect-action-id-collisions.md.
- [x] Fixed native-scale effect PREVIEW (loupe was cropping the zoomed composite) +
      the oversized EFFECTS dropdown (count loop included hidden flyout children — the
      5th child-walk). Commit d779caf.
- [x] README EFFECTS documentation.

## Deferred (large standalone efforts — not this pass)

- [ ] Liquify interactive tool (integration map in git history / earlier TASKS — model on SPRAY).
- [ ] Pixel Scaler (needs canvas+all-layers resize integration).
- [ ] QA harness: assert dialog TITLE not just region delta (title/known-pixel check).
