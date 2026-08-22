# native/ — C++ hot kernels (compiled at -O3)

DRAW's whole QB64→C++ program is one translation unit compiled at **`-O0`** (QB64-PE's
default; see the ~5-min build discussion). Pixel-hot inner loops pay for that on every
run. This directory holds small, header-only C++ kernels pulled out of the `-O0` TU so
they can be compiled at `-O3` independently, via `DECLARE LIBRARY`.

## How it works

- Each kernel is a **header-only** `.h` with an `extern "C"` entry point wrapped in
  `#pragma GCC push_options` / `optimize("O3")` / `pop_options`.
- The BASIC side declares it inside the calling FUNCTION:
  ```qb64
  DECLARE LIBRARY "../native/blur_kernel"   ' path is relative to the .BM file, not repo root
      SUB gj_box_blur (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL radius AS LONG)
  END DECLARE
  ```
- **Path resolution gotcha (verified empirically):** QB64-PE resolves the `DECLARE
  LIBRARY` path relative to the **directory of the file containing the DECLARE**, NOT the
  main .BAS or the build CWD. `GJ_IMGADJ_Blur` lives in `GUI/IMGADJ.BM`, so the path is
  `../native/blur_kernel` (`GUI/` → repo root → `native/`). A path relative to repo root
  (`./native/...`) fails with "LIBRARY not found" from an included .BM.
- **`_OFFSET` arrives as `intptr_t`** (QB64's `ptrszint`). C++ won't implicitly convert
  that to `uint32_t*`, so the kernel signature takes `intptr_t` and casts inside:
  `uint32_t *dst = reinterpret_cast<uint32_t*>(dst_);`
- QB64 32-bit pixels are **ARGB**: `_RED32=(p>>16)&0xFF`, `_GREEN32=(p>>8)&0xFF`,
  `_BLUE32=p&0xFF`, and `_RGB32(r,g,b)` = `0xFF000000 | (r<<16) | (g<<8) | b`.

## Cross-platform note

- **Linux / Windows (MinGW):** g++ honors `#pragma GCC optimize("O3")` → full win.
- **macOS (clang):** clang ignores the GCC optimize pragma, so the kernel compiles at the
  program's `-O0`. It is **still correct and still faster** than the BASIC path (no
  `_MEMGET` per-pixel call overhead, raw pointer deref), just not vectorized. For a
  guaranteed `-O3` on macOS too, the kernel would need to be precompiled to a `.o`/`.a`
  and linked via `DECLARE STATIC LIBRARY` (heavier build integration; not needed yet).

## Measured — blur_kernel.h (box blur)

Benchmark `bench_blur.bas` (repo root), 1280×720, radius 6, Linux/g++:

| | time |
|---|---|
| BASIC `-O0` (former inline loop) | 828 ms |
| C++ `-O3` (`gj_box_blur`) | 45 ms |
| **Speedup** | **18.4×** |
| Pixel diff vs BASIC reference | **0 mismatches (bit-identical)** |

Compile-time cost: +38 lines / 1.7 KB in the `-O0` TU — negligible.

To re-run: `qb64pe -w -x -o bench_blur bench_blur.bas && ./bench_blur`
