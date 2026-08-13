# DRAW — Keyboard Input Inventory (code-derived)

Exhaustive inventory of every keyboard behavior in DRAW, derived from source logic
(not comments-as-spec). Two dispatch paths coexist during the input re-architecture:

- **Modern / dispatched** — declarative bindings in `INPUT/INPUT.BM` `INPUTS_register_all`
  with `dispatched = TRUE`. These fire through `INPUT_dispatch_frame` →
  `CMD_execute_action <id>`.
- **Legacy / inline** — `_KEYDOWN`/`INKEY$` handlers in `INPUT/KEYBOARD.BM`. Bindings
  registered `dispatched = FALSE` are **metadata-only** (audit visibility); legacy code
  still owns their dispatch.

## Per-frame order (the seam that makes this work)

`DRAW.BAS` main loop:

| Line | Call | Role |
|---|---|---|
| `DRAW.BAS:463-471` | capture `_KEYHIT` → `LAST_KEYHIT_RAW&`, `KEYHIT_CHAR$` | one keyhit/frame cached for legacy fallbacks |
| `DRAW.BAS:478` | `MODIFIERS_update` | polls Ctrl/Shift/Alt via `_KEYDOWN`, applies latches |
| `DRAW.BAS:508` | `MOUSE_input_handler` | |
| `DRAW.BAS:512` | **`KEYBOARD_input_handler`** (legacy) | runs FIRST |
| `DRAW.BAS:519` | `INPUT_update_context` | builds `INPUT_CONTEXT` bitmask |
| `DRAW.BAS:520` | `INPUT_detect_events` | edge-detects → `DETECTED_EVENTS` |
| `DRAW.BAS:521` | **`INPUT_dispatch_frame`** (modern) | runs SECOND, fires `CMD_execute_action` |
| `DRAW.BAS:770-771` | `MOUSE_input_handler_loop`, `KEYBOARD_input_handler_loop` | post-render (Alt+O/Alt+X) |

**Double-fire prevention:** `CMD_execute_action` increments `INPUT_DISPATCH_DEPTH`
(`COMMAND.BM:721`, decrements `COMMAND.BM:5262`). Legacy `KEYBOARD_tools` /
`KEYBOARD_colors` early-exit when `INPUT_DISPATCH_DEPTH = 0` and the letter is flagged in
`INPUT_LETTER_DISPATCHED()` (set in `INPUT_register%`, `INPUT.BM:607-617`, **only when
`requireMods = 0`**). When the dispatcher later calls back into `KEYBOARD_tools "<letter>"`
from the action body, depth > 0 so the switch actually runs.

---

## 1. QB64-PE input quirks actually in play

