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
- [x] **Drip** — liquid runs drip off the bottom edge in the shape's OWN colour: sparse hash-gated columns run down a hash-scaled length, slightly darkened, with a rounded fuller bulb (full alpha) in the last ~20%. LENGTH + AMOUNT dialog, apply_spatial + SHAPE menu (2239, child 16) + QA test (effect-drip.sh, 398px, open_effect 7 16). NEW engine IMAGE_ADJ_drip&. Visually verified — green liquid runs.
- [x] **Electrify** — crackling electric arcs around the shape edge: transparent pixels within REACH get a distance-falloff glow that a high-frequency noise threshold breaks into thin blue-white filaments (electric core->white, cooler->blue). REACH + INTENSITY dialog, apply_spatial + SHAPE menu (2241, child 18) + QA test (effect-electrify.sh, 120px, open_effect 7 18). NEW engine IMAGE_ADJ_electrify&. Visually verified — blue-white arcs (subtle on small shapes; scale REACH/INTENSITY up).
- [x] **Extrude** — SHAPE-menu entry added (child 5 → action 2143). Guarded by effect-shape-reparent.sh (open_effect 7 5, 1189px).
- [x] **Fire** — flames rise off the shape's top edge: transparent pixels with an opaque pixel within HEIGHT below get heat = closeness x upward-flickering fractal noise, mapped through a black->red->orange->yellow->white ramp with heat-proportional alpha. HEIGHT + INTENSITY dialog, apply_spatial + SHAPE menu (2236, child 13) + QA test (effect-fire.sh, 2479px, open_effect 7 13). NEW engine IMAGE_ADJ_fire&. Visually verified — realistic flames w/ flickering silhouette + full gradient.
- [x] **Glass** — glassy sheen: translucent FROST lightening toward white + two gaussian diagonal specular SHINE streaks (broad + thin-bright) swept across the surface along the (x+y) diagonal. RGB-only apply_to_layer + SHAPE menu (2240, child 17) + QA test (effect-glass.sh, 549px, open_effect 7 17). NEW engine IMAGE_ADJ_glass&. Visually verified — diagonal glass highlights. (oR2 not oR: reserved-word.)
- [x] **Glow (Outer/Inner)** — SHAPE-menu entries added (Outer Glow child 6 → 2127, Inner Glow child 7 → 2128). Inner Glow guarded by effect-shape-reparent.sh (open_effect 7 7, 1228px).
- [x] **Icicles** — pale ice spikes hang off the shape's bottom edges: each bottom-edge column grows a downward spike whose length is a smooth per-column noise (neighbouring columns form pointed icicles), pale cyan-white fading/brightening toward a glassy tip. LENGTH + THICKNESS dialog, apply_spatial + SHAPE menu (2238, child 15) + QA test (effect-icicles.sh, 883px, open_effect 7 15). NEW engine IMAGE_ADJ_icicles&. Visually verified — pointed hanging icicles.
- [x] **Motion Trail** — color-preserving speed-blur smear: each opaque pixel scattered along DIRECTION as a fading run in its own colour, crisp original composited on top. LENGTH 2-40 + DIRECTION 0-359 dialog, apply_spatial + SHAPE menu (2203, child 10) + QA test (effect-motiontrail.sh, 253px, open_effect 7 10). NEW engine IMAGE_ADJ_motiontrail&. Dialog visually verified.
- [x] **Rust** — fractal-noise oxide overlay masked to the shape alpha, blended toward a brown->orange->light-oxide ramp. AMOUNT + SCALE dialog, RGB-only apply_to_layer + SHAPE menu (2234, child 11) + QA test (effect-rust.sh, 326px, open_effect 7 11). NEW engine IMAGE_ADJ_rust&. Dialog+oxide preview visually verified.
      NOTE: uncovered & fixed a CRITICAL action-ID collision — SHAPE effects were on 2200-2204 but the EXPORT range is 2201-2216, so Corona(2201)/Rust(2204) silently opened Export dialogs and their region-diff tests FALSE-PASSED (fullscreen dialog covered the snap). All SHAPE effects moved to 2230-2234. See commit 39e989c.
