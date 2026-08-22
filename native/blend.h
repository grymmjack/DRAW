#ifndef GJ_BLEND_H
#define GJ_BLEND_H
// -----------------------------------------------------------------------------
// Layer blend compositor — the per-frame render hot path. Bit-for-bit port of
// LAYER_blend_composite / LAYER_blend_composite_region (GUI/LAYERS.BM); those two
// shared one blend switch + final composite, so this one kernel replaces both
// (full-image = whole-image region). All math is integer, BASIC \ == C++ / on the
// guarded non-negative operands here (guards replicated exactly). Buffers are QB64
// ARGB; _OFFSET args arrive as intptr_t. Verified pixel-exact by bench_blend.bas.
//
// Mode ids mirror the BLEND_* CONSTs (GUI/LAYERS.BI). NORMAL(0)/unknown -> source.
// -----------------------------------------------------------------------------
#include <cstdint>

#pragma GCC push_options
#pragma GCC optimize ("O3")

namespace gjblend {
    static inline int32_t A(uint32_t p) { return (int32_t)((p >> 24) & 0xFFu); }
    static inline int32_t R(uint32_t p) { return (int32_t)((p >> 16) & 0xFFu); }
    static inline int32_t G(uint32_t p) { return (int32_t)((p >>  8) & 0xFFu); }
    static inline int32_t B(uint32_t p) { return (int32_t)( p        & 0xFFu); }
    static inline uint32_t RGBA(int32_t r, int32_t g, int32_t b, int32_t a) {
        return ((uint32_t)(a & 0xFF) << 24) | ((uint32_t)(r & 0xFF) << 16)
             | ((uint32_t)(g & 0xFF) << 8)  |  (uint32_t)(b & 0xFF);
    }
    static inline int32_t clamp8(int32_t v) { return v < 0 ? 0 : (v > 255 ? 255 : v); }
    // one channel of one blend mode; d=dest, s=src (0..255). Mirrors BLEND_ch math
    // inline in the BASIC switch.
    static inline int32_t ch(int32_t mode, int32_t d, int32_t s) {
        switch (mode) {
            case 1:  return (d * s) / 255;                                        // MULTIPLY
            case 2:  return 255 - ((255 - d) * (255 - s)) / 255;                  // SCREEN
            case 3:  return d < 128 ? (2 * d * s) / 255                           // OVERLAY
                                    : 255 - (2 * (255 - d) * (255 - s)) / 255;
            case 4:  { int32_t b = d + s; return b > 255 ? 255 : b; }             // ADD
            case 5:  { int32_t b = d - s; return b < 0 ? 0 : b; }                 // SUBTRACT
            case 6:  { int32_t b = d - s; return b < 0 ? -b : b; }                // DIFFERENCE
            case 7:  return d < s ? d : s;                                        // DARKEN
            case 8:  return d > s ? d : s;                                        // LIGHTEN
            case 9:  { if (s >= 255) return 255;                                  // COLOR_DODGE
                       int32_t b = (d * 255) / (255 - s); return b > 255 ? 255 : b; }
            case 10: { if (s <= 0) return 0;                                      // COLOR_BURN
                       int32_t b = 255 - ((255 - d) * 255) / s; return b < 0 ? 0 : b; }
            case 11: return s < 128 ? (2 * s * d) / 255                           // HARD_LIGHT
                                    : 255 - (2 * (255 - s) * (255 - d)) / 255;
            case 12: { int32_t b = ((255 - 2 * s) * d * d) / 65025 + (2 * s * d) / 255; // SOFT_LIGHT
                       return clamp8(b); }
            case 13: return d + s - (2 * d * s) / 255;                            // EXCLUSION
            case 14: { if (s > 128) { int32_t v = 2 * (s - 128);                  // VIVID_LIGHT
                                      if (v >= 255) return 255;
                                      int32_t b = (d * 255) / (255 - v); return b > 255 ? 255 : b; }
                       else { int32_t v = 2 * s; if (v <= 0) return 0;
                              int32_t b = 255 - ((255 - d) * 255) / v; return b < 0 ? 0 : b; } }
            case 15: { int32_t b = d + 2 * s - 255; return clamp8(b); }           // LINEAR_LIGHT
            case 16: { if (s > 128) { int32_t p = 2 * s - 255; return d > p ? d : p; } // PIN_LIGHT
                       else { int32_t p = 2 * s; return d < p ? d : p; } }
            default: return s;                                                    // NORMAL / fallback
        }
    }
}

