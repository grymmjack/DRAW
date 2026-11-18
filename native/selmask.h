#ifndef GJ_SELMASK_H
#define GJ_SELMASK_H
// -----------------------------------------------------------------------------
// Selection mask kernels (PLANS/AA-SELECTIONS.md - Rick 2026-11-17: "we need to have
// antialias be a global thing for selections too"). A selection mask is a canvas-sized
// QB64 32-bit image whose ALPHA is how much of each pixel is selected (0..255) and whose
// selected pixels are white: 0x00000000 = not selected, 0xAAFFFFFF = alpha AA selected.
// A hard mask (only 0 / 255) goes through every kernel unchanged in meaning.
// _OFFSET args arrive as intptr_t. Compiled at -O3 out of the -O0 program TU.
// -----------------------------------------------------------------------------
#include <cstdint>
#include <cstring>
#include <cmath>
#include <vector>
#include <algorithm>

#pragma GCC push_options
#pragma GCC optimize ("O3")

namespace gjsel {
    static inline uint32_t px(int a) { return a <= 0 ? 0u : ((uint32_t)(a > 255 ? 255 : a) << 24) | 0x00FFFFFFu; }
    static inline int al(uint32_t p) { return (int)(p >> 24); }
}

// ---------------------------------------------------------------------------
// A polygon's coverage, written into mask (w x h, cleared by the caller): even-odd,
// 16 sub-rows per pixel row, exact horizontal coverage on each. Vertices (n of them,
// SINGLE x / y arrays) are in pixel-index space - pixel i's centre is i - so a point
// list from the canvas (lasso, polygon, ellipse) lands where the hard fill puts it.
// Pixels where the polygon covers anything get max(their alpha, coverage).
// ---------------------------------------------------------------------------
extern "C" void gj_sel_poly(intptr_t mask_, int32_t w, int32_t h, intptr_t xs_, intptr_t ys_, int32_t n) {
    uint32_t *mask = (uint32_t *)mask_;
    const float *xs = (const float *)xs_, *ys = (const float *)ys_;
    if (n < 3 || w <= 0 || h <= 0) return;
    float minY = 1e30f, maxY = -1e30f;
    for (int i = 0; i < n; i++) { float y = ys[i] + 0.5f; if (y < minY) minY = y; if (y > maxY) maxY = y; }
    int y0 = (int)std::floor(minY), y1 = (int)std::ceil(maxY);
    if (y0 < 0) y0 = 0;
    if (y1 > h) y1 = h;
    const int S = 16;
    std::vector<float> acc((size_t)w + 2, 0.0f);
    std::vector<float> xi; xi.reserve(64);
    for (int y = y0; y < y1; y++) {
        std::fill(acc.begin(), acc.end(), 0.0f);
        int lo = w, hi = -1;
        for (int s = 0; s < S; s++) {
            float sy = y + (s + 0.5f) / S;
            xi.clear();
            for (int i = 0, j = n - 1; i < n; j = i++) {
                float ay = ys[j] + 0.5f, by = ys[i] + 0.5f;
                if ((ay <= sy && by > sy) || (by <= sy && ay > sy)) {
                    float ax = xs[j] + 0.5f, bx = xs[i] + 0.5f;
                    xi.push_back(ax + (sy - ay) * (bx - ax) / (by - ay));
                }
            }
            if (xi.size() < 2) continue;
            std::sort(xi.begin(), xi.end());
            for (size_t k = 0; k + 1 < xi.size(); k += 2) {
                float a = xi[k], b = xi[k + 1];
                if (a < 0) a = 0;
                if (b > (float)w) b = (float)w;
                if (b <= a) continue;
                int ia = (int)a, ib = (int)b;
                const float wgt = 1.0f / S;
                if (ia == ib) { acc[ia] += (b - a) * wgt; }
                else {
                    acc[ia] += ((ia + 1) - a) * wgt;
                    for (int x = ia + 1; x < ib; x++) acc[x] += wgt;
                    if (ib < w) acc[ib] += (b - ib) * wgt;
                }
                if (ia < lo) lo = ia;
                if (ib > hi) hi = ib;
            }
        }
        if (hi < lo) continue;
        if (hi >= w) hi = w - 1;
        uint32_t *row = mask + (size_t)y * w;
        for (int x = lo; x <= hi; x++) {
            int a = (int)(acc[x] * 255.0f + 0.5f);
            if (a > 255) a = 255;
            if (a > gjsel::al(row[x])) row[x] = gjsel::px(a);
        }
    }
}

