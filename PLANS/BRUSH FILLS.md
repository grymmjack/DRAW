

Let me research the relevant shape tool rendering and custom brush systems to assess feasibility. 

Research filled shape + custom brush

Searched for files matching `**/TOOLS/**/*FILLED*.B*`, no matches

Searched for files matching `**/TOOLS/CUSTOM-BRUSH.B*`, 2 matches

Searched for files matching `**/TOOLS/RECT.B*`, 2 matches

Searched for files matching `**/TOOLS/LINE.B*`, 2 matches

Searched for files matching `**/TOOLS/POLY*.B*`, 4 matches

Searched for files matching `**/TOOLS/ELLIPSE.B*`, 2 matches

Searched for regex `RECT_FILLED|ELLIPSE_FILLED|POLYGON_FILLED` (`**/TOOLS/**`), no results

Searched for regex `TOOL_RECT|TOOL_ELLIPSE|TOOL_POLY` (`**/*.BI`), 12 results

Read [](file:///home/grymmjack/git/DRAW/TOOLS)

Read [](file:///home/grymmjack/git/DRAW/TOOLS/RECT.BM)

Read [](file:///home/grymmjack/git/DRAW/TOOLS/ELLIPSE.BM#1-1), lines 1 to 200

Read [](file:///home/grymmjack/git/DRAW/TOOLS/POLY-FILL.BM)

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BM#1-1), lines 1 to 200

Read [](file:///home/grymmjack/git/DRAW/TOOLS/LINE.BM)

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BM#100-100), lines 100 to 500

Searched for regex `PAINT_stamp_brush|PAINT_pset_with_symmetry` (`**/_COMMON.BM`), no results

Searched for regex `CUSTOM_BRUSH_render|PAINT.*CUSTOM.*BRUSH|_PUTIMAGE.*CUSTOM` (`**/TOOLS/**`), 11 results

Read [](file:///home/grymmjack/git/DRAW/_COMMON.BM)

Searched for regex `SUB|FUNCTION.*PAINT_stamp|SUB|FUNCTION.*PAINT.*symmetry` (`**/_COMMON.BM`), 20 results

Searched for regex `PAINT_stamp_brush` (`**/*.BM`), 20 results

Read [](file:///home/grymmjack/git/DRAW/TOOLS/BRUSH.BM#340-340), lines 340 to 600

Read [](file:///home/grymmjack/git/DRAW/TOOLS/RECT.BI)

Searched for regex `SUB PAINT_pset_with_symmetry|SUB PAINT_draw_filled` (`**/TOOLS/BRUSH.BM`), 3 results

Searched for regex `RECT_FILLED|RECT_draw|LINE_draw` (`**/INPUT/MOUSE.BM`), 27 results

Read [](file:///home/grymmjack/git/DRAW/TOOLS/BRUSH.BM#45-45), lines 45 to 150

Read [](file:///home/grymmjack/git/DRAW/TOOLS/ELLIPSE.BM#100-100), lines 100 to 229

Searched for regex `ELLIPSE_fill|ELLIPSE_draw|ELLIPSE_FILLED` (`**/INPUT/MOUSE.BM`), 15 results

Read [](file:///home/grymmjack/git/DRAW/TOOLS/ELLIPSE.BI)

Searched for regex `SCALE|scale` (`**/TOOLS/CUSTOM-BRUSH.BM`), 20 results

Searched for regex `_MAPTRIANGLE|_PUTIMAGE` (`**/*.B*`), 20 results

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BI#1-1), lines 1 to 50

Searched for regex `scale_up|scale_down|scale_reset` (`**/TOOLS/CUSTOM-BRUSH.BM`), 3 results

Read memory repo

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BM#584-584), lines 584 to 650

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#200-200), lines 200 to 2195

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#200-200), lines 200 to 2330

Created memory file [](file:///home/grymmjack/.config/Code/User/workspaceStorage/a5bf8cf629be65aa703c378128d9369f/GitHub.copilot-chat/memory-tool/memories/ZjI3NmE5ZmEtYWU3Yi00NThhLThkZmQtODM2ZmRjMzNhNDFm/rendering-research.md)

Analyzing your answers...

Good. Let me now do a bit more targeted research on the specific rendering paths I'd need to hook into: 

Research fill dispatch paths

Searched for regex `RECT_FILLED|ELLIPSE_FILLED|POLYGON_FILLED` (`**/INPUT/MOUSE.BM`), 20 results

Searched for text `RECT_draw_clipped_filled` (`**/TOOLS/RECT.BM`), 1 result

Searched for text `CUSTOM_BRUSH_stamp` (`**/TOOLS/CUSTOM-BRUSH.BM`), 1 result

Searched for text `CUSTOM_BRUSH_stamp_line` (`**/TOOLS/CUSTOM-BRUSH.BM`), no results

Searched for regex `TYPE.*CUSTOM_BRUSH|SCALE` (`**/TOOLS/CUSTOM-BRUSH.BI`), 7 results

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#2550-2550), lines 2550 to 2580

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#2690-2690), lines 2690 to 2735

Read [](file:///home/grymmjack/git/DRAW/TOOLS/RECT.BM#39-39), lines 39 to 66

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BI#18-18), lines 18 to 50

Read [](file:///home/grymmjack/git/DRAW/TOOLS/CUSTOM-BRUSH.BM#284-284), lines 284 to 350

Searched for regex `SUB|FUNCTION` (`**/TOOLS/CUSTOM-BRUSH.BM`), 30 results

Searched for text `MOUSE_dispatch_tool_release` (`**/INPUT/MOUSE.BM`), 4 results

Searched for regex `stamp.*line|distribute.*stamp` (`**/TOOLS/*.BM`), 7 results

Searched for regex `SUB|FUNCTION` (`**/TOOLS/BRUSH.BM`), 30 results

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#3079-3079), lines 3079 to 3170

Read [](file:///home/grymmjack/git/DRAW/TOOLS/BRUSH.BM#605-605), lines 605 to 652

Searched for text `MOUSE_release_rect` (`**/INPUT/MOUSE.BM`), 3 results

Searched for text `MOUSE_release_ellip` (`**/INPUT/MOUSE.BM`), 3 results

Searched for regex `HISTORY_record_poly|poly.*HISTORY` (`**/INPUT/MOUSE.BM`), 15 results

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#2160-2160), lines 2160 to 2230

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#2288-2288), lines 2288 to 2360

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#2750-2750), lines 2750 to 2780

Now I have a comprehensive understanding of the system. Let me create the plan. 

Created memory file [](file:///home/grymmjack/.config/Code/User/workspaceStorage/a5bf8cf629be65aa703c378128d9369f/GitHub.copilot-chat/memory-tool/memories/ZjI3NmE5ZmEtYWU3Yi00NThhLThkZmQtODM2ZmRjMzNhNDFm/plan.md)

Compacted conversation## Plan: Custom Brush Fill for Filled Shapes

Enable filled shapes (RECT_FILLED, ELLIPSE_FILLED, POLYGON_FILLED) to use the active custom brush for filling. Default: tile/repeat the brush. SHIFT+CTRL: stretch brush to fit the shape's bounding box with aspect ratio preservation, using the shape as a clipping mask for non-rectangular shapes.

**Feasibility: YES** — all required primitives exist. `_PUTIMAGE` handles stretching, `CUSTOM_BRUSH_stamp` handles tiling with all modes (flip/recolor/eraser/symmetry), shape tools have scanline fill loops that serve as reference, and per-pixel masking is proven via `SELECTION_is_point_inside%`.

---

### Phase 1 — Tiled Fill (Medium effort, ~200-300 new lines)

1. **Add `CUSTOM_BRUSH_fill_rect` SUB** in CUSTOM-BRUSH.BM — tile `CUSTOM_BRUSH_stamp` across the rect bounding box in a grid with spacing = brush WIDTH/HEIGHT. Clipping to selection is already baked into the stamp→render→PSET pipeline.

2. **Add `CUSTOM_BRUSH_fill_ellipse` SUB** *(parallel with 1)* — same tile grid but only stamp where tile center satisfies `((x-cx)/rx)^2 + ((y-cy)/ry)^2 <= 1`. Partial-overlap bleed at edges is acceptable (matches how unfilled shapes stamp along their outlines).

3. **Add `CUSTOM_BRUSH_fill_polygon` SUB** *(parallel with 1-2)* — tile grid over polygon bounding box, point-in-polygon test per tile center (ray casting, reuse `POLY_FILL_scanline`'s edge intersection approach).

4. **Hook RECT_FILLED release** in MOUSE.BM (~L2192) — before the existing `IF RECT_TOOL.FILLED` block: `IF CUSTOM_BRUSH_is_active% THEN CUSTOM_BRUSH_fill_rect` *(depends on 1)*

5. **Hook ELLIPSE_FILLED release** (~L2318) — same pattern *(depends on 2)*

6. **Hook POLYGON_FILLED path** (~L2754) — the polygon fill already has a `NOT CUSTOM_BRUSH_is_active%` guard; extend it to call the new fill SUB instead of skipping *(depends on 3)*

7. **Re-enable custom brush cursor** in POINTER.BM (~L1108) — add `TOOL_RECT_FILLED, TOOL_ELLIPSE_FILLED, TOOL_POLYGON_FILLED` to the SELECT CASE *(parallel with 1-6)*

8. **Add DECLAREs** in CUSTOM-BRUSH.BI *(parallel with 1-3)*

### Phase 2 — Stretched Fill with SHIFT+CTRL (Higher effort, ~300-400 additional lines)

9. **Detect SHIFT+CTRL modifier** in each release handler — `MODIFIERS.shift% AND MODIFIERS.ctrl%` at commit time → stretched mode instead of tiled *(depends on Phase 1)*

10. **Add `CUSTOM_BRUSH_fill_rect_stretched`** — `_PUTIMAGE` stretch with aspect-ratio-preserving fit; handle flip flags by swapping source coords; handle recolor via temp image *(depends on 9)*

11. **Add `CUSTOM_BRUSH_fill_ellipse_stretched`** *(parallel with 10)* — stretch brush to temp image at bounding box size, apply per-pixel ellipse mask (`_RGBA32(0,0,0,0)` outside), blit with `_BLEND`

12. **Add `CUSTOM_BRUSH_fill_polygon_stretched`** *(parallel with 10-11)* — same as 11 but per-pixel point-in-polygon mask

13. **Wire SHIFT+CTRL dispatch** — if held → stretched variant; else → tiled variant *(depends on 10-12)*

---

### Relevant Files

- CUSTOM-BRUSH.BI — add DECLAREs for new SUBs
- CUSTOM-BRUSH.BM — implement all fill SUBs (tiled + stretched)
- MOUSE.BM — hook release handlers at ~L2192, ~L2318, ~L2754
- POINTER.BM — re-enable cursor for filled tools
- RECT.BM — reference: `RECT_draw_clipped_filled` pattern
- ELLIPSE.BM — reference: `ELLIPSE_fill_scanline` pattern
- POLY-FILL.BM — reference: `POLY_FILL_scanline` pattern
- BRUSH.BM — reference: `CUSTOM_BRUSH_stamp_line` spacing logic

### Verification

1. Tiled fill: 16x16 custom brush → RECT_FILLED → verify brush tiles seamlessly
2. Ellipse mask: same brush → ELLIPSE_FILLED → tiles only inside ellipse
3. Polygon mask: 5-point star → POLYGON_FILLED → tiles only inside polygon
4. Stretched: SHIFT+CTRL + RECT_FILLED → brush stretches to rect, aspect ratio preserved
5. Stretched + mask: SHIFT+CTRL + ELLIPSE_FILLED → stretched brush clipped to ellipse
6. Symmetry: fill with H mirror enabled → mirrored fills appear
7. Selection: fill with active selection → clips to selection
8. Recolor + eraser modes both work through fill
9. Undo: Ctrl+Z cleanly reverses each fill type

### Decisions

- Phase 1 is standalone-useful and can ship independently of Phase 2
- Partial stamp bleed at tiled shape edges is acceptable (matches existing brush behavior)
- Stretched mode uses aspect-ratio-preserving fit with centering
- No new tool constants needed — extends existing filled-tool behavior when custom brush is active
- Grid snap: tiled fill aligns tile origins to grid (matching `stamp_line` behavior)

### Further Considerations

1. **Opacity**: Stamps go through `PAINT_pset_with_symmetry` which handles `PAINT_OPACITY%` — no extra work for tiled mode. Stretched mode needs explicit opacity via temp-image compositing.
2. **Performance**: Large shapes + small brushes could stamp hundreds of times. Early bounding-box rejection would help, but unlikely to be a practical issue at typical pixel-art scales.
3. **Phase order**: Recommend implementing Phase 1 first, testing it, then adding Phase 2. They're cleanly separable.