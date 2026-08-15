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

- [ ] **RESET infra** — add a shared `IMGDLG_RESET_CLICKED%` flag + a "RESET" button
      in `IMGDLG_draw_ok_cancel` (left of OK) and hit-test in `IMGDLG_check_ok_cancel`
      (sets the flag, NOT done). Add helpers `IMGDLG_reset2 ctx, p1%, p2%, d1%, d2%`
      and `IMGDLG_reset3/4` that, when the flag is set, restore pN=dN, mark
      `ctx.previewDirty%`, and clear the flag. Widen the button row / shrink OK+CANCEL
      to fit RESET. Build + a quick visual check.
- [ ] **Wire RESET into every effect dialog** — for each `IMAGE_ADJ_*_dialog`, add
      `DIM dN : dN% = <default>` beside each param and one `IMGDLG_resetN` call in the
      loop. Do it in batches by file region; re-run the full effect QA suite after.

## Wave P2 — Relief / light effects get an ANGLE (Photoshop-authentic)

- [ ] **Bevel** (the effect Rick screenshotted) — params HEIGHT + STRENGTH + **ANGLE**
      (light 0-359, default 135 = top-left) + **DIRECTION** (Up/Down toggle). Replace
      the hardcoded top-left light vector in `IMAGE_ADJ_bevel&` with `cos/sin(angle)`;
      Direction flips the sign. Taller dialog. QA: effect-bevel still passes + angle changes result.
- [ ] **Emboss** — add **ANGLE** (0-359) to `IMAGE_ADJ_emboss&` (currently fixed direction).
- [ ] **Chrome** — add **ANGLE** (light direction) alongside DEPTH.
- [ ] **Drop Shadow** — Photoshop trio: **ANGLE** (0-359) + **DISTANCE** + SOFTNESS +
      **OPACITY** (0-100). Replace fixed down-right offset with angle+distance vector;
      OPACITY scales the shadow alpha.
- [ ] **Perspective / Long Shadow** — add **ANGLE** (cast direction, default 315 = down-right)
      to `IMAGE_ADJ_longshadow&` (currently fixed down-right diagonal).

## Wave P3 — Texture / overlay effects get a MIX (blend with original)

- [ ] **MIX slider on texture effects** — add MIX/OPACITY (0-100, default 100) that
      lerps the generated surface with the original layer colour, so textures aren't
      all-or-nothing. Apply to: Wood, Marble, Brick Wall, Brushed Metal, Weave, Stone
      Wall, Reptile Skin, Diamond Plate, and Rust. (Engine gains a `mix` param; at
      100 = full texture, 0 = original.) QA: each still applies; low MIX changes fewer px.

## Wave P4 — Manual

- [ ] **Document the EFFECTS menu in docs/MANUAL** — extend ch06 (or a new section)
      with the 8 flyout categories and the complete SHAPE (20) + TEXTURE (15) Eye
      Candy submenus, noting live preview + wheel + Reset-to-Default + alpha-preserving
      single-undo conventions. Rebuild the PDF manual if time permits (make-pdf-manual).

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