// ---------------------------------------------------------------------------
// Feather: blur the mask's alpha (three box passes of radius r / 3, at least 1 - DRAW's
// Gaussian blur; averaged over the canvas only, so the canvas edge stays as it was).
// ---------------------------------------------------------------------------
static void gj_sel_box_pass(std::vector<float> &a, std::vector<float> &t, int w, int h, int r) {
    // an average over the window's pixels ON the canvas: the canvas edge is not a selection edge
    for (int y = 0; y < h; y++) {                 // horizontal: a -> t
        const float *src = &a[(size_t)y * w]; float *dst = &t[(size_t)y * w];
        float sum = 0; int cnt = 0;
        for (int x = 0; x <= r && x < w; x++) { sum += src[x]; cnt++; }
        for (int x = 0; x < w; x++) {
            dst[x] = sum / cnt;
            int xo = x - r, xn = x + r + 1;
            if (xo >= 0) { sum -= src[xo]; cnt--; }
            if (xn < w) { sum += src[xn]; cnt++; }
        }
    }
    for (int x = 0; x < w; x++) {                 // vertical: t -> a
        float sum = 0; int cnt = 0;
        for (int y = 0; y <= r && y < h; y++) { sum += t[(size_t)y * w + x]; cnt++; }
        for (int y = 0; y < h; y++) {
            a[(size_t)y * w + x] = sum / cnt;
            int yo = y - r, yn = y + r + 1;
            if (yo >= 0) { sum -= t[(size_t)yo * w + x]; cnt--; }
            if (yn < h) { sum += t[(size_t)yn * w + x]; cnt++; }
        }
    }
}

extern "C" void gj_sel_feather(intptr_t mask_, int32_t w, int32_t h, int32_t radius) {
    uint32_t *mask = (uint32_t *)mask_;
    if (radius < 1 || w <= 0 || h <= 0) return;
    const size_t n = (size_t)w * h;
    std::vector<float> a(n), t(n);
    for (size_t i = 0; i < n; i++) a[i] = (float)gjsel::al(mask[i]);
    int r3 = radius / 3; if (r3 < 1) r3 = 1;
    for (int p = 0; p < 3; p++) gj_sel_box_pass(a, t, w, h, r3);
    for (size_t i = 0; i < n; i++) mask[i] = gjsel::px((int)(a[i] + 0.5f));
}

// ---------------------------------------------------------------------------
// Combine: cur = cur (op) add, per pixel, alpha as 0..1 -
//   1 ADD       max(a, b)
//   2 SUBTRACT  a * (1 - b)
//   3 INTERSECT min(a, b)
// (a hard pair gives exactly the old OR / AND NOT / AND).
// ---------------------------------------------------------------------------
extern "C" void gj_sel_merge(intptr_t cur_, intptr_t add_, int32_t w, int32_t h, int32_t mode) {
    uint32_t *cur = (uint32_t *)cur_; const uint32_t *add = (const uint32_t *)add_;
    const size_t n = (size_t)w * h;
    for (size_t i = 0; i < n; i++) {
        int a = gjsel::al(cur[i]), b = gjsel::al(add[i]), o;
        if (mode == 1) o = a > b ? a : b;
        else if (mode == 2) o = (a * (255 - b) + 127) / 255;
        else o = a < b ? a : b;
        cur[i] = gjsel::px(o);
    }
}

