# Hot-kernel migration — coverage report

Candidates for the `-O3` C++ `DECLARE LIBRARY` treatment, ranked by **hotness ×
inner-math stability**. Hotness = how tight/quadratic the inner loop is and how often it
runs (including effects that call it downstream). Stability = whether the *inner math* is
mathematically fixed (the surrounding dialog code churning does not count — only the
kernel loop). Per Rick's heuristic: a kernel whose math has not changed since it was
written is a strong candidate; a kernel still being reshaped is premature.

The whole QB64→C++ program compiles as one TU at **-O0**, so every candidate below pays a
double tax: no vectorization, and a real function call per `_MEMGET`/`_MEMPUT`.

## Tier 1 — do now (biggest bang, math is fixed)

| Kernel | File:line | Complexity | Why it's hot | Downstream callers |
|---|---|---|---|---|
| `IMAGE_ADJ_blur_alpha_aware` | IMAGE-ADJ.BM:876 | **O(w·h·r²) naive** | Menu Blur + unsharp sharpen; quadratic in radius | `apply_sharpen` |
| `IMAGE_ADJ_blur_premul_rgba` | IMAGE-ADJ.BM:715 | O(w·h) separable | The workhorse blur | glow, inner/outer glow, drop-shadow, `blur_typed` gaussian (**3× chained**) |

Making these two fast accelerates the entire spatial-effects menu, not just "Blur".

## Tier 2 — DONE (committed; bit-exact, measured @640×480)

All five diffed pixel-for-pixel against faithful BASIC copies (bench_imgfx2.bas):

| Kernel | native/imgfx.h entry | BASIC→C++ | speedup | mismatches |
|---|---|---|---|---|
| `IMAGE_ADJ_median` | `gj_median3` | 146→18 ms | 8.1× | 0 |
| `IMAGE_ADJ_edgedetect` | `gj_edgedetect` | 30→3 ms | 10.0× | 0 (FP-exact) |
| `IMAGE_ADJ_apply_sharpen` (combine) | `gj_unsharp_combine` | 18→2 ms | 9.0× | 0 |
| `IMAGE_ADJ_emboss` | `gj_emboss` | 13→2 ms | 6.5× | 0 |
| `IMAGE_ADJ_pixelate_alpha_aware` | `gj_pixelate_alpha_aware` | 5→1 ms | 5.0× | 0 |

edgedetect required replicating QB64's exact FP promotion (SINGLE `strength/100`
widened to DOUBLE in the sqrt multiply, `INT()`=floor) — verified bit-exact.

## Tier 3 — lower priority (procedural / infrequent / churning)

`cutout`, `corona`, `lightning`, `texnoise`, `addnoise`, glow dialogs — either run once
per invocation with small footprints, are procedural (RNG-driven, not per-pixel-hot on
large buffers), or are still being visually tuned (churn = premature to freeze in C++).

## Already done

| Kernel | Status |
|---|---|
| `GJ_IMGADJ_Blur` (GUI/IMGADJ.BM) | ✅ pilot — 18.4×, bit-exact (native/blur_kernel.h). Mirror to QB64_GJ_LIB submodule pending. |

## Cross-platform note

`#pragma GCC optimize("O3")` → full win on g++ (Linux/Windows-MinGW); clang (macOS)
ignores it, so the kernel runs at -O0 there — still correct, still faster than the BASIC
path (no per-pixel `_MEMGET` call overhead), just not vectorized. See native/README.md.
