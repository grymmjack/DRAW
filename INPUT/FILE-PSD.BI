''
' DRAW - INPUT/FILE-PSD.BI
' =============================================================================
' Declarations for Adobe Photoshop PSD file loading with layer support.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE SUB FILE_PSD_load (filename AS STRING)
DECLARE FUNCTION FILE_PSD_is_psd_file% (filename AS STRING)
DECLARE SUB FILE_PSD_open_dialog ()
