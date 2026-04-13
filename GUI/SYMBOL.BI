'$INCLUDEONCE

' Symbol Layers — Declarations
' Parent/child linked-instance system for reusable sprites

' --- Symbol operations ---
DECLARE FUNCTION SYMBOL_find_parent_slot% (childIdx AS INTEGER)
DECLARE SUB SYMBOL_find_children (parentIdx AS INTEGER, children() AS INTEGER, count AS INTEGER)
DECLARE SUB SYMBOL_render_child (childIdx AS INTEGER)
DECLARE SUB SYMBOL_sync_children (parentIdx AS INTEGER)
DECLARE SUB SYMBOL_sync_all ()

' --- Creation / conversion ---
DECLARE SUB SYMBOL_create_parent (layerIdx AS INTEGER)
DECLARE FUNCTION SYMBOL_create_parent_empty% ()
DECLARE SUB SYMBOL_create_child (parentIdx AS INTEGER)
DECLARE SUB SYMBOL_rasterize_parent (idx AS INTEGER)
DECLARE SUB SYMBOL_detach_child (idx AS INTEGER)

' --- Dirty flag helper ---
DECLARE SUB SYMBOL_mark_parent_dirty (layerIdx AS INTEGER)

' --- Utility ---
DECLARE SUB SYMBOL_select_parent (childIdx AS INTEGER)