- [x] **Shadow** — SHAPE-menu entries added (Drop Shadow child 8 → 2124, Perspective Shadow child 9 → 2125). Index 9 visually confirmed to open "LONG SHADOW" dialog (shape-pshadow-dialog screenshot).
- [x] **Smoke** — wispy translucent grey plume rising off the top edge: Fire's top-scan but noise-DOMINATED density (nz^2 -> gappy wisps), cool grey ramp at low alpha, taller reach. HEIGHT + DENSITY dialog, apply_spatial + SHAPE menu (2237, child 14) + QA test (effect-smoke.sh, 380px, open_effect 7 14). NEW engine IMAGE_ADJ_smoke&. Visually verified — real fractured smoke wisps.
- [x] **Snow** — white snow caps on the shape's top-facing edges (nearest transparent-above within DEPTH, granular hash break-up) + hash-scattered falling FLECKS. DEPTH + FLECKS dialog, apply_spatial + SHAPE menu (2235, child 12) + QA test (effect-snow.sh, 395px, open_effect 7 12). NEW engine IMAGE_ADJ_snow&. SNOW dialog title + top-cap visually verified. (oR->snR: reserved-word.)
- [x] **Cutout** — inset shadow (up-left distance-to-transparent darkens the inner top-left edge) so the shape looks punched through, apply_to_layer + SHAPE menu (2202) + QA test (effect-cutout.sh, 281px, open_effect 7 2). NEW engine IMAGE_ADJ_cutout&.
- [x] **Jiggle / Water Drops** — droplet lenses on a hash-jittered grid magnify the underlying surface (radial lens pulls the sample outward) with an up-left specular highlight + rim darkening, so each drop reads as a refractive bubble. SIZE + REFRACT dialog, RGB-only apply_to_layer + SHAPE menu (2242, child 19) + QA test (effect-waterdrops.sh, 306px, open_effect 7 19). NEW engine IMAGE_ADJ_waterdrops&. Visually verified — circular droplet lenses. **SHAPE category COMPLETE (20 items).**

## Wave 8 — Eye Candy: TEXTURE → submenu (procedural fills / overlays)

