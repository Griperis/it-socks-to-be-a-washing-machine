#!/usr/bin/env bash
# The voice bake (core/84, docs/architecture/voice.md "The bake"): drop a wav in assets/voice/<speaker>/, run
# this, edit the line's entry in game/voice/lines/<speaker>.json, run it again. Headless; the designer and the
# agents run the same command (no editor entry, Q2639).
#
#   tools/voice_bake.sh                   every speaker folder
#   tools/voice_bake.sh --speaker=washer  one speaker
#   tools/voice_bake.sh --retranscribe    replace every line's text with a new transcription
#   tools/voice_bake.sh --no-transcribe   new lines get the text TODO (no faster-whisper needed)
#
# It imports first (a new wav, the string table), bakes (tools/voice_bake.gd), then imports again so the game
# sees the new string table. project.godot is put back after each import (the editor rewrites it).
# The last line is `PASS voice_bake ...` or `FAIL voice_bake ...`.
set -uo pipefail
cd "$(dirname "$0")/.."
. kit/tools/_root.sh; need_game; cd "$REPO" || exit 1
GODOT="${GODOT:-$("$KIT/tools/engine.sh" --path)}"
[ -x "$GODOT" ] || { echo "FAIL voice_bake: no engine at $GODOT -- run kit/tools/engine.sh --fetch" >&2; exit 2; }
LOG="${TMPDIR:-/tmp}/voice_bake.$$.log"

import() {
	local snap
	snap="$(mktemp)"
	cp project.godot "$snap"
	timeout "${IMPORT_TIMEOUT:-600}" "$GODOT" --headless --path . --import >"$LOG" 2>&1
	local code=$?
	cp "$snap" project.godot
	rm -f "$snap"
	if [ "$code" != 0 ] && [ "$code" != 134 ] && [ "$code" != 139 ]; then
		tail -5 "$LOG"
		echo "FAIL voice_bake: the import failed ($code; log $LOG)"
		exit 1
	fi
}

import
"$GODOT" --headless --audio-driver Dummy --path . --script res://tools/voice_bake.gd -- "$@" 2>&1 | grep -v '^Godot Engine' | tee "$LOG.bake"
code=${PIPESTATUS[0]}
grep -q '^PASS voice_bake' "$LOG.bake" || code=1
if [ "$code" = 0 ]; then
	import
fi
rm -f "$LOG" "$LOG.bake"
exit "$code"