// ---------------------------------------------------------------------------
// Bounds of what is selected at all (alpha > 0): out[0..3] = minX, minY, maxX, maxY
// (LONGs); minX > maxX = nothing selected.
// ---------------------------------------------------------------------------
extern "C" void gj_sel_bounds(intptr_t mask_, int32_t w, int32_t h, intptr_t out_) {
    const uint32_t *mask = (const uint32_t *)mask_; int32_t *out = (int32_t *)out_;
    int minX = w, minY = h, maxX = -1, maxY = -1;
    for (int y = 0; y < h; y++) {
        const uint32_t *row = mask + (size_t)y * w;
        int x0 = -1, x1 = -1;
        for (int x = 0; x < w; x++) if (row[x] >> 24) { x0 = x; break; }
        if (x0 < 0) continue;
        for (int x = w - 1; x >= x0; x--) if (row[x] >> 24) { x1 = x; break; }
        if (x0 < minX) minX = x0; if (x1 > maxX) maxX = x1;
        if (y < minY) minY = y; maxY = y;
    }
    out[0] = minX; out[1] = minY; out[2] = maxX; out[3] = maxY;
}

// ---------------------------------------------------------------------------
// Grow (r > 0) / shrink (r < 0) by |r| px: a round max / min filter of the alpha (a soft
// edge stays soft, moved). Off the canvas counts as not selected (shrink pulls in from
// the canvas edge too - as the old contract did).
// ---------------------------------------------------------------------------
extern "C" void gj_sel_grow(intptr_t mask_, int32_t w, int32_t h, int32_t r) {
    uint32_t *mask = (uint32_t *)mask_;
    if (r == 0 || w <= 0 || h <= 0) return;
    const bool grow = r > 0; const int R = grow ? r : -r;
    const size_t n = (size_t)w * h;
    std::vector<uint8_t> a(n), t(n);
    for (size_t i = 0; i < n; i++) a[i] = (uint8_t)gjsel::al(mask[i]);
    // the disc's half-width per row offset
    std::vector<int> hw(2 * R + 1);
    for (int dy = -R; dy <= R; dy++) hw[dy + R] = (int)std::floor(std::sqrt((float)(R * R - dy * dy)) + 0.001f);
    // per row: a horizontal run filter of each half-width needed, then combine over dy
    // (simple O(n * R) with a row max over a sliding window per distinct width)
    std::vector<uint8_t> rowF((size_t)(R + 1) * w);
    std::vector<uint8_t> out(n, grow ? 0 : 255);
    for (int y = 0; y < h; y++) {
        const uint8_t *src = &a[(size_t)y * w];
        // rowF[k][x] = max / min over src[x-k .. x+k] (off canvas = 0)
        for (int x = 0; x < w; x++) rowF[x] = src[x];
        for (int k = 1; k <= R; k++) {
            uint8_t *prev = &rowF[(size_t)(k - 1) * w], *cur = &rowF[(size_t)k * w];
            for (int x = 0; x < w; x++) {
                uint8_t l = x - k >= 0 ? src[x - k] : 0, rr = x + k < w ? src[x + k] : 0, v = prev[x];
                if (grow) { if (l > v) v = l; if (rr > v) v = rr; }
                else { if (l < v) v = l; if (rr < v) v = rr; }
                cur[x] = v;
            }
        }
        for (int dy = -R; dy <= R; dy++) {
            int yy = y + dy;
            if (yy < 0 || yy >= h) continue; // (shrink: the off-canvas rows are handled below)
            const uint8_t *f = &rowF[(size_t)hw[dy + R] * w];
            uint8_t *o = &out[(size_t)yy * w];
            if (grow) { for (int x = 0; x < w; x++) if (f[x] > o[x]) o[x] = f[x]; }
            else { for (int x = 0; x < w; x++) if (f[x] < o[x]) o[x] = f[x]; }
        }
    }
    if (!grow) { // rows within R of the top / bottom see off-canvas (0) rows
        for (int y = 0; y < h; y++) if (y < R || y >= h - R) std::memset(&out[(size_t)y * w], 0, (size_t)w);
    }
    for (size_t i = 0; i < n; i++) mask[i] = gjsel::px(out[i]);
}

