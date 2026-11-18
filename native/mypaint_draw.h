// DRAW - native/mypaint_draw.h
// MyPaint brushes for DRAW (PLANS/MYPAINT.md): libmypaint (ISC, vendored in native/mypaint by
// DEV/mypaint/vendor.sh) painting straight into a DRAW layer buffer.
//
//  - one brush (mp_load / mp_save .myb v3 JSON, mp_set_base / mp_get_base, mp_set_color)
//  - a stroke on one layer: mp_stroke_begin (its pixels, size, the selection mask, the apron
//    offset, opacity lock) -> mp_stroke_to per pointer event -> mp_stroke_end (the changed box)
//  - the surface hands out 64x64 tiles lazily: a tile's first request converts that part of the
//    layer (8-bit straight BGRA, as QB64 stores 32-bit images) into libmypaint's 15-bit
//    premultiplied RGBA; when a writable request ends the tile goes back into the layer. A pixel
//    whose 15-bit value did not change keeps its original 8-bit value (no round-trip drift), a
//    soft selection blends by its coverage, an opacity lock keeps the old alpha.
#ifndef DRAW_MYPAINT_DRAW_H
#define DRAW_MYPAINT_DRAW_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <string>
#include <vector>
#include <unordered_map>

// ---- the vendored engine, one unit (C compiled as C++; see DEV/mypaint/patch.py) ----
#include "mypaint/mypaint-rectangle.c"
#include "mypaint/helpers.c"
#include "mypaint/rng-double.c"
#include "mypaint/mypaint-mapping.c"
#include "mypaint/mypaint-brush-settings.c"
#include "mypaint/mypaint-surface.c"
#include "mypaint/mypaint-matrix.c"
#include "mypaint/mypaint-symmetry.c"
#include "mypaint/brushmodes.c"
#include "mypaint/fifo.c"
#include "mypaint/tilemap.c"
#include "mypaint/operationqueue.c"
#include "mypaint/mypaint-tiled-surface.c"
#include "mypaint/mypaint-brush.c"
#include "mypaint/mypaint.c"

#define MPD_T MYPAINT_TILE_SIZE
#define MPD_ONE 32768u

struct MpdTile {
    uint16_t px[MPD_T * MPD_T * 4];   // what the engine paints (fix15 premultiplied RGBA)
    uint16_t base[MPD_T * MPD_T * 4]; // the layer as first converted
    uint32_t orig[MPD_T * MPD_T];     // the layer's 8-bit pixels at the stroke's start (0 = off the layer)
};

struct MpdSurface {
    MyPaintTiledSurface2 parent;
};

static MyPaintBrush *mpd_brush = NULL;
static MpdSurface mpd_surf;
static int mpd_surf_ok = 0;
static std::unordered_map<int64_t, MpdTile *> mpd_tiles;
static uint16_t mpd_null_tile[MPD_T * MPD_T * 4];

// the stroke's target
static uint32_t *mpd_px = NULL;  // layer pixels (BGRA in memory = 0xAARRGGBB little-endian)
static int mpd_w = 0, mpd_h = 0;
static const uint32_t *mpd_mask = NULL; // selection mask (canvas size) or NULL
static int mpd_mw = 0, mpd_mh = 0, mpd_ox = 0, mpd_oy = 0; // mask size; buffer = canvas + (ox, oy)
static int mpd_lock = 0;       // opacity lock: keep alpha, never paint on transparent
static int mpd_x1, mpd_y1, mpd_x2, mpd_y2; // changed box (buffer px), x1 > x2 = none
static int mpd_steps = 0;      // stroke_to calls this stroke
static std::string mpd_err;
static std::string mpd_meta_desc, mpd_meta_notes, mpd_meta_parent, mpd_meta_group, mpd_meta_comment;

static inline int64_t mpd_key(int tx, int ty) { return ((int64_t)ty << 32) ^ (uint32_t)tx; }

