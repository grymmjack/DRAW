# Create DRAW Theme Skill

When the user invokes this skill (e.g. "/create-draw-theme", "make a new theme",
"create a dark/light theme"), create a new DRAW theme under `ASSETS/THEMES/<NAME>/`.
Execute the steps below in order.

---

## What a DRAW theme is

A theme is a folder `ASSETS/THEMES/<NAME>/` containing:

- **`THEME.CFG`** — the colors + visual settings (INI-style: `[SECTION]` headers,
  `KEY = value`; comments start with `#`/`;`, keys case-insensitive). Values are:
  - **Color**: `R,G,B,A` (each 0-255). ~300 of these drive every panel/bar/dialog/cursor.
  - **Scalar**: a plain int / float (heights, widths, opacities), or a palette **index**
    (a bare int like `STATUS_BG = 8`), or a bit pattern (e.g. `-21846`), or a string.
- **`IMAGES/`** — toolbar/panel/dialog PNG assets (`TOOLBOX/`, `DRAWER/`, `LAYERS/`,
  `EDITBAR/`, `ADVANCEDBAR/`, `MSGBOX/`, `FILEDIALOG/`, `TEXTBAR/`, `PATTERNS/`, …).
- **`CURSORS/`, `FONTS/`, `SOUNDS/`, `MUSIC/`**, `splash.png`, `THEME.BI`.

DRAW loads assets from the **active** theme dir (`ASSETS/THEMES/<CFG.THEME>/…`) —
notably the toolbar (`GUI/TOOLBAR.BM`) reads icons straight from there with **no
DEFAULT fallback**, so a theme MUST ship its own `IMAGES/` (and cursors/fonts).
`THEME.CFG` overrides the compiled-in defaults at runtime (loaded by
`CFG/CONFIG-THEME.BM` → `THEME_load`). The DEFAULT theme is already dark-grey.

---

## Step 1 — Name + base

Ask the user for the **theme name** (folder-safe, UPPERCASE by convention, e.g.
`DARK`, `SOLARIZED`) unless they gave one. Base every new theme on `DEFAULT`
(the reference with a complete, correct asset set):

```bash
cp -r ASSETS/THEMES/DEFAULT ASSETS/THEMES/<NAME>
```

Git note: the copied PNGs are byte-identical to DEFAULT, so git content-dedups
them — committing a new theme costs ~the size of its edited `THEME.CFG`, not the
6.4 MB working tree. Fix the header comment: `sed -i '1,3 s/DEFAULT/<NAME>/g' ASSETS/THEMES/<NAME>/THEME.CFG`.

## The background/foreground model

Both helpers below share one model, so the chrome and the button images match:
a theme is a **BG gradient** (`--bg-dark` … `--bg-light`) plus a **FG** color.
Pixels/colors are mapped by luminance — dark → BG-dark (backgrounds), mid → BG-light
(borders/bevels), bright → FG (text, icons, button glyphs). Pass hex like `#1e1e1e`.

## Step 2 — Recolor `THEME.CFG` (the panels/bars/dialogs)

Pick the mode that matches the request:

- **Arbitrary scheme** (e.g. "dark purple bg, pink fg" / "cyan bg, violet fg"):
  ```bash
  python3 .claude/skills/create-draw-theme/darken-theme.py --recolor \
      --fg '#FF66CC' --bg-dark '#160826' --bg-light '#3a1a52' \
      ASSETS/THEMES/<NAME>/THEME.CFG
  ```
- **Darker variant of DEFAULT** (DEFAULT is already dark grey — push toward black,
  keep bright text): `darken-theme.py ASSETS/THEMES/<NAME>/THEME.CFG`
  (tune `--gamma 1.6` darker, `--protect 0.82` keep-bright cutoff)
- **Flip dark↔light** (invert lightness, keep hue/sat): add `--invert`.
- **Bespoke** — hand-edit. High-signal keys: `TOOLBAR_BG`, `DRAWER_PANEL_BG`,
  `LAYER_PANEL_BG`/`_ROW_BG`/`_HEADER_BG`, `MENU_BAR_BG`/`_SEL_BG`, `DIALOG_BG` +
  `DIALOG_*`, `STATUS_BG_COLOR`/`_FG_COLOR`, `PALETTE_MENU_BG`, `GRID_COLOR_FG`,
  accent/selection (`*_SEL_BG`). Keep alpha on RGBA lines; leave index scalars (`= 8`).