// ---------------------------------------------------------------------------
// Threshold: alpha >= 128 -> 255, else 0 (make a soft selection hard).
// ---------------------------------------------------------------------------
extern "C" void gj_sel_harden(intptr_t mask_, int32_t w, int32_t h) {
    uint32_t *mask = (uint32_t *)mask_;
    const size_t n = (size_t)w * h;
    for (size_t i = 0; i < n; i++) mask[i] = gjsel::px(gjsel::al(mask[i]) >= 128 ? 255 : 0);
}

// ---------------------------------------------------------------------------
// Invert: alpha -> 255 - alpha.
// ---------------------------------------------------------------------------
extern "C" void gj_sel_invert(intptr_t mask_, int32_t w, int32_t h) {
    uint32_t *mask = (uint32_t *)mask_;
    const size_t n = (size_t)w * h;
    for (size_t i = 0; i < n; i++) mask[i] = gjsel::px(255 - gjsel::al(mask[i]));
}

// ---------------------------------------------------------------------------
// Any partly-selected pixel (alpha 1..254)? 1 = a soft selection.
// ---------------------------------------------------------------------------
extern "C" int32_t gj_sel_is_soft(intptr_t mask_, int32_t w, int32_t h) {
    const uint32_t *mask = (const uint32_t *)mask_;
    const size_t n = (size_t)w * h;
    for (size_t i = 0; i < n; i++) { int a = gjsel::al(mask[i]); if (a > 0 && a < 255) return 1; }
    return 0;
}

// ---------------------------------------------------------------------------
// Copy through the selection: dst (dw x dh) pixel (x, y) = src (sw x sh) pixel
// (sx + x, sy + y) with its alpha scaled by the mask (mw x mh) coverage at (mx + x, my + y);
// nothing selected there (or off src / the mask) = transparent 0. A hard mask copies
// exactly what it selects.
// ---------------------------------------------------------------------------
extern "C" void gj_sel_copy(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sw, int32_t sh,
                            int32_t sx, int32_t sy, intptr_t mask_, int32_t mw, int32_t mh, int32_t mx, int32_t my) {
    uint32_t *dst = (uint32_t *)dst_; const uint32_t *src = (const uint32_t *)src_, *mask = (const uint32_t *)mask_;
    for (int y = 0; y < dh; y++) {
        for (int x = 0; x < dw; x++) {
            uint32_t o = 0;
            int ux = mx + x, uy = my + y, qx = sx + x, qy = sy + y;
            if (ux >= 0 && uy >= 0 && ux < mw && uy < mh && qx >= 0 && qy >= 0 && qx < sw && qy < sh) {
                int c = gjsel::al(mask[(size_t)uy * mw + ux]);
                if (c > 0) {
                    uint32_t p = src[(size_t)qy * sw + qx];
                    if (c >= 255) o = p;
                    else { int a = (gjsel::al(p) * c + 127) / 255; o = a > 0 ? ((uint32_t)a << 24) | (p & 0x00FFFFFFu) : 0; }
                }
            }
            dst[(size_t)y * dw + x] = o;
        }
    }
}

// ---------------------------------------------------------------------------
// Clear through the selection: img (iw x ih) pixel (ox + x, oy + y) for each canvas pixel
// (x, y) in x0..x1, y0..y1 keeps the unselected share of its alpha (alpha * (255 - c) / 255);
// none left = transparent 0 (a hard mask clears exactly what it selects, as before).
// ---------------------------------------------------------------------------
extern "C" void gj_sel_clear(intptr_t img_, int32_t iw, int32_t ih, int32_t ox, int32_t oy,
                             intptr_t mask_, int32_t mw, int32_t mh, int32_t x0, int32_t y0, int32_t x1, int32_t y1) {
    uint32_t *img = (uint32_t *)img_; const uint32_t *mask = (const uint32_t *)mask_;
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 >= mw) x1 = mw - 1;
    if (y1 >= mh) y1 = mh - 1;
    for (int y = y0; y <= y1; y++) {
        int iy = oy + y; if (iy < 0 || iy >= ih) continue;
        for (int x = x0; x <= x1; x++) {
            int ix = ox + x; if (ix < 0 || ix >= iw) continue;
            int c = gjsel::al(mask[(size_t)y * mw + x]);
            if (c <= 0) continue;
            uint32_t &p = img[(size_t)iy * iw + ix];
            if (c >= 255) { p = 0; continue; }
            int a = (gjsel::al(p) * (255 - c) + 127) / 255;
            p = a > 0 ? ((uint32_t)a << 24) | (p & 0x00FFFFFFu) : 0;
        }
    }
}

