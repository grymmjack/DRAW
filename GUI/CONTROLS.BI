''
' DRAW - GUI/CONTROLS.BI
' =============================================================================
' Customize Controls dialog — TYPE + constant declarations (Phase 4).
'
' The dialog reads the live input registry (INPUT_BINDS in INPUT/INPUT.BM) and,
' from 4.2 onward, edits keyboard bindings through the Phase 3 engine
' (CFG/BINDINGS.BM: BINDINGS_set_override / _find_conflict% / _reset_all). It is
' a blocking modal built on the shared DIALOG_CTX infrastructure (GUI/DIALOG.BM),
' mirroring SETTINGS_show_dialog.
'
' Scope note: the rebinding engine is keyboard-only today (mouse/wheel overrides
' are Phase 2B.2), so the CLICK/WHEEL columns are display-only until that lands.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Menu / command action id for opening the dialog. 2360 — verified free across all
' *.BI/*.BM (gotcha #17: 2300 collided with ANS_ACT_EXPORT in OUTPUT/FILE-ANS.BI).
CONST ACTION_CUSTOMIZE_CONTROLS = 2360

' --- Dialog geometry (logical px; DIALOG_init scales by USCALE.dialog%) --------
CONST CTRL_W         = 560 ' dialog width
CONST CTRL_H         = 420 ' dialog height
CONST CTRL_FIND_H    = 22  ' FIND row height (below the title bar)
CONST CTRL_HDR_H     = 15  ' column-header row height
CONST CTRL_BTN_BAR_H = 30  ' bottom button-bar height
CONST CTRL_ROW_H     = 16  ' per-binding content row height
CONST CTRL_CAT_H     = 15  ' category separator row height
CONST CTRL_SCROLL_W  = 10  ' scrollbar track width

' --- Column layout (x offsets within the dialog buffer) -----------------------
CONST CTRL_COL_NAME_X = 10  ' function/label column
CONST CTRL_COL_NAME_W = 300
CONST CTRL_COL_CUR_X  = 314 ' current assignment (rendered key)
CONST CTRL_COL_CUR_W  = 130
CONST CTRL_COL_BTN_X  = 448 ' rebind button (4.2+)
CONST CTRL_COL_BTN_W  = 92

' Dropdown id (unique within the dialog) for the "Export as…" menu.
CONST CTRL_DD_EXPORT  = 1

' A flattened, filtered display row: either a category header or one binding.
' bindIdx = index into INPUT_BINDS (0 for a header row); cat = CAT_* for headers.
TYPE CTRL_VISROW
    isHeader AS INTEGER
    cat      AS INTEGER ' CAT_* (header rows)
    bindIdx  AS INTEGER ' 1..INPUT_BIND_COUNT (binding rows)
END TYPE

' Singleton dialog state. ctx nests DIALOG_CTX (all fixed fields — safe to nest,
' as SETTINGS does). filter is fixed-length so it can live in the TYPE.
TYPE CONTROLS_STATE
    ctx         AS DIALOG_CTX
    filter      AS STRING * 40 ' current FIND text (trimmed on use)
    filterLen   AS INTEGER     ' live length of filter text
    scrollY     AS INTEGER     ' first visible pixel (content scroll offset)
    contentH    AS INTEGER     ' total laid-out content height (for scroll clamp)
    viewportH   AS INTEGER     ' visible content height
    visCount    AS INTEGER     ' number of populated CTRL_VISROWS rows
    needsRedraw AS INTEGER
    findTI      AS INTEGER     ' TI text-input widget id for the FIND box (0 = none)
    findFont    AS LONG        ' font handle loaded for the FIND widget (freed on close)
    scrollDrag  AS INTEGER     ' TRUE while dragging the scrollbar thumb
    scrollDragOff AS INTEGER   ' mouse-Y minus thumb-top at grab (keeps grab point under cursor)
    exportedMsg AS STRING * 96 ' transient "Exported to ..." status shown after EXPORT
    exportedLen AS INTEGER     ' live length of exportedMsg (0 = none shown)
END TYPE

DIM SHARED CONTROLS AS CONTROLS_STATE
' Flattened visible-row list, rebuilt from the registry + filter each open/edit.
REDIM SHARED CTRL_VISROWS(1 TO 1) AS CTRL_VISROW
