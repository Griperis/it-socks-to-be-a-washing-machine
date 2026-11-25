#!/usr/bin/env bash
# The co-op cost (coop/12): a Host and a Guest as two headless game processes on 127.0.0.1, the Host
# pouring 2,000 Socks at the zoo's heap station (tools/coop_cost.gd). Prints each machine's COST lines:
# bytes a second each way and its frame time (process plus physics, no drawing), while the pour falls
# and at rest after. Runs in a mirror of its own with private user data per process.
#
#   tools/coop_cost.sh                 2,000 Socks, 5 s at rest
#   SOCKS=500 REST=10 tools/coop_cost.sh
#
# The numbers are this machine's CPU; the designer's two windows are the reference.
set -uo pipefail
cd "$(dirname "$0")/.."
. kit/tools/_root.sh; need_game; cd "$REPO" || exit 1
source "$KIT/tools/_mirror.sh"
[ -x "$GODOT" ] || { echo "no engine at $GODOT -- run kit/tools/engine.sh --fetch" >&2; exit 2; }
MIRROR="${TMPDIR:-/tmp}/$PROJECT_SLUG-coop-cost"
OUT="${OUT:-$MIRROR-logs}"
mkdir -p "$OUT"
cleanup() { rm -rf "$MIRROR" "$MIRROR-user-host" "$MIRROR-user-guest"; }
trap cleanup EXIT
mirror_into "$REPO" "$MIRROR"
ensure_import "$REPO" "$MIRROR" "$GODOT" || exit 1
# A free UDP port for the Host.
PORT="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
run() {
	local role="$1"; shift
	private_user_data "$MIRROR-user-$role"
	timeout "${LIMIT:-600}" "$GODOT" --headless --audio-driver Dummy --path "$MIRROR" res://tools/coop_cost.tscn -- \
		--role="$role" --port="$PORT" --socks="${SOCKS:-2000}" --rest="${REST:-5}" "$@" > "$OUT/$role.log" 2>&1
}
run host &
HOST_PID=$!
sleep 3
run guest &
GUEST_PID=$!
wait "$HOST_PID"; h=$?
wait "$GUEST_PID"; g=$?
grep -hE '^COST|SCRIPT ERROR' "$OUT/host.log" "$OUT/guest.log"
if [ "$h" = 0 ] && [ "$g" = 0 ]; then
	echo "PASS coop cost (logs: $OUT)"
else
	echo "FAIL coop cost: host exit $h, guest exit $g (logs: $OUT)"
	exit 1
fi
