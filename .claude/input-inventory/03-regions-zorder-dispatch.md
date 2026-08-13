# DRAW Input System — Regions, Z-Order & Dispatch (code-derived)

Scope: `INPUT/INPUT.BI`, `INPUT/INPUT.BM`, and every `REGION_set_bounds` / `REGION_hit_test%` call site across the tree. Verified against code, **not** comments. Line refs are `file:line` at time of writing.

> **Headline:** All 64 mouse/wheel/hover bindings are `dispatched = FALSE` (metadata only). **Zero mouse events fire through the modern dispatcher.** Only keyboard bindings with `dispatched = TRUE` reach `CMD_execute_action` via `INPUT_dispatch_frame`. Everything mouse-shaped is still owned by legacy `INPUT/MOUSE.BM`. The region table therefore feeds only: (a) `CTX_OVER_*` context bits, and (b) four "am I over any chrome?" boolean call sites. The rich z-order design is **wired but dormant**.

---

## 1. Region inventory

Region constants: `INPUT/INPUT.BI:89-119`. `REGION_TABLE_SIZE = 64` (`INPUT.BI:119`). Table is `REGION_BOUNDS_TABLE(0 TO 63)` (`INPUT.BI:287`).

| # | Constant | Bounds set at (file:line, SUB) | Z-order passed | Registered every frame? |
|---|----------|-------------------------------|----------------|-------------------------|
| 0 | `REGION_GLOBAL` | — (sentinel; `REGION_hit_test%` default return) | — | n/a |
| 1 | `REGION_CANVAS` | **never** — no `REGION_set_bounds` call anywhere | — | **NEVER (see §5.1)** |
| 2 | `REGION_TOOLBAR` | `GUI/TOOLBAR.BM:50` (`TOOLBAR_render`) | `ZORDER_PANEL` (100) | when `showToolbar%` |
| 3 | `REGION_MENUBAR` | `GUI/MENUBAR.BM:788` (`MENUBAR_render`) | `ZORDER_PANEL` (100) | when menubar visible — **bar strip only, not open dropdown** |
| 4 | `REGION_LAYER_PANEL` | `GUI/LAYERS.BM:2160` (`LAYER_PANEL_render`) | `ZORDER_PANEL` (100) | when layer panel drawn |
| 5 | `REGION_PALETTE_STRIP` | `GUI/PALETTE-STRIP.BM:98` (`PALETTE_STRIP_render`) | `ZORDER_PANEL` (100) | when strip drawn |
| 6 | `REGION_EDIT_BAR` | `GUI/EDITBAR.BM:262` (`EDITBAR_render`) | `ZORDER_PANEL` (100) | when `showEditBar%` |
| 7 | `REGION_ADV_BAR` | `GUI/ADVANCEDBAR.BM:251` (`ADVBAR_render`) | `ZORDER_PANEL` (100) | when `showAdvBar%` |
| 8 | `REGION_STATUS_BAR` | `GUI/STATUS.BM:43` (`STATUS_render`) | `ZORDER_PANEL` (100) | when status shown |
| 9 | `REGION_DRAWER` | `GUI/DRAWER.BM:1725` (`DRAWER_render`) | `ZORDER_PANEL` (100) | when drawer drawn |
| 10 | `REGION_PREVIEW` | `GUI/PREVIEW.BM:337` (`PREVIEW_render`) | `ZORDER_PANEL` (100) | conditional — `PREVIEW_render` early-EXITs (see §6) |
| 11 | `REGION_COLOR_MIXER` | `GUI/COLOR-MIXER.BM:368` (`COLORMIXER_render`) | `ZORDER_PANEL` (100) | when mixer visible |
| 12 | `REGION_IMAGE_BROWSER` | `GUI/BROWSER.BM:1148` (`BROWSER_render`) | `ZORDER_PANEL` (100) | when browser visible |
| 13 | `REGION_CHARMAP` | `OUTPUT/SCREEN.BM:2501` (in `SCREEN_render`) | `ZORDER_PANEL` (100) | when `showCharMap%` |
| 14 | `REGION_ORGANIZER` | `GUI/ORGANIZER.BM:238` (`ORGANIZER_render`) | `ZORDER_PANEL` (100) | when organizer drawn |
| 15 | `REGION_COMMAND_PALETTE` | **never** | — | NEVER — dormant (see §5.2) |
| 16 | `REGION_SETTINGS_DLG` | **never** | — | NEVER — dormant |
| 17 | `REGION_FILE_DIALOG` | **never** | — | NEVER — dormant |
| 18 | `REGION_POPUP_MENU` | **never** | — | NEVER — dormant |
| 19 | `REGION_TOOLTIP` | **never** | — | NEVER (also explicitly skipped in hit-test, `INPUT.BM:728`) |
| 20 | `REGION_PIXEL_COACH` | **never** | — | NEVER — dormant |
| 21 | `REGION_TRANSPARENCY_CHECKER` | **never** | — | NEVER — dormant |
| 22 | `REGION_SMART_GUIDES` | **never** | — | NEVER — dormant |
| 23 | `REGION_SUBTOOL_FLYOUT` | `GUI/SUBTOOL-FLYOUT.BM:330` (`SUBTOOL_FLYOUT_render`) | **`ZORDER_FLYOUT` (300)** | when flyout open — **only region above 100** |
| 24 | `REGION_TEXT_BAR` | `GUI/TEXT-BAR.BM:359` (`TEXT_BAR_render`) | `ZORDER_PANEL` (100) | when text bar visible |
| 25 | `REGION_PALETTE_PICKER` | **never** | — | NEVER — dormant |
| 26 | `REGION_FILL_ADJ` | **never** | — | NEVER — dormant |
| 27 | `REGION_DIALOG_GENERIC` | **never** | — | NEVER — dormant |

