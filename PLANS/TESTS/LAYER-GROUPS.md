# [ ] LAYER GROUPS TESTING

## [x] GROUP CREATION

### [x] New Group (Ctrl+G / Action 720)
Create an empty group layer above the current layer.

#### [x] Create group via keyboard shortcut
1. [x] Select any layer in the layers panel
2. [x] Press Ctrl+G
3. [x] Verify a new "Group N" layer appears above the selected layer in the panel
4. [x] Verify the group header row has a collapse triangle (▶/▼) and distinct header styling
5. [x] Verify the group header shows the folder/group icon
6. [x] Verify CURRENT_LAYER% switches to the new group header

#### [x] Create group via Layer menu
1. [x] Open Layer menu in the menu bar
2. [x] Click "New Group"
3. [x] Verify a new group is created above the current layer

#### [x] Create group via context menu
1. [x] Right-click any layer row in the layers panel
2. [x] Click "New Group" in the context menu
3. [x] Verify a new group is created above the right-clicked layer

#### [x] Create group via Command Palette
1. [x] Press ? to open the Command Palette
2. [x] Type "new group"
3. [x] Select the matching command
4. [x] Verify a new group is created

#### [x] Create group inside another group (nested)
1. [x] Create a group (Ctrl+G)
2. [x] Select a child layer inside that group
3. [x] Press Ctrl+G again
4. [x] Verify a sub-group is created inside the parent group
5. [x] Verify the sub-group is indented one level deeper in the panel

#### [x] Create group respects MAX_GROUP_NESTING (8 levels)
1. [x] Create nested groups 8 levels deep
2. [x] Try to create a 9th nested group inside the deepest one
3. [x] Verify the operation is prevented or the group is created at the allowed depth

