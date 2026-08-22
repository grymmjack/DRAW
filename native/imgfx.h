#ifndef GJ_IMGFX_H
#define GJ_IMGFX_H
// -----------------------------------------------------------------------------
// DRAW spatial-effect hot kernels, compiled at -O3 out of the -O0 program TU.
// Buffers are QB64 32-bit ARGB, row-major. _OFFSET args arrive as intptr_t
// (QB64 ptrszint) and are cast to pixel pointers here. See native/README.md.
//
// Each kernel is a BIT-FOR-BIT port of the BASIC it replaces (GUI/IMAGE-ADJ.BM):
// same integer truncation (BASIC \ == C++ / on non-negative), same clamps, same
// write/skip conditions. Verified pixel-exact by bench_imgfx.bas before wiring.
// -----------------------------------------------------------------------------
#include <cstdint>
#include <cstring>
#include <cmath>

#pragma GCC push_options
#pragma GCC optimize ("O3")

namespace gjimgfx {
    static inline uint32_t A(uint32_t p) { return (p >> 24) & 0xFFu; } // _ALPHA32
    static inline uint32_t R(uint32_t p) { return (p >> 16) & 0xFFu; } // _RED32
    static inline uint32_t G(uint32_t p) { return (p >>  8) & 0xFFu; } // _GREEN32
    static inline uint32_t B(uint32_t p) { return  p        & 0xFFu; } // _BLUE32
    static inline uint32_t RGBA(int32_t r, int32_t g, int32_t b, int32_t a) {
        return ((uint32_t)(a & 0xFF) << 24) | ((uint32_t)(r & 0xFF) << 16)
             | ((uint32_t)(g & 0xFF) << 8)  |  (uint32_t)(b & 0xFF);      // _RGBA32
    }
    static inline uint32_t mkRGB(int32_t r, int32_t g, int32_t b) {
        return 0xFF000000u | ((uint32_t)(r & 0xFF) << 16)
             | ((uint32_t)(g & 0xFF) << 8) | (uint32_t)(b & 0xFF);        // _RGB32
    }
}

