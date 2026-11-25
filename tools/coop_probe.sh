#!/usr/bin/env bash
# The co-op probe (coop/13): a Host and a Guest as two headless game processes on 127.0.0.1, as the
# designer's two windows, LAG ms one way on each end. The Guest throws, drops, and the Host pours SOCKS
# at the heap (tools/coop_probe.gd); tools/coop_probe.py compares what both machines showed.
#
#   tools/coop_probe.sh              0 ms, 200 Socks
#   LAG=50 SOCKS=300 tools/coop_probe.sh
#   CASE=flight LAG=50 GUEST_FPS=144 tools/coop_probe.sh   coop/14: Throws, a drop and knocked Socks,
#                                                          drawn each frame on both (S lines)
#   UNEVEN=1 ...                                           each frame's cap drawn between 30 and the fps
#   SHOTS=<dir> CASE=flight ...                            rendered (Xvfb): both machines shoot the Host's
#                                                          Throw and drop from one camera into <dir>
set -uo pipefail
cd "$(dirname "$0")/.."
. kit/tools/_root.sh; need_game; cd "$REPO" || exit 1
source "$KIT/tools/_mirror.sh"
[ -x "$GODOT" ] || { echo "no engine at $GODOT -- run kit/tools/engine.sh --fetch" >&2; exit 2; }
MIRROR="${TMPDIR:-/tmp}/$PROJECT_SLUG-coop-probe-$$"
OUT="${OUT:-$MIRROR-logs}"
mkdir -p "$OUT"
rm -f "$OUT/go" "$OUT/go.done"
cleanup() { rm -rf "$MIRROR" "$MIRROR-user-host" "$MIRROR-user-guest"; }
trap cleanup EXIT
mirror_into "$REPO" "$MIRROR"
ensure_import "$REPO" "$MIRROR" "$GODOT" || exit 1
PORT="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
run() {
	local role="$1"; shift
	local fps="${HOST_FPS:-60}"
	[ "$role" = guest ] && fps="${GUEST_FPS:-60}"
	private_user_data "$MIRROR-user-$role"
	local engine=("$GODOT" --headless)
	if [ -n "${SHOTS:-}" ]; then
		mkdir -p "$SHOTS"
		engine=(xvfb-run -a -s "-screen 0 960x540x24" "$GODOT" --rendering-driver "$(render_driver "$MIRROR")" --resolution 960x540)
	fi
	timeout "${LIMIT:-400}" "${engine[@]}" --audio-driver Dummy --path "$MIRROR" res://tools/coop_probe.tscn -- \
		--role="$role" --port="$PORT" --lag="${LAG:-0}" --socks="${SOCKS:-200}" --flag="$OUT/go" --case="${CASE:-}" --fps="$fps" \
		${UNEVEN:+--uneven} ${SHOTS:+--shots="$SHOTS"} "$@" > "$OUT/$role.log" 2>&1
}
run host &
HOST_PID=$!
sleep 3
run guest &
GUEST_PID=$!
wait "$HOST_PID"; h=$?
wait "$GUEST_PID"; g=$?
rm -f "$OUT/go" "$OUT/go.done" "$OUT/go.cam"
python3 "$REPO/tools/coop_probe.py" "$OUT/host.log" "$OUT/guest.log"
if [ "$h" = 0 ] && [ "$g" = 0 ]; then
	echo "PASS coop probe (logs: $OUT)"
else
	echo "FAIL coop probe: host exit $h, guest exit $g (logs: $OUT)"
	exit 1
fi