static inline void mpd_to15(uint32_t c, uint16_t *o) {
    uint32_t a8 = c >> 24, r8 = (c >> 16) & 255, g8 = (c >> 8) & 255, b8 = c & 255;
    uint32_t a = (a8 * MPD_ONE + 127) / 255;
    o[0] = (uint16_t)((r8 * a + 127) / 255);
    o[1] = (uint16_t)((g8 * a + 127) / 255);
    o[2] = (uint16_t)((b8 * a + 127) / 255);
    o[3] = (uint16_t)a;
}

static inline uint32_t mpd_from15(const uint16_t *p) {
    uint32_t a = p[3];
    if (a == 0) return 0;
    if (a > MPD_ONE) a = MPD_ONE;
    uint32_t a8 = (a * 255 + MPD_ONE / 2) >> 15;
    if (a8 == 0) return 0;
    uint32_t r = ((uint32_t)p[0] * 255 + a / 2) / a; if (r > 255) r = 255;
    uint32_t g = ((uint32_t)p[1] * 255 + a / 2) / a; if (g > 255) g = 255;
    uint32_t b = ((uint32_t)p[2] * 255 + a / 2) / a; if (b > 255) b = 255;
    return (a8 << 24) | (r << 16) | (g << 8) | b;
}

static inline int mpd_cover(int bx, int by) {
    if (!mpd_mask) return 255;
    int cx = bx - mpd_ox, cy = by - mpd_oy;
    if (cx < 0 || cy < 0 || cx >= mpd_mw || cy >= mpd_mh) return 0;
    uint32_t m = mpd_mask[(size_t)cy * mpd_mw + cx];
    if ((m & 0xFFFFFFu) != 0xFFFFFFu) return 0;
    return (int)(m >> 24);
}

static MpdTile *mpd_tile_get(int tx, int ty) {
    int64_t k = mpd_key(tx, ty);
    auto it = mpd_tiles.find(k);
    if (it != mpd_tiles.end()) return it->second;
    MpdTile *t = (MpdTile *)malloc(sizeof(MpdTile));
    if (!t) return NULL;
    for (int y = 0; y < MPD_T; y++) {
        int by = ty * MPD_T + y;
        for (int x = 0; x < MPD_T; x++) {
            int bx = tx * MPD_T + x, i = y * MPD_T + x;
            uint32_t c = 0;
            if (mpd_px && bx >= 0 && by >= 0 && bx < mpd_w && by < mpd_h) c = mpd_px[(size_t)by * mpd_w + bx];
            t->orig[i] = c;
            mpd_to15(c, &t->base[i * 4]);
        }
    }
    memcpy(t->px, t->base, sizeof(t->px));
    mpd_tiles[k] = t;
    return t;
}

// the tile's pixels back into the layer
static void mpd_tile_put(int tx, int ty, MpdTile *t) {
    if (!mpd_px) return;
    for (int y = 0; y < MPD_T; y++) {
        int by = ty * MPD_T + y;
        if (by < 0 || by >= mpd_h) continue;
        for (int x = 0; x < MPD_T; x++) {
            int bx = tx * MPD_T + x;
            if (bx < 0 || bx >= mpd_w) continue;
            int i = y * MPD_T + x;
            const uint16_t *p = &t->px[i * 4], *b = &t->base[i * 4];
            uint32_t o = t->orig[i], c;
            if (p[0] == b[0] && p[1] == b[1] && p[2] == b[2] && p[3] == b[3]) {
                c = o;
            } else {
                c = mpd_from15(p);
                int cov = mpd_cover(bx, by);
                if (cov <= 0) c = o;
                else if (cov < 255) {
                    uint32_t r = 0;
                    for (int sh = 0; sh < 32; sh += 8) {
                        int co = (o >> sh) & 255, cn = (c >> sh) & 255;
                        r |= (uint32_t)(co + ((cn - co) * cov) / 255) << sh;
                    }
                    c = r;
                }
                if (mpd_lock) c = ((o >> 24) == 0) ? o : ((o & 0xFF000000u) | (c & 0xFFFFFFu));
            }
            uint32_t *d = &mpd_px[(size_t)by * mpd_w + bx];
            if (*d != c) {
                *d = c;
                if (bx < mpd_x1) mpd_x1 = bx;
                if (by < mpd_y1) mpd_y1 = by;
                if (bx > mpd_x2) mpd_x2 = bx;
                if (by > mpd_y2) mpd_y2 = by;
            }
        }
    }
}

