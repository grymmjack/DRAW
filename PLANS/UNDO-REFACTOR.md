# Unified History Refactor

## Goal

Replace the split pixel undo and workspace undo model with one chronological history system that can:

1. Undo and redo the last user action regardless of category.
2. Serialize and replay history as part of project data.
3. Emit exportable QB64PE source commands where an action is representable as intent instead of only pixels.

## Non-Goals For Phase 1

1. Remove the legacy undo modules immediately.
2. Make every existing operation exportable on day one.
3. Replace the native project format in the first pass.

## Why The Current Design Fails

The current system splits history across [TOOLS/UNDO.BM](/home/grymmjack/git/DRAW/TOOLS/UNDO.BM) and [TOOLS/WORKSPACE-UNDO.BM](/home/grymmjack/git/DRAW/TOOLS/WORKSPACE-UNDO.BM). That forces Ctrl+Z and Ctrl+Y routing logic to guess which stack should win next. The result is brittle because:

1. Two independent stacks are pretending to be one timeline.
2. Pixel history is keyed by layer slot identity.
3. Replay-side internal saves can truncate redo branches.
4. Structural replay and pixel replay can disagree about layer identity and order.

## Target Model

One history log. One cursor. One action record per committed user action.

Internally, actions may use different payload strategies, but they all sit in one chronological stream.

## Core Concepts

### 1. Action Record

Each committed action has:

1. Header metadata
2. Undo payload
3. Redo payload
4. Export metadata
5. Replay capability flags

### 2. Intent First

Where possible, history stores user intent rather than only bitmap snapshots.

Examples:

1. Line tool commit stores start, end, color, thickness, constraints.
2. Circle tool commit stores center or bounds, outline, fill, brush mode.
3. Fill stores seed point, fill color, target mode.
4. Layer reorder stores source layer identity and old/new z.

When intent cannot fully reproduce the visible result, the action stores raster fallback data too.

### 3. Stable Layer Identity

Layer slot index is not a durable identity. The unified history model needs a logical layer id that survives reorder, delete, recreate, and replay.

Each layer should eventually have:

1. Runtime slot index
2. Stable history id
3. Current z position

History actions target stable layer ids, not array slots.

### 4. Transaction Boundary

A user gesture becomes one committed history action.

Examples:

1. Brush stroke from press to release
2. Line preview to line commit
3. Marquee create or deselect
4. Layer add
5. Layer delete
6. Layer reorder drag drop
7. Merge down
8. Transform apply

## Action Taxonomy

### A. Pure Intent Actions

These should be replayable and exportable directly:

1. Dot
2. Line
3. Rect
4. Ellipse or circle
5. Polyline
6. Fill
7. Layer add
8. Layer delete
9. Layer reorder
10. Selection create or clear

### B. Hybrid Actions

These should store intent plus raster fallback:

1. Brush stroke
2. Spray
3. Text commit
4. Transform commit
5. Selection move or paste
6. Image adjustment operations

### C. Raster Only Actions

These may replay from snapshots first and gain better intent later:

1. Arbitrary imported bitmap transforms
2. Palette remap over layered content
3. Complex multi-layer edits with nontrivial blend interactions

## Unified Record Shape

Phase 1 record layout:

1. kind
2. sequence
3. stable primary layer id
4. stable secondary layer id
5. tool id
6. flags
7. export kind
8. geometry fields
9. color fields
10. payload offsets or snapshot references
11. human label

The payload container can evolve later, but the top-level history stream must stay chronological.

## Replay Contract

Each action kind must support:

1. Apply
2. Unapply
3. Serialize
4. Deserialize
5. Export attempt

If an action cannot export to DSL, it should report that explicitly and either:

1. emit raster fallback code, or
2. mark itself non-exportable while remaining undoable and replayable.

## DSL Export Strategy

### Export Classes

1. Direct DSL
   Examples: PSET, LINE, CIRCLE, PAINT, DRAW
2. Expanded DSL
   Examples: brush stroke emitted as many PSET or LINE segments
3. Raster fallback
   Examples: emitted DATA block or image reconstruction helper
4. Non-exportable
   Must be reported clearly in export UI

### Export Principle

Export should operate on history, not flattened pixels. Flattened pixels are only a fallback path.

## Migration Plan

### Phase 1: Foundation

1. Add a new HISTORY module and compile it into the app.
2. Define action kinds, export classes, and record headers.
3. Add stable layer ids to layer state.
4. Document producer sites.

### Phase 2: Route Low-Risk Actions

First producers to move:

1. Layer add
2. Layer delete
3. Layer reorder
4. Line
5. Rect
6. Ellipse
7. Fill
8. Selection clear or create

These are discrete commit actions with well-defined boundaries.

### Phase 3: Unified Ctrl+Z/Y

1. Add HISTORY_undo and HISTORY_redo.
2. Route keyboard and command undo calls to the unified history system.
3. Keep legacy undo modules only as fallback implementations behind history actions during migration.

### Phase 4: Persist History

1. Add history serialization to project save.
2. Add replay loading path.
3. Version the serialized history chunk independently.

### Phase 5: Export

1. Implement FILE_BAS export from history.
2. Add per-action exporter functions.
3. Surface unsupported actions cleanly.

## Producer Inventory To Migrate

Primary mutation entry points currently live in:

1. [INPUT/MOUSE.BM](/home/grymmjack/git/DRAW/INPUT/MOUSE.BM)
2. [GUI/COMMAND.BM](/home/grymmjack/git/DRAW/GUI/COMMAND.BM)
3. [GUI/LAYERS.BM](/home/grymmjack/git/DRAW/GUI/LAYERS.BM)
4. [TOOLS/TRANSFORM.BM](/home/grymmjack/git/DRAW/TOOLS/TRANSFORM.BM)
5. [TOOLS/BRUSH.BM](/home/grymmjack/git/DRAW/TOOLS/BRUSH.BM)
6. [TOOLS/MOVE.BM](/home/grymmjack/git/DRAW/TOOLS/MOVE.BM)
7. [GUI/IMAGE-ADJ.BM](/home/grymmjack/git/DRAW/GUI/IMAGE-ADJ.BM)

## First Success Criteria

Phase 1 is successful when:

1. New history module compiles in-tree.
2. Design document exists in-repo.
3. Stable layer id field exists or is planned with explicit slot migration notes.
4. First migrated action can be undone and redone without touching either legacy routing path directly.

## Recommended First Implementation Slice

Start with layer add, delete, and reorder.

Reasons:

1. They are the main source of split-stack brittleness.
2. They need stable layer identity anyway.
3. They directly prove the value of one chronological stream.
4. They are also relevant to replay and export metadata.

After that, move line, rect, ellipse, and fill.