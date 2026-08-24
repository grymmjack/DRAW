''
' DRAW - TOOLS/LAYERXFER.BI
' =============================================================================
' Cross-instance LAYER transfer: extract a layer to a portable form and re-add it
' as a new layer in another document / another running DRAW instance.
'
' Two transports share the same core (extract canvas-region pixels + tiny metadata):
'   * Clipboard  (Copy/Paste Layer): pixels ride _CLIPBOARDIMAGE (alpha-safe, cross-
'                platform), metadata rides _CLIPBOARD$ as one text line. No base64.
'   * Mailbox    (Send Layer -> Instance N): a self-contained binary blob
'                [MKI$(metaLen)][meta$][PNG bytes] written to the target's inbox.
'                PNG via _SAVEIMAGE/_LOADIMAGE -- no custom pixel codec, no _MEM.
'
' Only pixels + name/opacity/blend travel. layerType is intentionally forced to
' IMAGE on the receiving side (text/AI layers carry side-table data that is not
' transferable), so a transferred layer is always a plain image layer.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Text tag prefixing the clipboard/blob metadata line: "MAGIC|name|opacity|blend".
CONST LAYERXFER_META_MAGIC$ = "DRAWLAYER1"