static void mpd_req_start(MyPaintTiledSurface2 *s, MyPaintTileRequest *r) {
    (void)s;
    MpdTile *t = mpd_px ? mpd_tile_get(r->tx, r->ty) : NULL;
    if (!t) { memset(mpd_null_tile, 0, sizeof(mpd_null_tile)); r->buffer = mpd_null_tile; return; }
    r->buffer = t->px;
}

static void mpd_req_end(MyPaintTiledSurface2 *s, MyPaintTileRequest *r) {
    (void)s;
    if (r->readonly || !mpd_px) return;
    auto it = mpd_tiles.find(mpd_key(r->tx, r->ty));
    if (it != mpd_tiles.end()) mpd_tile_put(r->tx, r->ty, it->second);
}

static void mpd_tiles_free(void) {
    for (auto &kv : mpd_tiles) free(kv.second);
    mpd_tiles.clear();
}

static void mpd_ensure(void) {
    if (!mpd_brush) {
        mpd_brush = mypaint_brush_new();
        mypaint_brush_from_defaults(mpd_brush);
    }
    if (!mpd_surf_ok) {
        memset(&mpd_surf, 0, sizeof(mpd_surf));
        mypaint_tiled_surface2_init(&mpd_surf.parent, mpd_req_start, mpd_req_end);
        mpd_surf_ok = 1;
    }
}

// ---------------------------------------------------------------- .myb (JSON) reading
struct MpdJ { // a tiny JSON value
    int kind = 0; // 0 null, 1 number, 2 string, 3 array, 4 object, 5 bool
    double num = 0;
    std::string str;
    std::vector<MpdJ> items;
    std::vector<std::string> keys;
    const MpdJ *get(const char *k) const {
        for (size_t i = 0; i < keys.size(); i++) if (keys[i] == k) return &items[i];
        return NULL;
    }
};

struct MpdParser {
    const char *s; size_t i, n; bool bad = false;
    void ws() { while (i < n && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) i++; }
    bool str(std::string &out) {
        if (i >= n || s[i] != '"') return false;
        i++;
        while (i < n && s[i] != '"') {
            char c = s[i++];
            if (c == '\\' && i < n) {
                char e = s[i++];
                switch (e) {
                    case 'n': out += '\n'; break; case 't': out += '\t'; break;
                    case 'r': out += '\r'; break; case 'b': out += '\b'; break; case 'f': out += '\f'; break;
                    case 'u': { // keep ASCII, drop the rest
                        unsigned v = 0;
                        for (int k = 0; k < 4 && i < n; k++, i++) {
                            char h = s[i]; v <<= 4;
                            v |= (h >= '0' && h <= '9') ? h - '0' : ((h | 32) >= 'a' && (h | 32) <= 'f') ? (h | 32) - 'a' + 10 : 0;
                        }
                        out += (v < 128) ? (char)v : '?';
                        break;
                    }
                    default: out += e;
                }
            } else out += c;
        }
        if (i >= n) return false;
        i++;
        return true;
    }
    bool val(MpdJ &v, int depth) {
        if (depth > 32) return false;
        ws();
        if (i >= n) return false;
        char c = s[i];
        if (c == '{') {
            v.kind = 4; i++; ws();
            if (i < n && s[i] == '}') { i++; return true; }
            for (;;) {
                ws(); std::string k;
                if (!str(k)) return false;
                ws(); if (i >= n || s[i] != ':') return false; i++;
                MpdJ x; if (!val(x, depth + 1)) return false;
                v.keys.push_back(k); v.items.push_back(x);
                ws(); if (i < n && s[i] == ',') { i++; continue; }
                if (i < n && s[i] == '}') { i++; return true; }
                return false;
            }
        }
        if (c == '[') {
            v.kind = 3; i++; ws();
            if (i < n && s[i] == ']') { i++; return true; }
            for (;;) {
                MpdJ x; if (!val(x, depth + 1)) return false;
                v.items.push_back(x);
                ws(); if (i < n && s[i] == ',') { i++; continue; }
                if (i < n && s[i] == ']') { i++; return true; }
                return false;
            }
        }
        if (c == '"') { v.kind = 2; return str(v.str); }
        if (!strncmp(s + i, "true", 4)) { v.kind = 5; v.num = 1; i += 4; return true; }
        if (!strncmp(s + i, "false", 5)) { v.kind = 5; v.num = 0; i += 5; return true; }
        if (!strncmp(s + i, "null", 4)) { v.kind = 0; i += 4; return true; }
        char *end = NULL;
        v.num = strtod(s + i, &end);
        if (end == s + i) return false;
        v.kind = 1; i = (size_t)(end - s);
        return true;
    }
};

