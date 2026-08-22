#ifndef GJ_BLUR_KERNEL_H
#define GJ_BLUR_KERNEL_H
#include <cstdint>
// Box blur — matches GUI/IMGADJ.BM GJ_IMGADJ_Blur exactly: for each pixel, average the
// RGB of the (2r+1)^2 neighborhood clamped to image bounds; alpha forced opaque (the
// BASIC version wrote _RGB32(r,g,b), i.e. 0xFF alpha). Buffers are QB64 32-bit ARGB,
// row-major, dst != src. This is the hot loop, moved out of the -O0 program TU.
// dst_/src_ arrive as QB64 _OFFSET (intptr_t / ptrszint); cast to pixel pointers here.
#pragma GCC push_options
#pragma GCC optimize ("O3")
extern "C" void gj_box_blur(intptr_t dst_, intptr_t src_,
                            int32_t w, int32_t h, int32_t radius) {
    uint32_t *dst = reinterpret_cast<uint32_t *>(dst_);
    const uint32_t *src = reinterpret_cast<const uint32_t *>(src_);
    for (int32_t y = 0; y < h; ++y) {
        int32_t y0 = y - radius < 0 ? 0 : y - radius;
        int32_t y1 = y + radius >= h ? h - 1 : y + radius;
        for (int32_t x = 0; x < w; ++x) {
            int32_t x0 = x - radius < 0 ? 0 : x - radius;
            int32_t x1 = x + radius >= w ? w - 1 : x + radius;
            uint32_t r = 0, g = 0, b = 0, count = 0;
            for (int32_t sy = y0; sy <= y1; ++sy) {
                const uint32_t *row = src + (int64_t)sy * w;
                for (int32_t sx = x0; sx <= x1; ++sx) {
                    uint32_t p = row[sx];
                    r += (p >> 16) & 0xFFu;
                    g += (p >> 8) & 0xFFu;
                    b += p & 0xFFu;
                    ++count;
                }
            }
            r /= count; g /= count; b /= count;      // count >= 1 always
            dst[(int64_t)y * w + x] = 0xFF000000u | (r << 16) | (g << 8) | b;
        }
    }
}
#pragma GCC pop_options
#endif
