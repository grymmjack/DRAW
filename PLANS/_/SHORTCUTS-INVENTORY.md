# Shortcuts Inventory & Registry-Gap Audit

> Source-of-truth reconciliation for the customizable-shortcuts work. Built from a
> source-level extraction (agents over `INPUT/KEYBOARD.BM`, `INPUT/MOUSE.BM`,
> `INPUT/INPUT.BM` `INPUTS_register_all`, `GUI/COMMAND.BM` `CMD_init`,
> `GUI/MENUBAR.BM`). This is the audit that scopes the Phase 2 migration.

## Coverage snapshot

| Metric | Count |
|--------|------:|
| Registered bindings in `INPUTS_register_all` | **213** |
| — keyboard (`INPUT_register_key%`) | 141 |
| — mouse / wheel / hover (`INPUT_register_mouse%` / `_wheel%`) | 72 |
| `dispatched=TRUE` (fire through the central dispatcher) | **137** |
| `dispatched=FALSE` (metadata only — legacy code still owns dispatch) | **76** |
| Distinct `CMD_init` action IDs | ~330 |
| **Action IDs with NO central-registry trigger** (the gap) | **~150** |

**Reading of the gap:** the central registry today covers the *tool + edit + file +
view + layer + grid + selection* hotkeys well (all `dispatched=TRUE`). It does **not**
bind: the entire **Effects** menu, most of **Image adjustments**, **Audio**, layer
**Align/Distribute**, **Symbol** ops, **Custom-brush** transform keys (Home/End/PgUp/
PgDn/F9/F12/`/`), **Symmetry** `Ctrl+Click`, and all **mouse** actions (the 72 mouse
rows are metadata with `actionId=0`, owned by `MOUSE.BM`). Those are the migration
targets for rebindability.

## Dispatch architecture (three paths today — the thing to unify)

1. **Central dispatch** — `INPUT_dispatch_frame` (`DRAW.BAS:578`) matches the 137
   `dispatched=TRUE` registry rows → `CMD_execute_action`.
2. **Legacy inline** — `INPUT/KEYBOARD.BM` handlers (`_KEYDOWN`/`_KEYHIT` with STATIC
   guards) own the 76 `dispatched=FALSE` rows **and** many bindings not in the registry
   at all (text-editing, chords, shape-modifiers, panel modes, recent-files, music).
3. **Region-owned mouse** — `INPUT/MOUSE.BM` (~6k lines) + per-panel `GUI/*.BM` own all
   mouse/wheel/drag/hover; the 72 registry mouse rows are descriptive metadata only.

**Customization requires collapsing (2) and (3) into (1).** That is Phase 2.

## Registry GAPS — action IDs advertised (CMD/menu) but with no central binding

Grouped for the Phase 2 migration. (Some are reachable via menubar/palette/edit-bar
click dispatch; none have a rebindable key/mouse trigger in the registry.)

- **Tools:** 119/120/121 (Freehand / Polygon / Ellipse Select).
- **File:** 206, 208, 207, 210, 218, 219, 1911–1914, 2300/2301 (ANSI), 2201/2204–2216 (image exports), 2320/2321 (Kits).
- **Reference:** 1502, 1503, 1504.
- **Edit:** 308, 309, 319, 320, 324, 325–329 (Transform overlay modes).
- **View:** 2021/2022 (Mixer/Browser), 436–441, 450/451, 950–960 (CRT + AA), 442–448 & 2051–2057 (docking/charmap), 410/414/415.
- **Color:** 518 (default colors).
- **Layer:** 711, 717, 712–714, 1520–1522, 1530, 1901–1908 (Align/Distribute), 723–728, 730–736 (Symbols).
- **Select:** 1401, 1414.
- **Canvas:** 801/802 (pan — mouse-owned), 1801–1805 (resize/crop/flip).
- **Image:** 2001–2011 (all adjustments).
- **Effects:** the **entire** 2100–2291 block (incl. `Ctrl+F`/`Ctrl+Alt+F`/`Ctrl+Shift+F` = 2350/2351/2352, which the menubar advertises with accelerators but the registry does not bind — these live inline in `KEYBOARD.BM:3468-3475`).
- **Preview:** 2012–2019.
- **Grid/Symmetry:** 908/909/910/911 (cell-fill, fill-adjust, smart-guides), 1001–1003 (symmetry incl. `Ctrl+Click` center).
- **Custom Brush:** 1102–1112 (Home/End/PgUp/PgDn/F9/F12/`/`/`>`/`<`) — **all inline in `KEYBOARD.BM`, none in the registry** (F12 is registry-bound to 9999 dev-dump instead).
- **Assistants:** 1201–1206 (passive Hold-modifier assists — no discrete trigger).
- **All 72 mouse/wheel/hover rows** (`actionId=0`, region-owned) except canvas `Ctrl+Wheel` zoom (406/407).

