#!/usr/bin/env bash
# Export assets from their .blend source to the game's .glb (assets_src/generate/README.md).
#
#   assets_src/generate/export.sh <asset>...              overwrite the game's glb (assets/...)
#   assets_src/generate/export.sh --out <dir> <asset>...  write under <dir> instead (then glb_compare.py)
#   assets_src/generate/export.sh --check <asset>...      the kit's contract report only
#   assets_src/generate/export.sh --family sock|cabinet   every asset of that family
#
# <asset> is a key of assets/blender_assets.json; its `source` is the .blend under assets_src/blender/.
# Blender: $BLENDER (default ~/tools/blender/blender, from kit/tools/blender.sh), or $BPY_PYTHON, a
# Python with pip's bpy 5.3 (bpy_run.py). The log goes to $TMPDIR; the console gets one EXPORT line
# per asset.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
MANIFEST="$REPO/assets/blender_assets.json"
BLENDER="${BLENDER:-$HOME/tools/blender/blender}"
ARGS=()
ASSETS=()
while [ $# -gt 0 ]; do
	case "$1" in
		--check) ARGS+=(--check) ;;
		--out) mkdir -p "$2"; ARGS+=(--out "$(cd "$2" && pwd)"); shift ;;
		--family) mapfile -t -O "${#ASSETS[@]}" ASSETS < <(python3 -I "$HERE/manifest.py" family "$MANIFEST" "$2"); shift ;;
		-*) echo "unknown option $1" >&2; exit 2 ;;
		*) ASSETS+=("$1") ;;
	esac
	shift
done
[ ${#ASSETS[@]} -gt 0 ] || { echo "usage: assets_src/generate/export.sh [--out <dir>] [--check] <asset>... | --family <name>" >&2; exit 2; }

run() {
	if [ -x "$BLENDER" ]; then
		LP_NUM_THREADS=4 "$BLENDER" -b "$1" --factory-startup -t 4 -P "$HERE/export.py" -- "${@:2}"
	elif [ -n "${BPY_PYTHON:-}" ]; then
		"$BPY_PYTHON" "$HERE/bpy_run.py" "$1" "$HERE/export.py" -- "${@:2}"
	else
		echo "EXPORT-FAIL no Blender at $BLENDER and no BPY_PYTHON (kit/tools/blender.sh --fetch)"
		return 2
	fi
}

LOGDIR="${TMPDIR:-/tmp}/game-export"
mkdir -p "$LOGDIR"
fail=0
# One Blender run per source file, with every asset of it.
while IFS=$'\t' read -r src list; do
	read -r -a group <<< "$list"
	blend="$REPO/assets_src/blender/$src.blend"
	if [ ! -f "$blend" ]; then
		echo "EXPORT-FAIL ${group[*]}: no source at assets_src/blender/$src.blend"
		fail=1
		continue
	fi
	log="$LOGDIR/${src//\//_}.log"
	run "$blend" "${group[@]}" "${ARGS[@]}" > "$log" 2>&1 || fail=1
	grep -E "^(EXPORT-|[a-z_0-9]+: |  - )" "$log" || { echo "EXPORT-FAIL ${group[*]}: no verdict; log $log"; fail=1; }
	if grep -q "^EXPORT-FAIL" "$log"; then fail=1; fi
done < <(python3 -I "$HERE/manifest.py" sources "$MANIFEST" "${ASSETS[@]}")
exit $fail
