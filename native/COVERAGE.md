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

## Tier 2 — strong, same shape (do if appetite holds)

| Kernel | File:line | Complexity | Notes |
|---|---|---|---|
| `IMAGE_ADJ_median` | IMAGE-ADJ.BM:2066 | O(w·h·r²·log) | Per-pixel neighborhood sort — very hot |
| `IMAGE_ADJ_apply_sharpen` | IMAGE-ADJ.BM:1030 | O(w·h) combine | Unsharp = blur (Tier 1) + per-pixel mix |
| `IMAGE_ADJ_pixelate_alpha_aware` | IMAGE-ADJ.BM:955 | O(w·h) block-avg | Block average with alpha gate |
| `IMAGE_ADJ_emboss` / `_edgedetect` | 8872 / 9525 | O(w·h) 3×3 conv | Fixed convolution kernels |

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