// Apply a layer/group opacity to a buffer's alpha channel in place:
// for each pixel with alpha>0, alpha = alpha*opacity/255 (RGB untouched). Bit-for-bit
// port of the ~9 identical `newAlpha = (alpha*opacity)\255` loops across SCREEN/FILL/
// MARQUEE/LAYERS. pixelCount = w*h. opacity 0..255.
extern "C" void gj_apply_opacity(intptr_t buf_, int32_t pixelCount, int32_t opacity) {
    uint32_t *buf = reinterpret_cast<uint32_t *>(buf_);
    for (int32_t i = 0; i < pixelCount; ++i) {
        uint32_t p = buf[i];
        int32_t a = (int32_t)((p >> 24) & 0xFFu);
        if (a > 0) {
            int32_t na = (a * opacity) / 255;
            buf[i] = (p & 0x00FFFFFFu) | ((uint32_t)(na & 0xFF) << 24);
        }
    }
}

extern "C" void gj_blend_composite(intptr_t dst_, intptr_t src_, int32_t w, int32_t h,
                                   int32_t mode, int32_t opacity,
                                   int32_t rx1, int32_t ry1, int32_t rx2, int32_t ry2) {
    using namespace gjblend;
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);

    int32_t cx1 = rx1, cy1 = ry1, cx2 = rx2, cy2 = ry2;
    if (cx1 < 0) cx1 = 0;
    if (cy1 < 0) cy1 = 0;
    if (cx2 >= w) cx2 = w - 1;
    if (cy2 >= h) cy2 = h - 1;
    if (cx2 < cx1 || cy2 < cy1) return;

    for (int32_t y = cy1; y <= cy2; ++y) {
        int64_t row = (int64_t)y * w;
        for (int32_t x = cx1; x <= cx2; ++x) {
            int64_t o = row + x;
            uint32_t sp = src[o];
            int32_t sA = A(sp);
            if (sA == 0) continue;
            int32_t effAlpha = (sA * opacity) / 255;
            if (effAlpha <= 0) continue;

            int32_t sR = R(sp), sG = G(sp), sB = B(sp);
            uint32_t dp = dst[o];
            int32_t dA = A(dp), dR = R(dp), dG = G(dp), dB = B(dp);

            int32_t bR, bG, bB;
            if (mode == 17) {                       // COLOR: src hue+sat, dest luma
                int32_t srcLum = (sR * 77 + sG * 150 + sB * 29) / 256;
                int32_t dstLum = (dR * 77 + dG * 150 + dB * 29) / 256;
                int32_t dl = dstLum - srcLum;
                bR = clamp8(sR + dl); bG = clamp8(sG + dl); bB = clamp8(sB + dl);
            } else if (mode == 18) {                // LUMINOSITY: src luma, dest hue+sat
                int32_t srcLum = (sR * 77 + sG * 150 + sB * 29) / 256;
                int32_t dstLum = (dR * 77 + dG * 150 + dB * 29) / 256;
                int32_t dl = srcLum - dstLum;
                bR = clamp8(dR + dl); bG = clamp8(dG + dl); bB = clamp8(dB + dl);
            } else {
                bR = ch(mode, dR, sR); bG = ch(mode, dG, sG); bB = ch(mode, dB, sB);
            }

            int32_t rR, rG, rB, rA;
            if (dA == 0) {
                rR = bR; rG = bG; rB = bB; rA = effAlpha;
            } else {
                rR = dR + ((bR - dR) * effAlpha) / 255;
                rG = dG + ((bG - dG) * effAlpha) / 255;
                rB = dB + ((bB - dB) * effAlpha) / 255;
                rA = dA + effAlpha - (dA * effAlpha) / 255;
                if (rA > 255) rA = 255;
            }
            dst[o] = RGBA(rR, rG, rB, rA);
        }
    }
}

#pragma GCC pop_options
#endif
