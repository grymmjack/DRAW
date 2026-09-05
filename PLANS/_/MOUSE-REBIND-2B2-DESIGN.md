# Phase 2B.2 — Mouse-behavior rebinding: design + why it wants Rick in the loop

Status: **design complete (autonomous); implementation gated on Rick's visual
confirmation + a mouse-capture UI.** No hot-path code changed yet — deliberately.

## Scope (from 2B.1)

Make `INPUT/MOUSE.BM` honor per-behavior overrides for the ~6 genuinely-rebindable
"input-preference" mouse behaviors, WITHOUT routing the 2600-line positional pipeline
through the CMD dispatcher (tool strokes + panel affordances stay hardcoded):

| Behavior | DRAW default | Nature |
|----------|--------------|--------|
| Paint with FG color | Left button (B1) | button choice |
| Paint with BG color | Right button (B2) | button choice |
| Wheel = zoom vs. brush-size | plain wheel = zoom, Ctrl+wheel = brush size | modifier→action |
| Pick FG / BG | Alt+click (Alt+B1 / Alt+B2) | modifier+button |
| Symmetry center set | Ctrl+click | modifier+button |
| Pan trigger | Middle button (B3) or Space+drag | button / chord |

Key 2B.1 finding: most of these do **not** map to a dispatchable CMD action
(symmetry-center 1003 and reset-pan 802 have no CASE; Alt+click-pick is a tool-mode,
not an action). So mouse rebinding CANNOT reuse the keyboard "fire a CMD action"
model — MOUSE.BM must instead **ask the registry which button/modifier triggers each
behavior** and branch on the answer.

## Why this is not done unattended here

1. **Hot-path regression surface.** The button decisions are not centralized — `MOUSE.B1%`
   / `MOUSE.B2%` / `MOUSE.B3%` are read at ~dozens of sites across `MOUSE.BM` (tool hold
   at ~195, click gates at 747/777, palette/panel gates, tool dispatch, etc.). Threading
   an override query through all of them touches the core drawing pipeline — the one thing
   that must never regress — and the offscreen (Xvfb) harness cannot reliably confirm that
   a *paint stroke* still lands where it should (see the note in the paste/move/wand source
   guards: multi-step pointer workflows aren't drivable offscreen).
2. **No way to SET a mouse override yet.** The Phase 3 engine (`CFG/BINDINGS.BM`) stores
   *keyboard* keycode overrides. Mouse rebinding needs its own override kind
   (behavior → button + modifiers) AND a capture UI (Phase 4.3 mouse-capture, not built).
   Until a user can set one, the wiring is only testable on its default path — which proves
   nothing about the actual feature.
3. **Branch precedent.** `.claude/TASKS.md` already scoped 2B.2 as "hot-path MOUSE.BM
   changes; testable now but risky — best with visual confirmation … needs RICK-in-the-loop."

Rick owes: a live/visual confirmation pass on the hot-path changes once wired.

## Proposed implementation (when Rick is in the loop)

### 1. Override storage (`CFG/BINDINGS.*`, additive)
A small `MOUSE_BEHAVIOR_OVERRIDE` table parallel to the keyboard `BINDING_OVERRIDE`:
`behaviorId (enum), button (1/2/3), requireMods, active`. Persist in a `[mouse]` section
of `DRAW.bindings` (or a sibling `DRAW.mouse.bindings`) so keyboard + mouse stay separable.
Enumerate behaviors as `MB_PAINT_FG, MB_PAINT_BG, MB_PICK_FG, MB_PICK_BG, MB_SYM_CENTER,
MB_PAN, MB_WHEEL_ZOOM, MB_WHEEL_BRUSH`.

### 2. Query API (the indirection layer — one place, so the hot path stays readable)
`FUNCTION MOUSE_intent_button% (behaviorId)` → configured button (default from a compiled
table matching today's values). `FUNCTION MOUSE_intent_active% (behaviorId)` → TRUE when the
current button+modifier state matches that behavior's trigger. The hot path then reads
`IF MOUSE_intent_active%(MB_PAINT_FG) THEN …` instead of `IF MOUSE.B1% …`. Defaults make
every call byte-identical to today, so the refactor is a pure indirection with no behavior
change until an override is set.

### 3. Wheel action (lowest-risk first slice)
The wheel ELSEIF at `MOUSE.BM:4076` (`ELSEIF MODIFIERS.ctrl% THEN BRUSH_SIZE_*`) becomes
`ELSEIF MOUSE_wheel_is_brush%() THEN …`, where the helper returns whether the *current*
modifier maps to brush-size (default: Ctrl) vs zoom (default: none). This one is
offscreen-testable (wheel over canvas → zoom vs brush-size), so land it first as the proof
of the pattern.

### 4. Capture UI (Phase 4.3)
Extend the Customize Controls rebind modal (`GUI/CONTROLS.BM CTRL_assign_key%`) with a
mouse-capture mode: click a button + toggle modifiers instead of pressing a key. Only then
is end-to-end mouse rebinding testable.

### Test strategy
- Wheel slice: offscreen region-diff (zoom changes vs brush-size changes) with the default
  and with a flipped preference.
- Button behaviors: source-guards for the indirection + a live pass with Rick (paint FG/BG,
  pan, pick) since paint strokes aren't drivable offscreen.
- Conflict audit stays green (mouse overrides can't collide with keyboard bindings; add a
  mouse-vs-mouse check when two behaviors claim the same button+mods).

## Recommended sequencing
Wheel-action slice (§3, safe + offscreen-testable) → override storage + query API (§1–2,
default-preserving) → capture UI (§4) → wire paint/pick/pan behind the query API with Rick
watching. Each step is a commit with its own guard.
