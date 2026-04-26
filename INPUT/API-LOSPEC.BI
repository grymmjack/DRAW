''
' DRAW - INPUT/API-LOSPEC.BI
' =============================================================================
' UDT and declarations for the Lospec palette download dialog.
'
' Provides a modal dialog that lets users search the Lospec palette list,
' add palettes to a batch download list, and download them as .GPL files
' into ./USER/PALETTES/.  A downloads.json index is kept in that folder.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Maximum number of search results to keep in memory
CONST LOSPEC_MAX_RESULTS = 64

' Maximum number of entries in the batch list
CONST LOSPEC_MAX_BATCH = 32

' A single palette entry returned by the Lospec API
TYPE LOSPEC_PALETTE_INFO
    palName   AS STRING * 64   ' Display name
    palSlug   AS STRING * 64   ' URL slug (used to download .GPL)
    numColors AS INTEGER       ' Color count
    author    AS STRING * 64   ' Author display name (from API "author.name")
    colors    AS STRING * 2048 ' Comma-delimited hex color values, no # prefix (up to 256)
END TYPE

DIM SHARED LOSPEC_RESULTS(0 TO LOSPEC_MAX_RESULTS - 1) AS LOSPEC_PALETTE_INFO
DIM SHARED LOSPEC_RESULT_COUNT%

DIM SHARED LOSPEC_BATCH(0 TO LOSPEC_MAX_BATCH - 1) AS LOSPEC_PALETTE_INFO
DIM SHARED LOSPEC_BATCH_COUNT%

' Download status message (displayed at bottom of dialog)
DIM SHARED LOSPEC_DOWNLOAD_STATUS$

