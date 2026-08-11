---
name: qb64pe-mapunicode-illegal
description: _MAPUNICODE raises "Illegal function call" on some font handles; render Unicode glyphs with _UPRINTSTRING(UTF-8) instead
metadata:
  type: feedback
---

[Linux] `_MAPUNICODE codepoint TO slot` raises **ERR 5 "Illegal function call"** for some font handles (bitmap `.F??` handles, or TTFs without a cmap). It fires per-codepoint, so a scan loop can trap dozens of errors per frame — invisible at runtime because DRAW's `FatalError` does `RESUME NEXT`; only the QA harness's crash-log snapshot (`~/Desktop/DRAW-log/DRAW-crash-logs/`) surfaced it.

**Why:** the `_MAPUNICODE cp TO 1` + `_PRINTSTRING CHR$(1)` trick for rendering an arbitrary glyph assumes the current `_FONT` supports remapping. Bitmap/no-cmap fonts do not.

**How to apply:** to test/render a single Unicode glyph, skip `_MAPUNICODE` entirely — encode the codepoint to UTF-8 and `_UPRINTSTRING` it (that's how the rest of DRAW draws Unicode). DRAW has `FONT_utf8$(cp)` (BMP encoder) + `FONT_count_ttf_range%` in `GUI/FONT-LIST.BM` doing exactly this for the font-preview glyph counter.

Second half of the same bug: `FONT_PREVIEW_text$` computed the `{NumGlyphs}` count **unconditionally**, so the crashy path ran even for the default sample `{Font} ABCabc123` that never uses the token. Gate expensive substitutions on `INSTR(template, "{Token}") > 0`. See [[qb64pe-logic-operators]], [[reference_qa_harness_capture]].