// ---------------------------------------------------------------------------
// The magic wand (Selection Bar: TOLERANCE, CONTIGUOUS): select into mask (cleared by the
// caller) the pixels of src (w x h) within bL..bR, bT..bB whose colour is within tol of the
// seed's - the largest of the R, G, B, A differences; two fully transparent pixels always
// match - joined to the seed through 4-neighbours (contiguous) or anywhere (not).
// Returns how many pixels it selected.
// ---------------------------------------------------------------------------
extern "C" int32_t gj_sel_wand(intptr_t mask_, intptr_t src_, int32_t w, int32_t h, int32_t sx, int32_t sy,
                               int32_t tol, int32_t contiguous, int32_t bL, int32_t bT, int32_t bR, int32_t bB) {
    uint32_t *mask = (uint32_t *)mask_; const uint32_t *src = (const uint32_t *)src_;
    if (bL < 0) bL = 0;
    if (bT < 0) bT = 0;
    if (bR >= w) bR = w - 1;
    if (bB >= h) bB = h - 1;
    if (sx < bL || sx > bR || sy < bT || sy > bB) return 0;
    const uint32_t t = src[(size_t)sy * w + sx];
    const int ta = (int)(t >> 24), tr = (int)((t >> 16) & 255), tg = (int)((t >> 8) & 255), tb = (int)(t & 255);
    auto match = [&](uint32_t p) -> bool {
        int a = (int)(p >> 24);
        if (a == 0 && ta == 0) return true;
        int d = std::abs(a - ta), e;
        e = std::abs((int)((p >> 16) & 255) - tr); if (e > d) d = e;
        e = std::abs((int)((p >> 8) & 255) - tg); if (e > d) d = e;
        e = std::abs((int)(p & 255) - tb); if (e > d) d = e;
        return d <= tol;
    };
    int32_t count = 0;
    if (!contiguous) {
        for (int y = bT; y <= bB; y++)
            for (int x = bL; x <= bR; x++)
                if (match(src[(size_t)y * w + x])) { mask[(size_t)y * w + x] = 0xFFFFFFFFu; count++; }
        return count;
    }
    std::vector<int32_t> st; st.reserve(4096);
    st.push_back(sy * w + sx);
    mask[(size_t)sy * w + sx] = 0xFFFFFFFFu; count++;
    while (!st.empty()) {
        int32_t i = st.back(); st.pop_back();
        int x = i % w, y = i / w;
        const int nx[4] = {x - 1, x + 1, x, x}, ny[4] = {y, y, y - 1, y + 1};
        for (int k = 0; k < 4; k++) {
            if (nx[k] < bL || nx[k] > bR || ny[k] < bT || ny[k] > bB) continue;
            size_t j = (size_t)ny[k] * w + nx[k];
            if (mask[j]) continue;
            if (!match(src[j])) continue;
            mask[j] = 0xFFFFFFFFu; count++;
            st.push_back((int32_t)j);
        }
    }
    return count;
}

// ---------------------------------------------------------------------------
// The wand's ANTIALIAS EDGE: one 3 x 3 average of the coverage - a 1px soft rim.
// ---------------------------------------------------------------------------
extern "C" void gj_sel_soften(intptr_t mask_, int32_t w, int32_t h) {
    uint32_t *mask = (uint32_t *)mask_;
    if (w <= 0 || h <= 0) return;
    const size_t n = (size_t)w * h;
    std::vector<float> a(n), t(n);
    for (size_t i = 0; i < n; i++) a[i] = (float)gjsel::al(mask[i]);
    gj_sel_box_pass(a, t, w, h, 1);
    for (size_t i = 0; i < n; i++) mask[i] = gjsel::px((int)(a[i] + 0.5f));
}

