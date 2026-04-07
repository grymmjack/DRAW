# [ ] POLYGON TESTING

## [ ] TOOL ACTIVATION

### [ ] Activating the Polygon Tool
#### [ ] Activate outlined via P key
1. [ ] Press `P`
2. [ ] Verify toolbar highlights Polygon tool

#### [ ] Activate filled via Shift+P
1. [ ] Press `Shift+P`
2. [ ] Verify filled polygon mode

---

## [ ] DRAWING POLYGONS

### [ ] Multi-Segment Polyline
#### [ ] Draw a 3-segment polyline
1. [ ] Click point 1
2. [ ] Click point 2 — verify line from 1→2 with rubber-band for next segment
3. [ ] Click point 3 — verify line from 2→3
4. [ ] Double-click or press `Enter` to commit
5. [ ] Verify polyline committed

#### [ ] Draw a closed polygon
1. [ ] Click several points to form a polygon shape
2. [ ] Click near the first point (or double-click)
3. [ ] Verify polygon closes and fills if in filled mode

#### [ ] Cancel polygon (Escape)
1. [ ] Start placing polygon points
2. [ ] Press `Escape`
3. [ ] Verify all preview lines disappear, nothing committed

---

## [ ] UNDO / REDO

### [ ] Polygon Undo
#### [ ] Undo polygon
1. [ ] Draw and commit a polygon
2. [ ] Press `Ctrl+Z`
3. [ ] Verify polygon removed
