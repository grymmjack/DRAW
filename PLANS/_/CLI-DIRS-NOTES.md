# CLI path queries + colored help: review notes (branch `cli-dirs`)

`cli-dirs` was cut from `palette-cycling`, so its `--help` lists the cycling flags. **Merge `palette-cycling` first**, then this branch; it then contains only the CLI commits.

## Try it

```bash
make
./DRAW.run --cfg                      # the config file in use
vim "$(./DRAW.run --cfg)"
./DRAW.run --dirs                     # every directory, labeled
cd "$(./DRAW.run --dir-theme-sounds)"
./DRAW.run --help                     # colored; | cat shows the plain version
```

Directory names: `cfg data cache crash-logs templates brushes patterns gradients palettes fonts theme theme-images theme-sounds theme-music theme-cursors theme-fonts`.

## Behavior

- **Output:** every query prints an **absolute** path with no trailing slash and exits 0. An unknown `--dir-*` name exits 2 and lists the valid names.
- **No window:** queries run at include time, before any window opens, so they work over SSH or without a display. They read `THEME`, `TEMPLATE_DIR` and the `.dset` paths from the active config file, because the full config load hasn't run yet.
- **Instances:** query runs skip the multi-instance bootstrap. Without that, each run took an instance slot and never released it, so the next query reported `DRAW.instance-2.cfg`.
- **`--dir-crash-logs`:** creates the crash-log folder if it doesn't exist yet, the same way DRAW does on a crash.
- **Colors:** on in a terminal, off when piped (`isatty` via `native/cli_tty.h`), with `NO_COLOR` set, with `--no-color`, or on `TERM=dumb`. `FORCE_COLOR=1` forces them on. On Windows, ANSI escapes and UTF-8 output are switched on for the console.
- **Logo:** if `ASSETS/DRAW.ans` exists, it is printed above the help when colors are on. It's converted from CP437 to UTF-8, and the SAUCE record is dropped. I tested with a throwaway logo and didn't commit one — that's yours to draw. DRAW's own ANSI export would work.

## Tests

- `DEV/tools/test-cli-dirs.sh` (34 checks, no display needed): ALL PASS
- `QA/cli-smoke.sh`: ALL PASS