// ---------------------------------------------------------------------------
// Premultiplied-alpha separable box blur.
// Port of IMAGE_ADJ_blur_premul_rgba (IMAGE-ADJ.BM): premultiply -> horizontal
// running-sum -> vertical running-sum + un-premultiply. The BASIC used two extra
// QB64 images (premul, hblur) as scratch; here the kernel owns that scratch so
// the caller only passes src + a fresh (zeroed) dst. radius > 0 guaranteed by
// caller. Pixels whose blurred alpha resolves to 0 are left as dst's initial 0
// (transparent black) — matching the BASIC, which never wrote them.
// ---------------------------------------------------------------------------
extern "C" void gj_blur_premul(intptr_t dst_, intptr_t src_,
                               int32_t w, int32_t h, int32_t radius) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    const int64_t n = (int64_t)w * h;

    uint32_t *premul = new uint32_t[n];
    uint32_t *hblur  = new uint32_t[n];
    std::memset(dst, 0, (size_t)n * 4);   // BASIC result came from _NEWIMAGE (all 0)

    // Step 1: premultiply RGB by alpha/255.
    for (int64_t i = 0; i < n; ++i) {
        uint32_t p = src[i];
        int32_t a = (int32_t)A(p);
        if (a > 0) {
            premul[i] = RGBA((int32_t)R(p) * a / 255,
                             (int32_t)G(p) * a / 255,
                             (int32_t)B(p) * a / 255, a);
        } else {
            premul[i] = RGBA(0, 0, 0, a);
        }
    }

    // Step 2: horizontal running-sum (premul -> hblur).
    for (int32_t y = 0; y < h; ++y) {
        const uint32_t *prow = premul + (int64_t)y * w;
        uint32_t *hrow = hblur + (int64_t)y * w;
        int32_t sumR = 0, sumG = 0, sumB = 0, sumA = 0, cnt = 0;
        int32_t hi = radius; if (hi > w - 1) hi = w - 1;
        for (int32_t x = 0; x <= hi; ++x) {
            uint32_t s = prow[x];
            sumR += R(s); sumG += G(s); sumB += B(s); sumA += A(s); ++cnt;
        }
        for (int32_t x = 0; x < w; ++x) {
            if (cnt > 0) hrow[x] = RGBA(sumR / cnt, sumG / cnt, sumB / cnt, sumA / cnt);
            int32_t lo = x - radius;
            if (lo >= 0) {
                uint32_t s = prow[lo];
                sumR -= R(s); sumG -= G(s); sumB -= B(s); sumA -= A(s); --cnt;
            }
            int32_t nx = x + radius + 1;
            if (nx < w) {
                uint32_t s = prow[nx];
                sumR += R(s); sumG += G(s); sumB += B(s); sumA += A(s); ++cnt;
            }
        }
    }

    // Step 3: vertical running-sum (hblur -> dst) + un-premultiply.
    for (int32_t x = 0; x < w; ++x) {
        int32_t sumR = 0, sumG = 0, sumB = 0, sumA = 0, cnt = 0;
        int32_t hi = radius; if (hi > h - 1) hi = h - 1;
        for (int32_t y = 0; y <= hi; ++y) {
            uint32_t s = hblur[(int64_t)y * w + x];
            sumR += R(s); sumG += G(s); sumB += B(s); sumA += A(s); ++cnt;
        }
        for (int32_t y = 0; y < h; ++y) {
            if (cnt > 0) {
                int32_t ba = sumA / cnt;
                if (ba > 0) {
                    int32_t fr = (sumR / cnt) * 255 / ba; if (fr > 255) fr = 255;
                    int32_t fg = (sumG / cnt) * 255 / ba; if (fg > 255) fg = 255;
                    int32_t fb = (sumB / cnt) * 255 / ba; if (fb > 255) fb = 255;
                    dst[(int64_t)y * w + x] = RGBA(fr, fg, fb, ba);
                }
            }
            int32_t lo = y - radius;
            if (lo >= 0) {
                uint32_t s = hblur[(int64_t)lo * w + x];
                sumR -= R(s); sumG -= G(s); sumB -= B(s); sumA -= A(s); --cnt;
            }
            int32_t ny = y + radius + 1;
            if (ny < h) {
                uint32_t s = hblur[(int64_t)ny * w + x];
                sumR += R(s); sumG += G(s); sumB += B(s); sumA += A(s); ++cnt;
            }
        }
    }

    delete[] premul;
    delete[] hblur;
}