static std::string mpd_read_file(const char *path) {
    std::string out;
    FILE *f = fopen(path, "rb");
    if (!f) return out;
    char buf[65536]; size_t k;
    while ((k = fread(buf, 1, sizeof(buf), f)) > 0) out.append(buf, k);
    fclose(f);
    return out;
}

// Parse a .myb (version 3 JSON) into the current brush. 1 = loaded, 0 = failed (mp_error$).
static int mpd_load_string(const std::string &text) {
    mpd_ensure();
    MpdParser p; p.s = text.c_str(); p.i = 0; p.n = text.size();
    MpdJ root;
    if (!p.val(root, 0) || root.kind != 4) { mpd_err = "not a JSON .myb (MyPaint 1.x text brushes are not supported)"; return 0; }
    const MpdJ *ver = root.get("version");
    if (ver && ver->kind == 1 && ver->num > 3) { mpd_err = "a newer .myb version"; return 0; }
    const MpdJ *settings = root.get("settings");
    if (!settings || settings->kind != 4) { mpd_err = "no settings"; return 0; }
    mypaint_brush_from_defaults(mpd_brush);
    for (size_t k = 0; k < settings->keys.size(); k++) {
        MyPaintBrushSetting id = mypaint_brush_setting_from_cname(settings->keys[k].c_str());
        if ((int)id < 0) continue; // a setting this engine does not know: skip, as MyPaint does
        const MpdJ &so = settings->items[k];
        if (so.kind != 4) continue;
        const MpdJ *bv = so.get("base_value");
        if (bv && bv->kind == 1) mypaint_brush_set_base_value(mpd_brush, id, (float)bv->num);
        const MpdJ *ins = so.get("inputs");
        if (!ins || ins->kind != 4) continue;
        for (size_t j = 0; j < ins->keys.size(); j++) {
            MyPaintBrushInput in = mypaint_brush_input_from_cname(ins->keys[j].c_str());
            if ((int)in < 0) continue;
            const MpdJ &pts = ins->items[j];
            if (pts.kind != 3) continue;
            int np = (int)pts.items.size();
            if (np > 64) np = 64;
            int ok = 0;
            for (int q = 0; q < np; q++) {
                const MpdJ &pt = pts.items[q];
                if (pt.kind == 3 && pt.items.size() >= 2 && pt.items[0].kind == 1 && pt.items[1].kind == 1) ok++;
            }
            mypaint_brush_set_mapping_n(mpd_brush, id, in, ok);
            int w = 0;
            for (int q = 0; q < np; q++) {
                const MpdJ &pt = pts.items[q];
                if (pt.kind == 3 && pt.items.size() >= 2 && pt.items[0].kind == 1 && pt.items[1].kind == 1)
                    mypaint_brush_set_mapping_point(mpd_brush, id, in, w++, (float)pt.items[0].num, (float)pt.items[1].num);
            }
        }
    }
    const MpdJ *x;
    mpd_meta_desc = ((x = root.get("description")) && x->kind == 2) ? x->str : "";
    mpd_meta_notes = ((x = root.get("notes")) && x->kind == 2) ? x->str : "";
    mpd_meta_parent = ((x = root.get("parent_brush_name")) && x->kind == 2) ? x->str : "";
    mpd_meta_group = ((x = root.get("group")) && x->kind == 2) ? x->str : "";
    mpd_meta_comment = ((x = root.get("comment")) && x->kind == 2) ? x->str : "";
    mypaint_brush_new_stroke(mpd_brush);
    mpd_err.clear();
    return 1;
}