## Parallel-ID mismatches (Phase 1 reconciliation)

The registry fires a *different* actionId than `CMD_init` advertises for the same
physical key — the doc/generator must pick one canonical id per binding:

| Key | Registry fires | CMD_init advertises |
|-----|----------------|---------------------|
| F1/F2/F3 | 8001/8002/8003 | 603/604/605 |
| F6 | 8006 | 609 |
| F7 | 8007 | 1001 |
| F8 | 8008 | 909 / 1002 |
| `\` | 8009 | 608 |
| `'` `Shift+'` `;` `/` | 8101/8102/8104/8105 | 901/902/903/906 |
| F12 | 9999 (dev-dump) | 1110 (export brush) |
| Ctrl+F11 | 8011 | 411 |

## Menubar-only accelerators (advertised but not registry-bound)

FLIP H `Home`→315 · FLIP V `End`→316 (registry binds `H`/`Ctrl+Shift+H`, dispatched=FALSE) ·
SCALE `PgUp`/`PgDn`→318/317 · ROTATE `>`/`<`→319/320 · CLEAR `Del`→308 · MENU BAR `Ctrl+F11`→411 ·
BRUSH Home/End/PgUp/PgDn/`>`/`<`/`/`→1105–1112 · AUDIO `}`/`{`→427/428, RANDOM `*`→433, +417–426.
These are owned by inline `KEYBOARD.BM` handlers; the registry never sees them.

## UNCERTAIN — needs manual source confirm before Phase 1 finalizes

1. **F11/F12 keycode variants** differ across handlers (34048/28416 vs charmap 133120/134144 vs brush-export 34304) — QB64-PE shift-bit representations; confirm which fires per platform.
2. **Display-scale hotkeys** `Ctrl+Alt+Shift+=`/`-` — commented as "handled in DRAW.BAS" but no handler found there; may be removed. Confirm.
3. **`.`/`,` grid-size** — comment notes a past regression + restore; confirm they fire and aren't shadowed by digit/opacity handlers.
4. **`F5` family collision** — `F5`/`Shift+F5`/`Ctrl+Shift+F5` all on keycode 16128 with differing masks; confirm no collision where Ctrl is dropped (macOS).
5. **`H` flip double-path** — registered dispatched=FALSE AND inline in `KEYBOARD.BM:111`; inline is authoritative; confirm no double-fire.
6. **`Ctrl+Alt+O` (CRT)** vs **`Alt+O` (Open)** share keycode 111 — confirm modifier gating.
7. **GAMEPAD.BM** reportedly maps shoulder buttons → `MOUSE.WHEEL` (`GAMEPAD.BM:18`) — confirm whether it injects synthetic wheel events (affects wheel rebinding).
8. **macOS `Ctrl+Click`→right-click remap** — `$IF MAC` branches treat Ctrl+Shift+B2 as B1 point-placement for polygon tools; per-platform behavior differs.

## Notes for the doc / generator

- Nearly every keyboard binding carries `forbidCtx = CTX_TEXT_ACTIVE` (suppressed while
  typing) — the generator should surface "not while editing text" where relevant.
- Chords use `CTX_*_HELD` context bits (`G/M/Z/E/F/W/L/Space` held) — model these as a
  first-class "hold-key" trigger, not a modifier.
- Mouse bindings are region-scoped (`CTX_OVER_*`) — the same button differs per region;
  the doc's Mouse Reference is organized this way.
