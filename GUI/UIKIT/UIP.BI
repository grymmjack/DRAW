''
' DRAW - GUI/UIKIT/UIP.BI
' =============================================================================
' UIKIT property + component registry (UIP_). HOST-INDEPENDENT: nothing here
' reads a DRAW global, so it can move to QB64_GJ_LIB/UIKIT as it is. See
' PLANS/THEME-EDIT.md ("UIKIT layer").
'
' A PROPERTY is one themable value (a colour, a size, a font, an image file),
' named by its theme-file key. Values cross into and out of the host as theme-
' file text, through two functions THE HOST MUST DEFINE (a link-time contract;
' QB64 has no function pointers):
'
'     FUNCTION UIP_host_get$ (key AS STRING)            ' live value as text
'     FUNCTION UIP_host_set% (key AS STRING, v AS STRING) ' apply; TRUE = known key
'
' A COMPONENT is a named part of the UI. It owns property SECTIONS (the theme
' file's [SECTION] names) and IMAGE folders (relative to the theme root).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST UIP_T_COLOR = 1 ' "R,G,B,A"
CONST UIP_T_INT   = 2
CONST UIP_T_REAL  = 3
CONST UIP_T_TEXT  = 4
CONST UIP_T_BOOL  = 5 ' TRUE / FALSE
CONST UIP_T_IMAGE = 6 ' a file name, an image
CONST UIP_T_FONT  = 7 ' a file name, a font
CONST UIP_T_SOUND = 8 ' a file name, a sound

TYPE UIP_PROP
    pk     AS STRING  ' theme-file key, upper case
    ptype   AS INTEGER ' UIP_T_*
    section AS STRING  ' theme-file [SECTION]
    desc    AS STRING  ' one line for the inspector
    orig    AS STRING  ' value when the session started (revert target)
    saved   AS STRING  ' value in the theme file (at session start / the last save)
    pending AS INTEGER ' differs from saved
END TYPE

TYPE UIP_COMP
    id       AS STRING  ' "TOOLBOX", "LAYER_PANEL" - upper case, no spaces
    title    AS STRING  ' shown in the inspector
    parent   AS INTEGER ' 0 = top level
    sections AS STRING  ' " SECT1 SECT2 " (padded with spaces for INSTR)
    images   AS STRING  ' "IMAGES/TOOLBOX|CURSORS" - folders under the theme root
END TYPE

' A NODE is one thing on screen, in a tree (the inspector's ELEMENTS pane):
' the host fills the list - depth-first, every node after its parent and its
' parent's earlier children - and rebuilds it whenever its screen changes.
TYPE UIP_NODE
    nkey   AS STRING  ' stable id across rebuilds ("R:4", "TB:12")
    label  AS STRING  ' shown in the tree
    parent AS INTEGER ' 0 = a root
    depth  AS INTEGER ' 0 = a root
    kids   AS INTEGER ' number of children
    comp   AS INTEGER ' UIP_C index whose properties it shows (0 = none)
    x      AS INTEGER ' on-screen box, host window px (w = 0: no box)
    y      AS INTEGER
    w      AS INTEGER
    h      AS INTEGER
    fls    AS STRING  ' its own files ("|"-separated full paths), shown as its element
END TYPE

DIM SHARED UIP_P(1 TO 1)  AS UIP_PROP
DIM SHARED UIP_PN         AS INTEGER
DIM SHARED UIP_C(1 TO 1)  AS UIP_COMP
DIM SHARED UIP_CN         AS INTEGER
DIM SHARED UIP_N(1 TO 1)  AS UIP_NODE
DIM SHARED UIP_NN         AS INTEGER
DIM SHARED UIP_DIRTY      AS INTEGER ' any property pending
DIM SHARED UIP_LAST_ERROR AS STRING  ' why the last file operation failed
