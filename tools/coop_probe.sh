#!/usr/bin/env bash
# The co-op probe (coop/13): a Host and a Guest as two headless game processes on 127.0.0.1, as the
# designer's two windows, LAG ms one way on each end. The Guest throws, drops, and the Host pours SOCKS
# at the heap (tools/coop_probe.gd); tools/coop_probe.py compares what both machines showed.
#
#   tools/coop_probe.sh              0 ms, 200 Socks
#   LAG=50 SOCKS=300 tools/coop_probe.sh
set -uo pipefail
cd "$(dirname "$0")/.."
. kit/tools/_root.sh; need_game; cd "$REPO" || exit 1
source "$KIT/tools/_mirror.sh"
[ -x "$GODOT" ] || { echo "no engine at $GODOT -- run kit/tools/engine.sh --fetch" >&2; exit 2; }
MIRROR="${TMPDIR:-/tmp}/$PROJECT_SLUG-coop-probe-$$"
OUT="${OUT:-$MIRROR-logs}"
mkdir -p "$OUT"
rm -f "$OUT/go"
cleanup() { rm -rf "$MIRROR" "$MIRROR-user-host" "$MIRROR-user-guest"; }
trap cleanup EXIT
mirror_into "$REPO" "$MIRROR"
ensure_import "$REPO" "$MIRROR" "$GODOT" || exit 1
PORT="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
run() {
	local role="$1"; shift
	private_user_data "$MIRROR-user-$role"
	timeout "${LIMIT:-400}" "$GODOT" --headless --audio-driver Dummy --path "$MIRROR" res://tools/coop_probe.tscn -- \
		--role="$role" --port="$PORT" --lag="${LAG:-0}" --socks="${SOCKS:-200}" --flag="$OUT/go" "$@" > "$OUT/$role.log" 2>&1
}
run host &
HOST_PID=$!
sleep 3
run guest &
GUEST_PID=$!
wait "$HOST_PID"; h=$?
wait "$GUEST_PID"; g=$?
python3 "$REPO/tools/coop_probe.py" "$OUT/host.log" "$OUT/guest.log"
if [ "$h" = 0 ] && [ "$g" = 0 ]; then
	echo "PASS coop probe (logs: $OUT)"
else
	echo "FAIL coop probe: host exit $h, guest exit $g (logs: $OUT)"
	exit 1
fi
