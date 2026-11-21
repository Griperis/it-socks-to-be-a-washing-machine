#!/usr/bin/env bash
# The Mess benchmark (core/31; game/debug/mess_bench.gd, docs/architecture/mess.md "Benchmark"),
# headless in a mirror of its own, with Godot's worker pool capped at 4 threads (an override.cfg in
# the mirror only, as the old game's tools/stress.sh did). Prints one BENCH line per scenario and
# the verdict line last; the report goes to builds/mess-bench/report.md (or OUT=<folder>), and
# holds every run kept in that folder side by side.
#
#   tools/mess_bench.sh                      every scenario, on this checkout (label "this-checkout")
#   tools/mess_bench.sh --only=idle_500,sweep
#   tools/mess_bench.sh --list               the scenarios
#   tools/mess_bench.sh --label=after-fix    the run's name in the report
#   tools/mess_bench.sh --at=<commit>        the same scenarios on an older commit (a temporary
#                                            worktree with today's benchmark files copied in), label
#                                            the commit's short hash unless --label says otherwise
#   tools/mess_bench.sh --window             windowed under Xvfb, so draw calls are counted (frame
#                                            times on a software renderer mean nothing)
#   tools/mess_bench.sh --keep               keep the mirror (default: removed at the end)
#
# BENCH_THREADS=<n> changes the worker-pool cap; BENCH_OVERRIDE adds lines to the mirror's
# override.cfg (a trial of an engine setting, e.g. $'[physics]\njolt_physics_3d/simulation/position_steps=1\n');
# LIMIT=<seconds> is the longest the run may take (default 3600).
# The numbers are this machine's CPU; the designer's PC run is the reference (tools/mess_bench.cmd).
set -uo pipefail
cd "$(dirname "$0")/.."
. kit/tools/_root.sh; need_game; cd "$REPO" || exit 1
source "$KIT/tools/_mirror.sh"
source "$KIT/tools/_agent_common.sh"

# What the benchmark is made of: copied into an older commit's tree, which has none of it.
BENCH_FILES=(game/debug/mess_bench.gd game/debug/mess_bench.gd.uid game/debug/mess_bench.tscn
	game/debug/mess_bench_clock.gd game/debug/mess_bench_clock.gd.uid
	game/debug/mess_bench_level.gd game/debug/mess_bench_level.gd.uid game/debug/mess_bench_level.tscn
	game/debug/mess_bench_plan.gd game/debug/mess_bench_plan.gd.uid game/debug/mess_bench_plan.tres
	game/debug/mess_bench_report.gd game/debug/mess_bench_report.gd.uid
	game/debug/mess_bench_scenario.gd game/debug/mess_bench_scenario.gd.uid
	game/debug/mess_checks.gd game/debug/mess_checks.gd.uid game/debug/mess_checks.tres
	game/debug/mess_watch.gd game/debug/mess_watch.gd.uid)

KEEP=0; AT=""; LABEL=""; WINDOW=0
ARGS=()
for arg in "$@"; do
	case "$arg" in
		--keep) KEEP=1 ;;
		--window) WINDOW=1 ;;
		--at=*) AT="${arg#--at=}" ;;
		--label=*) LABEL="${arg#--label=}" ;;
		*) ARGS+=("$arg") ;;
	esac
done
[ -x "$GODOT" ] || { echo "no engine at $GODOT -- run kit/tools/engine.sh --fetch" >&2; exit 2; }
OUT="${OUT:-$REPO/builds/mess-bench}"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"

SRC="$REPO"
WT=""
MIRROR="${TMPDIR:-/tmp}/$PROJECT_SLUG-bench"
cleanup() {
	if [ -n "$WT" ]; then
		git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1
		rm -rf "$WT"
	fi
	[ "$KEEP" = 1 ] || rm -rf "$MIRROR" "$MIRROR-user"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

COMMIT="$(git rev-parse --short HEAD 2>/dev/null || true)"
if [ -n "$AT" ]; then
	COMMIT="$(git rev-parse --short "$AT" 2>/dev/null)" || { echo "no commit $AT" >&2; exit 2; }
	WT="$(mktemp -d "${TMPDIR:-/tmp}/mess-bench-at-XXXXXX")"
	rmdir "$WT"
	git worktree add --detach "$WT" "$AT" >/dev/null 2>&1 || { echo "cannot make a worktree of $AT" >&2; WT=""; exit 1; }
	( cd "$WT" && git lfs checkout >/dev/null 2>&1 )
	fill_kit "$WT" || echo "could not copy the kit into $WT/kit" >&2
	mkdir -p "$WT/game/debug"
	for f in "${BENCH_FILES[@]}"; do cp "$REPO/$f" "$WT/$f" || exit 1; done
	SRC="$WT"
	MIRROR="$MIRROR-$COMMIT"
	[ -n "$LABEL" ] || LABEL="$COMMIT"
elif [ -n "$(git status --porcelain -- game 2>/dev/null)" ]; then
	COMMIT="$COMMIT+changes"
fi
[ -n "$LABEL" ] || LABEL="this-checkout"

mirror_into "$SRC" "$MIRROR"
ensure_import "$SRC" "$MIRROR" "$GODOT" || exit 1
private_user_data "$MIRROR-user"
printf '[threading]\nworker_pool/max_threads=%s\n\n%s' "${BENCH_THREADS:-4}" "${BENCH_OVERRIDE:-}" > "$MIRROR/override.cfg"

LOG="$OUT/log-$LABEL.txt"
# Six physics ticks a frame (--fixed-fps 10 at 60 ticks a second): a tick is timed between two
# ticks of one frame, with no drawing and no wait in it (MessBenchClock).
RUN=("$GODOT" --audio-driver Dummy --path "$MIRROR" --fixed-fps 10 res://game/debug/mess_bench.tscn --
	--out="$OUT" --label="$LABEL" --commit="$COMMIT" "${ARGS[@]+"${ARGS[@]}"}")
if [ "$WINDOW" = 1 ]; then
	command -v xvfb-run >/dev/null || { echo "--window needs xvfb-run" >&2; exit 2; }
	timeout "${LIMIT:-3600}" xvfb-run -a -s "-screen 0 1280x720x24" "${RUN[@]:0:1}" \
		--rendering-driver "$(render_driver "$MIRROR")" --resolution 1280x720 "${RUN[@]:1}" > "$LOG" 2>&1
else
	timeout "${LIMIT:-3600}" "${RUN[@]:0:1}" --headless "${RUN[@]:1}" > "$LOG" 2>&1
fi
code=$?
grep -E '^BENCH|SCRIPT ERROR|^ERROR:|^Report:|^[a-z_0-9]+  ' "$LOG" | grep -vE 'RID allocations|resources still in use' | head -80
if grep -q 'contacts were ignored\|exceeded capacity' "$LOG"; then
	echo "BENCH WARNING Jolt dropped contacts: $(grep -m1 -o 'Jolt Physics [a-z ]* exceeded capacity' "$LOG")"
fi
verdict="$(grep -E '^(PASS|FAIL) mess bench' "$LOG" | tail -1)"
if [ -z "$verdict" ]; then
	case " ${ARGS[*]-} " in *" --list "*) exit 0 ;; esac
	echo "FAIL mess bench: no verdict printed (exit $code, log: $LOG)"
	exit 1
fi
echo "$verdict"
exit "$code"