#### [x] Create group auto-naming increments
1. [x] Create a group — should be "Group 1"
2. [x] Create another group — should be "Group 2"
3. [x] Delete "Group 1"
4. [x] Create another group — should be "Group 3" (counter doesn't reuse)

#### [x] Undo/Redo new group
1. [x] Create a new group (Ctrl+G)
2. [x] Press Ctrl+Z to undo
3. [x] Verify the group is removed
4. [x] Press Ctrl+Y to redo
5. [x] Verify the group reappears

### [ ] Group from Selection (Ctrl+Shift+G / Action 721)
Wrap multi-selected layers into a new group.

#### [x] Group from multi-selected layers
1. [x] Create 3 layers with distinct content
2. [x] Ctrl+Click to multi-select all 3 layers in the panel
3. [x] Press Ctrl+Shift+G
4. [x] Verify all 3 layers are now children of a new group
5. [x] Verify the group header appears above the topmost selected layer
6. [x] Verify the child layers are indented under the group

#### [x] Group from selection includes sub-group descendants
1. [x] Create a group with 2 child layers
2. [x] Multi-select the group header and another standalone layer
3. [x] Press Ctrl+Shift+G
4. [x] Verify the sub-group and its children are all inside the new parent group
5. [x] Verify nesting structure is preserved (sub-group stays a group)

#### [x] Group from selection respects nesting depth limit
1. [x] Create groups nested to depth 7
2. [x] Multi-select two layers at the deepest level
3. [x] Try Ctrl+Shift+G
4. [x] Verify a warning or prevention if the result would exceed MAX_GROUP_NESTING (8)

#### [x] Group from selection finds common parent
1. [x] Create a group with layers A and B
2. [x] Create another standalone layer C outside the group
3. [x] Multi-select A, B, and C
4. [x] Press Ctrl+Shift+G
5. [x] Verify the new group is created at the top level (common ancestor is root)

#### [ ] Undo/Redo group from selection
1. [x] Multi-select 3 layers and press Ctrl+Shift+G
2. [x] Ctrl+Z to undo
3. [x] Verify all 3 layers return to their original un-grouped positions
4. [ ] Ctrl+Y to redo
5. [x] Verify the group is recreated with the same structure

---

## [ ] GROUP PANEL INTERACTIONS

### [x] Collapse/Expand
Toggle group collapse state in the layers panel.

#### [x] Click collapse triangle to collapse
1. [x] Create a group with 3 child layers
2. [x] Click the collapse triangle (▶/▼) on the group header
3. [x] Verify child layers are hidden from the panel view
4. [x] Verify the triangle changes orientation (▶ for collapsed)

#### [x] Click collapse triangle to expand
1. [x] With a collapsed group, click the triangle again
2. [x] Verify child layers reappear in the panel
3. [x] Verify the triangle changes back (▼ for expanded)

#### [x] Collapsed group hides nested sub-groups
1. [x] Create a group with a sub-group containing child layers
2. [x] Collapse the parent group
3. [x] Verify the sub-group and all its children are hidden from the panel

#### [x] Collapsed state persists across save/load
1. [x] Collapse a group
2. [x] Save the project as .draw
3. [x] Close and reopen the project
4. [x] Verify the group is still collapsed in the panel

### [x] Select Layer in Group
Click to select layers within groups.

#### [x] Click group header to select it
1. [x] Click on a group header row (not on the eye icon or triangle)
2. [x] Verify CURRENT_LAYER% is the group header
3. [x] Verify the group header row is highlighted as selected

#### [x] Click child layer to select it
1. [x] Click on a child layer inside a group
2. [x] Verify CURRENT_LAYER% is the child layer
3. [x] Verify the child row is highlighted as selected

#### [x] Select collapsed group header
1. [x] Collapse a group
2. [x] Click the collapsed group header
3. [x] Verify the group header is selected even when collapsed

### [x] Group Indentation
Verify visual hierarchy in the layers panel.

#### [x] Direct children are indented one level
1. [x] Create a group with 2 child layers
2. [x] Verify child layers are indented by THEME.LAYER_PANEL_group_indent% pixels

#### [x] Nested groups show increasing indentation
1. [x] Create a group containing a sub-group with children
2. [x] Verify the sub-group header is indented 1 level from the parent group
3. [x] Verify the sub-group's children are indented 2 levels from the parent group

#### [x] Deep nesting up to 8 levels shows progressive indent
1. [x] Create groups nested 4 levels deep with a leaf layer
2. [x] Verify each level shows increasing indentation
3. [x] Verify the leaf layer is correctly indented at the deepest level

### [x] Group Header Styling
Verify group headers have distinct visual treatment.

#### [x] Group header background color
1. [x] Create a group
2. [x] Verify the group header row uses THEME.LAYER_PANEL_group_header_bg color

#### [x] Group header text color
1. [x] Create a group
2. [x] Verify the group name text uses THEME.LAYER_PANEL_group_header_fg color

#### [x] Collapse triangle uses theme color
1. [x] Create a group
2. [x] Verify the collapse triangle uses THEME.LAYER_PANEL_group_collapse_fg color

---

## [x] GROUP VISIBILITY

### [x] Toggle Group Visibility (Eye Icon)
Clicking the eye icon on a group header toggles all children.

#### [x] Hide group hides all children
1. [x] Create a group with 3 visible child layers, each with distinct content
2. [x] Click the eye icon on the group header
3. [x] Verify the group header eye shows "off"
4. [x] Verify all 3 child layers become hidden (eye icons off)
5. [x] Verify the canvas no longer shows any of the 3 children's content

#### [x] Show group restores individual child visibility
1. [x] Create a group with 3 child layers
2. [x] Hide one child layer individually (click its eye icon)
3. [x] Hide the group (click group header eye icon)
4. [x] Show the group again (click group header eye icon)
5. [x] Verify the previously-hidden child remains hidden (its state is restored)
6. [x] Verify the 2 previously-visible children are visible again

#### [x] Nested group visibility cascade
1. [x] Create a parent group containing a sub-group with children
2. [x] Hide the parent group
3. [x] Verify the sub-group and all its children are hidden
4. [x] Show the parent group
5. [x] Verify visibility is restored to pre-hide states

#### [x] Visibility swipe across group members
1. [x] Create a group with 5 child layers, all visible
2. [x] Click and drag across the eye icons of the child layers
3. [x] Verify the visibility swipe toggles each crossed layer

---

## [x] GROUP DRAG AND DROP

### [x] Drag Layer Into Group
Reorder layers into groups via drag-and-drop in the panel.

#### [x] Drag standalone layer onto group header
1. [x] Create a standalone layer and a group
2. [x] Drag the standalone layer and drop it onto the group header row
3. [x] Verify the layer becomes a child of the group
4. [x] Verify the layer is now indented under the group

#### [x] Drag standalone layer onto group child
1. [x] Create a standalone layer and a group with existing children
2. [x] Drag the standalone layer onto one of the group's child layers
3. [x] Verify the layer is inserted into that group
4. [x] Verify z-order reflects the drop position

#### [x] Drag layer out of group
1. [x] Create a group with 2 child layers
2. [x] Drag one child layer and drop it outside/above the group header
3. [x] Verify the layer is removed from the group
4. [x] Verify the layer is now at the top level

#### [x] Drag group into another group (nesting)
1. [x] Create two groups (GroupA and GroupB)
2. [x] Drag GroupB onto GroupA's header
3. [x] Verify GroupB becomes a sub-group of GroupA
4. [x] Verify GroupB's children remain intact inside GroupB

#### [x] Drag prevents circular nesting
1. [x] Create GroupA containing GroupB
2. [x] Try to drag GroupA onto GroupB (or onto a child of GroupB)
3. [x] Verify the operation is prevented (cannot nest a group inside its own descendant)

#### [x] Drag respects MAX_GROUP_NESTING
1. [x] Create groups nested to depth 7
2. [x] Try to drag a group (depth 1) into the deepest group
3. [x] Verify the operation is prevented if it would exceed depth 8

#### [x] Undo/Redo drag into group
1. [x] Drag a layer into a group
2. [x] Ctrl+Z to undo
3. [x] Verify the layer is back to its original position
4. [x] Ctrl+Y to redo
5. [x] Verify the layer is back inside the group

#### [x] Drag layer onto Delete button
1. [x] Create a group with 3 child layers
2. [x] Drag a child layer onto the Delete button at the bottom of the panel
3. [x] Verify the layer is deleted from the group

#### [x] Drag layer onto New Layer button
1. [x] Create a group with a child layer
2. [x] Drag the child layer onto the New Layer (+) button
3. [x] Verify expected behavior (duplicate or create new adjacent layer)

---

## [ ] GROUP OPERATIONS

### [x] Ungroup (Ctrl+Shift+U / Action 722)
Dissolve a group, reparenting children to the grandparent.

#### [x] Ungroup a top-level group
1. [x] Create a group with 3 child layers
2. [x] Select the group header
3. [x] Press Ctrl+Shift+U
4. [x] Verify the group header is deleted
5. [x] Verify the 3 children become top-level layers
6. [x] Verify the children retain their z-order relative to each other

#### [x] Ungroup a nested sub-group
1. [x] Create GroupA containing GroupB (with 2 children)
2. [x] Select GroupB's header
3. [x] Press Ctrl+Shift+U
4. [x] Verify GroupB is dissolved
5. [x] Verify GroupB's children become direct children of GroupA
6. [x] Verify GroupA still exists with its other children intact

#### [x] Ungroup via Layer menu
1. [x] Select a group header
2. [x] Open Layer menu → click "Ungroup"
3. [x] Verify the group is dissolved

#### [x] Ungroup via context menu
1. [x] Right-click a group header
2. [x] Click "Ungroup" in the context menu
3. [x] Verify the group is dissolved

#### [x] Ungroup disabled when not a group
1. [x] Select a regular image layer
2. [x] Open Layer menu
3. [x] Verify "Ungroup" is greyed out / disabled

#### [x] Undo/Redo ungroup
1. [x] Create a group with children, then ungroup it
2. [x] Ctrl+Z to undo
3. [x] Verify the group is recreated with the same children and structure
4. [x] Ctrl+Y to redo
5. [x] Verify the group is dissolved again

### [x] Merge Group (Action 723)
Flatten all group children into a single image layer.

#### [x] Merge group with image layers
1. [x] Create a group with 3 child layers, each with distinct pixel content
2. [x] Select the group header
3. [x] Execute Merge Group from the Layer menu or context menu
4. [x] Verify a single merged layer replaces the group
5. [x] Verify the merged layer's pixels are the correct composite of all children
6. [x] Verify the merged layer inherits the group's name
 
#### [x] Merge group with different blend modes
1. [x] Create a group with 2 child layers using different blend modes (e.g., Multiply, Screen)
2. [x] Merge the group
3. [x] Verify the merged result correctly composites the blend modes

#### [x] Merge group with varying opacities
1. [x] Create a group with children at different opacity levels (e.g., 128, 64, 255)
2. [x] Merge the group
3. [x] Verify the merged result correctly applies per-layer opacity

#### [x] Merge group with hidden children
1. [x] Create a group with 3 children, hide one
2. [x] Merge the group
3. [x] Verify hidden layers are excluded from the composite

#### [x] Merge group with nested sub-groups
1. [x] Create a group containing a sub-group with its own children
2. [x] Merge the parent group
3. [x] Verify ALL descendants (including sub-group children) are composited
4. [x] Verify the result is a single flat image layer

#### [x] Merge group preserves parent group membership
1. [x] Create GroupA containing GroupB with children
2. [x] Merge GroupB
3. [x] Verify the merged result layer remains a child of GroupA

#### [x] Merge group disabled when not a group
1. [x] Select a regular image layer
2. [x] Verify "Merge Group" is greyed out in the menu and context menu

#### [x] Undo/Redo merge group
1. [x] Merge a group with distinct child content
2. [x] Ctrl+Z to undo
3. [x] Verify the group and all children are restored to their original state
4. [x] Ctrl+Y to redo
5. [x] Verify the merge result reappears

### [x] Select All in Group (Action 725)
Multi-select all descendants of a group.

#### [x] Select all in group from group header
1. [x] Create a group with 4 child layers
2. [x] Select the group header
3. [x] Execute "Select All in Group" from Layer menu or context menu
4. [x] Verify all 4 children are multi-selected (highlighted in panel)

#### [x] Select all in group from child layer
1. [x] Create a group with 3 children
2. [x] Select one of the children
3. [x] Execute "Select All in Group"
4. [x] Verify all children of the parent group are selected

#### [x] Select all in nested group selects descendants recursively
1. [x] Create GroupA with children and a sub-group GroupB (also with children)
2. [x] Execute "Select All in Group" on GroupA
3. [x] Verify ALL descendants including GroupB's children are multi-selected

#### [x] Select all disabled when not in a group
1. [x] Select a top-level layer that is not in any group
2. [x] Verify "Select All in Group" is greyed out

### [x] Selection from Group (Action 727)
Create a pixel-accurate marquee selection from group contents.

#### [x] Selection from group creates marquee matching pixel bounds
1. [x] Create a group with 2 child layers, each with distinct pixel content at different positions
2. [x] Execute "Selection from Group" from context menu or Select menu
3. [x] Verify a marquee selection appears that encompasses all non-transparent pixels
4. [x] Verify the marquee box tightly fits the combined pixel content (not the full canvas)

#### [x] Selection from group with nested sub-groups
1. [x] Create a group with a sub-group, both containing pixel data
2. [x] Execute "Selection from Group"
3. [x] Verify the marquee includes pixels from ALL nested layers (not just direct children)

#### [x] Selection from group excludes hidden layers
1. [x] Create a group with 3 children, hide one
2. [x] Execute "Selection from Group"
3. [x] Verify hidden layers' pixels do NOT contribute to the selection bounds

#### [x] Selection from group with single child
1. [x] Create a group with only 1 child layer
2. [x] Execute "Selection from Group"
3. [x] Verify the selection matches the single child's non-transparent pixels

#### [x] Selection from group disabled when no group context
1. [x] Select a standalone top-level layer not in any group
2. [x] Verify "Selection from Group" is greyed out

### [x] Delete Group (Action via context menu)
Delete a group and all its children.

#### [x] Delete group prompts user
1. [x] Create a group with children
2. [x] Right-click the group header and choose delete, or select and press Ctrl+Shift+Delete
3. [x] Verify a dialog asks: "Yes = Delete all / No = Ungroup / Cancel"

#### [x] Delete group — Yes deletes all contents
1. [x] At the dialog, choose "Yes"
2. [x] Verify the group header and all children are removed

#### [x] Delete group — No ungroups children
1. [x] At the dialog, choose "No"
2. [x] Verify the group header is removed but children become top-level

#### [x] Delete group — Cancel aborts
1. [x] At the dialog, choose "Cancel"
2. [x] Verify nothing changes

#### [x] Delete empty group
1. [x] Create an empty group (no children)
2. [x] Delete it
3. [x] Verify no prompt — the empty group is simply removed

#### [x] Undo/Redo delete group
1. [x] Delete a group with children (choose Yes)
2. [x] Ctrl+Z to undo
3. [x] Verify the group and all children are restored
4. [x] Ctrl+Y to redo
5. [x] Verify the deletion is re-applied

---

## [x] GROUP ARRANGE / MOVE

### [x] Move Group Up/Down (Keyboard)
Move entire group blocks with keyboard shortcuts.

#### [x] Move group up (Ctrl+PgUp)
1. [x] Create 2 groups (GroupA below GroupB)
2. [x] Select GroupA's header
3. [x] Press Ctrl+PgUp
4. [x] Verify GroupA (with all children) moves above GroupB in z-order

#### [x] Move group down (Ctrl+PgDn)
1. [x] Create 2 groups (GroupA above GroupB)
2. [x] Select GroupA's header
3. [x] Press Ctrl+PgDn
4. [x] Verify GroupA (with all children) moves below GroupB in z-order

#### [x] Move group skips over adjacent groups
1. [x] Create GroupA, then Layer1, then GroupB (each with children)
2. [x] Select GroupA and move it up repeatedly
3. [x] Verify the entire block (header + children) moves as a unit, skipping over GroupB entirely

#### [x] Move child layer within group
1. [x] Create a group with 3 child layers (A, B, C from top to bottom)
2. [x] Select child B
3. [x] Press Ctrl+PgUp
4. [x] Verify B moves above A within the group

#### [x] Move child layer escapes group (upward)
1. [x] Create a group with layer A at the top
2. [x] Select layer A
3. [x] Press Ctrl+PgUp when A is already at the top of the group
4. [x] Verify A escapes the group and becomes a layer above the group header

#### [x] Move child layer escapes group (downward)
1. [x] Create a group with layer A at the bottom
2. [x] Select layer A
3. [x] Press Ctrl+PgDn when A is already at the bottom of the group
4. [x] Verify A escapes the group and becomes a layer below the group's lowest extent

#### [x] Move sub-group escapes parent group (upward)
1. [x] Create a parent group containing a sub-group
2. [x] Select the sub-group header
3. [x] Press Ctrl+PgUp until the sub-group is at the top of the parent
4. [x] Press Ctrl+PgUp once more
5. [x] Verify the sub-group (with its children) escapes the parent group

#### [x] Move sub-group escapes parent group (downward)
1. [x] Create a parent group containing a sub-group at the bottom
2. [x] Select the sub-group header
3. [x] Press Ctrl+PgDn
4. [x] Verify the sub-group (with its children) escapes the parent group downward

#### [x] Auto-delete empty parent after last child escapes
1. [x] Create a group with exactly 1 child layer
2. [x] Move the child out of the group (Ctrl+PgUp past the group header)
3. [x] Verify the now-empty group is automatically deleted

#### [x] Undo/Redo move group
1. [x] Move a group up
2. [x] Ctrl+Z to undo
3. [x] Verify the group returns to its original position
4. [x] Ctrl+Y to redo
5. [x] Verify the move is re-applied

---

## [x] GROUP TRANSFORMS (Quick Transforms)

### [x] Transforms Applied to Group
When a group is selected, transforms (flip, rotate, scale) apply to ALL descendants.

#### [x] Flip Horizontal on group (H key)
1. [x] Create a group with 2 child layers, each with asymmetric content
2. [x] Select the group header
3. [x] Press H to flip horizontally
4. [x] Verify BOTH child layers are flipped horizontally
5. [x] Verify the canvas shows all children flipped

#### [x] Flip Vertical on group (Ctrl+Shift+H)
1. [x] Create a group with 2 child layers
2. [x] Select the group header
3. [x] Press Ctrl+Shift+H
4. [x] Verify BOTH child layers are flipped vertically

#### [x] Rotate 90° CW on group (> key)
1. [x] Create a group with 2 child layers
2. [x] Select the group header
3. [x] Press > to rotate 90° clockwise
4. [x] Verify BOTH child layers are rotated 90° CW

#### [x] Rotate 90° CCW on group (< key)
1. [x] Create a group with 2 child layers
2. [x] Select the group header
3. [x] Press < to rotate 90° counter-clockwise
4. [x] Verify BOTH child layers are rotated 90° CCW

#### [x] Scale +50% on group (Ctrl+Shift+=)
1. [x] Create a group with 2 child layers
2. [x] Select the group header
3. [x] Press Ctrl+Shift+=
4. [x] Verify BOTH child layers are scaled up 50%

#### [x] Scale -50% on group (Ctrl+Shift+-)
1. [x] Create a group with 2 child layers
2. [x] Select the group header
3. [x] Press Ctrl+Shift+-
4. [x] Verify BOTH child layers are scaled down 50%

#### [x] Transform on group with nested sub-groups
1. [x] Create GroupA containing GroupB (with children), GroupA also has direct children
2. [x] Select GroupA's header
3. [x] Press H (Flip Horizontal)
4. [x] Verify ALL descendants are flipped — including GroupB's nested children
5. [x] Verify sub-group headers (1×1 sentinels) are NOT included in the transform

#### [x] Transform on group with hidden layers
1. [x] Create a group with 3 children, hide one
2. [x] Select the group header and press H
3. [x] Verify ALL children (including hidden ones) are flipped

#### [x] Undo/Redo group transform
1. [x] Select a group and flip it horizontally
2. [x] Ctrl+Z to undo
3. [x] Verify all child layers are restored to pre-flip state
4. [x] Ctrl+Y to redo
5. [x] Verify all child layers are flipped again

---

## [x] GROUP COMPOSITING / RENDERING

### [x] Pass-Through vs Isolated Blend Mode
Groups support pass-through (default) and isolated compositing.

#### [x] Pass-through group composites children directly
1. [x] Create a group with children using various blend modes (Multiply, Screen)
2. [x] Set the group to pass-through mode
3. [x] Verify children blend directly with layers below the group (as if the group doesn't exist)

#### [x] Isolated group composites children internally first
1. [x] Create a group with children using blend modes
2. [x] Set the group to isolated mode (NOT pass-through)
3. [x] Verify children are composited together first, then the result is blended as a unit onto layers below

#### [x] Group opacity applies to entire group output
1. [x] Create an isolated group with children
2. [x] Set the group's opacity to 128 (50%)
3. [x] Verify the entire group result renders at 50% opacity, not each child individually

#### [x] Group blend mode applies to group result
1. [x] Create an isolated group
2. [x] Set the group's blend mode to Multiply
3. [x] Verify the composited group result blends with Multiply onto layers below

#### [x] Nested isolated groups compose correctly
1. [x] Create GroupA (isolated) containing GroupB (isolated) with children
2. [x] Set different opacities on GroupA and GroupB
3. [x] Verify GroupB composites its children first at GroupB's opacity
4. [x] Verify GroupA then composites the GroupB result at GroupA's opacity

#### [x] Invisible group skips all children during render
1. [x] Create a group with visible children
2. [x] Hide the group (click eye icon)
3. [x] Verify none of the children render on the canvas even though their individual visible% is TRUE

---

## [ ] GROUP CONTEXT MENU

### [ ] Context Menu Items
Verify the context menu shows correct group-specific items.

#### [x] Right-click on group header shows group actions
1. [x] Right-click on a group header
2. [x] Verify these items are present and enabled: New Group, Group from Selection (disabled), Ungroup, Merge Group, Select All in Group, Selection from Group

#### [x] Right-click on child layer shows group actions
1. [x] Right-click on a child layer inside a group
2. [x] Verify "Select All in Group" is enabled
3. [x] Verify "Selection from Group" is enabled
4. [x] Verify "Ungroup" is disabled (needs group header selected)

#### [x] Right-click on standalone layer
1. [x] Right-click on a layer not in any group
2. [x] Verify "New Group" is enabled
3. [x] Verify "Ungroup" is disabled
4. [x] Verify "Merge Group" is disabled
5. [x] Verify "Select All in Group" is disabled
6. [x] Verify "Selection from Group" is disabled

#### [x] Group from Selection enabled when multi-selected
1. [x] Ctrl+Click to multi-select 3 layers
2. [x] Right-click one of them
3. [x] Verify "Group from Selection" is enabled

---

## [x] GROUP KEYBOARD SHORTCUTS

### [x] All Keyboard Bindings
Verify every keyboard shortcut related to groups works.

#### [x] Ctrl+G creates new group
1. [x] Press Ctrl+G with any layer selected
2. [x] Verify a new group is created

#### [x] Ctrl+Shift+G creates group from selection
1. [x] Multi-select 2+ layers and press Ctrl+Shift+G
2. [x] Verify the selected layers are wrapped in a group

#### [x] Ctrl+Shift+U ungroups
1. [x] Select a group header and press Ctrl+Shift+U
2. [x] Verify the group is dissolved

#### [x] Ctrl+PgUp moves group up
1. [x] Select a group header and press Ctrl+PgUp
2. [x] Verify the group block moves up in z-order

#### [x] Ctrl+PgDn moves group down
1. [x] Select a group header and press Ctrl+PgDn
2. [x] Verify the group block moves down in z-order

---

## [ ] DRAWING ON GROUPS

### [ ] Tool Behavior When Group Header Selected
Drawing tools should NOT operate on the 1×1 group sentinel.

#### [x] Brush tool on group header
1. [x] Select a group header as CURRENT_LAYER%
2. [x] Select the Brush tool and try to paint on the canvas
3. [x] Verify no painting occurs on the 1×1 sentinel image
4. [x] Verify the application does not crash

#### [x] Fill tool on group header
1. [x] Select a group header and try to use the Fill tool
2. [x] Verify the fill does not crash or corrupt anything

#### [x] Other tools on group header
1. [x] Select a group header
2. [x] Try Line, Rectangle, Ellipse, Dot, Spray tools
3. [x] Verify none of them produce unexpected results on the 1×1 sentinel

---

## [ ] GROUP SAVE / LOAD (DRW FORMAT)

### [ ] Save and Load Preserves Group Structure
DRW v24+ format saves group fields.

#### [ ] Save and reload single group
1. [ ] Create a group with 3 child layers, each with distinct content
2. [ ] Save as .draw file
3. [ ] Close and reopen the file
4. [ ] Verify the group header exists
5. [ ] Verify all 3 children are inside the group
6. [ ] Verify child content is intact

#### [ ] Save and reload nested groups
1. [ ] Create GroupA containing GroupB containing Layer1
2. [ ] Save as .draw
3. [ ] Reopen
4. [ ] Verify nesting structure: GroupA → GroupB → Layer1

#### [ ] Save and reload group properties
1. [ ] Create a group, set it to isolated mode, set opacity to 128, collapse it
2. [ ] Save as .draw
3. [ ] Reopen
4. [ ] Verify passThrough is FALSE (isolated)
5. [ ] Verify opacity is 128
6. [ ] Verify collapsed is TRUE

#### [ ] Save and reload parentGroupIdx mapping
1. [ ] Create complex nested structure: GroupA with Layer1, GroupB with Layer2 and Layer3
2. [ ] Save and reopen
3. [ ] Verify all parentGroupIdx references are correct (layers are in their correct groups)

#### [ ] Load pre-v24 DRW file (no groups)
1. [ ] Open a .draw file saved before v24 (no group data)
2. [ ] Verify all layers load as LAYER_TYPE_IMAGE with parentGroupIdx = 0
3. [ ] Verify the application does not crash

#### [ ] Group layers skip pixel data in DRW
1. [ ] Create a group (1×1 sentinel) and several image layers
2. [ ] Save as .draw
3. [ ] Verify file size is reasonable (group doesn't bloat the file)
4. [ ] Reopen and verify group header has a 1×1 image handle

---

## [ ] GROUP INTERACTIONS WITH OTHER FEATURES

### [ ] Multi-Select and Groups

#### [ ] Ctrl+Click to add group children to multi-select
1. [ ] Create a group with 3 children
2. [ ] Click one child, then Ctrl+Click another child
3. [ ] Verify multi-select works normally within the group

#### [ ] Ctrl+Click group header adds all descendants
1. [ ] Create a group, Ctrl+click the group header
2. [ ] Verify all descendants are added to multi-select (Select All in Group behavior)

#### [ ] Multi-select across groups
1. [ ] Create two groups
2. [ ] Ctrl+Click layers from both groups
3. [ ] Verify multi-select spans both groups

### [ ] Align and Distribute with Groups

#### [ ] Align selected group children
1. [ ] Multi-select children of a group
2. [ ] Use Edit → Align Left (or other align commands)
3. [ ] Verify alignment operates on the selected children

#### [ ] Align when group header is selected
1. [ ] Select a group header
2. [ ] Use an align command
3. [ ] Verify all group descendants are aligned (group expands for operation)

### [ ] Layer Operations on Group Children

#### [ ] Duplicate child layer stays in group
1. [ ] Select a child layer inside a group
2. [ ] Press Ctrl+Shift+D to duplicate
3. [ ] Verify the duplicate is also inside the same group

#### [ ] Delete child layer from group
1. [ ] Create a group with 3 children
2. [ ] Select one child and press Ctrl+Shift+Delete
3. [ ] Verify only that child is deleted
4. [ ] Verify the group still contains the other 2 children

#### [ ] Merge down within group
1. [ ] Create a group with layers A (top) and B (bottom)
2. [ ] Select A and press Ctrl+Alt+E (Merge Down)
3. [ ] Verify A merges into B within the group
4. [ ] Verify the result stays inside the group

### [ ] Rename Group

#### [ ] Double-click to rename group header
1. [ ] Double-click the group header name in the layers panel
2. [ ] Type a new name and press Enter
3. [ ] Verify the group is renamed

#### [ ] Undo/Redo rename
1. [ ] Rename a group
2. [ ] Ctrl+Z to undo
3. [ ] Verify the old name is restored
4. [ ] Ctrl+Y to redo
5. [ ] Verify the new name reappears

### [ ] Opacity and Blend Mode on Group Header

#### [ ] Drag opacity slider on group header
1. [ ] Click the opacity area on a group header row
2. [ ] Drag to change opacity
3. [ ] Verify the group's opacity changes and affects its rendered output

#### [ ] Change blend mode on group header
1. [ ] Click the blend mode cell on a group header row
2. [ ] Select a different blend mode (e.g., Multiply)
3. [ ] Verify the group's blend mode updates and the rendering changes

### [ ] Image Adjustments on Groups

#### [ ] Apply adjustment when group selected
1. [ ] Select a group header
2. [ ] Open Image → Brightness/Contrast
3. [ ] Apply an adjustment
4. [ ] Verify all group descendants are affected

### [ ] Text Layers in Groups

#### [ ] Text layer inside group renders correctly
1. [ ] Create a text layer inside a group
2. [ ] Verify the text layer renders at the correct position
3. [ ] Verify editing the text layer works normally

#### [ ] Merge group containing text layers
1. [ ] Create a group with a text layer and an image layer
2. [ ] Merge the group
3. [ ] Verify the text is rasterized and composited correctly into the merged result

---

## [ ] GROUP STATE MACHINE EDGE CASES

### [ ] Rapid Operations

#### [ ] Rapid create and ungroup
1. [ ] Quickly press Ctrl+G then Ctrl+Shift+U in rapid succession
2. [ ] Verify no stale state or crash

#### [ ] Rapid group from selection and undo
1. [ ] Multi-select layers, Ctrl+Shift+G, immediately Ctrl+Z
2. [ ] Verify clean undo without corruption

### [ ] Guard Conditions

#### [ ] Ungroup with no group selected
1. [ ] Select a non-group layer
2. [ ] Try Ctrl+Shift+U
3. [ ] Verify nothing happens (guard exits early)

#### [ ] Merge group on non-group layer
1. [ ] Select a non-group layer
2. [ ] Try executing Merge Group via command palette
3. [ ] Verify nothing happens

#### [ ] Group from selection with only group headers
1. [ ] Multi-select two group headers (no regular layers)
2. [ ] Try Ctrl+Shift+G
3. [ ] Verify it works or fails gracefully

### [ ] Re-entry / State Reset

#### [ ] Load file resets all group state
1. [ ] Create groups, modify them
2. [ ] Open a different .draw file
3. [ ] Verify all group state from the previous file is cleared
4. [ ] Verify the new file's group structure loads correctly

#### [ ] New canvas resets group state
1. [ ] Create groups with children
2. [ ] Press Ctrl+N for new canvas
3. [ ] Verify NEXT_GROUP_NUM is reset
4. [ ] Verify no orphaned group references exist

### [ ] Cancellation Paths

#### [ ] Cancel delete group dialog
1. [ ] Right-click group → Delete → Cancel
2. [ ] Verify the group remains intact with no side effects

#### [ ] Context menu dismiss
1. [ ] Right-click a group to open context menu
2. [ ] Press Escape or click outside
3. [ ] Verify the context menu closes cleanly with no state corruption

---

## [ ] GROUP UNDO/REDO COMPREHENSIVE

### [ ] Multi-Step Undo Through Group Operations

#### [ ] Undo through create → modify → ungroup
1. [ ] Create a group (Ctrl+G)
2. [ ] Paint on a child layer
3. [ ] Ungroup (Ctrl+Shift+U)
4. [ ] Ctrl+Z three times
5. [ ] Verify: ungroup reversed → paint reversed → group creation reversed

#### [ ] Undo through group from selection → transform
1. [ ] Multi-select layers, group them (Ctrl+Shift+G)
2. [ ] Flip the group (H)
3. [ ] Ctrl+Z twice
4. [ ] Verify: flip reversed → grouping reversed, layers back to original state

#### [ ] Undo merge group
1. [ ] Create a group with 3 layers, each with unique content
2. [ ] Merge the group
3. [ ] Ctrl+Z
4. [ ] Verify: the group header and all 3 children are fully restored

#### [ ] Undo drag layer into group
1. [ ] Drag a layer into a group
2. [ ] Ctrl+Z
3. [ ] Verify the layer returns to its original position outside the group

#### [ ] Multi-undo across tool switches
1. [ ] Create a group
2. [ ] Switch to Brush tool, paint on a child layer
3. [ ] Switch to Move tool, move the child
4. [ ] Ctrl+Z through all operations
5. [ ] Verify each step undoes correctly in reverse order

#### [ ] Redo after partial undo
1. [ ] Perform 5 group operations (create, rename, move, transform, ungroup)
2. [ ] Ctrl+Z 3 times
3. [ ] Ctrl+Y 2 times
4. [ ] Verify state is consistent at each step

---

## [ ] GROUP EDGE CASES

### [ ] Empty Groups

#### [ ] Empty group with no children
1. [ ] Create an empty group (Ctrl+G with no children)
2. [ ] Verify the group header exists but has no children
3. [ ] Verify the group can be collapsed/expanded (no-op visually)

#### [ ] Delete last child of a group
1. [ ] Create a group with 1 child
2. [ ] Delete the child
3. [ ] Verify the group becomes empty (or is auto-deleted depending on implementation)

### [ ] Maximum Layers

#### [ ] Groups near MAX_LAYERS (64)
1. [ ] Create many layers to approach the 64-layer limit
2. [ ] Try creating a group (needs 1 slot for the header)
3. [ ] Verify the group creation fails gracefully if no slots available

### [ ] Mixed Content

#### [ ] Group with mixed layer types
1. [ ] Create a group containing: an image layer, a text layer, and a sub-group
2. [ ] Verify all types display correctly in the panel
3. [ ] Verify all types render correctly on the canvas

#### [ ] Group operations across zoom levels
1. [ ] Set zoom to 800%
2. [ ] Create a group, add children, manipulate it
3. [ ] Set zoom to 25%
4. [ ] Verify the group panel and canvas rendering are correct at both zoom levels

#### [ ] Group operations with active selection
1. [ ] Create a marquee selection on the canvas
2. [ ] Create a group (Ctrl+G)
3. [ ] Verify the selection is preserved or properly handled
4. [ ] Perform group operations (merge, ungroup)
5. [ ] Verify the selection state remains consistent

#### [ ] Group operations with grid snap enabled
1. [ ] Enable grid snap (;)
2. [ ] Create and manipulate groups
3. [ ] Verify group operations are not affected by grid snap settings