- **`_KEYDOWN(physicalCode)` vs `_KEYHIT`.** Modifier combos are unreliable via `_KEYHIT`
  on Linux/SDL2 (CLAUDE.md gotcha #6). Nearly all chord/modifier handling uses
  `_KEYDOWN` + a `STATIC pressed%` edge guard. `_KEYHIT` is used only for: the per-frame
  cache (`DRAW.BAS:463`), macOS Alt tracking (`MODIFIERS_track_alt_keyhit`), buffer
  draining, and Windows Ctrl+comma (VK 188).
- **Shifted-ASCII reporting.** For printable symbol keys, `_KEYDOWN` reports the *shifted*
  ASCII, not `(physical, MOD_SHIFT)`. So DRAW binds the shifted codepoint directly with no
  required SHIFT: Shift+' → keycode **34** (`INPUT.BM:291`), Shift+\ → **124**
  (`INPUT.BM:277`), `>` → **62** / `<` → **60** (`KEYBOARD.BM:2234,2251`), `+`/`=` and
  `-`/`_` handled as pairs (`KEYBOARD.BM:2750-2756`).
- **`STATIC pressed%` edge guards** everywhere: `IF _KEYDOWN(kc) THEN IF NOT was% THEN …:
  was%=TRUE ELSE was%=FALSE`. Collapses level-triggered `_KEYDOWN` to one fire per press.
  The modern path does the same via `KEY_DOWN_LAST()` per binding + a per-frame
  `INPUT_KC_ENQUEUED`/`INPUT_KC_FRAME` version-counter (`INPUT.BM:885-914`) so a key with
  multiple bindings (M + Ctrl+M on 109) enqueues at most one event.
- **`KEYBOARD_SUPPRESS_FRAMES%`** (`KEYBOARD.BM:3214-3217`): after a native dialog closes,
  SDL2 reports stale `_KEYDOWN`; `MOUSE_cleanup_after_dialog` sets this to 3 and the
  handler `EXIT SUB`s until it drains (prevents a filename's letters triggering hotkeys).
- **`MODIFIERS` latch** (`MODIFIERS.BM:74-82, 113-133`): `MODIFIERS_force_release` latches
  a still-held modifier to report FALSE until physically released — guards against SDL2
  dropping a key-up during a native dialog (the "stuck Alt after Ctrl+Alt+Shift+S" bug).
- **macOS Alt** (`MODIFIERS.BM:37-47, 63-68`): `_KEYDOWN` unreliable for Option; tracked
  via `_KEYHIT` edges into `MAC_ALT_HELD%`.
- **Ctrl/Alt INKEY$ drain** (`KEYBOARD.BM:3223-3263`): while Ctrl or Alt is held, the
  `INKEY$`/`_KEYHIT` buffer is drained and `keypress$`/`KEYHIT_CHAR$` cleared so leaked
  control chars can't masquerade as ESC/Z/Y in the INKEY$ tool/color path.

### Modifier model (`INPUT/MODIFIERS.BM`, `CORE/HELPERS.BM`)
`MODIFIERS_update` (`MODIFIERS.BM:53`) polls `KEY_LCTRL&/RCTRL&/LSHIFT&/RSHIFT&/LALT&/RALT&`
(physical codes 100303-100308, `_COMMON.BI:35-40`) and precomputes `.ctrl/.shift/.alt`,
plus `.ctrlOnly/.shiftOnly/.altOnly/.ctrlShift/.ctrlAlt/.shiftAlt/.ctrlShiftAlt/.none`.
`MODS_NOW%` (`HELPERS.BM:168`) packs current state into `MOD_CTRL(1)|MOD_SHIFT(2)|MOD_ALT(4)`
(`HELPERS.BI:49-52`) for the dispatcher's `requireMods`/`forbidMods` bitmasks.

---

## 2. Context bitmask (`INPUT_CONTEXT`, built each frame in `INPUT_update_context`)

`INPUT.BI:141-184`, set in `INPUT.BM:753-830`. A binding fires only if
`(ctx AND requireCtx) = requireCtx` AND `(ctx AND forbidCtx) = 0`.

| Bit const | Set when | Source |
|---|---|---|
| `CTX_TEXT_ACTIVE` | `CURRENT_TOOL=TOOL_TEXT AND TEXT.ACTIVE` | `INPUT.BM:760` |
| `CTX_MOVE_ACTIVE` | `MOVE.ACTIVE` | `INPUT.BM:764` |
| `CTX_MAGIC_WAND_ACTIVE` | `MARQUEE.MAGIC_WAND_MODE` | `INPUT.BM:766` |
| `CTX_GRID_OFFSET_PICK` | `GRID_OFFSET_PICK_MODE%` | `INPUT.BM:768` |
| `CTX_REFIMG_REPOSITION` | `REFIMG.REPOSITION` | `INPUT.BM:770` |
| `CTX_COMMAND_PALETTE_OPEN` | `CMD_PALETTE.visible%` | `INPUT.BM:772` |
| `CTX_G_HELD` | `GRID_G_KEY_ARMED%` (armed on G-down no-mods, stays through added mods) | `INPUT.BM:778` |
| `CTX_M_HELD` | M(109/77) down, no Ctrl/Alt | `INPUT.BM:779` |
| `CTX_Z_HELD` | Z(122/90) down, no Ctrl/Alt | `INPUT.BM:782` |
| `CTX_E_HELD` | E(101/69) down, no Ctrl/Alt | `INPUT.BM:785` |
| `CTX_F_HELD` | F(102/70) down, no Ctrl/Alt | `INPUT.BM:788` |
| `CTX_W_HELD` | W(119/87) down, no Ctrl/Alt | `INPUT.BM:791` |
| `CTX_SPACE_HELD` | Space(32) down, no Ctrl/Alt | `INPUT.BM:794` |
| `CTX_ALT_HELD` | `MODIFIERS.alt%` | `INPUT.BM:797` |
| `CTX_SS_DRAGGING` | SS 3D cube OR SS polygon dragging | `INPUT.BM:800-801` |
| `CTX_DRAWING_IN_PROGRESS` | `TOOL_LINE AND LINE_TOOL.DRAGGING` | `INPUT.BM:805` |
| `CTX_OVER_*` (32-47) | region under cursor via `REGION_hit_test%` | `INPUT.BM:808-827` |

Note: several declared context bits are **never set** by `INPUT_update_context`:
`CTX_FILE_DIALOG_OPEN`, `CTX_IMAGE_IMPORT_ACTIVE`, `CTX_SETTINGS_OPEN`,
`CTX_POPUP_MENU_OPEN`, `CTX_TRANSFORM_ACTIVE` (declared `INPUT.BI:142-151`). See SEAMS.

---

## 3. Single-key (no modifier) map

### 3a. Tool letters — dispatched=TRUE, legacy body owns impl (`KEYBOARD_tools`, `KEYBOARD.BM:90`)

All registered with `forbidMods = allMods (Ctrl|Shift|Alt)`, `forbidCtx = CTX_TEXT_ACTIVE OR
<chord-held>`. `INPUT_LETTER_DISPATCHED()` flagged → INKEY$ path suppressed at depth 0.

| Key | kc | actionId | Action / notes | reg |
|---|---|---|---|---|
| B | 98 | 101 | Brush | `INPUT.BM:167` |
| D | 100 | 102 | Dot | `INPUT.BM:168` |
| F | 102 | 103 | Fill; forbids `chordHeldNoF` (allows own CTX_F_HELD on press) | `INPUT.BM:169` |
| L | 108 | 105 | Line | `INPUT.BM:170` |
| P | 112 | 106 | Polygon (outline) | `INPUT.BM:171` |
| R | 114 | 108 | Rectangle (outline) | `INPUT.BM:173` |
| C | 99 | 110 | Ellipse (outline) | `INPUT.BM:175` |
| E | 101 | 118 | Eraser; forbids `chordHeldNoE` + `CTX_DRAWING_IN_PROGRESS`; **tap/hold owned by legacy `KEYBOARD_handle_eraser_hold`** | `INPUT.BM:177` |
| M | 109 | 112 | Marquee; forbids `chordHeldNoM` | `INPUT.BM:178` |
| W | 119 | 117 | Magic wand; forbids `chordHeldNoW` | `INPUT.BM:179` |
| V | 118 | 113 | Move (KEYBOARD_tools re-routes to 316 Flip-V when `MOVE.ACTIVE`) | `INPUT.BM:180` |
| T | 116 | 114 | Text (VGA font) | `INPUT.BM:181` |
| Z | 122 | 1701 | Zoom tool; forbids `chordHeldNoZ` | `INPUT.BM:183` |
| I | 105 | 104 | Picker (legacy also does bevel-rect inner style branch) | `INPUT.BM:184` |
| S | 115 | 1706 | Smart Shapes activate; **double-tap<0.6s cycles** (`KEYBOARD.BM:208-219`); forbids `CTX_DRAWING_IN_PROGRESS` | `INPUT.BM:185` |
| Q | 113 | 122 | Bezier | `INPUT.BM:186` |
| K | 107 | 1702 | Spray | `INPUT.BM:187` |
| O | 111 | 1707 | Bevel-rect outer style (only meaningful under `TOOL_SS_BEVEL_RECT`) | `INPUT.BM:188` |
| H | 104 | 315 | **Flip Horizontal — dispatched=FALSE** (legacy inline `KEYBOARD.BM:111-114`); universal | `INPUT.BM:191` |
| X | 120 | 517 | Swap FG/BG | `INPUT.BM:395` |
| `[` | 91 | 601 | Brush size − | `INPUT.BM:400` |
| `]` | 93 | 602 | Brush size + | `INPUT.BM:401` |

**Legacy `KEYBOARD_tools` extra behaviors** (run only when dispatcher calls back, depth>0,
or for the non-flagged plain H): Shift+P/R/C/T pick the *filled/tiny* variant via live
`_KEYDOWN(LSHIFT/RSHIFT)` check inside the CASE (`KEYBOARD.BM:151,162,171,263`); M/W suppress
re-sound when already in that mode; `I`/`O` bevel-rect style branches; `GRID_G_KEY_ARMED%`
early-exit at `KEYBOARD.BM:108`.

### 3b. Digits 0-9 — opacity (dispatched=TRUE, `KEYBOARD_colors` suppressed)

`forbidCtx = CTX_TEXT_ACTIVE OR CTX_Z_HELD OR CTX_SS_DRAGGING` (`INPUT.BM:381-392`).

| Key | kc | actionId | Opacity | Also (context-shadowed) |
|---|---|---|---|---|
| 1 | 49 | 501 | 10% | Z+1 zoom 100% (9100); SS-poly 11 sides; dice D12; light 0.2× |
| 2 | 50 | 502 | 20% | Z+2 (9101); SS-poly 12; dice D20; light 0.4× |
| 3 | 51 | 503 | 30% | Z+3 (9102); SS-poly 3; dice D30; light 0.6× |
| 4 | 52 | 504 | 40% | Z+4 (9103); SS-poly 4; dice D4; light 0.8× |
| 5 | 53 | 505 | 50% | Z+5 (9104); SS-poly 5; light 1.0× |
| 6 | 54 | 506 | 60% | Z+6 (9105); SS-poly 6; dice D6; light 1.2× |
| 7 | 55 | 507 | 70% | Z+7 (9106); SS-poly 7; light 1.4× |
| 8 | 56 | 508 | 80% | Z+8 (9107); SS-poly 8; dice D8; light 1.6× |
| 9 | 57 | 509 | 90% | Z+9 (9108); SS-poly 9; light 1.8× |
| 0 | 48 | 510 | 100% | Z+0 zoom 3200% (9109); SS-poly 10; dice D10; light 1.0× |

Digit reservations during SS drag are handled by `INPUT_update_context` setting
`CTX_SS_DRAGGING` **and** by legacy guards in `KEYBOARD_colors` (`KEYBOARD.BM:34-45`) plus
`KEYBOARD_handle_shape_modifiers` (`KEYBOARD.BM:2602-2714`). Also `KEYBOARD_input_handler`
skips `KEYBOARD_colors` entirely when Z held (`KEYBOARD.BM:3386`).

### 3c. Function keys — dispatched=TRUE (`INPUT.BM:253-265`), forbid `CTX_TEXT_ACTIVE`

| Key | kc | actionId | Action |
|---|---|---|---|
| F1 | 15104 | 8001 | Drawer brush mode |
| F2 | 15360 | 8002 | Drawer gradient mode |
| F3 | 15616 | 8003 | Drawer pattern mode |
| F4 | 15872 | 434 | Toggle preview window |
| F5 | 16128 | 435 | Toggle edit bar |
| F6 | 16384 | 8006 | Pixel-perfect toggle |
| F7 | 16640 | 8007 | Symmetry cycle |
| F8 | 16896 | 8008 | Fill-Adjust toggle |
| F10 | 17408 | 402 | Toggle status bar |
| F11 | 34048 | 403 | Toggle all UI |

**Not dispatched (legacy `_KEYDOWN`, custom-brush/charmap contexts):**
- `KEYBOARD_handle_function_keys` (`KEYBOARD.BM:385`): backtick/tilde (96/126) → action 412
  toggle brush cursors, unless custom brush active, SS-polygon (snap/lock verts), or Bezier
  session (toggle handles) — `KEYBOARD.BM:400-421`.
- `KEYBOARD_handle_custom_brush` (`KEYBOARD.BM:2151`): **F9=17152** recolor (`:2268`),
  **F12=34304** export brush (`:2306`). Note these differ from the modern F12=28416.
- Text/charmap "Use Chars" mode maps **F1-F12 to block glyphs** with codes 15104/15360/
  15616/15872/16128/16384/16640/16896/17152/17408/**133120(F11)**/**134144(F12)**
  (`KEYBOARD.BM:2049-2096`) — three different F11/F12 physical codes appear across contexts.

### 3d. Other single keys

| Key | kc | Path | Action | ref |
|---|---|---|---|---|
| Tab | 9 | dispatched 401 | Toggle toolbar | `INPUT.BM:268` |
| `\` | 92 | dispatched 8009 | Toggle brush shape | `INPUT.BM:276` |
| `\|` (Shift+\) | 124 | dispatched 8009 | Toggle brush shape (shifted-ASCII form) | `INPUT.BM:277` |
| `'` | 39 | dispatched 8101 | Toggle grid visibility | `INPUT.BM:290` |
| `"` (Shift+') | 34 | dispatched 8102 | Toggle pixel grid | `INPUT.BM:291` |
| `;` | 59 | dispatched 8104 | Toggle snap-to-grid | `INPUT.BM:293` |
| `/` | 47 | dispatched 8105 | Toggle grid alignment mode | `INPUT.BM:294` |
| `#` | — | legacy INKEY$ → 441 | Toggle canvas border (`KEYBOARD_colors`) | `KEYBOARD.BM:62` |
| `*` | — | legacy INKEY$ → 433 | Random music track (if music enabled) | `KEYBOARD.BM:57` |
| `?` | — | legacy INKEY$ | `CMD_show_palette` (command palette w/ search) | `KEYBOARD.BM:3375` |
| `{` | — | legacy INKEY$ → 428 | Prev music track (if enabled) | `KEYBOARD.BM:3393` |
| `}` | — | legacy INKEY$ → 427 | Next music track (if enabled) | `KEYBOARD.BM:3396` |
| `>` (Shift+.) | 62 | legacy `_KEYDOWN` | Rotate 90 CW (319) / TRANSFORM_rotate_step / import rotate | `KEYBOARD.BM:2234, 630` |
| `<` (Shift+,) | 60 | legacy `_KEYDOWN` | Rotate 90 CCW (320) / TRANSFORM_rotate_step / import rotate | `KEYBOARD.BM:2251, 631` |
| `` ` `` | 96 | legacy | Custom-brush outline toggle (when active) | `KEYBOARD.BM:2284` |
| `.` `,` | 46 44 | see grid | Increase/Decrease grid size (actions 904/905) — registered in CMD only, see SEAMS | `COMMAND.BM:299-300` |

### 3e. Special keys (context-dependent, mostly `KEYBOARD_tools` SELECT CASE + handlers)

| Key | kc | Behavior by context | ref |
|---|---|---|---|
| **ESC** | 27 | Priority chain in `KEYBOARD_tools`: grid-offset-pick cancel → Palette-Ops deactivate → layer-drag cancel → Fill-Adjust cancel → TRANSFORM cancel → MOVE cancel → TEXT apply → BEZIER cancel → POLYGON cancel → wand-selection clear → marquee clear. Also drawer/blend popups close earlier (`:3150-3159`), menubar/import/crop/refimg/palette handlers each consume ESC first. | `KEYBOARD.BM:276-322` |
| **ENTER** | 13 | `KEYBOARD_tools`: text newline / Fill-Adjust commit / TRANSFORM commit / BEZIER commit / POLYGON finish / MOVE commit→marquee. Import/crop/refimg/palette/menubar consume first. | `KEYBOARD.BM:323-348` |
| **Space** | 32 | Sets `CTX_SPACE_HELD`; pan (Space+Drag) owned by MOUSE. No keyboard action. | `INPUT.BM:794` |
| **Arrows** | 18432/20480/19200/19712 | Heavily context-dependent — see §6. | multiple |
| **Home/End** | 18176/20224 | Custom-brush flip H/V (`:2159-2187`); text line start/end (`:1938-1992`); import flip; Ctrl+Home/End = Scale 2x H/V (331/333). | multiple |
| **PgUp/PgDn** | 18688/20736 | Custom-brush scale up/down OR Scale 2x/−50% (318/317) (`:2189-2217`); Ctrl+PgUp/PgDn = layer move up/down (703/704); import scale ×2/×0.5. | multiple |
| **Delete** | 21248 | dispatched 306 Clear selection (`INPUT.BM:280`); text delete-char (`:1994`); Ctrl+Shift+Del=702 delete layer; Shift+Del=519 BG transparent. | multiple |
| **Backspace** | 8 | dispatched 313 Fill w/ FG (`:281`); Shift+Backspace 314 Fill w/ BG (`:282`); text backspace. | multiple |

---

## 4. Chord / modifier-combo map (dispatched=TRUE unless noted)

### 4a. Ctrl+key (global) — `INPUT.BM`

| Combo | kc + mods | actionId | Action | reg |
|---|---|---|---|---|
| Ctrl+N | 110 CTRL | 209 | New canvas | `:364` |
| Ctrl+O | 111 CTRL | 201 | Open image | `:365` |
| Ctrl+S | 115 CTRL | 202 | Save | `:366` |
| Ctrl+A | 97 CTRL | 310 | Select All | `:344` |
| Ctrl+C | 99 CTRL | 303 | Copy | `:347` |
| Ctrl+X | 120 CTRL | 304 | Cut | `:350` |
| Ctrl+V | 118 CTRL | 305 | Paste | `:352` |
| Ctrl+Z | 122 CTRL | 301 | Undo | `:356` |
| Ctrl+Y | 121 CTRL | 302 | Redo | `:357` |
| Ctrl+D | 100 CTRL | 307 | Deselect (CMD 518 "Default Colors" also mapped Ctrl+D — see SEAMS) | `:338` |
| Ctrl+E | 101 CTRL | 306 | Clear Selection | `:354` |
| Ctrl+H | 104 CTRL | 332 | Hide Selection | `:346` |
| Ctrl+L | 108 CTRL | 404 | Toggle Layer Panel | `:304` |
| Ctrl+M | 109 CTRL | 2050 | Toggle Character Map | `:339` |
| Ctrl+T | 116 CTRL | 116 | Text tool (custom font) | `:355` |
| Ctrl+P | 112 CTRL | 1703 | Command palette | `:326` |
| Ctrl+B | 98 CTRL | 1101 | Capture/Clear custom brush | `:331` |
| Ctrl+R | 114 CTRL | 1501 | Toggle reference image (forbid `CTX_G_HELD`) | `:243` |
| Ctrl+Q | 113 CTRL | 212 | Quit — **dispatched=FALSE** | `:235` |
| Ctrl+0 | 48 CTRL | 405 | Reset zoom | `:370` |
| Ctrl+= | 61 CTRL | 406 | Zoom in | `:371` |
| Ctrl+- | 45 CTRL | 407 | Zoom out | `:372` |
| Ctrl+Home | 18176 CTRL | 331 | Scale 2x horizontal | `:313` |
| Ctrl+End | 20224 CTRL | 333 | Scale 2x vertical | `:314` |
| Ctrl+PgUp | 18688 CTRL | 703 | Layer move up | `:311` |
| Ctrl+PgDn | 20736 CTRL | 704 | Layer move down | `:312` |
| Ctrl+, | 44 CTRL | 2100 (ACTION_SETTINGS) | Settings — **dispatched=FALSE**, owned by `KEYBOARD_input_handler:3190-3205` (dual `_KEYDOWN(44)` + `_KEYHIT`/VK188 detect) | `:336` |

### 4b. Ctrl+Shift+key

| Combo | kc + mods | actionId | Action | reg |
|---|---|---|---|---|
| Ctrl+Shift+H | 104 CTRL+SHIFT | 316 | Flip vertical — **dispatched=FALSE** | `INPUT.BM:192` |
| Ctrl+Shift+N | 110 | 701 | New layer | `:305` |
| Ctrl+Shift+D | 100 | 707 | Duplicate layer | `:307` |
| Ctrl+Shift+R | 114 | 726 | Rename layer (forbid `CTX_G_HELD`) | `:308` |
| Ctrl+Shift+[ | 91 | 709 | Layer to bottom | `:309` |
| Ctrl+Shift+] | 93 | 708 | Layer to top | `:310` |
| Ctrl+Shift+Delete | 21248 | 702 | Delete layer | `:306` |
| Ctrl+Shift+G | 103 | 721 | Group from selection (forbid `CTX_G_HELD`) | `:320` |
| Ctrl+Shift+U | 117 | 722 | Ungroup | `:321` |
| Ctrl+Shift+I | 105 | 311 | Invert selection | `:345` |
| Ctrl+Shift+C | 99 | 322 | Copy merged | `:348` |
| Ctrl+Shift+V | 118 | 330 | Paste from OS clipboard | `:353` |
| Ctrl+Shift+S | 115 | 204 | Save As | `:367` |
| Ctrl+Shift+Q | 113 | 220 (EXPORT_QB64_ACTION) | Export QB64 project | `:369` |
| Ctrl+Shift+Z | 122 | 302 | Redo (alt) | `:358` |
| Ctrl+Shift+/ | 63 | 907 | Grid = brush size (forbid `CTX_G_HELD`) | `:207` |
| Ctrl+Shift+F5 | 16128 | 452 | Reload theme | `:259` |

### 4c. Ctrl+Alt / Ctrl+Alt+Shift

| Combo | kc + mods | actionId | Action | reg |
|---|---|---|---|---|
| Ctrl+Alt+C | 99 CTRL+ALT | 321 | Copy to new layer | `:349` |
| Ctrl+Alt+X | 120 CTRL+ALT | 323 | Cut to new layer | `:351` |
| Ctrl+Alt+E | 101 CTRL+ALT | 705 | Merge layer down | `:317` |
| Ctrl+Alt+K | 107 CTRL+ALT | 1822 | Cancel AI generation | `:316` |
| Ctrl+Alt+R | 114 CTRL+ALT | 1512 | Random palette (forbid `CTX_G_HELD`) | `:244` |
| Ctrl+Alt+Shift+E | 101 CTRL+ALT+SHIFT | 706 | Merge all visible | `:318` |
| Ctrl+Alt+Shift+S | 115 CTRL+ALT+SHIFT | 205 | Export selection | `:368` |
| Ctrl+Alt+Shift+G | 103 CTRL+ALT+SHIFT | 2020 | Grayscale preview (forbid `CTX_G_HELD`) | `:245` |
| Ctrl+Alt+O | 111/79 | 950 | Toggle CRT — **legacy `_KEYDOWN`** `KEYBOARD.BM:3453-3462` | — |
| Ctrl+F11 | 34048 CTRL | 8011 | Toggle menubar | `:265` |
| Shift+F5 | 16128 SHIFT | 449 | Toggle advanced bar | `:258` |

### 4d. Alt+key (legacy `_KEYDOWN`, no modern binding)

| Combo | Action | ref |
|---|---|---|
| Alt+O | Open .draw project dialog | `KEYBOARD.BM:3228-3239` (pre-render) & `:3591` (post-render loop) |
| Alt+X | Exit (212) | `KEYBOARD.BM:3241-3251` & `:3602` |
| Alt+1..9,0 | Open recent file slot 1..10 (`KEYBOARD_handle_recent_files`) | `KEYBOARD.BM:3476-3565` |
| Alt+U | Text: pick up style at cursor (normal mode) / pick FG+BG (char mode) | `KEYBOARD.BM:3277, 3324` |
| Alt+V | Text: paste picked style (normal mode) | `KEYBOARD.BM:3305` |
| Shift+O | Custom brush: apply outline w/ BG (when active) | `KEYBOARD.BM:2295` |

`CTRL+ALT+SHIFT+=/-` (display scale) is handled in DRAW.BAS via `_KEYHIT` (noted
`KEYBOARD.BM:3207`), outside these two files.

### 4e. Held-key chords (via `CTX_*_HELD` — dispatched=TRUE)

**G+ (grid) — `INPUT.BM:197-207`.** `GRID_G_KEY_ARMED%` armed in
`KEYBOARD_input_handler:3128-3136` (G-down with no mods; stays armed if user then adds mods).
`KEYBOARD_tools` early-exits while armed (`:108`) so G+R doesn't also select Rectangle.

| Chord | kc + mods | actionId | Action |
|---|---|---|---|
| G+R | 114 | 9001 | Reset grid offset |
| G+Shift+R | 114 SHIFT | 9002 | Reset grid size |
| G+Ctrl+R | 114 CTRL | 9003 | Reset grid all |
| G+O | 111 | 9004 | Grid offset pick mode |
| G+Right | 19712 | 9010 | Grid width + |
| G+Left | 19200 | 9011 | Grid width − |
| G+Down | 20480 | 9012 | Grid height + |
| G+Up | 18432 | 9013 | Grid height − |

**M+ (selection expand/contract) — `INPUT.BM:212-215`** (require `CTX_M_HELD`):

| Chord | kc + mods | actionId | Action |
|---|---|---|---|
| M+= | 61 | 1410 | Expand selection 1px |
| M+- | 45 | 1411 | Contract 1px |
| M+Shift+= | 61 SHIFT | 1412 | Expand large |
| M+Shift+- | 45 SHIFT | 1413 | Contract large |

**Z+ (zoom presets) — `INPUT.BM:220-229`** (require `CTX_Z_HELD`): Z+1..9,0 → 9100-9109
(100/200/300/400/500/600/700/800/1600/3200%).

**E+ / F+ / W+ (hold-to-modify at click):** `CTX_E_HELD` / `CTX_F_HELD` / `CTX_W_HELD` set
context, consumed at MOUSE click time (flood-erase / flood-fill while magic wand active) —
see mouse inventory. `KEYBOARD_tools` suppresses the F tool-switch while wand active
(`:135`), E tap/hold owned by `KEYBOARD_handle_eraser_hold` (`:3687`).

---

## 5. Text-tool context (`KEYBOARD_handle_text_tool%`, `KEYBOARD.BM:872`)

Only runs when `CURRENT_TOOL=TOOL_TEXT AND TEXT.ACTIVE`. Consumes the event and returns
TRUE (caller `EXIT SUB`s at `KEYBOARD.BM:3368`). All via `_KEYDOWN` + STATIC guards.
Because `CTX_TEXT_ACTIVE` is a `forbidCtx` on nearly every dispatched binding, the modern
path stays silent while typing — the text tool wholly owns keyboard here.

| Combo | Action | ref |
|---|---|---|
| Ctrl+Z / Ctrl+Y | Text-local undo/redo (intercepts before global) | `:883, 895` |
| Ctrl+B / Ctrl+I / Ctrl+U | Bold / Italic / Underline toggle (applies to selection) | `:914, 929, 944` |
| Ctrl+Shift+X | Strikethrough toggle | `:959` |
| Ctrl+Shift+. / Ctrl+Shift+, | Font size up / down (checks 46/62 and 44/60) | `:975, 1025` |
| Ctrl+Alt+. / Ctrl+Alt+, | Kerning up / down | `:1074, 1104` |
| Ctrl+Alt+Up / Ctrl+Alt+Down | Baseline raise / lower | `:1134, 1162` |
| Ctrl+C / Ctrl+X / Ctrl+V | Rich copy / cut / paste (internal TEXT_CLIP + `_CLIPBOARD$`) | `:1194, 1242, 1318` |
| Ctrl+A | Select all in layer | `:1388` |
| Ctrl+Left / Ctrl+Right | Word-boundary jump | `:1594, 1613` |
| Ctrl+Shift+Left / Ctrl+Shift+Right | Word-boundary select | `:1632, 1657` |
| Up / Down / Left / Right | Cursor move (repeat 0.3s→0.08s); Shift extends selection | `:1680-1936` |
| Home / End | Line start / end (Shift extends) | `:1938, 1965` |
| Delete | Delete char/selection (repeat) | `:1994` |
| Char-mode Left/Right/Up/Down/Home/End/Enter/Tab/Backspace/Delete | Grid cursor nav + edits (`TEXT_char_mode_*`) | `:1408-1587` |
| ESC | Close dropdowns else `TEXT_cancel` | `:2116` |
| Enter | Newline | `:2123` |
| Tab | Insert `CFG.CHARMAP_TAB_CHARS%` spaces | `:2126` |
| Backspace | `TEXT_backspace` | `:2135` |
| 32-126 | Insert printable char | `:2138` |
| F1-F12 (Use-Chars mode) | Quick-insert block glyphs | `:2041-2107` |

Text-tool Alt+U / Alt+V are intercepted *before* this function in
`KEYBOARD_input_handler` because Alt temporarily flips `CURRENT_TOOL` to picker
(`KEYBOARD.BM:3277, 3305, 3324`).

---

## 6. Arrow keys — full context dispatch (in call order)

Arrows are the most overloaded keys. Each earlier consumer `EXIT SUB`s.

| Order | Context guard | Behavior | ref |
|---|---|---|---|
| 1 | Menu open | Menu nav (arrows via INKEY$→codes) | `KEYBOARD_handle_menubar% :761` |
| 2 | Image import active | Ctrl=resize / Alt=pan / plain=move box; +repeat | `:562-625` |
| 3 | Crop active | (arrows fall through to marquee) | `:727` |
| 4 | Refimg reposition | Move image (Shift=×10) | `:3654-3669` |
| 5 | Command palette | Up/Down/PgUp/PgDn nav (repeat) | `:461-522` |
| 6 | Palette menu | Up/Down nav | `:818-831` |
| 7 | Text active | Cursor nav / selection (see §5) | `:1680-1992` |
| 8 | Shift only (no Ctrl/Alt, not text) | Pan canvas 24px/frame (`KEYBOARD_handle_shift_pan%`) | `:3099-3119` |
| 9 | G held | Grid resize (dispatched 9010-9013) | `INPUT.BM:202-205` |
| 10 | Shape tool dragging | Divisions/spokes/rings/SS params (Shift=×5) | `:2348-2570` |
| 11 | Marquee active | Ctrl+Arrow=nudge content (Shift=large, Alt=clone); plain=move box | `:2838-2931` |
| 12 | Move tool / Ctrl+Arrow | Nudge selection/layer (auto-capture; Ctrl+Shift=NUDGE_N; Alt=clone) | `:2949-3061` |
| — | Ctrl+Alt+Up/Down in text | Baseline (see §5) | `:1134, 1162` |

`KEYBOARD_handle_menubar%` also **blocks all other keyboard processing** while a dropdown
or overflow popup is open (`:790-796`) so arrows can't leak to marquee/move nudge.

---

## 7. Shape-tool-drag reserved keys (`KEYBOARD_handle_shape_modifiers`, `KEYBOARD.BM:2348`)

While a shape/SS tool is `DRAGGING`, these keys change parameters instead of their normal
meaning (all `_KEYDOWN` + STATIC guards; Shift often = ×5 step):

- **Arrows**: RECT h/v divisions; ELLIPSE slices/rings; LINE spokes; SS poly point-depth/
  sides; pie hole/slices; rounded-rect/tab radius; pill segments/roundness; pacman hole/
  mouth; cube rot-Y/z-depth; bevel border/bevel size; arrow head/stem; 3D-text rot/z.
  (`:2385-2570`)
- **LINE drag**: `s`(115)=cycle start cap, `e`(101)=cycle end cap (`:2573-2597`). This is
  why E and S bindings forbid `CTX_DRAWING_IN_PROGRESS`.
- **SS_POLYGON drag**: digits 3-9,0,1,2 → 3..12 sides (`:2602-2664`).
- **SS_3D_CUBE drag**: digits 4/6/8/0/1/2/3 → D4/6/8/10/12/20/30, suppressed while L held
  (`:2668-2714`).
- **3D cube/text drag (light controls)**: W/S elevation, A/D or Q/E azimuth, `=`/`-`
  elevation, `L`+digit intensity (`:2725-2827`). `KEYBOARD_input_handler:3382-3389`
  suppresses tools/colors while 3D dragging so WASD/QE/L don't fight.

---

## 8. Modal handlers that consume ALL keys first (`KEYBOARD_input_handler` gate order)

`KEYBOARD.BM:3121` — each returns TRUE→`EXIT SUB`:

1. G-arm tracking (`:3128`)
2. `KEYBOARD_handle_eraser_hold` (always, unless text) (`:3148`)
3. Drawer context menu ESC (`:3150`); blend popup ESC (`:3156`)
4. `KEYBOARD_handle_menubar%` (`:3162`)
5. `KEYBOARD_handle_image_import%` (`:3165`)
6. `KEYBOARD_handle_crop_tool%` (`:3168`)
7. `KEYBOARD_handle_refimg_reposition%` (`:3171`)
8. `KEYBOARD_handle_command_palette%` (`:3174`)
9. `KEYBOARD_handle_palette_menu%` (`:3177`)
10. Ctrl+, Settings (`:3190`)
11. `KEYBOARD_SUPPRESS_FRAMES%` drain (`:3214`)
12. Ctrl/Alt buffer drain + Alt+O/Alt+X (`:3223`)
13. `KEYBOARD_handle_custom_brush` (`:3266`)
14. Alt+U/Alt+V/char-mode Alt+U (`:3277-3362`)
15. `KEYBOARD_handle_text_tool%` (`:3368`)
16. `KEYBOARD_handle_shift_pan%` (`:3372`)
17. INKEY$ path: `?`, `KEYBOARD_colors`, `KEYBOARD_tools`, `{`/`}` music (`:3373-3401`)
18. `KEYBOARD_handle_function_keys`, `_shape_modifiers`, `_marquee_keys`, `_move_keys`,
    `_recent_files`, Ctrl+Alt+O (`:3407-3462`)

---

## 9. Action-ID map (ranges)

From `CMD_init` (`GUI/COMMAND.BM:41-334`). Hotkey strings are the CMD-registered display
labels; the **actual** binding is the dispatched/legacy path above (they can disagree —
see SEAMS). Every id below has a live `CASE` in `CMD_execute_action` (verified: 0 duplicate
CASE labels via gotcha-#17 audit).

| Range | Category | Examples |
|---|---|---|
| 101-122 | Tools (`CMD_CAT_TOOL`) | 101 Brush … 118 Eraser, 122 Bezier |
| 201-220 | File | 201 Open, 202 Save, 204 SaveAs, 205 ExportSel, 206 OpenProject, 209 New, 212 Exit, 220 ExportQB64 |
| 217-219 | Extract/export flyout | 218 Extract from grid, 219 Extract to layers |
| 301-333 | Edit | 301 Undo, 302 Redo, 303-305 Copy/Cut/Paste, 306 Clear, 307 Deselect, 310 SelAll, 311 Invert, 315/316 Flip H/V, 319/320 Rotate, 321-323 copy/cut-to-layer, 324-329 transforms, 330-333 |
| 401-452 | View | 401 Toolbar, 402 Status, 403 AllUI, 404 Layers, 405-407 Zoom, 410 Crosshair, 434 Preview, 435 EditBar, 436-439 side UI, 440 PatternTile, 441 Border, 449 AdvBar, 452 ReloadTheme |
| 427/428/433 | Music | 427 Next, 428 Prev, 433 Random track |
| 501-519 | Color | 501-510 opacity, 517 Swap, 518 DefaultColors, 519 BG transparent |
| 601-609 | Brush | 601/602 size −/+, 603-605 modes, 607 preview, 608 shape, 609 pixel-perfect |
| 701-736 | Layer | 701 New, 702 Delete, 703/704 move, 705/706 merge, 707 Dup, 708/709 arrange, 720-728 groups, 726 Rename, 730-736 symbols |
| 801/802 | Canvas pan | 801 Pan, 802 Reset pan |
| 901-911 | Grid | 901 grid, 902 pixel grid, 903 snap, 904/905 size, 906 align, 907 match brush, 908 cell fill, 909 fill-adjust, 910/911 smart guides |
| 950-957 | CRT | 950 toggle, 951 settings, 952-957 sub-toggles |
| 1001-1003 | Symmetry | 1001 cycle, 1002 clear, 1003 center |
| 1101-1112 | Custom brush | 1101 capture, 1103 recolor, 1104 outline, 1105-1112 transform |
| 1201-1206 | Assist (hold-modifiers, informational) | 1201 constrain, 1203 square/circle, 1205 clone, 1206 temp picker |
| 1401-1414 | Select | 1401 from layer, 1410-1413 expand/contract, 1414 from layers |
| 1501-1530 | View/Edit | 1501-1504 refimg, 1512 random palette, 1520-1522 text styles, 1530 TDF fonts |
| 1701-1707 | Tools (high IDs) | 1701 Zoom, 1702 Spray, 1703 CmdPalette, 1706 SmartShapes, 1707 BevelOuter |
| 1801-1914 | Canvas/Image/Align/Drawer | 1801 resize, 1802 crop, 1803/1804 flip, 1805 resize+content, 1822 cancel AI, 1901-1908 align, 1911-1914 drawer sets |
| 2001-2057 | Image adj / Preview / Charmap | 2001-2011 adjustments, 2012-2020 preview, 2021/2022 mixer/browser, 2050-2057 charmap |
| 2100 | Settings | ACTION_SETTINGS |
| 2201-2216 | Export formats | PNG/GIF/JPG/TGA/BMP/HDR/ICO/QOI |
| 2300-2321 | ANSI / Kit | 2300-2302 ANSI, 2320/2321 kit |
| 8001-8105 | Migrated function/grid keys | 8001-8008 F1-F8 fns, 8009 brush shape, 8011 menubar, 8101-8105 grid toggles |
| 9001-9013 | G-chord | grid reset/offset/resize |
| 9100-9109 | Z-chord | zoom presets |
| 9999 | Dev | F12 dump INPUT_EVENT to inputs.log |

---

## 10. Metadata-only (dispatched=FALSE) keyboard bindings

These are registered for audit but legacy code owns dispatch (or, in one noted case,
NOTHING owns it):

| Binding | reg | Who actually handles it |
|---|---|---|
| H (315 Flip H) | `INPUT.BM:191` | `KEYBOARD_tools:111-114` inline |
| Ctrl+Shift+H (316 Flip V) | `INPUT.BM:192` | `KEYBOARD_tools:117-122` (only when MOVE.ACTIVE) + custom-brush End key |
| Ctrl+Q (212 Quit) | `INPUT.BM:235` | menubar / Alt+X path |
| Ctrl+, (2100 Settings) | `INPUT.BM:336` | `KEYBOARD_input_handler:3190-3205` |
| All mouse bindings (canvas/toolbar/menubar/panels, `INPUT.BM:424-525`) | — | `MOUSE.BM` legacy |

---

## SEAMS/GAPS

- **Ctrl+D is double-mapped.** Dispatched binding fires **307 Deselect** (`INPUT.BM:338`),
  but `CMD_register` labels Ctrl+D as **518 Default Colors** (`COMMAND.BM:199`) and the
  Phase-6d comment (`KEYBOARD.BM:3270`) claims Ctrl+D "now fires CASE 518". Code says 307.
  The menu/cheatsheet and the actual key disagree — test which one really runs.
- **Ctrl+, (Settings) is dispatched=FALSE but the dispatched table still lists it**, and
  the legacy handler uses a triple-detect (`_KEYDOWN(44)` OR `_KEYHIT==188/-188/44`). Test
  on all three platforms; verify it does not double-open, and that VK188 path doesn't also
  leak the comma to `KEYBOARD_colors`/grid `,`.
- **`.` and `,` grid size (904/905) have NO keyboard binding.** `CMD_register` advertises
  "`.` (period)" / "`,` (comma)" (`COMMAND.BM:299-300`) but there is no dispatched binding
  for 46/44 and the legacy `KEYBOARD_handle_grid_controls` was removed (`KEYBOARD.BM:3418`).
  Only reachable via command palette/menu. Coverage gap vs. documented hotkey.
- **F12 has three different physical keycodes across contexts:** dispatched dev-dump uses
  **28416** (`INPUT.BM:409`), custom-brush export uses **34304** (`KEYBOARD.BM:2306`),
  charmap Use-Chars uses **134144** (`KEYBOARD.BM:2093`). F11 similarly 34048 vs 133120.
  Verify each fires in its intended context and that 28416 dev-dump doesn't shadow the
  custom-brush export (or vice-versa) when both could match.
- **Backtick (96/126) triple-purposed** with no context bits in the modern table: toggle
  brush cursors (412), SS-polygon snap/lock-verts, Bezier handle visibility, custom-brush
  outline — all resolved by legacy `IF` ordering in `KEYBOARD_handle_function_keys` and
  `_handle_custom_brush`. Test each branch; confirm custom-brush-active path in
  `_handle_custom_brush:2284` doesn't collide with `_handle_function_keys:400`.
- **`>`/`<` (62/60) rotate is legacy-only, universal, and shared** by canvas rotate
  (319/320), TRANSFORM_rotate_step, image-import rotate, and custom-brush rotate — routed
  by nested `IF TRANSFORM.ACTIVE / IMG_IMPORT.STATE` checks (`KEYBOARD.BM:2232-2264`).
  Regression-prone; test with transform overlay + import both active/inactive.
- **Declared-but-never-set context bits:** `CTX_FILE_DIALOG_OPEN`,
  `CTX_IMAGE_IMPORT_ACTIVE`, `CTX_SETTINGS_OPEN`, `CTX_POPUP_MENU_OPEN`,
  `CTX_TRANSFORM_ACTIVE` (`INPUT.BI:142-151`) are never OR'd into `INPUT_CONTEXT`
  (`INPUT.BM:753-830`). Any future dispatched binding relying on these forbid/require bits
  would silently misfire. Modal blocking during import/crop/settings currently depends
  entirely on the legacy handler ordering running BEFORE the dispatcher — a context-forbid
  gap. Test: with image-import or a native dialog active, confirm no dispatched hotkey
  (e.g. Ctrl+S, a tool letter) leaks through.
- **Legacy runs before modern each frame** (`DRAW.BAS:512` vs `521`). Any key handled in
  BOTH paths where the legacy path does NOT `EXIT SUB`/consume can double-fire. Skip-list
  only covers `requireMods=0` printable ASCII (`INPUT.BM:607`). Test plain-letter tools,
  digits, `[`/`]`, X for exactly-one effect per press.
- **Chord-initiator self-forbid subtlety:** M/Z/E/F/W tool keys must NOT forbid their own
  `CTX_*_HELD` (they use `chordHeldNo*`), because `INPUT_update_context` sets the held bit
  the same frame the key goes down. Test: tapping M/Z/E/F/W still switches tool (not
  swallowed by its own chord guard), and holding + secondary key fires the chord.
- **G-chord vs Ctrl+G / Ctrl+Shift+R / Ctrl+Shift+G / Ctrl+Alt+R / Ctrl+R:** these forbid
  `CTX_G_HELD` (`INPUT.BM:243-244,308,319-320`) so they're suppressed while G is held for
  the grid chord. Test both orders (G-then-Ctrl vs Ctrl-then-G) since `GRID_G_KEY_ARMED%`
  latches on a no-mods G-down only.
- **Z+digit vs opacity digit:** opacity digits forbid `CTX_Z_HELD`; additionally
  `KEYBOARD_colors` is skipped in the handler when Z is down (`KEYBOARD.BM:3386`). Two
  independent guards — test that Z+3 zooms (not opacity 30%) and bare 3 sets opacity.
- **SS-drag digit/WASD reservation is enforced in three places** (context bit
  `CTX_SS_DRAGGING`, `KEYBOARD_colors` guard, `KEYBOARD_handle_shape_modifiers`, plus the
  `ss3dDragging` suppress at `:3382`). Test digit keys during SS-poly/dice drag change
  sides/type and never opacity; WASD/QE/L drive light not tool switches.
- **Alt+X / Alt+O handled in TWO places** — pre-render `KEYBOARD_input_handler:3228` AND
  post-render `KEYBOARD_input_handler_loop:3581`. Guarded by separate STATICs; test a
  single Alt+X doesn't exit-dialog twice or re-open the project dialog.
- **Ctrl+Alt+O (CRT toggle, legacy `_KEYDOWN`)** vs **Alt+O (open project)**: both watch
  key 111. Ctrl+Alt+O checks `MODIFIERS.ctrl% AND alt%`; Alt+O checks `alt% AND NOT ctrl%`
  — mutually exclusive, but timing of Ctrl release could momentarily satisfy Alt+O. Test
  Ctrl+Alt+O release sequence doesn't pop the open dialog.
- **`KEYBOARD_SUPPRESS_FRAMES%` (3-frame post-dialog)**: a genuinely fast hotkey right
  after a dialog close is dropped. Test edge behavior isn't perceived as a dead key.
