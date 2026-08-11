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

## Step 2 — Recolor `THEME.CFG`

Pick the approach that matches the request:

- **Darker variant** (default for "dark theme" — DEFAULT is already dark, so push
  it toward true black while protecting bright text/icons):
  ```bash
  python3 .claude/skills/create-draw-theme/darken-theme.py ASSETS/THEMES/<NAME>/THEME.CFG
  # tune: --gamma 1.6 (higher = darker), --protect 0.82 (keep lightness >= this as-is)
  ```
- **Flip a dark theme to light** (or vice-versa) — invert lightness, keep hue/sat:
  ```bash
  python3 .claude/skills/create-draw-theme/darken-theme.py --invert ASSETS/THEMES/<NAME>/THEME.CFG
  ```
- **Bespoke palette** — edit `THEME.CFG` by hand / with `sed`. The high-signal keys:
  `TOOLBAR_BG`, `DRAWER_PANEL_BG`, `LAYER_PANEL_BG`/`_ROW_BG`/`_HEADER_BG`,
  `MENU_BAR_BG`/`_SEL_BG`, `DIALOG_BG` + `DIALOG_*` (frame/label/toggle/button),
  `STATUS_BG_COLOR`/`_FG_COLOR`, `PALETTE_MENU_BG`, `GRID_COLOR_FG`,
  accent/selection colors (`*_SEL_BG`, `*_ROW_SEL_BG`). Keep **alpha** on RGBA lines
  and leave palette-index scalars (`= 8`) alone.

The helper only rewrites `KEY = R,G,B[,A]` color lines (HLS lightness map, hue/sat
preserved); scalars, strings, indices, and bit patterns pass through untouched.

## Step 3 — (Optional) recolor images

For a fully cohesive theme, recolor `IMAGES/` (esp. `TOOLBOX/` icons) and cursors
to suit — the copied ones are DEFAULT's. For a functional/test theme, leaving them
is fine (transparent-glyph icons read acceptably on either ground). Only pursue
image recoloring if the user asks for visual polish.

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
