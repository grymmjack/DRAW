// DEV/mypaint/unit.cpp - the MyPaint engine glue without DRAW (PLANS/MYPAINT.md M2):
//   g++ -O2 -Inative -o /tmp/mp-unit DEV/mypaint/unit.cpp && /tmp/mp-unit BRUSH.myb OUT.ppm
// Paints an S stroke with rising pressure into a 256x160 transparent buffer, checks pixels
// changed and only near the stroke, saves / reloads the brush, writes a PPM over white.
#include "mypaint_draw.h"
int main(int argc, char **argv) {
    const char *brush = argc > 1 ? argv[1] : NULL, *out = argc > 2 ? argv[2] : NULL;
    int fails = 0;
    if (brush && !mp_load(brush)) { printf("FAIL load %s: %s\n", brush, mpd_err.c_str()); return 1; }
    mp_set_color(200, 40, 40);
    const int W = 256, H = 160;
    std::vector<uint32_t> px(W * H, 0);
    px[5] = 0x80123456u; // a lone half-transparent pixel far from the stroke: must survive exactly
    mp_stroke_begin((uintptr_t)px.data(), W, H, 0, 0, 0, 0, 0, 0);
    for (int i = 0; i <= 100; i++) {
        float t = i / 100.0f;
        mp_stroke_to(30 + t * 200, 80 + 40 * sinf(t * 6.28f), 0.2f + 0.8f * t, 0, 0, 0.01, 1.0f);
    }
    int x1, y1, x2, y2; mp_stroke_end(&x1, &y1, &x2, &y2);
    int painted = 0;
    for (uint32_t c : px) if (c >> 24) painted++;
    printf("box %d,%d - %d,%d  painted %d px  steps %d\n", x1, y1, x2, y2, painted, mpd_steps);
    if (x2 < x1 || painted < 200) { printf("FAIL nothing painted\n"); fails++; }
    if (px[5] != 0x80123456u) { printf("FAIL untouched pixel changed: %08x\n", px[5]); fails++; }
    // save -> reload -> same base values
    float r0 = mp_get_base(mp_setting_id("radius_logarithmic"));
    if (!mp_save("/tmp/mp-unit-save.myb")) { printf("FAIL save\n"); fails++; }
    mp_defaults();
    if (!mp_load("/tmp/mp-unit-save.myb")) { printf("FAIL reload: %s\n", mpd_err.c_str()); fails++; }
    float r1 = mp_get_base(mp_setting_id("radius_logarithmic"));
    if (fabsf(r0 - r1) > 1e-5f) { printf("FAIL radius %g -> %g\n", r0, r1); fails++; }
    // a selection mask: left half selected, right half not
    std::vector<uint32_t> px2(W * H, 0), mask(W * H, 0);
    for (int y = 0; y < H; y++) for (int x = 0; x < W / 2; x++) mask[y * W + x] = 0xFFFFFFFFu;
    mp_stroke_begin((uintptr_t)px2.data(), W, H, (uintptr_t)mask.data(), W, H, 0, 0, 0);
    for (int i = 0; i <= 50; i++) mp_stroke_to(20 + i * 4, 80, 0.8f, 0, 0, 0.01, 1.0f);
    mp_stroke_end(&x1, &y1, &x2, &y2);
    int right = 0, left = 0;
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) if (px2[y * W + x] >> 24) (x < W / 2 ? left : right)++;
    printf("masked stroke: left %d right %d\n", left, right);
    if (left == 0 || right != 0) { printf("FAIL mask\n"); fails++; }
    if (out) {
        FILE *f = fopen(out, "wb"); fprintf(f, "P6 %d %d 255\n", W, H);
        for (uint32_t c : px) { int a = c >> 24; unsigned char rgb[3];
            for (int k = 0; k < 3; k++) { int v = (c >> (16 - 8 * k)) & 255; rgb[k] = (unsigned char)((v * a + 255 * (255 - a)) / 255); }
            fwrite(rgb, 1, 3, f); }
        fclose(f);
    }
    printf(fails ? "UNIT FAIL (%d)\n" : "UNIT PASS\n", fails);
    return fails ? 1 : 0;
}