- [x] **Animal Fur** — directional furry noise: fine strands along a DIRECTION-blended axis lighten/darken the shape colour like short fur. DENSITY + DIRECTION dialog, RGB-only apply_to_layer + TEXTURE menu (2276, child 9) + QA test (effect-texture-natural.sh, 1568px, open_effect 8 9). NEW engine IMAGE_ADJ_fur&.
- [x] **Brick Wall** — running-bond brick tiling with grey mortar joints + per-brick colour jitter + faint intra-brick grain, painted onto the shape. SIZE + MORTAR dialog, RGB-only apply_to_layer + TEXTURE menu (2272, child 2) + QA test (effect-texture-basics.sh, 2691px, open_effect 8 2). NEW engine IMAGE_ADJ_brick&. Visually verified — red brick wall.
- [x] **Brushed Metal** — anisotropic horizontal streak noise (fine along y, smooth along x) reads as brushed steel. BRIGHT + GRAIN dialog, RGB-only apply_to_layer + TEXTURE menu (2273, child 3) + QA test (effect-texture-more.sh, open_effect 8 3). NEW engine IMAGE_ADJ_brushmetal&. (base->bmBase: reserved-word.)
- [x] **Clouds (texture)** — TEXTURE-menu entry (child 5 -> action 2150, reuses Wave 5 Clouds). Guarded by effect-texture-more.sh (open_effect 8 5, 2131px).
- [x] **Diamond Plate** — metal tread: alternating diagonal raised bars (direction flips per tile) shaded for 3D relief on a metal-grey base. SIZE + DEPTH dialog, RGB-only apply_to_layer + TEXTURE menu (2280, child 13) + QA test (effect-texture-metal.sh, open_effect 8 13). NEW engine IMAGE_ADJ_diamondplate&. Visually verified — real diamond tread.
- [x] **Lightning** — a jagged bolt runs down the shape: bolt x per row wanders by fractal noise; pixels near the path get a white core -> blue glow over a darkened shape, plus a lower branch. JAG + GLOW dialog, RGB-only apply_to_layer + TEXTURE menu (2281, child 14) + QA test (effect-texture-metal.sh, 2579px, open_effect 8 14). NEW engine IMAGE_ADJ_lightning&. Visually verified — white-hot bolt w/ blue glow. **TEXTURE category COMPLETE (15 items). Both Eye Candy categories done.**
- [x] **Marble** — turbulence-veined marble: sine of x warped by 3-octave noise gives thin dark veins on a light grey body. SCALE + VEINS dialog, RGB-only apply_to_layer + TEXTURE menu (2271, child 1) + QA test (effect-texture-basics.sh, 3054px, open_effect 8 1). NEW engine IMAGE_ADJ_marble&. Visually verified.
- [x] **Reptile Skin** — Voronoi scale cells shaded like domes (bright centre via d2-d1, dark ridge at borders) tinted with the shape colour. SIZE + RELIEF dialog, RGB-only apply_to_layer + TEXTURE menu (2279, child 12) + QA test (effect-texture-voronoi.sh, 1090px, open_effect 8 12). NEW engine IMAGE_ADJ_reptile&.
- [x] **Ripples** — concentric water ripples: radial sinusoidal sample displacement centred on the shape. AMOUNT + FREQ dialog, RGB-only apply_to_layer + TEXTURE menu (2275, child 8) + QA test (effect-texture-natural.sh, open_effect 8 8). NEW engine IMAGE_ADJ_ripples&. Visually verified — rippled edge.
- [x] **Stone Wall** — irregular Voronoi stone cells (jittered-grid seeds) in mottled greys with dark mortar where the nearest two seeds are close + intra-stone speckle. SIZE + MORTAR dialog, RGB-only apply_to_layer + TEXTURE menu (2278, child 11) + QA test (effect-texture-voronoi.sh, open_effect 8 11). NEW engine IMAGE_ADJ_stone&. Visually verified — dry-stone wall.
- [x] **Swirl** — TEXTURE-menu entry (child 6 -> action 2131, reuses Wave 3 Twirl).
- [x] **Texture Noise / HSB Noise** — per-pixel hash noise perturbs brightness (MONO) or each channel independently (colour speckle). AMOUNT + MONO dialog, RGB-only apply_to_layer + TEXTURE menu (2277, child 10) + QA test (effect-texture-natural.sh, 223px, open_effect 8 10). NEW engine IMAGE_ADJ_texnoise&.
- [x] **Water Drops (texture)** — TEXTURE-menu entry (child 7 -> action 2242, reuses the SHAPE Water Drops engine).
- [x] **Weave** — over/under basket weave: cells alternate warp/weft strands, each shaded across its width (sin) so strands look rounded; TONE blends shape colour with straw. SIZE + TONE dialog, RGB-only apply_to_layer + TEXTURE menu (2274, child 4) + QA test (effect-texture-more.sh, 1342px, open_effect 8 4). NEW engine IMAGE_ADJ_weave&. Visually verified — real basket weave.
- [x] **Wood** — concentric ring grain warped by turbulence in a dark-brown->tan ramp, painted onto the shape. SCALE + GRAIN dialog, RGB-only apply_to_layer + TEXTURE menu (2270, child 0) + QA test (effect-texture-basics.sh, open_effect 8 0). NEW engine IMAGE_ADJ_wood&. Visually verified — flowing wood grain. **TEXTURE category established (index 8, action block 2270-2299).**

## Wave 6 — Liquify tool ("Kai's Power Goo") — big, own design pass

