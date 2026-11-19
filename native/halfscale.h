#ifndef GJ_HALFSCALE_H
#define GJ_HALFSCALE_H
// -----------------------------------------------------------------------------
// Bicubic resample for a panel drawn at a half-step Scale (1.5x, 2.5x ..; GUI/PANEL-SURFACE
// PSURF_blit). Rick 2026-11-18: "the pixel art font tiny 5 where we've used it is crunchy
// looking" at nearest-neighbour 1.5x ("can we use bicubic scale on .5 sizes?").
//
// The source rect (sx, sy, sw, sh) of a QB64 ARGB image sstride px wide is resampled to
// a dw x dh image. pre > 1 = "sharp": the source is first taken as nearest-pixel scaled by
// pre (a virtual sw*pre x sh*pre image, pre = the next whole scale up), so the bicubic only
// shrinks it - edges keep most of their crispness instead of the plain bicubic blur.
// Catmull-Rom (a = -0.5), separable: a horizontal pass into a float buffer, then vertical.
// Premultiplied alpha (an icon's transparent edge does not darken), clamped to 0..255.
// _OFFSET args arrive as intptr_t.
// -----------------------------------------------------------------------------
#include <cstdint>
#include <cmath>
#include <vector>
#include <cstring>

#pragma GCC push_options
#pragma GCC optimize ("O3")

static inline float gj_cr_w(float t) { // Catmull-Rom weight for distance t
    t = std::fabs(t);
    if (t < 1.f) return 1.5f * t * t * t - 2.5f * t * t + 1.f;
    if (t < 2.f) return -0.5f * t * t * t + 2.5f * t * t - 4.f * t + 2.f;
    return 0.f;
}

// one output coord's 4 taps over a source length n (virtual length n * pre)
static inline void gj_taps(int32_t o, double scale, int32_t n, int32_t pre, int32_t *idx, float *w) {
    const double c = (o + 0.5) / scale - 0.5; // in virtual px
    const int32_t c0 = (int32_t)std::floor(c);
    float sum = 0.f;
    for (int32_t j = 0; j < 4; ++j) {
        int32_t v = c0 - 1 + j;
        w[j] = gj_cr_w((float)(c - v));
        sum += w[j];
        if (v < 0) v = 0;
        int32_t vn = n * pre - 1;
        if (v > vn) v = vn;
        idx[j] = v / pre; // virtual px -> source px
    }
    if (sum != 0.f) for (int32_t j = 0; j < 4; ++j) w[j] /= sum;
}

extern "C" void gj_halfscale(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sstride,
                             int32_t sx, int32_t sy, int32_t sw, int32_t sh, int32_t pre) {
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    if (!dst || !src || dw <= 0 || dh <= 0 || sw <= 0 || sh <= 0 || sstride <= 0) return;
    if (pre < 1) pre = 1;
    const double scx = (double)dw / ((double)sw * pre), scy = (double)dh / ((double)sh * pre);
    static std::vector<int32_t> xi, yi;
    static std::vector<float> xw, yw, tmp; // tmp: sh rows x dw cols x 4 channels
    xi.resize((size_t)dw * 4); xw.resize((size_t)dw * 4);
    yi.resize((size_t)dh * 4); yw.resize((size_t)dh * 4);
    for (int32_t x = 0; x < dw; ++x) gj_taps(x, scx, sw, pre, &xi[(size_t)x * 4], &xw[(size_t)x * 4]);
    for (int32_t y = 0; y < dh; ++y) gj_taps(y, scy, sh, pre, &yi[(size_t)y * 4], &yw[(size_t)y * 4]);
    tmp.resize((size_t)sh * dw * 4);
    // horizontal: every source row -> dw columns
    for (int32_t r = 0; r < sh; ++r) {
        const uint32_t *row = src + (int64_t)(sy + r) * sstride + sx;
        float *out = &tmp[(size_t)r * dw * 4];
        for (int32_t x = 0; x < dw; ++x) {
            const int32_t *ix = &xi[(size_t)x * 4];
            const float *wx = &xw[(size_t)x * 4];
            float a = 0, rr = 0, g = 0, b = 0;
            for (int32_t j = 0; j < 4; ++j) {
                const uint32_t c = row[ix[j]];
                const float w = wx[j], ca = (float)(c >> 24), wa = w * ca * (1.f / 255.f); // premultiplied
                a += w * ca; rr += wa * (float)((c >> 16) & 0xFF);
                g += wa * (float)((c >> 8) & 0xFF); b += wa * (float)(c & 0xFF);
            }
            out[x * 4] = a; out[x * 4 + 1] = rr; out[x * 4 + 2] = g; out[x * 4 + 3] = b;
        }
    }
    // vertical: dh rows
    for (int32_t y = 0; y < dh; ++y) {
        const int32_t *iy = &yi[(size_t)y * 4];
        const float *wy = &yw[(size_t)y * 4];
        const float *r0 = &tmp[(size_t)iy[0] * dw * 4], *r1 = &tmp[(size_t)iy[1] * dw * 4];
        const float *r2 = &tmp[(size_t)iy[2] * dw * 4], *r3 = &tmp[(size_t)iy[3] * dw * 4];
        uint32_t *out = dst + (int64_t)y * dw;
        for (int32_t x = 0; x < dw; ++x) {
            float v[4];
            for (int32_t k = 0; k < 4; ++k)
                v[k] = wy[0] * r0[x * 4 + k] + wy[1] * r1[x * 4 + k] + wy[2] * r2[x * 4 + k] + wy[3] * r3[x * 4 + k];
            float a = v[0];
            if (a < 0.f) a = 0.f;
            if (a > 255.f) a = 255.f;
            uint32_t ch[4];
            ch[0] = (uint32_t)(a + 0.5f);
            const float un = a > 0.f ? 255.f / a : 0.f; // un-premultiply
            for (int32_t k = 1; k < 4; ++k) {
                float c = v[k] * un;
                if (c < 0.f) c = 0.f;
                if (c > 255.f) c = 255.f;
                ch[k] = (uint32_t)(c + 0.5f);
            }
            out[x] = (ch[0] << 24) | (ch[1] << 16) | (ch[2] << 8) | ch[3];
        }
    }
}

// Has the source rect changed since the last call with this copy? The copy is a QB64 image
// sw x sh (its own buffer); 1 = it differed (and now holds the new pixels), 0 = the same.
// Lets a floating window be resampled only when its picture changed (HSC_put): a row
// memcmp costs far less than a resample.
extern "C" int32_t gj_region_changed(intptr_t src_, int32_t sstride, int32_t sx, int32_t sy, int32_t sw, int32_t sh,
                                     intptr_t copy_) {
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    uint32_t *copy = reinterpret_cast<uint32_t *>(copy_);
    if (!src || !copy || sw <= 0 || sh <= 0) return 1;
    int32_t changed = 0;
    for (int32_t r = 0; r < sh; ++r) {
        const uint32_t *row = src + (int64_t)(sy + r) * sstride + sx;
        uint32_t *c = copy + (int64_t)r * sw;
        if (changed || std::memcmp(row, c, (size_t)sw * 4) != 0) {
            std::memcpy(c, row, (size_t)sw * 4);
            changed = 1;
        }
    }
    return changed;
}

#pragma GCC pop_options

#endif
