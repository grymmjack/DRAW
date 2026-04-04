''
' DRAW - INPUT/FILE-ASE.BI
' =============================================================================
' Declarations for Aseprite (.ase/.aseprite) file loading.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DECLARE SUB FILE_ASE_load (filename AS STRING)
DECLARE FUNCTION FILE_ASE_is_aseprite_file% (filename AS STRING)
DECLARE FUNCTION FILE_ASE_map_blend_mode% (aseBlendMode AS INTEGER)
DECLARE SUB FILE_ASE_open_dialog ()