> STATUS 2026-08-15: deferred to a fresh session. This is a large INTERACTIVE
> tool (not a dialog effect) that touches the project's #1 bug-risk subsystems —
> the MOUSE.BM dispatch pipeline, the unified history system (gotcha #4), the
> tool-switch reset lists (gotcha #9) and the three doc-creation resets (gotcha
> #15), plus the render cursor-preview. It was intentionally NOT started at the
> tail of the big effects sweep to avoid shipping regressions into those areas.
> INTEGRATION MAP already scouted (model it on the SPRAY tool, which is the exact
> analog — snapshot-on-press / modify-on-drag / commit-on-release):
>   - TOOLS/LIQUIFY.BI  — LIQUIFY_OBJ {ACTIVE, MODE, RADIUS, STRENGTH, LAST_X,
>       LAST_Y, HISTORY_BEFORE_IMG} + LIQUIFY_reset (mirror TOOLS/SPRAY.BI).
>   - TOOLS/LIQUIFY.BM  — LIQUIFY_warp(cx,cy,dx,dy,mode) + MOUSE_tool_liquify
>       (copy MOUSE_tool_spray's press/hold structure at INPUT/MOUSE.BM:2722).
>       WARP: snapshot the brush's bbox into a small work buffer each apply-step
>       and SAMPLE FROM IT (avoids feedback smear); mind the apron offset
>       (gotcha #14) on promoted layers. Modes: PUSH shift by (dx,dy)*falloff;
>       PINCH/BULGE radial; TWIRL rotate by angle*falloff. Reuse the existing
>       IMAGE_ADJ_pinch / IMAGE_ADJ_twirl math, localized to the brush radius.
>   - CONST TOOL_LIQUIFY = 45 in GUI/GUI.BI (44 = TOOL_SMART_SHAPES).
>   - _ALL.BI / _ALL.BM includes (TOOLS group, near SPRAY at lines 136/138).
>   - MOUSE dispatch: add `CASE TOOL_LIQUIFY: MOUSE_tool_liquify` to
>       MOUSE_dispatch_tool_hold (~INPUT/MOUSE.BM:4380) AND the release commit to
>       MOUSE_dispatch_tool_release (~:4472 / the spray-release block ~:3580 that
>       does `HISTORY_record_brush ... SPRAY.HISTORY_BEFORE_IMG`). Add
>       TOOL_LIQUIFY to the brush-cursor tool list at ~:31 for a free radius ring.
>   - Registration: keybind in KEYBOARD.BM (near :252), action in CMD_init +
>       handler in CMD_execute_action (sets CURRENT_TOOL% = TOOL_LIQUIFY, like
>       :4989), MENUBAR entry, and LIQUIFY_reset in ALL THREE doc-creation paths
>       (DRW_load_binary / DRW_new_canvas / DRW_create_canvas_at_size) + the
>       tool-switch reset.
>   - MODE picker: a small edit-bar segmented control or number keys 1-4 while the
>       tool is active. QA: best-effort (interactive) — drag across a shape and
>       assert the region warped.

- [ ] **TOOL_LIQUIFY** scaffold — BI/BM, CONST, _ALL chains, keybind, tool-switch reset, undo snapshot
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

## QA hardening (found during Wave 7)

- [ ] **Effect tests should assert the dialog TITLE, not just a region delta.**
      assert_regions_differ cannot distinguish a real effect from an unrelated
      fullscreen dialog covering the snap region — that's how the 2201/2204
      action-ID collision false-passed for several commits. Add a lightweight
      title/OCR or known-pixel check (e.g. snap the dialog title bar and assert
      it matches) to open_effect-based tests, at least for the SHAPE category.

## Wrap-up

- [x] **Docs: EFFECTS menu documented in README.MD** — added an "Effects (Photoshop /
      Alien-Skin Eye Candy style)" section listing all 8 flyout categories incl. the
      complete SHAPE (20) and TEXTURE (15) Eye Candy submenus. CHEATSHEET.md needs
      NO effect entries — every effect is menu-only (no hotkeys). Remaining doc work
      (Liquify tool + its hotkey) is deferred with the Liquify tool itself.
- [ ] Full suite QA run (`cd QA && ./draw-qa.sh`) green; final clean build; open PR to main
      — do AFTER Liquify lands (or explicitly descope Liquify first).

<!--
loop:off — 2026-08-15. Stopping the autonomous loop deliberately, NOT because the
list is finished. What shipped this session (all committed on branch
`more-image-effects`, each with a clean 0-warning build, a QA guard test, and a
verified dialog/visual):
  • Both Eye Candy categories COMPLETE — SHAPE (20 effects) + TEXTURE (15 effects),
    22 brand-new engines, plus re-parent homes for shared engines.
  • THREE critical bugs found & fixed, each of which had been FALSE-PASSING QA:
    (1) flyout child-index numbering across 4 walks; (2) SHAPE effects colliding
    with the EXPORT action-ID range 2201-2216 (Corona/Rust opened Export dialogs);
    (3) Gamma on 2100 shadowing ACTION_SETTINGS (Ctrl+, opened Gamma — Settings
    dialog was unreachable). Memory recorded: draw-effect-action-id-collisions.md.
  • README EFFECTS documentation.
The 4 items left unchecked are LARGE STANDALONE efforts that touch the riskiest
subsystems (MOUSE.BM / history / tool-reset / canvas-resize) and were deliberately
NOT started at extreme context depth to avoid regressions:
  • Liquify interactive tool (integration map scouted above — a fresh session can
    implement it fast by mirroring SPRAY).
  • Pixel Scaler (needs canvas+all-layers resize integration).
  • QA title-assert hardening (needs a text/known-pixel check in the harness).
  • Final full-suite QA run + PR (do after Liquify or after descoping it).
TO RESUME: re-arm the loop on this file in a fresh session
(`~/.claude/hooks/task-loop-guard.sh --arm .claude/TASKS.md`) and delete this
loop:off block. Each remaining item is independently pickable.
-->
loop:off
