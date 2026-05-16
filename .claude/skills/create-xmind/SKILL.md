---
name: create-xmind
description: "Generate a multi-sheet .xmind mind map from a hierarchical feature tree using the xmind-sdk-js toolchain in DEV/. Supports cross-sheet hyperlinks, back-links, and themes."
---

# Create XMind Mind Map

Generate a `.xmind` mind map file from a hierarchical data structure. Uses the `xmind` npm SDK (v2.2.33) installed in `DEV/` with workarounds for multi-sheet and theme limitations in the high-level API.

---

## Step 0 — Clarify Requirements

Ask the user:

1. **What is the subject?** (e.g. "all DRAW features", "layer system", "a custom topic")
2. **Single sheet or multi-sheet?** Multi-sheet creates an overview with clickable links to sub-sheets.
3. **Theme?** Options: `snowbrush` (default), `robust`, `business`
4. **Output location?** Default: `PLANS/diagrams/<name>.xmind`

---

## Step 1 — Define the Feature Tree

Build a JavaScript array of objects representing the hierarchy:

```javascript
const featureTree = [
    {
        title: 'Category Name',   // Top-level branch (becomes its own sheet in multi-sheet mode)
        id: 'short-id',           // Optional identifier
        children: [
            {
                title: 'Sub-item',
                children: [
                    { title: 'Leaf node' },
                ]
            },
        ]
    },
    // ... more branches
];
```

Rules:
- Each object must have a `title` string
- `children` is optional (omit for leaf nodes)
- Nesting depth is unlimited
- Emoji prefixes in titles are supported and render correctly in XMind

---

## Step 2 — Write the Generator Script

Create or update a Node.js script in `DEV/`. Use this pattern:

### Dependencies

```javascript
const { Workbook, Topic, Zipper } = require('xmind');
const { Theme } = require(require.resolve('xmind/dist/core/theme'));
```

The `xmind` npm package is already installed in `DEV/node_modules/`. If missing, run:

```bash
cd DEV && npm install xmind
```

### Single-Sheet Mode

```javascript
const wb = new Workbook();
const sheet = wb.createSheet('Sheet Title', 'Central Topic Title');
const t = new Topic({ sheet });

function addChildren(parentUUID, children) {
    for (const child of children) {
        if (parentUUID) t.on(parentUUID); else t.on();
        t.add({ title: child.title });
        const uuid = t.cid();
        if (child.children) addChildren(uuid, child.children);
    }
}

addChildren(null, featureTree);
wb.theme('Sheet Title', 'snowbrush');

const zipper = new Zipper({ path: OUTPUT_DIR, workbook: wb, filename: FILENAME });
zipper.save().then(status => { /* ... */ });
```

### Multi-Sheet Mode (with cross-sheet hyperlinks)

**CRITICAL**: Use `createSheets()` (batch) instead of `createSheet()` (single). The high-level `createSheet()` overwrites `this.workbook` each call — only the last sheet survives.

```javascript
// 1. Define all sheets upfront
const sheetDefs = [
    { s: 'Overview', t: 'Overview Central Topic' },
];
for (const branch of featureTree) {
    sheetDefs.push({ s: branch.title, t: branch.title });
}

const wb = new Workbook();
const created = wb.createSheets(sheetDefs);

// 2. Map titles to sheet IDs
const sheetIds = {};
for (const c of created) sheetIds[c.title] = c.id;

// 3. Collect root topic IDs (links must target topics, NOT sheets)
const rootTopicIds = {};
for (const branch of featureTree) {
    const sheet = wb.getSheet(sheetIds[branch.title]);
    rootTopicIds[branch.title] = sheet.getRootTopic().getId();
}

// 4. Build overview with hyperlinks to sub-sheet root topics
const overviewSheet = wb.getSheet(sheetIds['Overview']);
const overviewTopic = new Topic({ sheet: overviewSheet });

for (const branch of featureTree) {
    overviewTopic.on().add({ title: branch.title });
    const childUUID = overviewTopic.cid();
    const comp = overviewSheet.findComponentById(childUUID);
    if (comp && comp.addHref) {
        comp.addHref('xmind:#' + rootTopicIds[branch.title]);
    }
}

// 5. Build sub-sheets with back-links and full subtrees
const overviewRootTopicId = overviewSheet.getRootTopic().getId();

for (const branch of featureTree) {
    const sheet = wb.getSheet(sheetIds[branch.title]);
    const topic = new Topic({ sheet });

    // Back-link to overview
    sheet.getRootTopic().addHref('xmind:#' + overviewRootTopicId);

    // Recursive children
    if (branch.children) addChildren(topic, null, branch.children);
}
```

### Applying Themes to Multi-Sheet Workbooks

**CRITICAL**: `wb.theme(title, name)` only works with `createSheet()` (it uses `this.sheet` which isn't set by `createSheets()`). For multi-sheet, apply themes directly via the xmind-model API:

```javascript
const { Theme } = require(require.resolve('xmind/dist/core/theme'));

function applyTheme(sheetId, themeName) {
    const sheet = wb.getSheet(sheetId);
    if (sheet && sheet.changeTheme) {
        const themeInstance = new Theme({ themeName });
        sheet.changeTheme(themeInstance.data);
    }
}

// Apply to every sheet
for (const title in sheetIds) {
    applyTheme(sheetIds[title], 'snowbrush');
}
```

Available themes: `robust`, `snowbrush`, `business`

---

## Step 3 — Run the Generator

```bash
cd /home/grymmjack/git/DRAW/DEV && node generate-draw-mindmap.js
```

Expected output:
```
Total nodes: 658, Sheets: 20
SUCCESS: /home/grymmjack/git/DRAW/PLANS/diagrams/DRAW-feature-mindmap.xmind
```

---

## Step 4 — Verify

Optionally verify the internal structure:

```bash
cd /tmp && rm -rf xmind-verify && mkdir xmind-verify && cd xmind-verify && \
unzip -q /path/to/output.xmind && \
python3 -c "
import json
with open('content.json') as f:
    data = json.load(f)
print(f'Sheets: {len(data)}')
for i, sheet in enumerate(data):
    root = sheet['rootTopic']
    children = root.get('children', {}).get('attached', [])
    href = root.get('href', '')
    print(f'  [{i}] {sheet[\"title\"]} — {len(children)} children, rootHref={href or \"none\"}')
"
```

---

## Known SDK Gotchas

| Issue | Workaround |
|-------|-----------|
| `createSheet()` overwrites previous sheets | Use `createSheets([...])` for multiple sheets |
| `wb.theme()` crashes with `createSheets()` | Use `sheet.changeTheme(new Theme({themeName}).data)` directly |
| `topic.on(customId)` doesn't accept custom IDs | Use `topic.cid()` after `topic.add()` to capture the auto-generated UUID |
| Cross-sheet links must target topic IDs, not sheet IDs | Use `sheet.getRootTopic().getId()` for the href target |
| `findComponentById()` is on the sheet object, not workbook | Call `sheet.findComponentById(uuid)` to get the raw xmind-model topic for `addHref()` |
| Theme `data` includes a random UUID each call | Safe to call per-sheet; each gets its own theme instance |

---

## Reference

- **Existing generator**: `DEV/generate-draw-mindmap.js` — 20-sheet DRAW feature mind map
- **npm package**: `xmind` v2.2.33 (installed in `DEV/node_modules/`)
- **Underlying model**: `xmind-model` (accessed via `require('xmind-model')` or `sheet.getRootTopic()`)
- **Output format**: .xmind (ZIP containing `content.json`, `content.xml`, `manifest.json`, `metadata.json`)