static void mpd_json_str(std::string &o, const std::string &s) {
    o += '"';
    for (char c : s) {
        if (c == '"' || c == '\\') { o += '\\'; o += c; }
        else if (c == '\n') o += "\\n";
        else if (c == '\t') o += "\\t";
        else if ((unsigned char)c < 32) o += ' ';
        else o += c;
    }
    o += '"';
}

// The current brush as .myb version 3 JSON (every setting, as MyPaint writes them).
static std::string mpd_save_string(void) {
    mpd_ensure();
    std::string o = "{\n";
    char buf[96];
    o += "    \"comment\": "; mpd_json_str(o, mpd_meta_comment.empty() ? std::string("MyPaint brush file (saved by DRAW)") : mpd_meta_comment); o += ",\n";
    o += "    \"description\": "; mpd_json_str(o, mpd_meta_desc); o += ",\n";
    o += "    \"group\": "; mpd_json_str(o, mpd_meta_group); o += ",\n";
    o += "    \"notes\": "; mpd_json_str(o, mpd_meta_notes); o += ",\n";
    o += "    \"parent_brush_name\": "; mpd_json_str(o, mpd_meta_parent); o += ",\n";
    o += "    \"settings\": {\n";
    for (int s = 0; s < MYPAINT_BRUSH_SETTINGS_COUNT; s++) {
        MyPaintBrushSetting id = (MyPaintBrushSetting)s;
        const MyPaintBrushSettingInfo *info = mypaint_brush_setting_info(id);
        o += "        "; mpd_json_str(o, info->cname); o += ": {\n";
        snprintf(buf, sizeof(buf), "%.9g", (double)mypaint_brush_get_base_value(mpd_brush, id));
        o += "            \"base_value\": "; o += buf; o += ",\n";
        o += "            \"inputs\": {";
        int first = 1;
        for (int i = 0; i < MYPAINT_BRUSH_INPUTS_COUNT; i++) {
            MyPaintBrushInput in = (MyPaintBrushInput)i;
            int n = mypaint_brush_get_mapping_n(mpd_brush, id, in);
            if (n <= 0) continue;
            o += first ? "\n" : ",\n"; first = 0;
            o += "                "; mpd_json_str(o, mypaint_brush_input_info(in)->cname); o += ": [";
            for (int q = 0; q < n; q++) {
                float px, py;
                mypaint_brush_get_mapping_point(mpd_brush, id, in, q, &px, &py);
                snprintf(buf, sizeof(buf), "%s[%.9g, %.9g]", q ? ", " : "", (double)px, (double)py);
                o += buf;
            }
            o += "]";
        }
        o += first ? "}\n" : "\n            }\n";
        o += (s + 1 < MYPAINT_BRUSH_SETTINGS_COUNT) ? "        },\n" : "        }\n";
    }
    o += "    },\n    \"version\": 3\n}\n";
    return o;
}

// ---------------------------------------------------------------- entry points (QB64)
// Strings come in from BASIC NUL-terminated (path$ + CHR$(0)).

int32_t mp_load(const char *path) {
    std::string t = mpd_read_file(path);
    if (t.empty()) { mpd_err = "cannot read the file"; return 0; }
    return mpd_load_string(t);
}

int32_t mp_save(const char *path) {
    std::string t = mpd_save_string();
    FILE *f = fopen(path, "wb");
    if (!f) { mpd_err = "cannot write the file"; return 0; }
    size_t k = fwrite(t.data(), 1, t.size(), f);
    fclose(f);
    if (k != t.size()) { mpd_err = "write failed"; return 0; }
    return 1;
}

void mp_defaults(void) { mpd_ensure(); mypaint_brush_from_defaults(mpd_brush); mypaint_brush_new_stroke(mpd_brush); }

// the last error, copied into buf (cap bytes, NUL-terminated)
void mp_error(char *buf, int32_t cap) {
    if (cap <= 0) return;
    strncpy(buf, mpd_err.c_str(), (size_t)cap - 1);
    buf[cap - 1] = 0;
}

