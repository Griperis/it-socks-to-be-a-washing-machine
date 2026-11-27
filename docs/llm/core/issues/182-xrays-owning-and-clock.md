---
type: ticket
status: done
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done: 2026-11-27
blocked_by: ["[[154-batch-c-groundwork]]", "[[129-upgrades-and-menu]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 2", "suggested model: opus"]
terms: [X-ray, Cabinet X-ray, Show pair, Show Cabinet, Upgrade, Hands]
suites: [xrays, upgrades, economy, coop_xrays, player]
---

# The X-rays: owning, the keys, the clock, the Upgrades

Each player who has bought the X-ray presses key 1 to Show pair, and with the Cabinet X-ray key 2 to Show Cabinet: on
for a while, then a cooldown; nothing at all (no sound, no cooldown spent) while nothing held fits; "X-ray not bought"
before the Upgrade. Only its user sees it; nothing is decided or sent. Build `docs/architecture/x-rays.md` "The shape",
"How it is authored", draft 152-A:

- `XRayAbility` (Resource) and the two files `game/xray/abilities/sock.tres`, `cabinet.tres` (no `view` yet);
  `XRays` (a Node under the local player in `player.tscn`, listing the folder with `ResourceLoader.list_directory()`);
  `XRay` (the `Show` and `Cooldown` Timers read from `Upgrades.value` when they start, the key in `_unhandled_input`,
  `use()`, `shown_items()`, `targets()` for MATES and CABINET, `usable()`, `state()`, `switched`, `became_ready`;
  `targets()` refreshed on `Parts.applied` and the Hands' cycle); `XRayTuning` (`glow_scale` 1.08, `screen_fade` 3 s);
- the eight `UpgradeStat`s (`xray`, `cabinet_xray`, `all_hands_xray`, `all_hands_cabinet_xray` FLAG; `xray_duration`
  ADD 10 s step 5 "%.0fs"; `xray_cooldown` SCALE_DOWN 50 s step 0.2 least 0.1; `cabinet_xray_duration` ADD 10 s step 5;
  `cabinet_xray_cooldown` SCALE_DOWN 30 s step 0.2 least 0.1) set on the eight Upgrade files (no longer "Coming soon");
- the Cabinet X-ray's title "Cabinet X-ray: Show Cabinet" and tooltip "Show Cabinet (key 2): the right Cabinet glows
  through walls." (Q2713);
- the input actions through `python3 kit/tools/input_actions.py add xray_show <key 1> <joypad 13>` and
  `cabinet_xray_show <key 2> <joypad 14>` (the pad ones placeholders until batch D);
- `xray_on` on use and `xray_off` at the show's end, flat, for this player (the SoundEvents are core/154's);
- the X-rays station filled (shell from core/154 at x = 292): a board row per ability file (icon, key, words, Upgrades
  and their stats' now -> top), a switch per X-ray Upgrade (Own / level up / Reset), a room with a wall and a Heap,
  mates behind the wall and under the Heap, a Teammate stand-in holding a mate, two small Cabinets (one sheeted and
  locked) with "Grow a Row", its own `Mess`, `Hands`, `Upgrades`;
- `tests/upgrades_test.gd`'s "Coming soon" case moved to a test-only Upgrade with no `stat` under `tests/`.

Behaviour lines (`docs/migration/m4-lists/10-x-rays.md`, by heading): "Owning and using" (all 6); "Show pair" line 3 and line 4's rule; "Show drawer" line 3 and line 4's rule;
"The Upgrades" (all 8); "Words" (all, with "Show Cabinet", Q2701, Q2713).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The abilities, stats and tuning are typed Resources in the inspector (`# placeholder:` the old `xray.json`,
`cabinet_xray.json`, `upgrades.gd:191-197`; prices and cells as core/129 set them); a dropped ability file of a kind that
exists shows in the station's board and the HUD with no code.

## Acceptance
- Real path: the player's key 1 press, through `XRay._unhandled_input`, to the HUD's message "Sock X-ray on" and
  `xray_on` played, in the station with the X-ray owned and a loose Sock whose mate lies behind the wall picked with a
  left click.
- `usable()` is false while on; after the show (a test-only duration stat) `xray_off` plays and the cooldown runs; a
  press while cooling down does nothing and plays nothing.
- Not owned, key 1 reads "X-ray not bought" with `refuse`; holding a Pair key 1 does nothing and spends no cooldown, key
  2 (owned) reads "Cabinet X-ray on"; with empty Hands neither does anything.
- All-Hands X-ray makes `targets()` hold the mates of every loose Sock held, each Design once; Recharge level 2 makes
  the cooldown 30 s, Lingering level 1 the show 15 s.
- The eight Upgrades are bought from the menu (none "Coming soon"); the Cabinet X-ray's card reads its new title and
  tooltip; the board's numbers show "%.0fs".
- A save and load in the house while an X-ray cools down starts it ready; on a Guest the X-ray uses the Guest's own
  copy and sends no Command (the Session's sent count unchanged).
- Placeholders: the eight stats, `XRayTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The X-rays as the old, with "Show Cabinet"; no cue until usable; only its user sees it; the old timings and prices as
  placeholders (Q2701, 2026-11-26).
- The Cabinet X-ray's words (Q2713, 2026-11-26).
- The X-ray Upgrades are "Coming soon" until this piece (Q2669).

## Open follow-ups
