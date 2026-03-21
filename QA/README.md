# QA — Automated xdotool test harness for DRAW

Automated smoke/regression tests using `xdotool` + `scrot`.

## Structure

```
QA/
├── draw-qa.sh          Main harness — run this
├── tests/              Test files (one feature per file)
│   ├── smoke.sh
│   ├── keyboard-shortcuts.sh
│   ├── brush-draw.sh
│   └── new-layer.sh
├── results/            Run logs (gitignored)
└── screenshots/        Screenshots captured during runs (gitignored)
```

## Usage

```bash
cd QA
chmod +x draw-qa.sh

# Run all tests
./draw-qa.sh

# Run a single test
./draw-qa.sh tests/smoke.sh

# List available tests
./draw-qa.sh --list
```

## Writing a new test

Create `QA/tests/my-feature.sh`. All helper functions are available:

| Helper | Description |
|--------|-------------|
| `click X Y [btn]` | Click at window-relative coords |
| `right_click X Y` | Right-click |
| `double_click X Y` | Double-click |
| `drag X1 Y1 X2 Y2 [btn]` | Click-drag |
| `scroll_up X Y` | Scroll wheel up |
| `scroll_down X Y` | Scroll wheel down |
| `type_text "str"` | Type printable characters |
| `key combo...` | Send key(s) e.g. `key ctrl+z` |
| `wait_for N "msg"` | Sleep N seconds |
| `screenshot "label"` | Capture window screenshot |
| `assert_no_crash` | Verify process is alive |
| `assert_window_exists` | Verify window is still open |
| `assert_window_title "substr"` | Check title bar text |
| `info / pass / fail / warn / skip` | Log messages |

## Notes

- DRAW is launched once per run, shared across all test files.
- Each test file is sourced in order — keep tests independent.
- Canvas coords depend on your `DISPLAY_SCALE` / `TOOLBAR_SCALE` settings.
  Default tests assume TB=2, canvas roughly centred at (300, 250).
- Results and screenshots are gitignored — add to `.gitignore` if needed.
