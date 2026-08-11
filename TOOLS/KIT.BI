$INCLUDEONCE
'==============================================================================
' KIT.BI - DRAW KITS core: shareable-asset types, manifest model, item list.
' Dialogs live in GUI/; the ZIP container is TOOLS/KIT-ZIP.BI/BM.
'==============================================================================

' Shareable asset types (index into per-type tables; keep in sync with KIT_type_key$).
CONST KIT_TYPE_THEME       = 0
CONST KIT_TYPE_PATTERN     = 1
CONST KIT_TYPE_GRADIENT    = 2
CONST KIT_TYPE_BRUSH       = 3
CONST KIT_TYPE_PALETTE     = 4
CONST KIT_TYPE_FONT_BITMAP = 5
CONST KIT_TYPE_FONT_TTF    = 6
CONST KIT_TYPE_TEXTSTYLE   = 7
CONST KIT_TYPE_TEMPLATE    = 8
CONST KIT_TYPE_COUNT       = 9

' Menu/command action IDs (see gotcha #17: unique, grepped free).
CONST KIT_ACT_EXPORT  = 2320 ' File > Export Kit...
CONST KIT_ACT_INSTALL = 2321 ' File > Install Kit...

' Kit-level metadata. NOTE: `name` is a QB64 reserved word, hence the kit* prefix.
TYPE KIT_MANIFEST
    kitName   AS STRING
    kitDesc   AS STRING
    kitAuthor AS STRING
    kitShot   AS STRING ' screenshot filename inside the kit ("" = none)
END TYPE

' The kit's contents as parallel arrays (type + item identity), filled by the
' export picker or by parsing an installed kit's manifest.
REDIM SHARED KIT_ITEM_TYPE(0) AS INTEGER ' KIT_TYPE_*
REDIM SHARED KIT_ITEM_NAME(0) AS STRING  ' item identity (theme name, palette base, font filename, ...)
DIM SHARED KIT_ITEM_COUNT% ' number of valid entries in the arrays above

' Enumeration output (KIT_enumerate fills these with the user's items of one type).
REDIM SHARED KIT_ENUM_NAME(0) AS STRING ' item identity for the export picker
DIM SHARED KIT_ENUM_COUNT% ' number of valid entries in KIT_ENUM_NAME

' Internal scratch for directory draining (KIT_drain) — one _FILES$ sweep at a time.
REDIM SHARED KIT_DRAIN_NAME(0) AS STRING
DIM SHARED KIT_DRAIN_COUNT%

' Export/install dialog shared state.
DIM SHARED KIT_TOTAL(0 TO KIT_TYPE_COUNT - 1) AS INTEGER ' cached enumerate totals per type
DIM SHARED KIT_EXPORT_MF AS KIT_MANIFEST                 ' metadata edited in the export dialog
DIM SHARED KIT_OUT_PATH$                                 ' chosen export .zip path
DIM SHARED KIT_SHOT_SRC$                                 ' full path of chosen screenshot (source on disk)
DIM SHARED KIT_INSTALL_ON(0 TO KIT_TYPE_COUNT - 1) AS INTEGER ' install dialog: include this type?
DIM SHARED KIT_INSTALL_PATH$                             ' chosen kit file to install
