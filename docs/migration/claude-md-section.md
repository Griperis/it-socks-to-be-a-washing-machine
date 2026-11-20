<!-- Insert under "Rules only this project has" in CLAUDE.md (START-HERE step 4). -->
- **This is a port.** The old game is the reference: a plain clone in `reference/it-socks/` (its own git
  repository, ignored here, skipped by Godot and by the tools). Grep it; do not read its big files whole. What is
  known and decided: `docs/migration/README.md`. How one piece is ported: the `migration-port` skill.
- **Q numbers continue the old game's sequence;** the next free number is line 1 of `docs/migration/decisions.md`.
  Read that file before asking anything: most questions are answered.
- **A piece:** behaviour list approved, then design and grilling, then build with tests from the list, then a
  walkthrough; it merges on the designer's OK, in batches. Code is approved per piece, assets per family batch.
- **Ported by examination, never copied unexamined.** "Improve" means technical only; a look change is its own
  ticket (Q2153).
- **Decided state lives on scene parts** and only the Host's answer to a Command writes it. A player's body and
  things in the air use Godot's synchronizers; things created during play use Godot's spawner; the Mess is one
  bulk system that is one Part. Prediction is looks only (`docs/migration/coop-structure-for-the-port.md`).
- **An entity is behaviour plus a swappable Looks child scene**; state plays an AnimationPlayer in Looks, not
  code animation. A new feature is first a station in the zoo, with the game's real entities.
- **Numbers are typed Resources edited in the inspector; screens are scenes on one Theme; Jolt and Godot's own
  nodes wherever they can do the job** (the ragdoll included).
- **A journal line per merged ticket** in `docs/migration/journal.md`.
- **No commit message carries a Claude (or any AI assistant) `Co-Authored-By` line** (designer, 2026-11-20);
  `kit/tools/commit.sh` refuses one.
