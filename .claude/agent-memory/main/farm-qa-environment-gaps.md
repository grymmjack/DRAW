---
name: farm-qa-environment-gaps
description: Why full QA suites failed by the hundred on the farm (2026-11-15) - stale-window relaunch bug, missing ImageMagick 7 / Python, Linux-only keymap seeding, bare-version farm builds, a hanging farm-check - and what fixed each
metadata:
  type: project
---

First full 530-file suite on all four machines at once (DRAW 96a6248a, QB64-PE
dd66c0c58 everywhere, 2026-11-15). Most failures were the test environment, not DRAW:

- **[Linux] Mid-test relaunch bound the dying window** (~30 tests: every `clip-*`
  restore step, file-save-as-draw, drawer-slots, animbrush-load, file-export-qb64-fill,
  dock-browser-band...). `xdotool search --pid P --name T` ORs its conditions, so the
  pid never filtered; the new launch bound the old instance's still-closing window,
  it vanished, the geometry check read 0x0 and "the test script DIED". Not
  `_NET_WM_PID` (GLFW QB64-PE sets it). Fixed in qa-harness 14e6da7: `--all`, title
  fallback only for windows without a pid. known-failures.txt entries blaming
  "relaunch 0x0 geometry" are this.
- **[Linux/titan] ImageMagick 6 only** (`convert`, no `magick`): 112 fixture-building
  tests got no fixture ("lightbox: 0 frames"). Fixed by a `magick` shim in qa-harness
  core/assert.sh. First as an exported bash function (0dfe71f) - not enough: tests also
  run `magick` from python (`os.system` -> /bin/sh, which never sees bash functions),
  so file-anim-sheet-import / file-anim-ase-import still had no fixtures ("compare-im6.q16:"
  = IM6 couldn't open the missing file). Now a real `magick` script in
  `$TMPDIR/qa-harness-im6-$UID` first on PATH (8679b09). Titan has python3.
- **[Windows/thinkpad] no ImageMagick and no Python** in Git Bash: every fixture test
  failed. Installed machine-wide 2026-11-15 (Rick: "go ahead on thinkpad get parity"):
  ImageMagick 7.1.2-34 Q16-HDRI x64 + Python 3.13.17, both on the system PATH, plus a
  copied `C:\Program Files\Python313\python3.exe` (tests call `python3`; otherwise the
  Store stub in WindowsApps answers). **[Windows] winget fails over ssh** (0x8a15000f
  "Data required by the source is missing" even after `source reset`: its index is an
  MSIX package a network logon can't open) - take the installer URL + SHA256 from the
  winget-pkgs manifest on GitHub, `curl.exe` it, `certutil -hashfile` it, run it silently
  (Inno: `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS="modifypath"`;
  python.org: `/quiet InstallAllUsers=1 PrependPath=1`). Installers kept in
  `C:\qa-runner\installers`.
- **[macOS + Windows] keymap tests can't seed DRAW.bindings**: the adapter's per-test
  config folder is Linux-only (XDG_CONFIG_HOME), so `QA_CONFIG_DIR` is empty and the
  tests pressed every key against the machine's own keymap (59 failures in
  deluxepaint-keymap on the Mac). `km_seeded` in QA/keymap-lib.sh now SKIPS there.
- **[macOS] floating windows 2x under DISPLAY_SCALE 1** (QB64-PE #789) - most of the
  Mac's dock-native-* failures; already in known-failures.txt.
- **Farm builds showed the bare version**: farm-check compiled with plain qb64pe and
  never ran DEV/build-info.sh (anim-new-animation failed). Now it does on all three
  recipes ([Windows] via `"C:\Program Files\Git\bin\bash.exe"` - the first `bash` on
  cmd's PATH is WSL's). And QB64-PE's object reuse missed a `build_info_gen.h` that
  appeared after the last compile (its dependency list only names headers that
  existed then): build-info.sh now touches native/build_info.h on a new value.
  Verified on titan: `DRAW 2.7.0 (bc7bcb08 animation)`.
- **[Linux/titan] slow host (~4x local)**: fixed sleeps after an action can read the
  dump before DRAW redraws. clip-lanes-mod died on empty lane geometry (now retries);
  swatches-color-edit typed before the color dialog opened (titan only).
- **`farm-check.sh qa titan` never returned**: `a && b && nohup ... & echo` backgrounds
  the whole `&&`-list, which kept ssh's output open until the suite ended. Now only
  the nohup is backgrounded (`{ nohup ... & } && echo started`).
- **[Windows] compiler self-host over SSH via PowerShell 5.1 stopped after `make`**:
  native-command output + `*>` redirection; run the self-host step through `cmd /c`
  from a .ps1 instead (see [[farm-build-recipes-per-host]]).

The farm gets qa-harness by rsync without `.git`, so `git log` on a host is stale
but its files are current - don't read the host's harness version from git.
