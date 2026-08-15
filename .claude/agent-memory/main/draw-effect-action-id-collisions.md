---
name: draw-effect-action-id-collisions
description: New effect/menu action IDs must avoid ACTION_SETTINGS=2100 and the EXPORT range 2201-2216; audit CASE order, not just uniqueness
metadata:
  type: project
---

[Linux] Concrete instance of gotcha #17 (grep before allocating an action ID).
When wiring the "More Image Effects" waves, two action-ID collisions shipped and
BOTH produced **false-passing QA tests** — `assert_regions_differ` cannot tell a
real effect from an unrelated fullscreen dialog covering the snap region, so a
mis-dispatched effect that opened Export/Settings still turned the region green.

Reserved action IDs that new effects/menu items collided with:
- **`ACTION_SETTINGS = 2100`** (`GUI/SETTINGS.BI`). Gamma was put on 2100 →
  Ctrl+, / Edit>Settings opened Gamma; the Settings dialog was unreachable.
  Fixed: Gamma → 2107.
- **EXPORT range `2201-2216`** (`OUTPUT/FILE-EXPORT.BI`:
  PNG_NATIVE=2201, PNG=2204, GIF=2205, JPG=2206, TGA=2208, BMP=2209, HDR=2210,
  ICO=2211, QOI=2216). SHAPE effects Corona(2201)/Rust(2204) opened Export
  dialogs. Fixed: all SHAPE effects → **2230-2234** (2230-2260 reserved for Eye
  Candy SHAPE/TEXTURE).

Key subtlety beyond "is the ID unique": **CASE ORDER decides the winner.**
`CMD_execute_action` is one giant `SELECT CASE`; BASIC takes the FIRST matching
CASE. The grouped effect block (`CASE 2001,...,2234`) sits BEFORE
`CASE ACTION_SETTINGS`, so 2100 resolved to the effect and shadowed Settings —
even though the Settings CASE existed. A later duplicate is silent dead code
(QB64-PE emits no warning).

Audit both directions before allocating:
```
# 1. all CONST-defined action IDs in the effect/image/export space
grep -rhnoE 'CONST [A-Z_]+ *= *2[0-2][0-9][0-9]' --include='*.BI' --include='*.BM' .
# 2. any standalone CASE that catches your ID BEFORE the grouped block (line of
#    'CASE 2001, 2002, ...'), which would shadow it
awk 'NR<LINE_OF_GROUPED_BLOCK && /^        CASE [0-9]/' GUI/COMMAND.BM \
  | grep -oE '[0-9]+' | sort -n
```

Follow-up recorded in TASKS.md QA-hardening: effect tests should also assert the
dialog TITLE (snap the title bar), not only a region delta, so a wrong-dialog
mis-dispatch fails loudly instead of false-passing. Relates to
[[draw-command-palette-registration]] and [[every-fix-needs-a-qa-test]].
