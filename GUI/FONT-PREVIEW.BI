''
' DRAW - GUI/FONT-PREVIEW.BI
' =============================================================================
' Font previews for the font-picker dropdown. Declarations only; the render
' engine + cache live in FONT-PREVIEW.BM.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Per-font preview strip cache (keyed by font index).
'   FONT_PREVIEW_STATE: 0 = not built, 1 = ready, -1 = none (TDF/failed)
DIM SHARED FONT_PREVIEW_IMG(0 TO FONT_LIST_TOTAL_MAX - 1) AS LONG
DIM SHARED FONT_PREVIEW_STATE(0 TO FONT_LIST_TOTAL_MAX - 1) AS INTEGER
DIM SHARED FONT_PREVIEW_BUDGET AS INTEGER      ' remaining fresh renders this frame
DIM SHARED FONT_PREVIEW_DIR_READY AS INTEGER   ' cache dir ensured once
DIM SHARED FONT_PREVIEW_MAX_STRIP_W AS INTEGER ' widest strip rendered so far (px); sizes the dropdown so MAX_W is a CAP, not a forced width
CONST FONT_PREVIEW_BUDGET_MAX = 4              ' cap fresh renders per frame
