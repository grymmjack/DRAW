# DRAW Mind Map Generator

Generates `.xmind` mind map files from a hierarchical JavaScript data structure using the [xmind-sdk-js](https://github.com/nickshere/xmind-sdk-js) npm package.

## Prerequisites

- **Node.js** (v18+)
- npm dependencies (installed in `DEV/`)

```bash
cd DEV
npm install
```

This installs the `xmind` package (v2.2.33) which provides `Workbook`, `Topic`, `Zipper`, and the underlying `xmind-model` library.

## Usage

```bash
cd DEV
node generate-draw-mindmap.js [output-dir]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `output-dir` | `../PLANS/diagrams/` | Directory where the `.xmind` file is written |

Output filename is always `DRAW-feature-mindmap.xmind`.

### Example

```bash
# Default output to PLANS/diagrams/
node generate-draw-mindmap.js

# Custom output directory
node generate-draw-mindmap.js /tmp
```

Expected output:
```
Total nodes: 658, Sheets: 20
SUCCESS: /home/grymmjack/git/DRAW/PLANS/diagrams/DRAW-feature-mindmap.xmind
```

## What It Generates

A **multi-sheet** XMind mind map with:

- **1 Overview sheet** — central topic "DRAW — Pixel Art Editor v0.31.0" with 19 child nodes
- **19 sub-sheets** — one per major feature category, each containing the full subtree for that category
- **Cross-sheet hyperlinks** — click any overview node to jump to its detail sheet
- **Back-links** — click any sub-sheet's root topic to return to the Overview
- **Snowbrush theme** applied to all sheets

### The 19 Feature Categories

| # | Category | Nodes |
|---|----------|-------|
| 1 | Drawing Tools | 19 tool groups with sub-features |
| 2 | Selection & Clipboard | Marquee, wand, clipboard ops |
| 3 | Layer System | 64 layers, blend modes, groups |
| 4 | Color & Palette | Strip, ops, picker, workflows |
| 5 | Text System | Fonts, formatting, char map, char mode |
| 6 | Canvas & View | Zoom, pan, preview window |
| 7 | Grid System | 4 geometries, smart guides |
| 8 | Brush System | Size, shape, paint modes, dithering |
| 9 | Transform Operations | Flip, rotate, scale, transform overlay |
| 10 | Image Adjustments | B/C, H/S, levels, blur, posterize |
| 11 | File I/O | Open, save, export, DRW format |
| 12 | User Interface | Menus, toolbar, panels, settings |
| 13 | Audio System | SFX, background music |
| 14 | Theming System | Colors, icons, sounds |
| 15 | Configuration | Config files, auto-detection |
| 16 | Undo / Redo | Unified history system |
| 17 | Input System | Mouse, keyboard, joystick |
| 18 | Platform Support | Windows, Linux, macOS |
| 19 | Rendering Pipeline | Scene cache, compositing |

## Modifying the Feature Tree

Edit the `featureTree` array in `generate-draw-mindmap.js`. Each node is an object:

```javascript
{
    title: 'Node Title',        // Required — displayed text
    id: 'optional-id',          // Optional — not used by SDK
    children: [                 // Optional — omit for leaf nodes
        { title: 'Child node' },
        {
            title: 'Parent with children',
            children: [
                { title: 'Grandchild' }
            ]
        }
    ]
}
```

After editing, re-run `node generate-draw-mindmap.js` to regenerate.

## Changing the Theme

Three built-in themes are available: `robust`, `snowbrush`, `business`.

In the script, find the `applyTheme` function and change the theme name:

```javascript
const themeInstance = new Theme({themeName: 'snowbrush'});  // change here
```

## Verifying the Output

Inspect the generated `.xmind` file (which is a ZIP):

```bash
cd /tmp && mkdir xmind-check && cd xmind-check
unzip -q /path/to/DRAW-feature-mindmap.xmind
python3 -c "
import json
with open('content.json') as f:
    data = json.load(f)
print(f'Sheets: {len(data)}')
for i, sheet in enumerate(data):
    root = sheet['rootTopic']
    children = root.get('children', {}).get('attached', [])
    print(f'  [{i}] {sheet[\"title\"]} — {len(children)} children')
"
```

## SDK Notes

The `xmind` npm package has some quirks when creating multi-sheet workbooks:

- **Use `createSheets()`** (batch) instead of `createSheet()` (single) — the latter overwrites the internal workbook on each call.
- **Theme application** — `wb.theme()` doesn't work with `createSheets()`. Apply themes directly: `sheet.changeTheme(new Theme({themeName}).data)`.
- **Cross-sheet links** must target a **topic ID** (`sheet.getRootTopic().getId()`), not a sheet ID. Format: `xmind:#<topicId>`.
- **UUID capture** — after `topic.add({title})`, call `topic.cid()` to get the auto-generated UUID of the last-added node.
- **Raw model access** — use `sheet.findComponentById(uuid)` to get the `xmind-model` topic object, which exposes `addHref()`, `addLabel()`, `addMarker()`, `changeCustomWidth()`, etc.
