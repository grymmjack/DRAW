#ifndef GJ_LANEFX_H
#define GJ_LANEFX_H
// -----------------------------------------------------------------------------
// DRAW effect lanes (TOOLS/LAYER-LANES LL_fx): in-place kernels on one frame
// cell of a layer's display copy, compiled at -O3 out of the -O0 program TU.
// Buffers are QB64 32-bit ARGB, row-major; _OFFSET args arrive as intptr_t.
// Every kernel keeps a fully transparent pixel transparent, so an effect never
// paints outside the layer's picture (the blur is the one that spreads alpha -
// IMAGE_ADJ_blur_premul_rgba, native/imgfx.h).
// -----------------------------------------------------------------------------
#include <cstdint>

#pragma GCC push_options
#pragma GCC optimize ("O3")

namespace gjlanefx {
    static inline uint32_t mix32(uint32_t x) { // a well-spread integer hash
        x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; x ^= x >> 16;
        return x;
    }
    static inline int32_t clamp8(int32_t v) { return v < 0 ? 0 : (v > 255 ? 255 : v); }
}

// Pixelate: each bs x bs block (from the cell's top-left) becomes one pixel -
// its alpha the block's average alpha, its colour the alpha-weighted average
// (transparent pixels add no black). An empty block stays empty.
extern "C" void gj_lfx_pixelate(intptr_t buf_, int32_t w, int32_t h, int32_t bs) {
    uint32_t *buf = reinterpret_cast<uint32_t *>(buf_);
    if (bs < 2 || w <= 0 || h <= 0) return;
    for (int32_t by = 0; by < h; by += bs) {
        int32_t y2 = by + bs < h ? by + bs : h;
        for (int32_t bx = 0; bx < w; bx += bs) {
            int32_t x2 = bx + bs < w ? bx + bs : w;
            uint64_t sa = 0, sr = 0, sg = 0, sb = 0, n = 0;
            for (int32_t y = by; y < y2; ++y) {
                const uint32_t *row = buf + (int64_t)y * w;
                for (int32_t x = bx; x < x2; ++x) {
                    uint32_t p = row[x], a = p >> 24;
                    sa += a; sr += ((p >> 16) & 255u) * a; sg += ((p >> 8) & 255u) * a; sb += (p & 255u) * a;
                    ++n;
                }
            }
            uint32_t out = 0;
            if (sa > 0) {
                uint32_t a = (uint32_t)((sa + n / 2) / n);
                if (a > 0) {
                    uint32_t r = (uint32_t)((sr + sa / 2) / sa), g = (uint32_t)((sg + sa / 2) / sa), b = (uint32_t)((sb + sa / 2) / sa);
                    out = (a << 24) | (r << 16) | (g << 8) | b;
                }
            }
            for (int32_t y = by; y < y2; ++y) {
                uint32_t *row = buf + (int64_t)y * w;
                for (int32_t x = bx; x < x2; ++x) row[x] = out;
            }
        }
    }
}

// Invert: pct (0..100) of the way to the inverted colour; alpha kept.
extern "C" void gj_lfx_invert(intptr_t buf_, int32_t w, int32_t h, int32_t pct) {
    uint32_t *buf = reinterpret_cast<uint32_t *>(buf_);
    if (pct <= 0) return;
    if (pct > 100) pct = 100;
    const int64_t n = (int64_t)w * h;
    for (int64_t i = 0; i < n; ++i) {
        uint32_t p = buf[i];
        if ((p >> 24) == 0) continue;
        int32_t r = (p >> 16) & 255, g = (p >> 8) & 255, b = p & 255;
        r += ((255 - 2 * r) * pct) / 100; g += ((255 - 2 * g) * pct) / 100; b += ((255 - 2 * b) * pct) / 100;
        buf[i] = (p & 0xFF000000u) | ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
    }
}

// Noise: a mono grain (the same delta on R, G and B, roughly bell-shaped, up to
// amount% of 255 either way) on every visible pixel; alpha kept. The same seed
// gives the same grain every time (a frozen grain keeps its seed).
extern "C" void gj_lfx_noise(intptr_t buf_, int32_t w, int32_t h, int32_t amount, int32_t seed) {
    using namespace gjlanefx;
    uint32_t *buf = reinterpret_cast<uint32_t *>(buf_);
    if (amount <= 0) return;
    if (amount > 100) amount = 100;
    const uint32_t s = mix32((uint32_t)seed * 0x9E3779B9u + 0x632BE5ABu);
    const float sc = amount / 100.0f * 255.0f;
    for (int32_t y = 0; y < h; ++y) {
        uint32_t *row = buf + (int64_t)y * w;
        for (int32_t x = 0; x < w; ++x) {
            uint32_t p = row[x];
            if ((p >> 24) == 0) continue;
            uint32_t k = mix32((uint32_t)x * 0x85EBCA6Bu ^ mix32((uint32_t)y * 0xC2B2AE35u ^ s));
            float t = ((k & 0xFFFFu) + (k >> 16)) / 65535.0f - 1.0f; // -1..1, a triangle
            int32_t d = (int32_t)(t * sc);
            int32_t r = clamp8((int32_t)((p >> 16) & 255) + d), g = clamp8((int32_t)((p >> 8) & 255) + d), b = clamp8((int32_t)(p & 255) + d);
            row[x] = (p & 0xFF000000u) | ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
        }
    }
}

#pragma GCC pop_options

#endif