**15 of 27 regions are actually bounded.** 12 are declared (and several are handled in `INPUT_update_context`'s `SELECT CASE`) yet never receive bounds, so they can never be returned by `REGION_hit_test%` and their `CTX_OVER_*` cases are dead code.

### Panels hidden without `REGION_set_inactive`
`REGION_set_inactive` (`INPUT.BM:675`) exists but has **zero callers**. Hiding is done entirely by `REGION_clear_all` (`INPUT.BM:686`) once per frame at the top of `SCREEN_render` (`OUTPUT/SCREEN.BM:2614`). A panel goes inactive by *not re-registering* the frame it is hidden. Consequence: exactly one frame of stale hit-test survives after a panel hides (documented as acceptable), but see the PREVIEW early-EXIT wrinkle in §6.

---

## 2. Z-order — declared vs. used

Constants (`INPUT.BI:125-131`): `ZORDER_CANVAS=0`, `ZORDER_PANEL=100`, `ZORDER_FLYOUT=300`, `ZORDER_POPUP_MENU=500`, `ZORDER_MODAL_DIALOG=1000`, `ZORDER_COMMAND_PALETTE=1500`, `ZORDER_TOOLTIP=9999`.

**Only two z-order values are ever passed to `REGION_set_bounds`:**
- `ZORDER_PANEL` (100) — **every bounded region except the flyout** (14 regions).
- `ZORDER_FLYOUT` (300) — `REGION_SUBTOOL_FLYOUT` only.

`ZORDER_POPUP_MENU`, `ZORDER_MODAL_DIALOG`, `ZORDER_COMMAND_PALETTE`, `ZORDER_TOOLTIP`, `ZORDER_CANVAS` are **defined but never used** (their regions never register).

### Tie-break rule (critical)
`REGION_hit_test%` (`INPUT.BM:720-742`) walks `i = 1 → 63` and replaces the winner only on **strictly greater** z-order: `IF REGION_BOUNDS_TABLE(i).zOrder > bestZ`. On a tie the **first (lowest region index) wins**; later equal-z regions do **not** displace it.

Because 14 panels all share `zOrder = 100`, overlap winners are decided **purely by region constant number**, lowest-first:

**Actual hit-test precedence, top (wins) → bottom:**
1. `REGION_SUBTOOL_FLYOUT` (23) — z=300, always wins.
2. Among all z=100 panels, lowest index wins: `TOOLBAR(2)` > `MENUBAR(3)` > `LAYER_PANEL(4)` > `PALETTE_STRIP(5)` > `EDIT_BAR(6)` > `ADV_BAR(7)` > `STATUS_BAR(8)` > `DRAWER(9)` > **`PREVIEW(10)` > `COLOR_MIXER(11)` > `IMAGE_BROWSER(12)`** > `CHARMAP(13)` > `ORGANIZER(14)` > `TEXT_BAR(24)`.

This is **inverted relative to visual/render order** for the floating windows (see §3).

---

## 3. Floating-window ordering: render vs. hit-test **contradiction**

Floating overlays are drawn to screen 0, after the canvas upscale, in this order (`OUTPUT/SCREEN.BM:3600-3602`, mirrored at 2849-2851 and 3087-3089):

```
PREVIEW_render      ' painted first  → visually bottom
COLORMIXER_render   ' painted second
BROWSER_render      ' painted last   → visually TOP
```

So **paint order (bottom→top): PREVIEW < COLOR_MIXER < IMAGE_BROWSER.** The comment at `SCREEN.BM:3599` even says "Preview renders under the color mixer."

But the hit-test tie-break gives the opposite: `PREVIEW(10)` beats `COLOR_MIXER(11)` beats `IMAGE_BROWSER(12)`. **The visually-topmost window (browser) loses the region hit-test to the two windows beneath it.** Where these overlap, `REGION_hit_test%` names the wrong (lower, visually-occluded) window.

Currently *latent* because no dispatched binding consumes `CTX_OVER_PREVIEW/MIXER/BROWSER`, and the four live consumers only ask "> REGION_CANVAS?" (any-chrome boolean, §4). It becomes a real bug the moment any mouse binding is flipped to `dispatched = TRUE` or any code branches on the *specific* floating region.

---

## 4. `REGION_hit_test%` consumers (who actually reads the table)

| Call site | Use | Sensitive to which-region? |
|-----------|-----|----------------------------|
| `INPUT.BM:808` (`INPUT_update_context`) | maps hit region → one `CTX_OVER_*` bit | **Yes** — full precedence matters |
| `INPUT.BM:917` (`INPUT_detect_events`) | region stamped onto every mouse `DETECTED_EVENT` (down/click/drag/hover) | **Yes** |
| `INPUT/MOUSE.BM:5294` | Alt screen-eyedropper: fire only over chrome (`> REGION_CANVAS`) | No — boolean |
| `TOOLS/PICKER-LOUPE.BM:358` | loupe previews UI over chrome (`> REGION_CANVAS`) | No — boolean |
| `OUTPUT/SCREEN.BM:3036` | picker loupe render gate (`> REGION_CANVAS`) | No — boolean |
| `OUTPUT/SCREEN.BM:3514` | same, other render path (`> REGION_CANVAS`) | No — boolean |

The three boolean sites rely on `REGION_CANVAS` never registering (canvas → `REGION_GLOBAL = 0`), so `> REGION_CANVAS(1)` means "over a real panel." The two region-sensitive sites (context + event stamping) are where §3's inversion and §5's gaps bite.

---

## 5. Dispatch flow

### Frame pipeline (main loop calls these before `SCREEN_render`)
1. **`INPUT_update_context`** (`INPUT.BM:753`): rebuilds the 64-bit `INPUT_CONTEXT` from world state each frame —
   - Mode bits actually set: `CTX_TEXT_ACTIVE`, `CTX_MOVE_ACTIVE`, `CTX_MAGIC_WAND_ACTIVE`, `CTX_GRID_OFFSET_PICK`, `CTX_REFIMG_REPOSITION`, `CTX_COMMAND_PALETTE_OPEN`, `CTX_SS_DRAGGING`, `CTX_DRAWING_IN_PROGRESS` (line-drag only).
   - Held-key chords via `_KEYDOWN` + `MODIFIERS`: `CTX_G_HELD` (armed latch), `CTX_M/Z/E/F/W_HELD`, `CTX_SPACE_HELD`, `CTX_ALT_HELD`.
   - Cursor region: one `REGION_hit_test%(MOUSE.RAW_X/Y)` → one `CTX_OVER_*` bit (`INPUT.BM:808-827`).
   - **Defined-but-never-set** ctx bits: `CTX_FILE_DIALOG_OPEN`, `CTX_IMAGE_IMPORT_ACTIVE`, `CTX_SETTINGS_OPEN`, `CTX_POPUP_MENU_OPEN`, `CTX_TRANSFORM_ACTIVE`. Any binding gating on these never (un)matches on them.
2. **`INPUT_detect_events`** (`INPUT.BM:863`): builds the `DETECTED_EVENTS` queue.
   - **Keyboard:** walks all bindings; for each `EVT_KEY_PRESS` binding polls `_KEYDOWN(keycode)` (+case-flip for letters). Fresh down-edge vs. `KEY_DOWN_LAST(i)` enqueues **one** `EVT_KEY_PRESS` in `REGION_GLOBAL`. A version-counter (`INPUT_KC_ENQUEUED`/`INPUT_KC_FRAME`, `INPUT.BM:885,906`) de-dups so a keycode shared by multiple bindings (e.g. `M` + `Ctrl+M`) enqueues only once/frame.
   - **Mouse:** one `region% = REGION_hit_test%` (`INPUT.BM:917`), then per button 1-3 a state machine emits `EVT_MOUSE_DOWN`, then either `DRAG_START`+`DRAG_MOVE`(threshold `DRAG_THRESHOLD_PX=3`) / `DRAG_END`, or `CLICK`(+`DBLCLICK` within `DBLCLICK_WINDOW_S=0.3`) if same-region no-motion, plus `EVT_MOUSE_UP`. Drag events carry the **down-region** (`MOUSE_DOWN_REGION`), not the current region.
   - **Hover:** enter/leave when `region% <> HOVER_REGION_LAST`.
   - Note: **wheel events are never enqueued here** — no `EVT_MOUSE_WHEEL` producer exists in `INPUT_detect_events`, so all `INPUT_register_wheel%` bindings are pure metadata even if someone set `dispatched = TRUE`.
3. **`INPUT_dispatch_frame`** (`INPUT.BM:993`):
   - **Idle fast-path:** `IF DETECTED_EVENT_COUNT = 0 AND INPUT_CONTEXT = INPUT_CONTEXT_PREV THEN EXIT SUB` (`INPUT.BM:994`). No events + unchanged context → return immediately.
   - For each detected event, populates the shared `INPUT_EVENT` snapshot, then scans bindings `1 → INPUT_BIND_COUNT` for the **first** binding with `dispatched = TRUE` where `INPUT_BIND_matches%` is true (**registration order = priority**), fires `CMD_execute_action b.actionId`, and `EXIT FOR` (one action per event).
   - `INPUT_BIND_matches%` (`INPUT.BM:1045`): equal `eventType`; region matches iff `b.region = REGION_GLOBAL OR b.region = e.region`; keycode match (case-insensitive for letters); button/wheelDir (0 = any); `(mods AND requireMods) = requireMods` and `(mods AND forbidMods) = 0`; `(ctx AND requireCtx) = requireCtx` and `(ctx AND forbidCtx) = 0`.

### Legacy-vs-modern split (`dispatched` flag)
- **`dispatched = TRUE`:** modern dispatcher owns it. In `INPUTS_register_all` these are **keyboard-only** — tool letters, chord combos (G/M/Z/W/F chords), F-keys, zoom, selection grow/shrink, etc. (`INPUT.BM:167-290+`).
- **`dispatched = FALSE`:** metadata only; legacy `KEYBOARD.BM`/`MOUSE.BM` still dispatch. **Every** `INPUT_register_mouse%` / `INPUT_register_wheel%` / `INPUT_register_hover%` in the file is `FALSE` (`INPUT.BM:424-525`), plus a few keyboard rows (`Ctrl+Q` quit 235, flips 191-192).
- Migration guards keep the two systems from double-firing letters: `INPUT_LETTER_DISPATCHED(0..127)` skip-list + `INPUT_DISPATCH_DEPTH` re-entrancy counter (`INPUT.BI:329,337`) so a `dispatched=TRUE` letter suppresses the legacy `KEYBOARD_tools` path, except while inside a `CMD_execute_action`.

---

## 5.1 `REGION_CANVAS` is intentionally NOT registered

There is **no `REGION_set_bounds REGION_CANVAS` anywhere**. The canvas (and all dead space around panels) therefore hit-tests as `REGION_GLOBAL = 0`. Implications:

- **Canvas mouse bindings** (`INPUT.BM:424-445`) register with `region = REGION_CANVAS`, but since no detected event is ever stamped `REGION_CANVAS` (hit-test returns `REGION_GLOBAL` there), `INPUT_BIND_matches%`'s `b.region = e.region` test would **fail** for these — they'd never match even if flipped to `dispatched = TRUE`. They're doubly-inert (both `dispatched=FALSE` **and** region-unreachable). A future migration of canvas mouse handling must either register `REGION_CANVAS` bounds or special-case `REGION_GLOBAL`/`REGION_CANVAS` equivalence in the matcher.
- The four boolean consumers (§4) **depend** on this: `> REGION_CANVAS` = "over real chrome." If canvas were ever registered, that idiom silently breaks (loupe/eyedropper would treat the canvas as chrome).
- `CTX_OVER_CANVAS` (`INPUT.BM:810`) is therefore also **never set** — the `CASE REGION_CANVAS` is dead.

## 5.2 Dormant regions (declared, never bounded)

`COMMAND_PALETTE(15)`, `SETTINGS_DLG(16)`, `FILE_DIALOG(17)`, `POPUP_MENU(18)`, `PIXEL_COACH(20)`, `TRANSPARENCY_CHECKER(21)`, `SMART_GUIDES(22)`, `PALETTE_PICKER(25)`, `FILL_ADJ(26)`, `DIALOG_GENERIC(27)` never call `REGION_set_bounds`. They are hit-testable in principle but permanently inactive, so:
- Modal dialogs, the command palette, popup menus, and menubar dropdowns are **invisible to the region system**. Clicks over them hit-test as `REGION_GLOBAL`/whatever docked panel sits beneath — legacy modal guards (`CMD_PALETTE.visible`, dialog handlers) must catch them.
- `INPUT_update_context` cases `REGION_POPUP_MENU`, `REGION_SETTINGS_DLG/FILE_DIALOG/DIALOG_GENERIC` (`INPUT.BM:824-826`) are unreachable dead code.
- Command palette is nonetheless covered *by state* via `CTX_COMMAND_PALETTE_OPEN` (set from `CMD_PALETTE.visible%`, `INPUT.BM:772`), not by its region.

---

## 6. PREVIEW window: cursor-under-pane + brittle input (the reported bug)

### 6a. Cursor renders **under** the preview pane — root cause is render order, not the region table
- The software cursor is composited onto `SCRN.CANVAS&` by `POINTER_render_cursor_overlay` at `OUTPUT/SCREEN.BM:3533`, **before** the whole canvas is upscaled to screen 0 at `SCREEN.BM:3595` (`_PUTIMAGE (0,0)-... SCRN.CANVAS&, 0`).
- **After** the upscale, the floating overlays are blitted directly to screen 0: `PREVIEW_render` at `SCREEN.BM:3600`, then mixer/browser (3601-3602).
- So the preview pane paints on top of the already-baked cursor. Nothing redraws the cursor above the floating overlays (only `PREVIEW_render_loupe` and `PREVIEW_render_tooltip` follow at 3606-3608). **Whenever the mouse is over the preview/mixer/browser window, the cursor disappears beneath it.** This is a pure z-order-of-rendering seam, independent of `REGION_BOUNDS_TABLE`.

### 6b. Region bounds vs. legacy hit-test — dual source of truth
- Preview region bounds: `REGION_set_bounds REGION_PREVIEW, PREVIEW.x%, PREVIEW.y%, PREVIEW.dispW%, pvFootH%, ZORDER_PANEL` (`PREVIEW.BM:337`), where `pvFootH% = PREVIEW.dispH%` (or a minimized title-strip height).
- Legacy preview input uses its **own** geometry `PREVIEW_hit_window%` (`PREVIEW.BM:962-969`): same `PREVIEW.x/y`, `dispW`, `dispH`/minimized. `MOUSE.BM` routes all preview input through `PREVIEW_hit_window%` + `PREVIEW_mouse_input` (`MOUSE.BM:1153, 1242, 1381, 1404, 3952, 4600, 5136-5149`), **never** through `REGION_PREVIEW`.
- Geometry is currently identical, but it is computed twice from two code paths — a classic drift seam. They can also disagree in **time**: the region is set during frame N's render (line 3600, late) and read during frame N+1's input; `PREVIEW_hit_window%` is evaluated live in-frame. One-frame skew during moves/resizes.

### 6c. PREVIEW registers its region **conditionally** and **late**, and can leave stale bounds
`PREVIEW_render` early-EXITs (before reaching line 337) when: not visible / autoHidden (`PREVIEW.BM:302-303`), or **any** of menubar/palette-menu/layer-blend-popup/layer-ctx-menu/drawer-ctx-menu/command-palette is open (`PREVIEW.BM:309-314`). On those frames `REGION_set_bounds REGION_PREVIEW` is not called. Because hiding relies on the once-per-frame `REGION_clear_all` (`SCREEN.BM:2614`), the region correctly deactivates that frame — **but** the preview is still *painted* to screen 0 at `SCREEN.BM:3600` unless it's also not-visible/autoHidden. Net effect: while a menu/popup is open, the preview window **is visually absent** (it also EXITs its own render), so region and pixels agree — but the coupling is fragile: the region's active-ness is a side effect of a long guard list inside a different SUB than the one that blits it (3600 re-checks only `visible% AND NOT autoHidden%`, a *different* condition than PREVIEW_render's full guard set). Any divergence between the 3600 guard and the `PREVIEW_render` guard list would paint a window with no region (or vice-versa).

### 6d. Z-order: preview shares `ZORDER_PANEL` with docked panels
`REGION_PREVIEW` = `ZORDER_PANEL` (100), the same as toolbar/layers/palette/etc. A preview floating **over** a docked panel (it's painted after the canvas, so visually on top) still **loses** the hit-test to any docked panel with a lower region index (toolbar 2, menubar 3, layer 4, palette 5, edit 6, adv 7, status 8, drawer 9) on overlap, because ties go to the lower index. Floating windows are visually top but z-order-of-hit-test mid-pack. Should arguably be `ZORDER_FLYOUT`+ or a dedicated floating tier.

---

## SEAMS/GAPS

- **[SEAM] Cursor drawn under floating panes (reported bug).** `POINTER_render_cursor_overlay` writes the cursor to `SCRN.CANVAS&` (`SCREEN.BM:3533`) before the upscale (`3595`); `PREVIEW_render`/`COLORMIXER_render`/`BROWSER_render` blit to screen 0 *after* (`3600-3602`) with no cursor re-draw on top. Cursor vanishes under any floating window.
- **[SEAM] Render order vs. hit-test order inverted for floating windows.** Paint bottom→top is PREVIEW(10) < COLOR_MIXER(11) < IMAGE_BROWSER(12) (`SCREEN.BM:3600-3602`), but `REGION_hit_test%` tie-break (`>` strict, lowest index wins, `INPUT.BM:733`) makes PREVIEW win over MIXER win over BROWSER. Visually-top window loses the region hit-test.
- **[SEAM] Every panel shares `ZORDER_PANEL=100`.** Overlap resolution is decided by region *constant number*, not visual stacking. Floating windows (10-12) don't outrank docked panels (2-9). Only `REGION_SUBTOOL_FLYOUT` (z=300) escapes the flat tier.
- **[GAP] 4 of 7 z-order constants unused.** `ZORDER_POPUP_MENU/MODAL_DIALOG/COMMAND_PALETTE/TOOLTIP` never passed to `REGION_set_bounds` — their regions never register. Z-order hierarchy is designed but dormant.
- **[GAP] `REGION_CANVAS` never registered.** Canvas → `REGION_GLOBAL`. Canvas mouse bindings (`INPUT.BM:424-445`) are region-unreachable; `CTX_OVER_CANVAS` never set; four consumers depend on the `> REGION_CANVAS` idiom (`MOUSE.BM:5294`, `PICKER-LOUPE.BM:358`, `SCREEN.BM:3036,3514`).
- **[GAP] 12 declared regions never bounded** (command palette, all dialogs, popup menu, pixel-coach, transparency checker, smart guides, palette picker, fill-adj, generic dialog, tooltip). Their `CTX_OVER_*`/`SELECT CASE` handling is dead; modals/dropdowns are invisible to the region system and must be caught by legacy guards.
- **[SEAM] PREVIEW dual hit-test source.** `REGION_PREVIEW` bounds (`PREVIEW.BM:337`) vs. `PREVIEW_hit_window%` (`PREVIEW.BM:962`) compute the same rect twice from two code paths; legacy input uses only the latter. Drift + 1-frame skew risk.
- **[SEAM] PREVIEW region registered conditionally/late.** `PREVIEW_render` early-EXITs on 8 conditions (`PREVIEW.BM:302-314`) before `REGION_set_bounds`; the blit guard at `SCREEN.BM:3600` checks a *different* (narrower) condition. Guard-list divergence = window painted with no region or region with no window.
- **[GAP] All mouse/wheel/hover bindings are `dispatched=FALSE`.** 64 metadata-only rows (`INPUT.BM:424-525`). Modern dispatcher never fires a mouse action; legacy `MOUSE.BM` owns all pointer input. The region table only feeds `CTX_OVER_*` bits + 4 boolean chrome checks.
- **[GAP] Wheel events have no producer.** `INPUT_detect_events` never enqueues `EVT_MOUSE_WHEEL`; all `INPUT_register_wheel%` rows are inert regardless of `dispatched`.
- **[GAP] 5 context bits declared but never set.** `CTX_FILE_DIALOG_OPEN`, `CTX_IMAGE_IMPORT_ACTIVE`, `CTX_SETTINGS_OPEN`, `CTX_POPUP_MENU_OPEN`, `CTX_TRANSFORM_ACTIVE` never OR'd in `INPUT_update_context`. Any binding gating on them mis-evaluates.
- **[SEAM] Menubar region is bar-strip only.** `REGION_MENUBAR` bounds (`MENUBAR.BM:788`) cover the bar height, not an open dropdown. Dropdown clicks hit-test as whatever sits beneath; legacy menu handler owns them.
- **[GAP] `REGION_set_inactive` has zero callers.** Deactivation relies solely on `REGION_clear_all` + non-re-registration; the per-panel inactive API is unused, so any code path that skips `REGION_clear_all` would leak stale active regions.
- **[NOTE] Drag events carry down-region, not current region** (`INPUT.BM:940,944,949`), and click requires up-region == down-region (`952`). A drag that starts on a panel and moves onto canvas keeps the panel region — correct for capture semantics but a mismatch vs. `CTX_OVER_*` (which tracks the live cursor region).
