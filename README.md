# It Socks

A Godot 4.7 game, built by a designer and Claude Code agents on ticket branches. The workflow
and rules are in `CLAUDE.md`; the starter kit it is built with is the folder `kit/` (a git
submodule and a Claude Code plugin, see `kit/README.md`).

## Get it

```bash
git clone --recurse-submodules <this repository> && cd <its folder>
# an existing clone:  git submodule update --init
python3 kit/tools/setup.py --plugin          # once per machine: the kit's skills for Claude Code
kit/tools/engine.sh --fetch                  # once: puts the engine in extras/
```

## Run

```bash
"$(kit/tools/engine.sh --path)" --path .
```

Or open `project.godot` in the Godot editor.

## Test

```bash
kit/tools/run.sh      # every suite, headless: prints one PASS or FAIL line
kit/tools/shot.sh     # a screenshot into docs/screens/shots/
```

More: `kit/docs/TESTING.md`.
