#ifndef GJ_MINIFY_H
#define GJ_MINIFY_H
// -----------------------------------------------------------------------------
// Area-average (box filter) shrink for the zoomed-out canvas in Antialias mode
// (RENDER_minify_put, OUTPUT/SCREEN.BM). Output pixel (ox, oy) of a zw x zh
// image is the premultiplied mean of the source pixels it covers:
// x in [ox*sw/zw, (ox+1)*sw/zw), y likewise - so thin lines and fine detail stay,
// softened, instead of whole rows / columns dropping out as with nearest-pixel.
// Only the output box (ox0,oy0)-(ox1,oy1) is written (the part on screen).
// QB64 ARGB buffers; _OFFSET args arrive as intptr_t. The BASIC loop it replaced
// cost ~30 ms a frame on a 1920x1080 canvas.
// -----------------------------------------------------------------------------
#include <cstdint>

#pragma GCC push_options
#pragma GCC optimize ("O3")

#include <vector>

extern "C" void gj_minify(intptr_t dst_, int32_t zw, int32_t zh, intptr_t src_, int32_t sw, int32_t sh,
                          int32_t ox0, int32_t oy0, int32_t ox1, int32_t oy1) {
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    if (!dst || !src || zw <= 0 || zh <= 0 || sw <= 0 || sh <= 0 || ox1 < ox0 || oy1 < oy0) return;
    static std::vector<int32_t> xa, xb; // each output column's source span (reused)
    xa.resize(zw); xb.resize(zw);
    for (int32_t ox = ox0; ox <= ox1; ++ox) {
        int32_t a = (int32_t)((int64_t)ox * sw / zw), b = (int32_t)((int64_t)(ox + 1) * sw / zw) - 1;
        if (b < a) b = a;
        if (b > sw - 1) b = sw - 1;
        xa[ox] = a; xb[ox] = b;
    }
    for (int32_t oy = oy0; oy <= oy1; ++oy) {
        int32_t ya = (int32_t)((int64_t)oy * sh / zh), yb = (int32_t)((int64_t)(oy + 1) * sh / zh) - 1;
        if (yb < ya) yb = ya;
        if (yb > sh - 1) yb = sh - 1;
        uint32_t *out = dst + (int64_t)oy * zw;
        const uint32_t *row0 = src + (int64_t)ya * sw;
        const int32_t rows = yb - ya + 1;
        for (int32_t ox = ox0; ox <= ox1; ++ox) {
            const int32_t x0 = xa[ox], x1 = xb[ox];
            uint64_t sa = 0, sr = 0, sg = 0, sb = 0; // (64-bit: any zoom-out depth)
            const uint32_t *row = row0;
            for (int32_t y = 0; y < rows; ++y, row += sw) {
                uint32_t ra = 0, rr = 0, rg = 0, rb = 0; // one row: <= 255*255*sw, fits
                for (int32_t x = x0; x <= x1; ++x) {
                    const uint32_t c = row[x], a = c >> 24;
                    ra += a;
                    rr += ((c >> 16) & 0xFFu) * a;
                    rg += ((c >> 8) & 0xFFu) * a;
                    rb += (c & 0xFFu) * a;
                }
                sa += ra; sr += rr; sg += rg; sb += rb;
            }
            const uint64_t n = (uint64_t)rows * (uint64_t)(x1 - x0 + 1);
            out[ox] = sa ? ((uint32_t)((sa + n / 2) / n) << 24) | ((uint32_t)(sr / sa) << 16)
                           | ((uint32_t)(sg / sa) << 8) | (uint32_t)(sb / sa)
                         : 0u;
        }
    }
}

#pragma GCC pop_options
#endif