int32_t mp_setting_id(const char *cname) { return (int32_t)mypaint_brush_setting_from_cname(cname); }
int32_t mp_setting_count(void) { return MYPAINT_BRUSH_SETTINGS_COUNT; }
float mp_get_base(int32_t id) {
    mpd_ensure();
    if (id < 0 || id >= MYPAINT_BRUSH_SETTINGS_COUNT) return 0;
    return mypaint_brush_get_base_value(mpd_brush, (MyPaintBrushSetting)id);
}
void mp_set_base(int32_t id, float v) {
    mpd_ensure();
    if (id < 0 || id >= MYPAINT_BRUSH_SETTINGS_COUNT) return;
    mypaint_brush_set_base_value(mpd_brush, (MyPaintBrushSetting)id, v);
}
// 1 = the setting has an input curve (not a constant)
int32_t mp_setting_dynamic(int32_t id) {
    mpd_ensure();
    if (id < 0 || id >= MYPAINT_BRUSH_SETTINGS_COUNT) return 0;
    return mypaint_brush_is_constant(mpd_brush, (MyPaintBrushSetting)id) ? 0 : 1;
}

// The paint colour (0..255 RGB) -> the brush's COLOR_H / S / V.
void mp_set_color(int32_t r, int32_t g, int32_t b) {
    mpd_ensure();
    float fr = r / 255.0f, fg = g / 255.0f, fb = b / 255.0f;
    float mx = fmaxf(fr, fmaxf(fg, fb)), mn = fminf(fr, fminf(fg, fb)), d = mx - mn;
    float h = 0, s = (mx > 0) ? d / mx : 0, v = mx;
    if (d > 0) {
        if (mx == fr) h = fmodf((fg - fb) / d, 6.0f);
        else if (mx == fg) h = (fb - fr) / d + 2.0f;
        else h = (fr - fg) / d + 4.0f;
        h /= 6.0f; if (h < 0) h += 1.0f;
    }
    mypaint_brush_set_base_value(mpd_brush, MYPAINT_BRUSH_SETTING_COLOR_H, h);
    mypaint_brush_set_base_value(mpd_brush, MYPAINT_BRUSH_SETTING_COLOR_S, s);
    mypaint_brush_set_base_value(mpd_brush, MYPAINT_BRUSH_SETTING_COLOR_V, v);
}

// Start a stroke on a layer: px = its pixels (w x h, 32-bit), mask = the selection mask
// (mw x mh, canvas size) or 0, (ox, oy) = the layer's apron (buffer = canvas + ox / oy),
// lock = the opacity lock.
void mp_stroke_begin(uintptr_t px, int32_t w, int32_t h, uintptr_t mask, int32_t mw, int32_t mh, int32_t ox, int32_t oy, int32_t lock) {
    mpd_ensure();
    mpd_tiles_free();
    mpd_px = (uint32_t *)px; mpd_w = w; mpd_h = h;
    mpd_mask = (const uint32_t *)mask; mpd_mw = mw; mpd_mh = mh;
    mpd_ox = ox; mpd_oy = oy; mpd_lock = lock ? 1 : 0;
    mpd_x1 = mpd_y1 = 0x7fffffff; mpd_x2 = mpd_y2 = -1;
    mpd_steps = 0;
    mypaint_brush_reset(mpd_brush);
    mypaint_brush_new_stroke(mpd_brush);
}

// The pen's barrel rotation for every event, in turns (0..1) - the MyPaint Brush
// Settings panel's TWIST (GUI/MYPAINT-SET), a stand-in for a pen that has none.
static float mpd_twist = 0.0f;
void mp_set_twist(float turns) {
    turns = turns - (float)(int)turns; if (turns < 0) turns += 1.0f;
    mpd_twist = turns;
}

// One pointer event at buffer (x, y). dtime in seconds since the last; zoom = the view's.
// Returns 1 when the engine split the stroke (MyPaint's own idea; harmless).
int32_t mp_stroke_to(float x, float y, float pressure, float xtilt, float ytilt, double dtime, float zoom) {
    if (!mpd_px) return 0;
    if (dtime <= 0) dtime = 0.0001;
    mypaint_surface_begin_atomic((MyPaintSurface *)&mpd_surf.parent);
    int r = mypaint_brush_stroke_to_2(mpd_brush, (MyPaintSurface2 *)&mpd_surf.parent, x, y, pressure, xtilt, ytilt, dtime, zoom, 0.0f, mpd_twist);
    MyPaintRectangle one; MyPaintRectangles rr; rr.num_rectangles = 1; rr.rectangles = &one;
    mypaint_surface2_end_atomic((MyPaintSurface2 *)&mpd_surf.parent, &rr);
    mpd_steps++;
    return r;
}