// ---------------------------------------------------------------------------
// Alpha-aware box blur — SEPARABLE masked running-sum (bit-exact rewrite).
// The BASIC (IMAGE_ADJ_blur_alpha_aware, IMAGE-ADJ.BM) is naive O(w·h·r²): per
// pixel with alpha>0, average RGB over the (2r+1)^2 window counting ONLY alpha>0
// neighbors; output _RGB32 (alpha 255); transparent pixels -> RGB32(0,0,0).
//
// A masked 2D box-sum IS separable: box-sum(R·mask) via H-then-V running sums
// equals the direct 2D sum EXACTLY (pure integer addition, no intermediate
// division), and sumR/sumW then matches the naive value bit-for-bit. O(w·h·r²)
// -> O(w·h). dst arrives as a copy of src; only overwritten where the BASIC
// overwrote (alpha==0, or alpha>0 && sumW>0).
// ---------------------------------------------------------------------------
extern "C" void gj_blur_alpha_aware(intptr_t dst_, intptr_t src_,
                                    int32_t w, int32_t h, int32_t radius) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    const int64_t n = (int64_t)w * h;

    // Horizontal pass: per-pixel box-sum (over [x-r,x+r], clamped) of masked
    // R,G,B and the alpha>0 count.
    int32_t *hR = new int32_t[n];
    int32_t *hG = new int32_t[n];
    int32_t *hB = new int32_t[n];
    int32_t *hW = new int32_t[n];
    for (int32_t y = 0; y < h; ++y) {
        const uint32_t *srow = src + (int64_t)y * w;
        int64_t base = (int64_t)y * w;
        int32_t sR = 0, sG = 0, sB = 0, sW = 0;
        int32_t hi = radius; if (hi > w - 1) hi = w - 1;
        for (int32_t x = 0; x <= hi; ++x) {
            uint32_t p = srow[x];
            if (A(p) > 0) { sR += R(p); sG += G(p); sB += B(p); ++sW; }
        }
        for (int32_t x = 0; x < w; ++x) {
            hR[base + x] = sR; hG[base + x] = sG; hB[base + x] = sB; hW[base + x] = sW;
            int32_t lo = x - radius;
            if (lo >= 0) {
                uint32_t p = srow[lo];
                if (A(p) > 0) { sR -= R(p); sG -= G(p); sB -= B(p); --sW; }
            }
            int32_t nx = x + radius + 1;
            if (nx < w) {
                uint32_t p = srow[nx];
                if (A(p) > 0) { sR += R(p); sG += G(p); sB += B(p); ++sW; }
            }
        }
    }

    // Vertical pass: box-sum the horizontal sums over [y-r,y+r] (clamped) -> the
    // full 2D masked sums; emit per the BASIC's per-pixel rules.
    for (int32_t x = 0; x < w; ++x) {
        int32_t sR = 0, sG = 0, sB = 0, sW = 0;
        int32_t hi = radius; if (hi > h - 1) hi = h - 1;
        for (int32_t y = 0; y <= hi; ++y) {
            int64_t i = (int64_t)y * w + x;
            sR += hR[i]; sG += hG[i]; sB += hB[i]; sW += hW[i];
        }
        for (int32_t y = 0; y < h; ++y) {
            int64_t o = (int64_t)y * w + x;
            uint32_t cur = src[o];
            if (A(cur) > 0) {
                if (sW > 0) dst[o] = mkRGB(sR / sW, sG / sW, sB / sW);
            } else {
                dst[o] = mkRGB(0, 0, 0);
            }
            int32_t lo = y - radius;
            if (lo >= 0) {
                int64_t i = (int64_t)lo * w + x;
                sR -= hR[i]; sG -= hG[i]; sB -= hB[i]; sW -= hW[i];
            }
            int32_t ny = y + radius + 1;
            if (ny < h) {
                int64_t i = (int64_t)ny * w + x;
                sR += hR[i]; sG += hG[i]; sB += hB[i]; sW += hW[i];
            }
        }
    }

    delete[] hR; delete[] hG; delete[] hB; delete[] hW;
}

