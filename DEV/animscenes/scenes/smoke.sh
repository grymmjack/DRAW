# smoke - every Move Brush value, a drawn path, Z, the soundtrack
if open_scene smoke 24; then
    fg_pick 1 1 e43b44
    layer spin; pick 1 4 star
    mv 20 20 140 20 label="line + turn Z 360 + size 50>150" tz=360 s0=50 s1=150
    layer fade; pick 1 4 star
    mv 20 60 140 60 label="fade + tint to red, ease both" o0=100 o1=20 t0=0 t1=100 ease=3 every=2
    layer z; pick 1 4 star
    mv 80 100 80 100 label="Z away + turn X/Y, frames 5-16" z=600 tx=180 ty=90 from=5 count=12
    layer drawn; pick 1 4 star
    mv 0 0 0 0 label="drawn arc" path=drawn pts="10,110 30,90 50,80 70,78 90,80 110,90 130,110"
    sound_drop "$ANS_DIR/smoke-music.wav"
    sound_drop "$ANS_DIR/smoke-sfx.wav"
    finish_scene smoke
fi