// End the stroke: the changed box in buffer px (x1 > x2 = nothing changed). Frees the tiles.
void mp_stroke_end(int32_t *x1, int32_t *y1, int32_t *x2, int32_t *y2) {
    *x1 = mpd_x1; *y1 = mpd_y1; *x2 = mpd_x2; *y2 = mpd_y2;
    if (mpd_x2 < 0) { *x1 = 1; *x2 = 0; *y1 = 1; *y2 = 0; }
    mpd_tiles_free();
    mpd_px = NULL; mpd_mask = NULL;
}

// the box changed so far this stroke (live redraw) - same convention as mp_stroke_end
void mp_stroke_box(int32_t *x1, int32_t *y1, int32_t *x2, int32_t *y2) {
    *x1 = mpd_x1; *y1 = mpd_y1; *x2 = mpd_x2; *y2 = mpd_y2;
    if (mpd_x2 < 0) { *x1 = 1; *x2 = 0; *y1 = 1; *y2 = 0; }
}

int32_t mp_stroke_steps(void) { return mpd_steps; }

// The palette's thumbnails: an area-average resample of a 32-bit image (src sw x sh) into dst
// (dw x dh) - every source pixel counts by the part of it each destination pixel covers, so a
// 128 -> 45 shrink is smooth, not a pick of every 3rd pixel. Premultiplied, so transparent
// pixels add no dark fringe. (Meant for shrinking: growing gives near-nearest-neighbour.)
void mp_resample_area(intptr_t dst_, int32_t dw, int32_t dh, intptr_t src_, int32_t sw, int32_t sh) {
    const uint32_t *src = (const uint32_t *)src_;
    uint32_t *dst = (uint32_t *)dst_;
    if (!src || !dst || dw < 1 || dh < 1 || sw < 1 || sh < 1) return;
    const double fx = (double)sw / dw, fy = (double)sh / dh;
    for (int32_t y = 0; y < dh; y++) {
        const double y0 = y * fy, y1 = (y + 1) * fy;
        for (int32_t x = 0; x < dw; x++) {
            const double x0 = x * fx, x1 = (x + 1) * fx;
            double a = 0, r = 0, g = 0, b = 0, wsum = 0;
            for (int32_t sy = (int32_t)y0; sy < sh && sy < y1; sy++) {
                const double wy = (sy + 1 < y1 ? sy + 1 : y1) - (sy > y0 ? sy : y0);
                if (wy <= 0) continue;
                const uint32_t *row = src + (size_t)sy * sw;
                for (int32_t sx = (int32_t)x0; sx < sw && sx < x1; sx++) {
                    const double wx = (sx + 1 < x1 ? sx + 1 : x1) - (sx > x0 ? sx : x0);
                    if (wx <= 0) continue;
                    const double w = wx * wy;
                    const uint32_t p = row[sx];
                    const double pa = ((p >> 24) & 255) * w;
                    a += pa;
                    r += ((p >> 16) & 255) * pa; g += ((p >> 8) & 255) * pa; b += (p & 255) * pa;
                    wsum += w;
                }
            }
            uint32_t out = 0;
            if (a > 0 && wsum > 0) {
                int32_t oa = (int32_t)(a / wsum + 0.5), orr = (int32_t)(r / a + 0.5), og = (int32_t)(g / a + 0.5), ob = (int32_t)(b / a + 0.5);
                if (oa > 255) oa = 255; if (orr > 255) orr = 255; if (og > 255) og = 255; if (ob > 255) ob = 255;
                out = ((uint32_t)oa << 24) | ((uint32_t)orr << 16) | ((uint32_t)og << 8) | (uint32_t)ob;
            }
            dst[(size_t)y * dw + x] = out;
        }
    }
}

#endif // DRAW_MYPAINT_DRAW_H