// ---------------------------------------------------------------------------
// Pixelate (alpha-aware block average). Port of IMAGE_ADJ_pixelate_alpha_aware.
// For each blockSize x blockSize block (clamped to image), average RGB of the
// alpha>0 pixels; if any, fill the block with RGB32(avg). dst arrives as a copy
// of src; blocks with no opaque pixel keep the copy. blockSize clamped by caller.
// ---------------------------------------------------------------------------
extern "C" void gj_pixelate_alpha_aware(intptr_t dst_, intptr_t src_,
                                        int32_t w, int32_t h, int32_t blockSize) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    if (blockSize < 1) blockSize = 1;
    for (int32_t by = 0; by < h; by += blockSize) {
        int32_t endY = by + blockSize - 1; if (endY > h - 1) endY = h - 1;
        for (int32_t bx = 0; bx < w; bx += blockSize) {
            int32_t endX = bx + blockSize - 1; if (endX > w - 1) endX = w - 1;
            int32_t sR = 0, sG = 0, sB = 0, sW = 0;
            for (int32_t y = by; y <= endY; ++y) {
                const uint32_t *row = src + (int64_t)y * w;
                for (int32_t x = bx; x <= endX; ++x) {
                    uint32_t p = row[x];
                    if (A(p) > 0) { sR += R(p); sG += G(p); sB += B(p); ++sW; }
                }
            }
            if (sW > 0) {
                uint32_t avg = mkRGB(sR / sW, sG / sW, sB / sW);
                for (int32_t y = by; y <= endY; ++y) {
                    uint32_t *row = dst + (int64_t)y * w;
                    for (int32_t x = bx; x <= endX; ++x) row[x] = avg;
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Unsharp-mask combine. Port of the per-pixel loop in IMAGE_ADJ_apply_sharpen
// (the blur it needs is already the fast gj_blur_alpha_aware). Given src + its
// blurred copy: dd = src-blur per channel, zeroed if |dd|<=threshold; out =
// clamp(src + dd*amt/5); alpha preserved from src.
// ---------------------------------------------------------------------------
extern "C" void gj_unsharp_combine(intptr_t dst_, intptr_t src_, intptr_t blur_,
                                   int32_t w, int32_t h, int32_t amt, int32_t threshold) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    const uint32_t *blur = reinterpret_cast<const uint32_t *>(blur_);
    const int64_t n = (int64_t)w * h;
    for (int64_t i = 0; i < n; ++i) {
        uint32_t px = src[i], bpx = blur[i];
        int32_t r = R(px), g = G(px), bl = B(px), a = A(px);
        int32_t ddr = r - (int32_t)R(bpx); if ((ddr < 0 ? -ddr : ddr) <= threshold) ddr = 0;
        int32_t ddg = g - (int32_t)G(bpx); if ((ddg < 0 ? -ddg : ddg) <= threshold) ddg = 0;
        int32_t ddb = bl - (int32_t)B(bpx); if ((ddb < 0 ? -ddb : ddb) <= threshold) ddb = 0;
        int32_t nr = r + ddr * amt / 5;
        int32_t ng = g + ddg * amt / 5;
        int32_t nb = bl + ddb * amt / 5;
        if (nr < 0) nr = 0; else if (nr > 255) nr = 255;
        if (ng < 0) ng = 0; else if (ng > 255) ng = 255;
        if (nb < 0) nb = 0; else if (nb > 255) nb = 255;
        dst[i] = RGBA(nr, ng, nb, a);
    }
}

// ---------------------------------------------------------------------------
// 3x3 median (despeckle). Port of IMAGE_ADJ_median: for each pixel gather the 9
// clamped neighbors per channel, take the median (index 4 of the sorted 9),
// keep the CENTER pixel's alpha. The median is unique regardless of sort method.
// ---------------------------------------------------------------------------
static inline void gj_med9(int32_t *v) {          // partial insertion is fine; sort 9
    for (int32_t n = 1; n < 9; ++n) {
        int32_t t = v[n], j = n - 1;
        while (j >= 0 && v[j] > t) { v[j + 1] = v[j]; --j; }
        v[j + 1] = t;
    }
}
extern "C" void gj_median3(intptr_t dst_, intptr_t src_, int32_t w, int32_t h) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    for (int32_t y = 0; y < h; ++y) {
        for (int32_t x = 0; x < w; ++x) {
            int32_t rV[9], gV[9], bV[9], k = 0;
            for (int32_t dy = -1; dy <= 1; ++dy) {
                int32_t ny = y + dy; if (ny < 0) ny = 0; else if (ny >= h) ny = h - 1;
                const uint32_t *row = src + (int64_t)ny * w;
                for (int32_t dx = -1; dx <= 1; ++dx) {
                    int32_t nx = x + dx; if (nx < 0) nx = 0; else if (nx >= w) nx = w - 1;
                    uint32_t p = row[nx];
                    rV[k] = R(p); gV[k] = G(p); bV[k] = B(p); ++k;
                }
            }
            gj_med9(rV); gj_med9(gV); gj_med9(bV);
            int32_t a = A(src[(int64_t)y * w + x]);
            dst[(int64_t)y * w + x] = RGBA(rV[4], gV[4], bV[4], a);
        }
    }
}

// ---------------------------------------------------------------------------
// Emboss. Port of IMAGE_ADJ_emboss: luminance (R*30+G*59+B*11)/100, then per
// pixel out = clamp(128 + (lum[here]-lum[here+offset]) * strength), grey RGB32.
// The light-direction offset (odx,ody) is computed by the caller from the angle.
// ---------------------------------------------------------------------------
extern "C" void gj_emboss(intptr_t dst_, intptr_t src_, int32_t w, int32_t h,
                          int32_t odx, int32_t ody, int32_t strength) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    const int64_t n = (int64_t)w * h;
    int32_t *lum = new int32_t[n];
    for (int64_t i = 0; i < n; ++i) {
        uint32_t p = src[i];
        lum[i] = ((int32_t)R(p) * 30 + (int32_t)G(p) * 59 + (int32_t)B(p) * 11) / 100;
    }
    for (int32_t ey = 0; ey < h; ++ey) {
        int32_t pym = ey + ody; if (pym < 0) pym = 0; else if (pym >= h) pym = h - 1;
        for (int32_t ex = 0; ex < w; ++ex) {
            int32_t pxm = ex + odx; if (pxm < 0) pxm = 0; else if (pxm >= w) pxm = w - 1;
            int32_t dLum = lum[(int64_t)ey * w + ex] - lum[(int64_t)pym * w + pxm];
            int32_t outv = 128 + dLum * strength;
            if (outv < 0) outv = 0; else if (outv > 255) outv = 255;
            dst[(int64_t)ey * w + ex] = mkRGB(outv, outv, outv);
        }
    }
    delete[] lum;
}

// ---------------------------------------------------------------------------
// Sobel edge detect. Port of IMAGE_ADJ_edgedetect: luminance map, 3x3 Sobel gx/gy,
// mag = INT(sqrt(gx^2+gy^2) * (strength/100)); clamp 255; optional invert; grey.
// FP note: QB64 SQR(LONG) is a DOUBLE sqrt and sf! is a SINGLE widened to DOUBLE
// in the multiply, INT() = floor (value >=0 so (int) truncation matches). This is
// replicated exactly below; verified bit-exact by bench_imgfx.bas.
// ---------------------------------------------------------------------------
extern "C" void gj_edgedetect(intptr_t dst_, intptr_t src_, int32_t w, int32_t h,
                              int32_t strength, int32_t invert) {
    using namespace gjimgfx;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    const int64_t n = (int64_t)w * h;
    int32_t *lum = new int32_t[n];
    for (int64_t i = 0; i < n; ++i) {
        uint32_t p = src[i];
        lum[i] = ((int32_t)R(p) * 30 + (int32_t)G(p) * 59 + (int32_t)B(p) * 11) / 100;
    }
    float sf = (float)((double)strength / 100.0);   // sf! is SINGLE
    for (int32_t ey = 0; ey < h; ++ey) {
        int32_t ym = ey - 1; if (ym < 0) ym = 0;
        int32_t yp = ey + 1; if (yp >= h) yp = h - 1;
        for (int32_t ex = 0; ex < w; ++ex) {
            int32_t xm = ex - 1; if (xm < 0) xm = 0;
            int32_t xp = ex + 1; if (xp >= w) xp = w - 1;
            int32_t tl = lum[(int64_t)ym * w + xm], tm = lum[(int64_t)ym * w + ex], tr = lum[(int64_t)ym * w + xp];
            int32_t ml = lum[(int64_t)ey * w + xm], mr = lum[(int64_t)ey * w + xp];
            int32_t blv = lum[(int64_t)yp * w + xm], bm = lum[(int64_t)yp * w + ex], br = lum[(int64_t)yp * w + xp];
            int32_t gx = (tr + 2 * mr + br) - (tl + 2 * ml + blv);
            int32_t gy = (blv + 2 * bm + br) - (tl + 2 * tm + tr);
            double mm = sqrt((double)(gx * gx + gy * gy)) * (double)sf;  // SINGLE->DOUBLE
            int32_t mag = (int32_t)mm;                                    // INT() floor, mm>=0
            if (mag > 255) mag = 255;
            int32_t outv = mag;
            if (invert) outv = 255 - outv;
            dst[(int64_t)ey * w + ex] = mkRGB(outv, outv, outv);
        }
    }
    delete[] lum;
}

#pragma GCC pop_options
#endif
