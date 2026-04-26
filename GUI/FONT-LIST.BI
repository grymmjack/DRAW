''
' DRAW - GUI/FONT-LIST.BI
' =============================================================================
' Font enumeration, caching, and handle management.
' Discovers bundled + system TTF/OTF/TTC fonts, provides cached _LOADFONT handles.
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
    path              AS STRING * 260 ' Full path to the font file
    displayName       AS STRING * 64  ' Human-readable name (extracted from filename)
    isBundled         AS INTEGER      ' TRUE if shipped with DRAW (ASSETS/FONTS/)
    isBuiltIn         AS INTEGER      ' TRUE if QB64-PE built-in bitmap font (_FONT 8/14/16)
    builtInHandle     AS LONG         ' Built-in font handle (8, 14, or 16); 0 if not built-in
    hasBold           AS INTEGER      ' TRUE if bold variant file detected
    hasItalic         AS INTEGER      ' TRUE if italic variant file detected
    hasBoldItalic     AS INTEGER      ' TRUE if bold-italic variant file detected
    boldPath          AS STRING * 260 ' Path to bold variant (if found)
    italicPath        AS STRING * 260 ' Path to italic variant (if found)
    boldItalicPath    AS STRING * 260 ' Path to bold-italic variant (if found)
    isFavorite        AS INTEGER      ' TRUE if font is in DRAW_FONT_FAVORITES.txt
    isBitmapFont      AS INTEGER      ' TRUE if raw bitmap font (F??, PSF, BDF, PCF)
    isColorBitmapFont AS INTEGER      ' TRUE if color bitmap spritesheet font (.BMP)
    bitmapGlyphW      AS INTEGER      ' Glyph width for bitmap fonts (pixels)
    bitmapGlyphH      AS INTEGER      ' Glyph height for bitmap fonts (pixels)
    folderName        AS STRING * 64  ' Subfolder name ("AMIGA", "RETRO", etc.) or empty for root
END TYPE

' Font list (populated by FONT_LIST_scan)
DIM SHARED FONT_LIST(0 TO FONT_LIST_MAX - 1) AS FONT_ENTRY
DIM SHARED FONT_LIST_COUNT   AS INTEGER
DIM SHARED FONT_LIST_SCANNED AS INTEGER                             ' TRUE after first scan

' Font handle cache (size+style → loaded handle)
DIM SHARED FONT_CACHE_IDX(0 TO FONT_CACHE_MAX - 1)  AS INTEGER      ' Font list index
DIM SHARED FONT_CACHE_SIZE(0 TO FONT_CACHE_MAX - 1)  AS INTEGER     ' Point size
DIM SHARED FONT_CACHE_STYLE(0 TO FONT_CACHE_MAX - 1) AS STRING * 16 ' Style string
DIM SHARED FONT_CACHE_HANDLE(0 TO FONT_CACHE_MAX - 1) AS LONG       ' Loaded handle
DIM SHARED FONT_CACHE_MONO(0 TO FONT_CACHE_MAX - 1) AS INTEGER      ' Monospace flag
DIM SHARED FONT_CACHE_AA(0 TO FONT_CACHE_MAX - 1) AS INTEGER        ' Antialias flag
DIM SHARED FONT_CACHE_COUNT AS INTEGER

' Blacklist: fonts whose path/filename matches are excluded from the list
DIM SHARED FONT_BLACKLIST_FILE$
FONT_BLACKLIST_FILE$     = PATHS_config$("DRAW_FONT_BLACKLIST.txt")
CONST FONT_BLACKLIST_MAX = 256
DIM SHARED FONT_BLACKLIST(0 TO FONT_BLACKLIST_MAX - 1) AS STRING * 260
DIM SHARED FONT_BLACKLIST_COUNT AS INTEGER

' Favorites: font display names shown at the top of the dropdown
DIM SHARED FONT_FAVORITES_FILE$
FONT_FAVORITES_FILE$     = PATHS_config$("DRAW_FONT_FAVORITES.txt")
CONST FONT_FAVORITES_MAX = 64
DIM SHARED FONT_FAVORITES(0 TO FONT_FAVORITES_MAX - 1) AS STRING * 64
DIM SHARED FONT_FAVORITES_COUNT AS INTEGER

' Font dropdown display list — maps visible row to font or folder header.
' Built after scan+sort by FONT_LIST_build_display_list.
CONST FONT_DD_MAX    = 576                                          ' FONT_LIST_MAX + FONT_FOLDER_MAX headroom
CONST FONT_DD_FONT   = 0                                            ' Row is a selectable font
CONST FONT_DD_FOLDER = 1                                            ' Row is a folder header with submenu
DIM SHARED FONT_DD_TYPE(0 TO FONT_DD_MAX - 1)  AS INTEGER           ' FONT_DD_FONT or FONT_DD_FOLDER
DIM SHARED FONT_DD_VALUE(0 TO FONT_DD_MAX - 1) AS INTEGER           ' fontIdx or folderIdx
DIM SHARED FONT_DD_COUNT AS INTEGER

' Subfolder names (deduplicated, in order of first appearance after sort)
CONST FONT_FOLDER_MAX = 64
DIM SHARED FONT_FOLDER_NAME(0 TO FONT_FOLDER_MAX - 1) AS STRING * 64
DIM SHARED FONT_FOLDER_COUNT AS INTEGER

' Color Bitmap Font (CBF) spritesheet cache — DPaint-style .BMP fonts
CONST CBF_CACHE_MAX = 8
CONST CBF_GLYPH_MAX = 128

DIM SHARED CBF_CACHE_PATH(0 TO CBF_CACHE_MAX - 1) AS STRING * 260
DIM SHARED CBF_CACHE_SHEET(0 TO CBF_CACHE_MAX - 1) AS LONG
DIM SHARED CBF_CACHE_GLYPH_X(0 TO CBF_CACHE_MAX - 1, 0 TO CBF_GLYPH_MAX - 1) AS INTEGER
DIM SHARED CBF_CACHE_GLYPH_W(0 TO CBF_CACHE_MAX - 1, 0 TO CBF_GLYPH_MAX - 1) AS INTEGER
DIM SHARED CBF_CACHE_CHAR_MAP(0 TO CBF_CACHE_MAX - 1, 0 TO 255) AS INTEGER
DIM SHARED CBF_CACHE_GLYPH_CNT(0 TO CBF_CACHE_MAX - 1) AS INTEGER
DIM SHARED CBF_CACHE_HEIGHT(0 TO CBF_CACHE_MAX - 1) AS INTEGER
DIM SHARED CBF_CACHE_SPACE_W(0 TO CBF_CACHE_MAX - 1) AS INTEGER
DIM SHARED CBF_CACHE_BG_CLR(0 TO CBF_CACHE_MAX - 1) AS _UNSIGNED LONG
DIM SHARED CBF_CACHE_COUNT AS INTEGER

