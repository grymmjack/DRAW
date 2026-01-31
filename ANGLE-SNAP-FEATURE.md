# Angle Snapping Feature

## Overview
Added angle snapping for precise line and polygon drawing. When holding **Ctrl+Shift** while using line tools, endpoints snap to the nearest configured angle increment (default: 45°).

## Usage

### Basic Usage
1. Select the LINE tool, POLYGON tool, or POLYGON_FILLED tool
2. Press and hold **Ctrl+Shift** together
3. Click and drag (LINE) or click points (POLYGON)
4. The endpoint will automatically snap to the nearest angle

### Angle Increments
- **45°** (default) - 8 directions: 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
- **30°** - 12 directions
- **15°** - 24 directions  
- **90°** - 4 directions (horizontal/vertical only)

## Configuration

Edit `DRAW.cfg` to change the snap angle:

```
# Angle snap increment in degrees when holding Ctrl+Shift while drawing lines (default: 45)
# Common values: 15 (24 angles), 30 (12 angles), 45 (8 angles), 90 (4 angles)
ANGLE_SNAP_DEGREES=45
```

Valid range: 1-90 degrees

## Tools Affected
- **LINE tool** - Angle snapping during drag
- **POLYGON tool** - Angle snapping for each segment
- **POLYGON_FILLED tool** - Angle snapping for each segment

## Technical Details

### Implementation
- Added `SNAP_to_angle()` SUB in [_COMMON.BM](_COMMON.BM)
- Uses ATN2 for accurate angle calculation
- Preserves line distance while snapping angle
- Integrated into mouse input handler in [MOUSE.BM](INPUT/MOUSE.BM)

### Algorithm
1. Calculate angle from start point to current mouse position using `_ATAN2(dy, dx)`
2. Round to nearest multiple of snap angle: `INT(angle / snap_degrees + 0.5) * snap_degrees`
3. Calculate new endpoint at snapped angle with same distance from start point
4. Use COS/SIN to convert back to X,Y coordinates

## Examples

### 45° Snap (Default)
Drawing from center outward, lines snap to:
- 0° (East/Right)
- 45° (Northeast)
- 90° (North/Up)
- 135° (Northwest)
- 180° (West/Left)
- 225° (Southwest)
- 270° (South/Down)
- 315° (Southeast)

### 30° Snap
Provides 12 evenly-spaced directions around the circle.

### 15° Snap  
Provides 24 fine-grained directional options for more precision.

### 90° Snap
Constrains to perfectly horizontal or vertical lines only.

## Version
Added in: **v0.6.2** (in development)
