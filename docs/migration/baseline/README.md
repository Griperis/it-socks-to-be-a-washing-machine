# Looks baseline of It Socks at tag v0.1

70 fixed views of the old game, taken by its capture tour in one run in the sandbox on 2026-11-19
(`tour_info.txt`: software renderer llvmpipe, Forward+, High preset, 1280x720, fixed seed, the clock held).

- `tour-sandbox/`: the 70 stills, named after their view.
- `views_baseline.json`: the views file the tour read (in the reference clone: `game/debug/tour/views_baseline.json`).
- `numbers.md`: what can be measured without a GPU (counts, sizes, lines, the suite verdict), and how to measure
  frame times on the designer's PC.

**Comparing the rebuild.** Capture the same views the same way (in the sandbox, with the starter kit's capture
tour and a views file with the same names), then `python3 tools/baseline.py compare docs/migration/baseline/tour-sandbox <new folder>`
(`docs/agents/baseline.md`). A view the rebuild cannot show yet is skipped, not faked. A difference is a question
for the designer, never accepted automatically: the half-metre house and the avatar updates are meant to differ.

**Known.** 69 of the 70 stills are pixel-identical between two runs; `avatar-hat-clothes` is not (an unseeded idle
animation). These are a software renderer's pictures and differ from a GPU's; the designer chose not to capture
on their PC. Not in the views: the Splitter carried, the Cellar hatch, the Grotto.

To take the old game's set again: `bash tools/tour.sh` in `reference/it-socks/` (it needs the engine in its
`extras/`).
