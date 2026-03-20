''
' DRAW - GUI/FONT-LIST.BI
' =============================================================================
' Font enumeration, caching, and handle management.
' Discovers bundled + system TTF/OTF fonts, provides cached _LOADFONT handles.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Maximum number of fonts in the list
CONST FONT_LIST_MAX = 512

' Maximum cached font handles (loaded at specific size+style)
CONST FONT_CACHE_MAX = 128

' Style constants for FONT_LIST_get_handle&
CONST FONT_STYLE_REGULAR$    = ""
CONST FONT_STYLE_BOLD$       = "BOLD"
CONST FONT_STYLE_ITALIC$     = "ITALIC"
CONST FONT_STYLE_BOLDITALIC$ = "BOLDITALIC"

TYPE FONT_ENTRY
    path          AS STRING * 260  ' Full path to the font file
    displayName   AS STRING * 64   ' Human-readable name (extracted from filename)
    isBundled     AS INTEGER       ' TRUE if shipped with DRAW (ASSETS/FONTS/)
    isBuiltIn     AS INTEGER       ' TRUE if QB64-PE built-in bitmap font (_FONT 8/14/16)
    builtInHandle AS LONG          ' Built-in font handle (8, 14, or 16); 0 if not built-in
    hasBold       AS INTEGER       ' TRUE if bold variant file detected
    hasItalic     AS INTEGER       ' TRUE if italic variant file detected
    hasBoldItalic AS INTEGER       ' TRUE if bold-italic variant file detected
    boldPath      AS STRING * 260  ' Path to bold variant (if found)
    italicPath    AS STRING * 260  ' Path to italic variant (if found)
    boldItalicPath AS STRING * 260 ' Path to bold-italic variant (if found)
END TYPE

' Font list (populated by FONT_LIST_scan)
DIM SHARED FONT_LIST(0 TO FONT_LIST_MAX - 1) AS FONT_ENTRY
DIM SHARED FONT_LIST_COUNT AS INTEGER
DIM SHARED FONT_LIST_SCANNED AS INTEGER  ' TRUE after first scan

' Font handle cache (size+style → loaded handle)
DIM SHARED FONT_CACHE_IDX(0 TO FONT_CACHE_MAX - 1)  AS INTEGER  ' Font list index
DIM SHARED FONT_CACHE_SIZE(0 TO FONT_CACHE_MAX - 1)  AS INTEGER  ' Point size
DIM SHARED FONT_CACHE_STYLE(0 TO FONT_CACHE_MAX - 1) AS STRING * 16 ' Style string
DIM SHARED FONT_CACHE_HANDLE(0 TO FONT_CACHE_MAX - 1) AS LONG    ' Loaded handle
DIM SHARED FONT_CACHE_MONO(0 TO FONT_CACHE_MAX - 1) AS INTEGER   ' Monospace flag
DIM SHARED FONT_CACHE_COUNT AS INTEGER

DECLARE SUB FONT_LIST_scan ()
DECLARE SUB FONT_LIST_scan_dir (dir$, recursive%, isBundled%)
DECLARE SUB FONT_LIST_add_font (fontPath$, isBundled%)
DECLARE SUB FONT_LIST_add_builtin (displayName$, builtInHandle&)
DECLARE SUB FONT_LIST_sort ()
DECLARE FUNCTION FONT_LIST_get_handle& (fontIdx%, fontSize%, fontStyle$, mono%)
DECLARE FUNCTION FONT_LIST_extract_name$ (fontPath$)
DECLARE FUNCTION FONT_LIST_find_by_name% (displayName$)
DECLARE SUB FONT_LIST_free_cache ()
