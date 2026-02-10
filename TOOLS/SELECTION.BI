''
' DRAW - TOOLS/SELECTION.BI
' =============================================================================
' UDT for selection tool and clipboard operations.
'
' Clipboard operations for marquee selections:
' - Copy (Ctrl+C): Copy selected region to clipboard
' - Cut (Ctrl+X): Copy selected region to clipboard and clear original with BG color
' - Paste (Ctrl+V): Paste clipboard at mouse position, center selection, engage move tool
' - Clear (Ctrl+E): Fill selected region with background color
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE CLIPBOARD_OBJ
    IMAGE       AS LONG     ' Image buffer holding clipboard pixels
    WIDTH       AS INTEGER  ' Width of clipboard content
    HEIGHT      AS INTEGER  ' Height of clipboard content
    VALID       AS INTEGER  ' Whether clipboard has valid content
    SOURCE_X    AS INTEGER  ' Original X position where content was copied from
    SOURCE_Y    AS INTEGER  ' Original Y position where content was copied from
END TYPE

DIM SHARED CLIPBOARD AS CLIPBOARD_OBJ

DECLARE SUB CLIPBOARD_init ()
DECLARE SUB CLIPBOARD_copy ()
DECLARE SUB CLIPBOARD_copy_merged ()
DECLARE SUB CLIPBOARD_cut ()
DECLARE SUB CLIPBOARD_paste (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB CLIPBOARD_clear_selection ()
DECLARE SUB CLIPBOARD_free ()
