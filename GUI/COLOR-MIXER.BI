''
' DRAW - GUI/COLOR-MIXER.BI
' =============================================================================
' Color Mixer — floating non-modal color picker panel declarations.
' Wraps the QB64_GJ_LIB COLOR_PICKER (CP module) in a DRAW-style floating
' panel with live color editing that syncs with the current FG color.
' Toggle via organizer button or View > Color Mixer.
' State persists to DRAW.cfg.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

TYPE COLOR_MIXER_OBJ
    visible       AS INTEGER        ' TRUE = panel is shown
    positioned    AS INTEGER        ' TRUE once auto-positioned
    initialized   AS INTEGER        ' TRUE after first CP_init call
    autoHidden    AS INTEGER        ' Auto-hidden while drawing over panel
    lastSyncColor AS _UNSIGNED LONG ' Last color synced to/from mixer
    renderScale   AS SINGLE         ' Scale factor for display (<= 1.0)
    dispW         AS INTEGER        ' Displayed width on SCRN.CANVAS
    dispH         AS INTEGER        ' Displayed height on SCRN.CANVAS
    fitW AS INTEGER ' docked: native size its slot gives it (0 = natural) - FPANEL_fit
    fitH AS INTEGER
    natW AS INTEGER ' its natural (floating) native size, from its layout
    natH AS INTEGER
    docked      AS INTEGER ' in a dock slot (GUI/DOCK): the slot places it; no clamp
    dispX         AS INTEGER        ' Displayed X (viewport coords)
    dispY         AS INTEGER        ' Displayed Y (viewport coords)
    dragging      AS INTEGER        ' TRUE while title-bar drag is active
    dragStartMX   AS INTEGER        ' Raw mouse X at drag start
    dragStartMY   AS INTEGER        ' Raw mouse Y at drag start
    dragStartDX   AS INTEGER        ' dispX at drag start
    dragStartDY   AS INTEGER        ' dispY at drag start
    moreHover     AS INTEGER        ' the pointer is on the MORE row (redraw when it changes)
    ' In a top / bottom dock row it lies sideways (COLORMIXER_side_flow): the
    ' title bar + SV field at the left, as tall as the row; the picker's rows
    ' under it (OLD / NEW, MORE, sliders, hex, ...) copied as strips into
    ' columns to the right. The picker itself still lays out stacked.
    side     AS INTEGER ' TRUE: laid sideways
    fitRow   AS INTEGER ' (FPANEL_fit saw it in a row)
    sideW    AS INTEGER ' the sideways panel (native px)
    sideH    AS INTEGER
    sideMainH AS INTEGER ' the left block's height: title bar + SV field (the stacked rows above OLD / NEW)
    sideN    AS INTEGER ' strips in use
    sideGrab AS INTEGER ' the strip a press began in (a drag keeps its mapping); 0 = the left block
    sideImg  AS LONG    ' the composed sideways panel
END TYPE

DIM SHARED COLORMIXER AS COLOR_MIXER_OBJ
CONST COLORMIXER_SIDE_MAX = 10 ' strips (stacked y ranges) placed beside the SV field
CONST COLORMIXER_ROW_FIELD_MIN = 20 ' the SV field's least height in a row (native px)
DIM SHARED CMX_SY0(1 TO COLORMIXER_SIDE_MAX) AS INTEGER ' strip i: stacked rows sy0 .. sy1 - 1,
DIM SHARED CMX_SY1(1 TO COLORMIXER_SIDE_MAX) AS INTEGER '   shown at (dx, dy) in the sideways panel
DIM SHARED CMX_DX(1 TO COLORMIXER_SIDE_MAX) AS INTEGER
DIM SHARED CMX_DY(1 TO COLORMIXER_SIDE_MAX) AS INTEGER
CONST COLORMIXER_MORE_PAD = 3 ' px above and below the MORE disclosure row

