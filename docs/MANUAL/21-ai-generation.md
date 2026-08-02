# Chapter 21 — 🤖 AI Image Generation

> 🎯 **Goal:** Generate pixel art from a text prompt using an external generator of your choosing, and work with the results as ordinary layers.

---

## Off by default

AI features are **disabled until you ask for them**, and while disabled DRAW
shows nothing about them at all — no AI menu, no commands, no layer markers, no
status text. Enable them in **Settings → General → Enable AI Features**.

Turning the feature off again hides it completely, including on projects that
already contain AI layers: those layers keep working and simply render as
ordinary layers.

## DRAW does not talk to a model

DRAW runs an **external command-line generator that you configure**. It builds a
command, runs it, and imports the PNG that comes back. You choose the engine,
the models, and whether anything leaves your machine.

The bundled example is [pixelmon](https://github.com/grymmjack/pixelmon), a
local ComfyUI + SDXL pipeline. A test engine (`DEV/ai-echo.sh`) is also included
so you can exercise the whole pipeline in about a second.

Generators live in `DRAW.ai.cfg` in your config directory. **AI → Tools...**
edits them; the first time you use an AI command with nothing configured, DRAW
offers to write a starter file.

---

## Generating

**AI → New AI Layer...** opens the generate dialog.

| Field | Notes |
| --- | --- |
| **Tool** | Which configured generator to run |
| **Style** | Optional style guide — see below |
| **Preset** | A saved prompt; picking one loads it into the prompt box |
| **Prompt** | Multi-line, word-wrapped, with selection and clipboard |
| **Size** | `[IMAGE SIZE]` fills in the canvas size; `[IMAGE xN]` appears only when your display is scaled |
| **Position** | 3×3 preset grid, or type X/Y directly |
| **Seed** | Same seed reproduces a result; `[RANDOM]` re-rolls |
| **Count** | Above 1 generates a batch — see below |
| **SURPRISE ME** | Random style, random saved prompt, fresh seed |

Generation runs **in the background**. DRAW stays fully usable, and the status
bar shows an animated progress line with the elapsed time. Press **`Ctrl+Alt+K`**
to abort — this terminates the generator process, it does not merely stop
watching it.

### Working with a selection

With a selection active, the dialog starts with the selection's **size** and its
**top-left corner**. The result is scaled to fit inside the selection with its
aspect ratio preserved, so nothing is skewed: the limiting dimension fills the
selection exactly and the other is centred.

Enlarging is restricted to **whole-number factors**, because scaling pixel art by
a fractional amount resamples it into mush. A small result inside a large
selection therefore sits centred at 1×, 2× or 3× rather than being smeared to
fill.

---

## Batch generation

Set **Count** above 1 (up to 20) to generate several variations at once. They
land in a **layer group**, and every item shares identical settings — same tool,
style, prompt, size and position — differing **only by seed**. A batch is a set
of variations on one idea, not a set of unrelated images.

Seeds run from the seed shown in the dialog upward, so re-running a batch with
the same starting seed reproduces the same set.

Items are generated one at a time. The status bar shows progress as `[2/10]`,
and `Ctrl+Alt+K` stops the remainder — anything already generated is kept.

---

## AI layers

A generated layer is marked **`[AI]`** in the layer panel. Hovering it shows the
full prompt, with the engine, model, style and seed beneath.

Right-click an AI layer for:

- **Edit Prompt...** — change the stored prompt without regenerating
- **Regenerate** — re-run it, pre-filled with the prompt and seed it was made with

The prompt, style, tool, seed and size are **saved in the `.draw` file**, so a
layer can be regenerated — or reproduced exactly — after reloading a project.

---

## Styles and prompts

**AI → Style Editor...** manages style guides. A style can:

- wrap your prompt with a **prefix** and **suffix**
- add its own **CLI arguments** (e.g. pixelmon's `--style ega`)
- be **scoped to one tool**, since a style name means nothing to a different generator
- **lock a seed**, so its look is reproducible

> ⚠️ Command-line flags belong in a style's **Args** field, not its prefix or
> suffix. Prefix and suffix are *prompt text* — a flag placed there is passed
> inside the quoted prompt and the generator never sees it as a flag. DRAW
> migrates obviously-misplaced flags automatically and notes it in the log.

**AI → Prompt Editor...** manages saved prompt presets — plain text starting
points you can pick from the generate dialog.

---

## Argument macros

A tool's arguments are a **template**. DRAW expands `{macros}` before running it,
so one configuration adapts to whatever you are working on.

Click **[?]** in the tool or style editor for a live reference listing every
macro alongside **its current value**, so you can see exactly what your tool will
receive.

| Group | Macros |
| --- | --- |
| Run | `{prompt}` `{style}` `{seed}` `{outdir}` `{outname}` |
| Document | `{if}` `{id}` `{iw}` `{ih}` |
| Selection | `{sw}` `{sh}` |
| Layer | `{numlayers}` `{lidx}` `{lname}` `{lw}` `{lh}` `{lx}` `{ly}` |
| Brush / grid | `{bw}` `{bh}` `{gw}` `{gh}` |
| Colour | `{pal}` `{numpal}` `{fg}` `{bg}` `{pmode}` |
| Context | `{tool}` `{px}` `{py}` `{font}` `{fsize}` `{fontfile}` |
| Steering | `{limg}` `{dimg}` `{bimg}` |

Three rules apply to every macro:

1. **Values are whitespace-trimmed.**
2. **An UPPERCASE name yields an UPPERCASE value** — `{PAL}` gives `ANSI32`,
   `{pal}` gives it as-is. `{pal:lower}` and `{pal:slug}` are also available.
3. **`sc*` variants give the screen-scaled value** — `{sciw}` is the image width
   multiplied by the display scale. Every dimension and position macro has one.

DRAW supplies `{outdir}` as a fresh directory per run and imports the newest PNG
it finds there, so tools that name their own output files work unchanged.

### Steering images

`{limg}`, `{dimg}` and `{bimg}` export the **current layer**, the **flattened
document** and the **custom brush** as PNGs, for generators that accept a
reference image. `{dimg}` is the artwork only — never DRAW's interface.

---

## The log

Every run is recorded in **`ai.log`** in your config directory: the full command
line, the exit code, the tool's own output, and the imported file or the reason
it failed. When a generation misbehaves, that file will tell you why. A failure
dialog offers to open it for you.

---

## Exercises

1. Enable AI features and let DRAW write the starter config. Generate once with
   the bundled `echo (test)` engine to confirm the pipeline end to end.
2. Make a selection, then generate into it. Note that the dialog pre-fills the
   selection's size and corner.
3. Create a style with a suffix of `pixel art, bold outlines` and generate the
   same prompt with and without it.
4. Run a batch of 4 and compare the variations — same prompt, four seeds.
5. Open the **[?]** macro reference and find three macros whose current values
   change when you switch tool or palette.
