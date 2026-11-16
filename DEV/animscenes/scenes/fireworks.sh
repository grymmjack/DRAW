# fireworks - see fireworks.py (it writes moves.sh).
if open_scene fireworks 60; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/fireworks-music.wav"
    sound_drop "$ANS_DIR/fireworks-sfx.wav"
    finish_scene fireworks
fi
