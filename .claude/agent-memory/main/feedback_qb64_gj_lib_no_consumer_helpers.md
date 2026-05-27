---
name: feedback-qb64-gj-lib-no-consumer-helpers
description: The vendored QB64_GJ_LIB submodule (under DRAW/includes/QB64_GJ_LIB/) is used by multiple QB64-PE applications, not just DRAW. Never call a DRAW-side helper (SAFE_FREEIMAGE, SCENE_invalidate, INVALIDATE_scene, MODS_NOW%, etc.) from any file inside the lib — only QB64-PE built-ins and library-prefixed (QB64_GJ_*) helpers. Borrowing a consumer-app helper breaks the lib for every other consumer.
metadata:
  type: feedback
---

`includes/QB64_GJ_LIB/` is a git submodule. Its source of truth lives in
the separate `QB64_GJ_LIB` repo and the same files ship to multiple
QB64-PE applications (DRAW is one of them, but not the only one).

**Rule:** files inside `includes/QB64_GJ_LIB/**` may only call:

1. **QB64-PE built-ins** — `_FREEIMAGE`, `_NEWIMAGE`, `_PUTIMAGE`,
   `_KEYDOWN`, etc.
2. **Library-internal SUBs/FUNCTIONs** prefixed with the
   `QB64_GJ_` namespace, or sub-module prefixes that already exist
   (`CP_*`, `FD_*`, `MB_*`, `TI_*`, `MB_STATE`, etc.).

**Never** call:

- `SAFE_FREEIMAGE` (DRAW-side wrapper in `CORE/HELPERS.BM`) — use
  `QB64_GJ_SAFE_FREE_IMAGE` (in `_GJ_LIB_COMMON.BI`) instead.
- `SCENE_invalidate` / `INVALIDATE_scene` (DRAW-side dirty-flag helpers)
- `MODS_NOW%` / `MODS_only%` (DRAW input system helpers)
- `DEST_SAVE/RESTORE` / `SOURCE_SAVE/RESTORE` / `FONT_SAVE/RESTORE` (DRAW
  helper stacks)
- Any SUB/FUNCTION defined in `DRAW/CORE/`, `DRAW/INPUT/`, `DRAW/GUI/`,
  `DRAW/TOOLS/`, etc. — that's the consumer's code, not the lib's.

**How to add a new helper to the lib:**

1. Add the SUB body to `_GJ_LIB_COMMON.BI` (QB64-PE allows SUB bodies
   in `.BI` files). Name it `QB64_GJ_<name>`.
2. Make sure DRAW's `_ALL.BI` `$INCLUDE`s `_GJ_LIB_COMMON.BI`
   (it does, added during the 2026-05-26 SAFE_FREEIMAGE rename).
3. Same SUB body is visible to every consumer that includes
   `_GJ_LIB_COMMON.BI` (or transitively any of its top-level files).

**How DRAW pulls the lib in:** `_ALL.BI` and `_ALL.BM` cherry-pick
individual `.BI`/`.BM` files (e.g. `MSG_BOX/MB-TYPES.BI`,
`COLOR_PICKER/CP-API.BM`). They do NOT include the lib's master
`_GJ_LIB.BI`/`_GJ_LIB.BM` (which would pull EVERYTHING and conflict
with DRAW's cherry-picks). So a helper added at the lib master root
is NOT visible to DRAW unless DRAW also includes the specific file it
lives in.

**Caught & fixed:** commit `93ff4b9` (DRAW) + `ba5edb6` (lib).
42 sites across 10 lib files were calling DRAW's `SAFE_FREEIMAGE`.
Renamed to `QB64_GJ_SAFE_FREE_IMAGE` in the lib, helper defined in
`_GJ_LIB_COMMON.BI`, DRAW's `_ALL.BI` now includes that file.

Related: [[reference-input-system]] — DRAW-side architecture.
