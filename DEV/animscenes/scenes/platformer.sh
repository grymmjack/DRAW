# platformer - see platformer.py (it writes moves.sh).
if open_scene platformer 60; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/platformer-music.wav"
    sound_drop "$ANS_DIR/platformer-sfx.wav"
    finish_scene platformer
fi
