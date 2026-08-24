# Multiple-instance support

DRAW can run several isolated windows at once, with a shared clipboard and the
ability to move layers between windows. Added on branch `multi-instance`.

## User-facing surface

- **Preference** `ALLOW_MULTIPLE_INSTANCES` (default FALSE), Settings > General >
  "Allow Multiple Instances". Gates only the in-app **File > New Window**
  (`Ctrl+Alt+N`, action 213). A manually-launched second copy is **always** allowed
  and auto-isolated regardless of the setting.
- **Copy Layer** (action 715, `Ctrl+Alt+Shift+C`) / **Paste Layer** (716,
  `Ctrl+Alt+Shift+V`) — move a whole layer through the OS clipboard between windows.
- **Send Layer to Other Window** (717, Layer menu) — push the current layer to every
  other live instance's mailbox (broadcast; targeted for the common 2-window case).
- Plain **Ctrl+V** (action 305) now falls back to the OS clipboard when the internal
  clipboard is empty, so it pastes a copy made in another instance.
- A window title shows ` [N]` when this is a secondary instance or a peer is running.

## Architecture

### Identity & isolation (`CORE/INSTANCE.BI/BM`)

- Identity resolves at **include time** (`INSTANCE_bootstrap`, called from
  `INSTANCE.BI`) — right after `PATHS_init`, BEFORE `CFG/CONFIG.BI`, because the
  per-instance config path is derived from the instance id.
- Registry lives at `<cache>/instances/<id>.instance` — one file per live instance.
  Liveness is an **in-file heartbeat** (`heartbeat=<TIMER>` rewritten every
  `INSTANCE_HEARTBEAT_SECS`); an entry older than `INSTANCE_STALE_SECS` is reaped.
  There is NO OS file lock (`LOCK`/`UNLOCK` are no-ops on Linux/mac) and NO file-mtime
  keyword in QB64-PE, so the heartbeat value carries liveness. Slots are a small fixed
  range (1..`INSTANCE_MAX`), probed with `_FILEEXISTS` — no directory enumeration.
- **Slot assignment**: `INSTANCE_bootstrap` reaps stale entries then claims the lowest
  free slot (optimistic claim: write reg file, read back token, walk to next slot if a
  peer won the race). Explicit `--instance N` forces a slot (testing/power use).
- **Config isolation** (`CFG/CONFIG.BI`): `INST.id > 1` + no `--config` →
  `<base>.instance-N.cfg`, **seeded** by copying the primary's config on first launch,
  then diverges. id==1 keeps the normal path (100% backward compatible). This matters
  because `CONFIG_save` truncate-rewrites the whole file (with the recent-files list)
  at ~100 call sites during normal use — two instances on one config continuously
  clobber each other.
- **Other per-instance state**: `inputs.log` → `inputs.instance-N.log`; all cache
  scratch tmps route through `INSTANCE_scratch$()` (inserts `-iN` before the ext).
- **Lifecycle** (DRAW.BAS): heartbeat via `INSTANCE_tick` each frame (self-throttled);
  `INSTANCE_shutdown` in `MAIN_shutdown` (covers loop-exit AND CMD 212). A crash
  (`SYSTEM 1`) leaves a slot the heartbeat-reap reclaims in ~`INSTANCE_STALE_SECS`.

### Launching (`INSTANCE_launch_new`)

`SHELL _DONTWAIT COMMAND$(0)` with NO `--instance` flag — the child auto-assigns a free
slot with its own optimistic-claim race handling (safer than forcing a slot from the
parent). `" &"` appended on non-Windows for full detach. `COMMAND$(0)` is the exe path.

### Layer transfer (`TOOLS/LAYERXFER.BI/BM`)

Two transports share one core (extract canvas-region pixels + tiny text metadata):

- **Clipboard** (Copy/Paste Layer): pixels ride `_CLIPBOARDIMAGE` (alpha-safe,
  cross-platform since QB64-PE v3.13.0); metadata rides `_CLIPBOARD$` as one line
  `DRAWLAYER1|name|opacity|blend`. No base64, no custom pixel codec.
- **Mailbox** (Send Layer): a self-contained blob `[MKI$(metaLen)][meta][PNG bytes]`
  written to `<cache>/instances/mailbox/<targetId>/from-<senderId>.layerxfer` via
  atomic write-temp-then-`NAME`. PNG via `_SAVEIMAGE`/`_LOADIMAGE`. The receiver polls
  `from-1..MAX` with `_FILEEXISTS` (fixed names — no enumeration), claims each by
  renaming to `.claim`, then deserializes. Poll is `LAYERXFER_poll_mailbox%`, called
  from the main loop and throttled by `INSTANCE_MAILPOLL_SECS`.

`LAYERXFER_add_layer%` mirrors **Duplicate Layer** for undo: it suppresses
`LAYERS_new%`'s auto-recorded (empty) `LAYER_ADD` via `HISTORY_IN_PROGRESS%`, fills the
pixels, then records ONE `HISTORY_record_layer_add` — so undo removes the layer and
redo restores it WITH content. `layerType` is forced IMAGE (text/AI side-table data is
not transferable).

## Constraints (QB64-PE / GLFW)

- **No drag-OUT.** QB64-PE has no keyword to initiate an OS drag from its window, so
  moving layers is menu/hotkey-driven, not literal mouse-drag between windows. Drag-IN
  (`_ACCEPTFILEDROP`) IS cross-platform now (a `.drawlayer` file can be dropped to
  import — see the DRAW.BAS drop handler). See [[qb64pe-acceptfiledrop-cross-platform]].
- `LOCK`/`UNLOCK` no-op on Linux/mac; no file-mtime keyword; no FS-watch; no
  single-instance/mutex built-in — hence heartbeat + atomic-rename + `_FILEEXISTS`
  polling throughout.

## Deferred / future

- Named per-instance "Send to Instance N" **dynamic submenu** (currently broadcast to
  all peers). Would follow the Recent-Files dynamic-submenu pattern with a reserved
  action-id range + per-target dispatch.
- Multiple pending layers per (sender→target) pair (currently one; a second send
  before the target consumes replaces the first).