Only `KEY = R,G,B[,A]` color lines are rewritten; scalars/strings/indices/bit
patterns pass through untouched.

## Step 3 — Recolor `IMAGES/` (toolbox + all button/icon PNGs)

DRAW's buttons are baked PNGs: a near-black **glyph** on a 3-shade grey **bevel**.
`recolor-images.py` maps each opaque pixel by luminance — glyph → FG, bevel → the
BG gradient — so buttons stay 3D but re-hued, and transparency is preserved. Use the
SAME `--fg/--bg-dark/--bg-light` as Step 2 so chrome and buttons match:

```bash
python3 .claude/skills/create-draw-theme/recolor-images.py \
    --fg '#DCDCDC' --bg-dark '#1e1e1e' --bg-light '#5c5c5c' \
    ASSETS/THEMES/<NAME>/IMAGES
# optional: --glyph-max 40 (luminance <= this = glyph)  ·  add CURSORS dir to also recolor cursors
```

**Colored content icons are preserved automatically.** The recolor model only fits
grey glyph-on-bevel *chrome* (buttons). Icons whose colors ARE the information —
the mini **color-palette strip** (`PALETTE/palette-thin.png`), pattern swatches
(`PATTERNS/`), the red/blue **msgbox** badges, colored **filetype** icons, the
color-mode/mixer swatches — are skipped: any image whose mean saturation exceeds
`--sat-max` (default 12) passes through untouched. Do **not** grayscale these — a
dark theme still wants a real color palette. Pass `--force-all` only if you truly
want every icon re-hued; lower `--sat-max` to also recolor near-grey text-style
buttons. The run prints `recolored N chrome image(s), kept M colored content icon(s)`.

(No system Python packages touched — the script self-bootstraps a Pillow venv at
`~/.cache/draw-theme-venv` on first run.)

### Recipes

| Theme | Step 2 + Step 3 shared flags |
|-------|------------------------------|
| Darker grey (the shipped `DARK`) | `--fg '#DCDCDC' --bg-dark '#1e1e1e' --bg-light '#5c5c5c'` |
| Dark purple bg / pink fg | `--fg '#FF66CC' --bg-dark '#160826' --bg-light '#3a1a52'` |
| Cyan bg / violet fg (cyberpunk) | `--fg '#B388FF' --bg-dark '#062026' --bg-light '#0f4c52'` |

Run Step 2 with `--recolor` + those flags on `THEME.CFG`, then Step 3 with the same
flags on `IMAGES/`. Cursors: pass `ASSETS/THEMES/<NAME>/CURSORS` to Step 3 too only
if you want them themed (they can get hard to see on the canvas — usually skip).

## Step 4 — Verify

Themes have no compile step (runtime assets). Verify the theme loads and looks right:

- It appears automatically wherever DRAW lists themes (and in **DRAW KITS** export —
  `KIT_enumerate(KIT_TYPE_THEME)` scans `ASSETS/THEMES/`).
- To preview it, set `THEME=<NAME>` in the config DRAW runs with, or switch in
  Settings. **Do not run the QA/smoke harness** — Rick tests the running app himself
  (memory `feedback_user_tests_qa`). A headless render to PNG is fine:
  ```bash
  xvfb-run -a ./DRAW.run --config <throwaway.cfg-with THEME=<NAME>>   # offscreen, no desktop window
  ```

## Step 5 — Report

Tell the user the theme path, how many color lines changed, and how to activate it
(Settings ▸ theme, or `THEME=<NAME>` in DRAW.cfg). Mention images are inherited from
DEFAULT unless recolored.

---

## Notes

- **Never** edit `ASSETS/THEMES/DEFAULT/` — it's the reference base. Always copy first.
- A theme is self-contained: DRAW does not merge two themes, so every asset the UI
  needs must exist in the theme dir. Copying DEFAULT guarantees completeness.
- The darken/​invert transform is a fast first pass; hand-tune the high-signal keys
  in Step 2 for a polished result.
