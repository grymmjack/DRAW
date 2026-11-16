# stormy-night - the extra credit pack's sampler. See stormy-night.py (it writes moves.sh).
if open_scene stormy-night 48; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/stormy-night-music.wav"
    sound_drop "$ANS_DIR/stormy-night-sfx.wav"
    finish_scene stormy-night
fi
