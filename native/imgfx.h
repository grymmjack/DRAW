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
    static inline uint32_t RGB(int32_t r, int32_t g, int32_t b) {
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
                if (sW > 0) dst[o] = RGB(sR / sW, sG / sW, sB / sW);
            } else {
                dst[o] = RGB(0, 0, 0);
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

#pragma GCC pop_options
#endif
