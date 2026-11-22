#ifndef GJ_AA_RESAMPLE_H
#define GJ_AA_RESAMPLE_H
// -----------------------------------------------------------------------------
// Smooth resize for the scale ops with Antialias on (CORE/IMAGE.BM IMG_scale_rect).
// Rick 2026-11-22: "if antialias is on when we do transforms it should also keep
// antialiasing. even scale down/up and so on" (PgUp / PgDn, 2x H / V, resize with
// content ...; Edit > Transform already resamples bicubic itself).
//
// The source rect (sx, sy, sw, sh) of a QB64 ARGB image sstride px wide becomes a
// dw x dh image (dst, overwritten):
//   - shrinking on both axes: an area average - every source pixel counts by the part
//     of it each output pixel covers, so 50% is a clean 2x2 mean, not every 2nd pixel;
//   - otherwise (growing, or one axis grows): Catmull-Rom bicubic (halfscale.h), which is
//     exact on an axis left 1:1, so 2x H keeps the rows untouched.
// Premultiplied alpha in both (transparent pixels add no dark fringe).
// _OFFSET args arrive as intptr_t.
// -----------------------------------------------------------------------------
#include <cstdint>
#include "halfscale.h"

#pragma GCC push_options
#pragma GCC optimize ("O3")

static void gj_aa_area(uint32_t *dst, int32_t dw, int32_t dh, const uint32_t *src, int32_t sstride,
                       int32_t sx, int32_t sy, int32_t sw, int32_t sh) {
    const double fx = (double)sw / dw, fy = (double)sh / dh;
    for (int32_t y = 0; y < dh; y++) {
        const double y0 = y * fy, y1 = (y + 1) * fy;
        for (int32_t x = 0; x < dw; x++) {
            const double x0 = x * fx, x1 = (x + 1) * fx;
            double a = 0, r = 0, g = 0, b = 0, wsum = 0;
            for (int32_t yy = (int32_t)y0; yy < sh && yy < y1; yy++) {
                const double wy = (yy + 1 < y1 ? yy + 1 : y1) - (yy > y0 ? yy : y0);
                if (wy <= 0) continue;
                const uint32_t *row = src + (int64_t)(sy + yy) * sstride + sx;
                for (int32_t xx = (int32_t)x0; xx < sw && xx < x1; xx++) {
                    const double wx = (xx + 1 < x1 ? xx + 1 : x1) - (xx > x0 ? xx : x0);
                    if (wx <= 0) continue;
                    const double w = wx * wy;
                    const uint32_t p = row[xx];
                    const double pa = ((p >> 24) & 255) * w;
                    a += pa;
                    r += ((p >> 16) & 255) * pa; g += ((p >> 8) & 255) * pa; b += (p & 255) * pa;
                    wsum += w;
                }
            }
            uint32_t out = 0;
            if (a > 0 && wsum > 0) {
                int32_t oa = (int32_t)(a / wsum + 0.5), orr = (int32_t)(r / a + 0.5);
                int32_t og = (int32_t)(g / a + 0.5), ob = (int32_t)(b / a + 0.5);
                if (oa > 255) oa = 255;
                if (orr > 255) orr = 255;
                if (og > 255) og = 255;
                if (ob > 255) ob = 255;
                out = ((uint32_t)oa << 24) | ((uint32_t)orr << 16) | ((uint32_t)og << 8) | (uint32_t)ob;
            }
            dst[(int64_t)y * dw + x] = out;
        }
    }
}

extern "C" void gj_aa_resample(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sstride,
                               int32_t sx, int32_t sy, int32_t sw, int32_t sh) {
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    if (!dst || !src || dw <= 0 || dh <= 0 || sw <= 0 || sh <= 0 || sstride <= 0) return;
    if (dw <= sw && dh <= sh) gj_aa_area(dst, dw, dh, src, sstride, sx, sy, sw, sh);
    else gj_halfscale(dst_, dw, dh, src_, sstride, sx, sy, sw, sh, 1);
}

#pragma GCC pop_options
#endif // GJ_AA_RESAMPLE_H