// ---------------------------------------------------------------------------
// src (sw x sh) OVER dst (dw x dh) at (dx, dy), straight alpha done right: a half-
// transparent pixel over an empty one keeps its colour. QB64's _BLEND darkens it there
// (half-alpha white onto alpha 0 came out grey), so a soft-edged float - a feathered or
// AA selection moved / pasted onto a transparent layer - grew grey rims.
// ---------------------------------------------------------------------------
extern "C" void gj_sel_over(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sw, int32_t sh,
                            int32_t dx, int32_t dy) {
    uint32_t *dst = (uint32_t *)dst_; const uint32_t *src = (const uint32_t *)src_;
    if (!dst || !src) return;
    for (int32_t y = 0; y < sh; y++) {
        const int32_t ty = y + dy; if (ty < 0 || ty >= dh) continue;
        for (int32_t x = 0; x < sw; x++) {
            const int32_t tx = x + dx; if (tx < 0 || tx >= dw) continue;
            const uint32_t s = src[(size_t)y * sw + x];
            const uint32_t sa = s >> 24;
            if (!sa) continue;
            uint32_t &d = dst[(size_t)ty * dw + tx];
            const uint32_t da = d >> 24;
            if (sa == 255 || !da) { d = s; continue; }
            // out alpha and colour, in 0..255 x 255 fixed point
            const uint32_t dw2 = da * (255 - sa);          // dst's weight x 255
            const uint32_t oa255 = sa * 255 + dw2;          // out alpha x 255
            uint32_t o = 0;
            for (int sh8 = 0; sh8 < 24; sh8 += 8) {
                const uint32_t c = (((s >> sh8) & 255) * sa * 255 + ((d >> sh8) & 255) * dw2 + oa255 / 2) / oa255;
                o |= (c > 255 ? 255 : c) << sh8;
            }
            d = o | (((oa255 + 127) / 255) << 24);
        }
    }
}

// ---------------------------------------------------------------------------
// The rect (x1, y1)-(x2, y2) of src OVER the same rect of dst (images of any size, the
// rect clipped to both), straight alpha as gj_sel_over: what a blended
// _PUTIMAGE (x1,y1)-(x2,y2), src, dst, (x1,y1)-(x2,y2) should do. The layer composite
// (SCREEN_render), merges and flatten use it - QB64's blend greyed a soft pixel where
// the layers below were empty, so a soft stroke looked darker with the composite on
// (Preview open, a blend mode, a group) than without, and merged / exported darker.
// ---------------------------------------------------------------------------
extern "C" void gj_over_rect(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sw, int32_t sh,
                             int32_t x1, int32_t y1, int32_t x2, int32_t y2) {
    uint32_t *dst = (uint32_t *)dst_; const uint32_t *src = (const uint32_t *)src_;
    if (!dst || !src) return;
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 >= dw) x2 = dw - 1;
    if (x2 >= sw) x2 = sw - 1;
    if (y2 >= dh) y2 = dh - 1;
    if (y2 >= sh) y2 = sh - 1;
    for (int32_t y = y1; y <= y2; y++) {
        const uint32_t *sr = src + (size_t)y * sw;
        uint32_t *dr = dst + (size_t)y * dw;
        for (int32_t x = x1; x <= x2; x++) {
            const uint32_t s = sr[x];
            const uint32_t sa = s >> 24;
            if (!sa) continue;
            uint32_t &d = dr[x];
            const uint32_t da = d >> 24;
            if (sa == 255 || !da) { d = s; continue; }
            const uint32_t dw2 = da * (255 - sa);
            const uint32_t oa255 = sa * 255 + dw2;
            uint32_t o = 0;
            for (int sh8 = 0; sh8 < 24; sh8 += 8) {
                const uint32_t c = (((s >> sh8) & 255) * sa * 255 + ((d >> sh8) & 255) * dw2 + oa255 / 2) / oa255;
                o |= (c > 255 ? 255 : c) << sh8;
            }
            d = o | (((oa255 + 127) / 255) << 24);
        }
    }
}

#pragma GCC pop_options
#endif
