## DRAW v2.0.0

> Released 2026-08-24

The biggest release yet — 353 commits since v1.9.0. A full image-effects
system, an experimental anti-aliasing mode across every drawing tool, asset
Kits, multiple isolated windows, target-aware drag-and-drop, an OS hardware
cursor, live theming, and a large pile of fixes and performance work.

### New Features

**Effects — a full "Eye Candy"-style EFFECTS menu**
- **SHAPE effects** (act on the layer's shape/silhouette): Fire, Smoke, Snow, Water Drops, Electrify, Glass, Drip, Icicles, Motion Trail, Corona, Backlight, Cutout, Bevel, Chrome, Extrude, Outer/Inner Glow, Drop/Perspective Shadow.
- **TEXTURE engines**: Wood, Marble, Brick Wall, Weave, Reptile Skin, Stone Wall, Diamond Plate, Lightning, Brushed Metal, Ripples, Animal Fur, Texture Noise, Rust — most with type variants.
- **RENDER engines**: Render Sky (day/night/space — sun, moon, stars, nebula), Render Grid (endless perspective), Terrain, Clouds & Difference Clouds (fBm), Lens Flare (click-to-place), Kaleidoscope (click-to-set mirror centre).
- Every effect dialog has a **split ORIG/ADJ live preview loupe**, **mouse-wheel sliders**, a visual **angle dial**, a **seed**, a **MIX** (blend-with-original) slider, and a **Reset-to-Default** button.
- **Blend/Fade Last Effect** exposes all 19 blend modes and an "Isolate onto new layer" option.
- Effects can be **clipped to the active selection** or run **selection-as-shape**; effects are multi-layer aware with unified undo and a progress overlay.
- Sharpen is now a full Photoshop-style **Unsharp Mask**; Mosaic gains cell shapes (square/rect/triangle/hex/voronoi/random).

**Anti-Aliasing mode** (experimental, default OFF, per-document)
- Soft, coverage-blended edges for **Brush/Dot** (2px+), **Line** (Xiaolin Wu), **Ellipse/Circle** (outline + fill), **Poly-line**, **Bezier**, **Poly-fill**, and **all Smart Shapes** (strokes, arcs, and fills).
- A soft **coverage-subtract Eraser** — round brushes (2px+) erase with a feathered edge.
- Toggle from **Edit → Anti-Aliasing** or the shared Edit Bar **Edge-Mode** button (Pixel-Perfect ⟷ AA, mutually exclusive; an "AA" status badge shows when on).
- Crisp by design: 1px brush, rectangles, square brushes/erasers, and spray.

**Kits** — export and install asset **kits**: ZIP bundles of fonts, palettes, brushes, and themes, with a manifest, per-type item picker, conflict prompts, and headless export/install flags.

**Multiple instances** — run isolated DRAW windows with a shared clipboard and **Copy / Paste / Send Layer** between them (Settings → General → Allow Multiple Instances; `Ctrl+Alt+N`). Background music plays only in the primary window.

**Target-aware drag-and-drop** — drop an image onto the **canvas** (stamp onto the current layer, undoable), the **layer panel** (new layer), the **brush bin** (custom brush, new page if full), or the **menu bar** (open in a new isolated window). Hold Shift to center; larger-than-canvas images route through the interactive import flow.

**OS hardware cursor** — icon cursors via `_MOUSECURSOR` give render-free canvas moves; toggle in Settings → Cursors & Tooltips.

**Live theming** — a complete **DARK** theme, instant theme switching with no restart (`Ctrl+Shift+F5` to hot-reload colors + icons), a theme picker as the first Appearance option, and a reusable `/create-draw-theme` workflow.

**User-installable fonts** — TDF, bitmap, and Color Bitmap fonts installable by the user, with font-preview strips in the Text-tool and item pickers.

**Selections** — flip (H/V), rotate (`>`/`<`), and scale (PageUp/PageDown) now auto-float a marquee selection and persist it on commit.

**Picker** — Alt+click eyedrops **any on-screen pixel** (GUI chrome included) via a loupe magnifier.

**Also new**: `--option KEY=VALUE` CLI overrides + `--options-list` registry; OS-enforced min/max window size (`_WINDOWSIZELIMIT`, HiDPI-aware); pan + zoom in the ANSI export preview; **Resize Image with Content** dialog (scale canvas + pixels together); brush size control split (Ctrl+wheel = presets 1/3/5/7, `[`/`]` = +1 fine step); remote build/test dashboards for the mac/Windows fleet.

### Improvements

- **Performance**: box-blur moved to an -O3 C++ kernel (18.4×, bit-exact) powering the whole spatial-effects menu; -O3 kernels for median/edge/emboss/sharpen/pixelate; the layer blend compositor unified into one -O3 kernel; no MIDI/OPL spin-up at startup when music is off; gradient swatches rebuild only when FG/BG changes; `FPS_CURSOR` default 240 → 60.
- **UI**: EFFECTS reorganized into flyout submenu categories; a shared DROPDOWN widget, angle **dial** widget, and click-to-set-center widget; RENDER/SHAPE/TEXTURE categories marked (WIP) where still growing.
- Clean build — 0 compiler warnings.

### Bug Fixes

- **Windows/HiDPI**: fixed startup crashes on high-DPI displays; deferred-snap window resize for GLFW; `_RESIZE` echo dimension-match so restore-from-maximized redraws; hide the CMD console flash when launching a new window.
- **macOS**: native rounded-squircle Retina app icon; hardware cursor sized to the native PNG; headless DISPLAY probe no longer misfires under `$IF LINUX` (which includes Mac).
- **Window/startup**: console-only CLI ops no longer flash a window; minimum-size polish (padding, menu-bar fit, dialog cap); opening a flat image no longer resizes the window.
- **Cursor/z-order**: cursor renders above floating windows; floating windows win the input hit-test; `REGION_CANVAS` registered as the z-stack floor; pointer no longer vanishes after Alt+1–9 quick-open.
- **Text**: apron-aware render (off-canvas font layers no longer clip); rasterize before transform; kerning rebound to Alt+Left/Right; close font dropdown on click-away.
- **Fonts/dialogs**: `{NumGlyphs}` can no longer crash the font menu; dropdown open/close spasm and wheel snap-back fixed.
- **Selection/paint**: instant non-destructive scale for all multi-selected layers; Ctrl+Alt clone-stamp edge-drag keeps the selection live; pastes stay in clone mode so committing never wipes the layer; Posterize dither preserves color.
- **Other**: strip inline `;`/`#` comments from config values; deep hotkey audit across code, menus, docs & manual; restore the AUDIO menu; save no longer leaves a stuck modifier; browser double-click/Enter opens the file.

### Internal / Refactoring

- QA harness extracted into a standalone toolkit (DRAW keeps a thin adapter).
- Hardware cursor became the **sole** icon-cursor path; the software cursor was removed.
- Drop dispatch extracted into `INPUT/DROP.BM`; z-order unified into one stack for render + input; remote fleet build/test dashboards added.

### Breaking Changes

- **Toolchain**: the hardware cursor path uses GLFW (`_MOUSECURSOR`). This has merged upstream into QB64-PE (v4.6.0+), which is now the default build compiler — pre-GLFW compilers can no longer build DRAW.
- No user-facing file-format or config-key breaks — Anti-Aliasing is default OFF and byte-for-byte identical to previous output when off.
