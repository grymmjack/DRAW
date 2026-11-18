''
' DRAW - GUI/PANEL-SLIDER.BI
' =============================================================================
' A labelled slider row for the dock panels that draw their own controls (the
' MyPaint Brush Settings, GUI/MYPAINT-SET, and the brush palette, GUI/BRUSH-PANEL):
' LABEL  [track######.....]  VALUE  in one row, or - narrower than PSL_one_line_w% -
' LABEL ........ VALUE over a full-width track (two rows). The menu bar's font, the
' text bar's colours. The panel keeps the value and the input: the universal value
' input (Rick 2026-11-18) is the panel's - wheel +/-1 (Shift 10), middle-click resets,
' a double-click on the track resets, a double-click on the value types one
' (VAL_wheel_step% / VAL_dbl% / VAL_type%, GUI/DIALOG.BM). PSL_part% says which part
' a point is on; PSL_value& turns a pointer x into a value.
'
$INCLUDEONCE

CONST PSL_PART_LABEL = 1
CONST PSL_PART_TRACK = 2
CONST PSL_PART_VALUE = 3
