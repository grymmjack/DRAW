# More Image Effects — branch `more-image-effects`

Each box = implement (engine + dialog/action + menu wiring) → build clean (0 warnings)
→ commit → add a QA harness guard test (apply effect → region differs) where feasible.
Effects follow the existing `GJ_IMGADJ_*&(sourceImg, ...)` clone-and-return pattern;
dialogs/preview/undo reuse `IMAGE_ADJ_apply_to_layer` / `IMAGE_ADJ_apply_spatial`.
Grep `CMD_execute_action` before allocating each new action ID (gotcha #17).

## Menu organization (Photoshop / Alien-Skin style)

EFFECTS menu is organized into flyout submenu categories:
  ADJUST → · STYLIZE → · DISTORT → · PIXELATE → · NOISE → · RENDER →
  · SHAPE → (Eye Candy Shape) · TEXTURE → (Eye Candy Texture)
The DRAW menubar is currently FLAT (no nested flyouts) — so submenu support is a
foundational task that must land before the categories are usable. Until then,
new effects live under a flat EFFECTS menu and get re-parented into submenus once
the infra exists.

- [x] **Menubar flyout submenus** — GENERIC data-driven flyout (MENU_ITEM_OBJ
      hasSubmenu/subParent + one MENU_BAR gen* state block + render/click/in_bounds
      trio), EFFECTS reorganized into ADJUST/STYLIZE/LAYER FX/DISTORT/PIXELATE/
      NOISE/RENDER flyout categories. Verified: EFFECTS>ADJUST>GAMMA opens dialog.
      Key fixes: stable genY re-anchor each render; category click always-opens
      (never toggle-closes a hover-opened flyout); MOUSE.BM click routing now
      includes MENUBAR_generic_in_bounds. QA helper open_effect added to the
      qa-harness DRAW adapter. SHAPE/TEXTURE categories added in Waves 7/8.
      DECISION 2026-08-14: user confirmed **flyout submenus** (over multi-menu or
      flat-scroll). Model on the existing recent-files flyout if present.
      NOTE: this re-coordinates ALL 40 effect-*.sh QA tests (they click flat item
      y = 20 + index*12) — they'll need a shared helper for "open EFFECTS >
      CATEGORY > item" once the reorg lands.

## 🔨 NOW — doing right now

(nothing in progress)

- [x] **FIX SHAPE-category QA navigation** — ROOT CAUSE was NOT the coordinate.
      MENUBAR_render_submenu skips hidden generic-flyout children (subParent>=0)
      WITHOUT advancing childIdx, but three OTHER child-index walks did NOT skip
      them: MENUBAR_get_submenu_item_at% (the Y→childIdx mapper), the click-
      resolution walk, and the keyboard Enter/arrow-nav walks. So a category
      click resolved to a HIDDEN effect item (SHAPE click → DUOTONE), and every
      category test that "passed" was opening the WRONG dialog (any effect
      changes the region). Fixed by adding `IF subParent >= 0 THEN GOTO next`
      (no childIdx increment) to ALL FOUR walks so numbering matches render.
      Verified: effect-cutout (open_effect 7 2) now passes its inner-edge
      assertion (281px), corona (5884px ring), backlight (1135px rays) all with
      correct dialogs. open_effect's y=20+cat*12 formula was correct all along.

<!-- REORG PLAN (EFFECTS menu, 21xx only; leave IMAGE menu 2001-2011 as-is).
     9 flyout categories under EFFECTS:
       ADJUST →   : Gamma 2100, Sepia 2101, Threshold 2102, Colorize 2103,
                    Gradient Map 2112, Solarize 2122, Duotone 2123
       STYLIZE →  : Glow 2104, Film Grain 2105, Vignette 2106, Outline 2110,
                    Edge Detect 2111, Grow/Shrink 2113, Chromatic 2120,
                    Emboss 2121, Wind 2145
       LAYER FX → : Drop Shadow 2124, Long Shadow 2125, Bevel 2126,
                    Outer Glow 2127, Inner Glow 2128, Chrome 2129
       DISTORT →  : Wave 2130, Twirl 2131, Pinch/Bulge 2132, Kaleidoscope 2133
       PIXELATE → : Crystallize 2140, Stained Glass 2141, Mosaic 2142,
                    Extrude 2143, Pointillize 2144
       NOISE →    : Add Noise 2160, Median 2161, Dust & Scratches 2162
       RENDER →   : Clouds 2150, Difference Clouds 2151, Lens Flare 2152,
                    Terrain 2153, Grid 2170, Sky 2171
       SHAPE →    : Eye Candy shape effects (Wave 7, to build)
       TEXTURE →  : Eye Candy texture effects (Wave 8, to build)
     QA: add a helper open_effect "CATEGORY" <child-index> that clicks EFFECTS,
     hovers the category, clicks the child; convert the 40 effect-*.sh tests. -->


<!-- Menu-overflow plan: the flat EFFECTS dropdown auto-scrolls past ~41 items
     (availH = SCRN.h - subY, 12px/item). At 25 items now; Waves 4/5/5b/5c (15
     more) reach ~40 and still fit flat. The submenu infra becomes MANDATORY only
     for the Eye-Candy waves (7/8, 33 items) — do it then, before those, and
     reorganize everything into ADJUST/STYLIZE/DISTORT/PIXELATE/NOISE/RENDER/
     SHAPE/TEXTURE (updating QA item-y coords once). -->


<!-- QA note: invoke effects via the EFFECTS menu (click 395,6 then item at
     viewport y = 20 + index*12), NOT the command palette — palette-open is racy
     under the harness. Commit dialogs with `key Return`. Snap AFTER dialog close. -->


## Wave 0 — Activate dormant engine effects (math already implemented + tested)

- [x] Wire **Gamma** (GJ_IMGADJ_Gamma) — EFFECTS menu + cmd palette + dialog + QA test (effect-gamma.sh)
- [x] Wire **Sepia** (GJ_IMGADJ_Sepia) — one-shot + EFFECTS menu + cmd palette + QA test (effect-sepia.sh)
- [x] Wire **Threshold** (GJ_IMGADJ_Threshold) — LEVEL slider + INVERT toggle dialog + menu + QA test (effect-threshold.sh)
- [x] Wire **Colorize** (GJ_IMGADJ_Colorize) — HUE + SATURATION tint dialog + menu + QA test (effect-colorize.sh). NOTE: distinct from existing Hue/Saturation (2002) — Colorize *replaces* all hues (monotone tint); Hue/Sat *shifts* them.
- [x] Wire **Glow** (GJ_IMGADJ_Glow) — RADIUS + INTENSITY dialog + menu + QA test (effect-glow.sh, menu-click invocation)
- [x] Wire **Film Grain** (GJ_IMGADJ_FilmGrain) — AMOUNT dialog + menu + QA test (effect-filmgrain.sh)
- [x] Wire **Vignette** (GJ_IMGADJ_Vignette) — STRENGTH dialog + menu + QA test (effect-vignette.sh)
- (Pixel Scaler moved to the "Deferred — needs bigger integration" section at the bottom.)

## Wave 1 — Tier-1 pixel-art effects (new engine)

- [x] **Outline / Stroke** — alpha-edge border, THICKNESS 1-8 + INSIDE/OUTSIDE, FG colour, apply_spatial + menu + QA test (effect-outline.sh, transparent-layer). NEW engine IMAGE_ADJ_outline&.
- [x] **Edge Detect (Sobel)** — 3x3 Sobel line art, STRENGTH 10-300 + INVERT + menu + QA test (effect-edgedetect.sh). NEW engine IMAGE_ADJ_edgedetect&.
- [x] **Gradient Map** — luminance → BG..FG 2-colour ramp (256-entry LUT) + SWAP toggle + menu + QA test (effect-gradientmap.sh). NEW engine IMAGE_ADJ_gradientmap&.
- [x] **Grow / Shrink (Dilate/Erode)** — alpha morphology, AMOUNT 1-8 + SHRINK toggle, apply_spatial + menu + QA test (effect-growshrink.sh). NEW engine IMAGE_ADJ_growshrink&.

## Wave 2 — Retro / stylize (new engine)

- [x] **Chromatic Aberration** — horizontal R/B channel split, AMOUNT 0-20px + menu + QA test (effect-chromatic.sh). NEW engine IMAGE_ADJ_chromatic&.
- [x] **Emboss / Bevel** — directional grey relief, STRENGTH 1-10 + menu + QA test (effect-emboss.sh). NEW engine IMAGE_ADJ_emboss&.
- [x] **Solarize** — per-channel invert above THRESHOLD 0-255 (Sabattier) + menu + QA test (effect-solarize.sh). NEW engine IMAGE_ADJ_solarize&.
- [x] **Duotone / Tritone** — discrete 2/3-band flat tone map (BG..FG), TRITONE toggle + menu + QA test (effect-duotone.sh). NEW engine IMAGE_ADJ_duotone&.
- [x] **Drop Shadow (flat)** — offset softened BG-colour silhouette composited behind, OFFSET 1-20 + SOFTNESS 0-8, apply_spatial + menu + QA test (effect-dropshadow.sh). NEW engine IMAGE_ADJ_dropshadow&.
- [x] **Perspective / 3D Shadow** — "long shadow": solid diagonal cast trail (BG colour), LENGTH 1-40, apply_spatial + menu + QA test (effect-longshadow.sh). NEW engine IMAGE_ADJ_longshadow&.

## Wave 2b — Layer Styles (Alien Skin / Eye Candy feel)

- [x] **Bevel** — inner bevel via distance-to-edge heightfield lit top-left, HEIGHT 1-8 + STRENGTH 1-10 + menu + QA test (effect-bevel.sh). NEW engine IMAGE_ADJ_bevel&. Visually verified 3D button.
- [x] **Outer Glow** — FG-colour silhouette blurred outward + INTENSITY boost, composited behind, RADIUS 1-16, apply_spatial + menu + QA test (effect-outerglow.sh). NEW engine IMAGE_ADJ_outerglow&.
- [x] **Inner Glow** — FG-colour glow blended inward from edges via distance field, RADIUS 1-16 + INTENSITY 1-5 + menu + QA test (effect-innerglow.sh). NEW engine IMAGE_ADJ_innerglow&. (Gotcha: gg collided with gG — QB64 case-insensitive.)
- [x] **Chrome / Metallic** — distance-field |sin| metallic bands mapped BG..FG, DEPTH 2-16 + menu + QA test (effect-chrome.sh). NEW engine IMAGE_ADJ_chrome&. Visually verified silver look.

## Wave 3 — Distort filters (one-shot, whole layer)

- [x] **Wave / Ripple** — sinusoidal per-pixel displacement, AMPLITUDE 1-20 + WAVELENGTH 4-64, apply_spatial + menu + QA test (effect-wave.sh). NEW engine IMAGE_ADJ_wave&.
- [x] **Twirl** — distance-falloff angular swirl around centre, ANGLE 10-360, apply_spatial + menu + QA test (effect-twirl.sh). NEW engine IMAGE_ADJ_twirl&.
- [x] **Pinch / Bulge (Spherize)** — radial power displacement, AMOUNT -100..+100, apply_spatial + menu + QA test (effect-pinch.sh). NEW engine IMAGE_ADJ_pinch&.
- [x] **Kaleidoscope** — reflect a base wedge radially into a mandala, SEGMENTS 3-24 + ROTATION 0-359 (aims the source wedge), apply_spatial + menu + QA test (effect-kaleidoscope.sh). NEW engine IMAGE_ADJ_kaleidoscope&. Visually verified mandala. (seg renamed klSeg — reserved word.)

## Wave 4 — Photoshop Pixelate / Stylize family (new engine)

- [x] **Crystallize** — Voronoi cells (deterministic grid-jitter, nearest-seed colour), CELL SIZE 4-40 + menu + QA test (effect-crystallize.sh). NEW engine IMAGE_ADJ_crystallize&.
- [x] **Stained Glass** — Voronoi + dark leading via 2nd-nearest-seed borders, CELL SIZE 4-40 + BORDER 1-4 + menu + QA test (effect-stainedglass.sh). NEW engine IMAGE_ADJ_stainedglass&.
- [x] **Mosaic / Tessellate** — per-tile colour averaging (vs Pixelate's sample) + GROUT toggle, TILE 3-48 + menu + QA test (effect-mosaic.sh). NEW engine IMAGE_ADJ_mosaic&.
- [x] **Extrude** — brightness-raised tile blocks over darkened base, TILE 4-40 + DEPTH 2-16 + menu + QA test (effect-extrude.sh). NEW engine IMAGE_ADJ_extrude&.
- [x] **Pointillize** — sampled colour dots (hash-jittered) over BG colour, DOT SIZE 3-20 + menu + QA test (effect-pointillize.sh). NEW engine IMAGE_ADJ_pointillize&.
- [x] **Wind** — horizontal edge smear (Photoshop wind), STRENGTH 2-20 + menu + QA test (effect-wind.sh). NEW engine IMAGE_ADJ_wind&.

## Wave 5 — Render / generative (fill a layer; no source needed)

- [x] **Clouds** — 3-octave value-noise plasma mapped BG..FG, SCALE 8-64, generative (apply_spatial) + menu + QA test (effect-clouds.sh). NEW engines IMGADJ_valnoise! + IMAGE_ADJ_clouds&.
- [x] **Difference Clouds** — grayscale plasma |src-cloud| per channel, one-shot + menu + QA test (effect-diffclouds.sh). NEW engine IMAGE_ADJ_diffclouds&.
- [x] **Lens Flare** — additive bright core + 5 halo orbs along the flare axis, BRIGHTNESS 10-100 + menu + QA test (effect-lensflare.sh). NEW engine IMAGE_ADJ_lensflare&.
- [x] **Terrain** — 5-octave fractal heightmap → water/sand/grass/rock/snow ramp, SCALE 16-96, generative (apply_spatial) + menu + QA test (effect-terrain.sh). NEW engine IMAGE_ADJ_terrain&. Visually verified continents.

## Wave 5b — Noise (render / filter)

- [x] **Add Noise** — deterministic per-pixel hash noise (~gaussian), AMOUNT 0-100 + MONOCHROME toggle + menu + QA test (effect-addnoise.sh). NEW engine IMAGE_ADJ_addnoise&.
- [x] **Median / Despeckle** — 3x3 per-channel median (insertion-sort), one-shot + menu + QA test (effect-median.sh). NEW engine IMAGE_ADJ_median&.
- [x] **Reduce Noise / Dust & Scratches** — thresholded 3x3 median (replaces only outliers), THRESHOLD 2-64 + menu + QA test (effect-dustscratches.sh). NEW engine IMAGE_ADJ_dustscratches&.

## Wave 5c — Render: Grid & Sky

- [x] **Render Grid** — flat + PERSPECTIVE floor grid in FG colour, SPACING 4-64, apply_spatial + menu + QA test (effect-grid.sh). NEW engine IMAGE_ADJ_grid&. (spc renamed gspc — SPC reserved.)
- [x] **Render Sky** — procedural day/night/space (gradient + stars + planet), MODE 0-2, generative (apply_spatial) + menu + QA test (effect-sky.sh). NEW engine IMAGE_ADJ_sky&. Visually verified starfield.

## Wave 7 — Eye Candy: SHAPE → submenu

- [x] **Backlight** — radial sunburst rays behind the shape (FG colour), RAYS 4-48 + INTENSITY, apply_spatial + SHAPE category + QA test (effect-backlight.sh). NEW engine IMAGE_ADJ_backlight&. NOTE: functional + test-passing but ray visuals are faint — flagged for a polish pass. First effect in the new SHAPE flyout category (open_effect 7 0).
- [x] **Bevel (Eye Candy)** — SHAPE-menu entry added (child 3 → action 2126, reuses Wave 2b engine). Guarded by effect-shape-reparent.sh (open_effect 7 3, 353px).
- [x] **Chrome** — SHAPE-menu entry added (child 4 → action 2129, reuses Wave 2b engine). Guarded by effect-shape-reparent.sh (open_effect 7 4, 1071px).
- [x] **Corona** — triangular ring of light offset outside the alpha edge, RADIUS 3-24 + INTENSITY, apply_spatial + SHAPE menu + QA test (effect-corona.sh, 1542px). NEW engine IMAGE_ADJ_corona&.
- [ ] **Drip** — liquid drips hanging off the bottom of shapes + dialog + QA test
- [ ] **Electrify** — jagged lightning tendrils around edges + dialog + QA test
- [x] **Extrude** — SHAPE-menu entry added (child 5 → action 2143). Guarded by effect-shape-reparent.sh (open_effect 7 5, 1189px).
- [ ] **Fire** — flame render rising from the shape (gradient + noise) + dialog + QA test
- [ ] **Glass** — refractive glassy shading + highlight + dialog + QA test
- [x] **Glow (Outer/Inner)** — SHAPE-menu entries added (Outer Glow child 6 → 2127, Inner Glow child 7 → 2128). Inner Glow guarded by effect-shape-reparent.sh (open_effect 7 7, 1228px).
- [ ] **Icicles** — ice spikes hanging off the bottom edge + dialog + QA test
- [x] **Motion Trail** — color-preserving speed-blur smear: each opaque pixel scattered along DIRECTION as a fading run in its own colour, crisp original composited on top. LENGTH 2-40 + DIRECTION 0-359 dialog, apply_spatial + SHAPE menu (2203, child 10) + QA test (effect-motiontrail.sh, 253px, open_effect 7 10). NEW engine IMAGE_ADJ_motiontrail&. Dialog visually verified.
- [ ] **Rust** — corroded noise overlay masked to shape + dialog + QA test
- [x] **Shadow** — SHAPE-menu entries added (Drop Shadow child 8 → 2124, Perspective Shadow child 9 → 2125). Index 9 visually confirmed to open "LONG SHADOW" dialog (shape-pshadow-dialog screenshot).
- [ ] **Smoke** — wispy smoke render rising from shape (noise plume) + dialog + QA test
- [ ] **Snow** — snow cap on top edges + falling flecks + dialog + QA test
- [x] **Cutout** — inset shadow (up-left distance-to-transparent darkens the inner top-left edge) so the shape looks punched through, apply_to_layer + SHAPE menu (2202) + QA test (effect-cutout.sh, 281px, open_effect 7 2). NEW engine IMAGE_ADJ_cutout&.
- [ ] **Jiggle / Water Drops** — bubble/droplet displacement bumps + dialog + QA test

## Wave 8 — Eye Candy: TEXTURE → submenu (procedural fills / overlays)

- [ ] **Animal Fur** — directional furry noise + dialog + QA test
- [ ] **Brick Wall** — brick tiling with mortar + color jitter + dialog + QA test
- [ ] **Brushed Metal** — anisotropic horizontal streak noise + dialog + QA test
- [ ] **Clouds (texture)** — covered by Wave 5 Clouds; add TEXTURE-menu entry
- [ ] **Diamond Plate** — tromp-l'oeil metal tread pattern + dialog + QA test
- [ ] **Lightning** — branching bolt between two points + dialog + QA test
- [ ] **Marble** — turbulence-veined marble (perlin + sine) + dialog + QA test
- [ ] **Reptile Skin** — scale cell pattern (Voronoi + shading) + dialog + QA test
- [ ] **Ripples** — concentric water ripple displacement + dialog + QA test
- [ ] **Stone Wall** — irregular stone tiling with mortar + dialog + QA test
- [ ] **Swirl** — covered by Wave 3 Twirl; add TEXTURE-menu entry
- [ ] **Texture Noise / HSB Noise** — per-channel/HSB noise overlay + dialog + QA test
- [ ] **Water Drops** — refractive droplet bumps scattered over layer + dialog + QA test
- [ ] **Weave** — over/under basket-weave pattern + dialog + QA test
- [ ] **Wood** — concentric wood-grain rings + grain noise + dialog + QA test

## Wave 6 — Liquify tool ("Kai's Power Goo") — big, own design pass

- [ ] **TOOL_LIQUIFY** scaffold — BI/BM, CONST, _ALL chains, tool button, keybind, tool-switch reset, undo snapshot
- [ ] **Liquify: Push/Smudge (move)** — drag displaces pixels along cursor motion (radius + strength)
- [ ] **Liquify: Pinch / Bulge** — radial squeeze/expand under cursor
- [ ] **Liquify: Twirl** — rotational warp under cursor (CW/CCW)
- [ ] Liquify live preview + commit-to-history + QA test (best-effort; interactive tool)

## Deferred — needs bigger integration (not externally blocked, just large)

- [ ] Wire **Pixel Scaler** (GJ_IMGADJ_PixelScaler, xBR/HQx/MMPX) — unlike every
      other effect it *resizes* the image 2–4×, so it can't use the same-size
      apply_to_layer path. Needs to scale ALL layers by the factor AND resize the
      canvas, reusing `CANVAS_resize_with_content_dialog` machinery — the #1
      bug-risk area (document-state resets across the three doc-creation paths,
      gotcha #15). Also the engine currently uses `PRINT` for errors (gotcha #1)
      and a temp-file round-trip; both need cleanup before wiring. Do as its own
      focused pass with a QA test, not inside the effects sweep.

## Wrap-up

- [ ] Update CHEATSHEET.md + docs (new Image/Render menu entries, Liquify tool + hotkey)
- [ ] Full suite QA run (`cd QA && ./draw-qa.sh`) green; final clean build; open PR to main
