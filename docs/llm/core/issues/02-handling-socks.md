---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done: 2026-11-20
blocked_by: ["[[01-zoo-movement]]"]
notes: []
terms: []
---

# Handling Socks: pick, hold, drop

Milestone M0.5. A station with loose Socks: the Hands, picking a Sock the crosshair reaches, carry capacity, dropping. The Throw is core/08 (Q2250). Socks at this station are few and real entities; the Mess as one bulk system comes in M3 (Q2168), but the Sock's look and its state fields are the real ones.

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
Taken from `docs/migration/behaviour-core-loop.md` (rows M12-M15, H01-H30, T01-T16, read from the old code with
their test names) and the old `game/player/rig_click.gd`, `rig_drop.gd`, `rig_aim.gd`. Ids keep the survey's,
so each line can be traced. Numbers are **today's values, not decisions**: placeholders until the designer sets
them. M0.5 is one player (a Host of one); the co-op lines are listed at the end with where they go.

**Aim and pick**
- M12 When the crosshair rests on a Sock within reach (2.5 m) while standing, then the Sock is outlined and a left
  click can pick it; the first Sock on the aim line wins; the floor beside a Sock, or a Sock out of reach, picks
  nothing.
- M13 When a Sock lies under another but its tip sticks out, then aiming at the tip picks the lower Sock and the
  one on top stays.
- M14 When a wall (or a shut Door) is between you and a Sock, then it is not outlined and cannot be picked, not
  even just past the wall (3 cm slack).
- M15 When a cupboard or drawer is shut, then the Socks inside cannot be aimed at; open, they can. (The zoo's
  example cupboard.)
- H01 When you left-click an aimed Sock with a free place in the Hands, then it goes into the Hands and becomes
  the active item.
- H02 When you click Socks faster than the grab interval (0.35 s), then the extra clicks do nothing, no message.
- H03 The Hands hold 1 item to start (a Pair counts as one). (Big Hands raises it: M4.)
- H04 When the Hands are full and the clicked Sock is not the mate of a held Sock, then it stays and "Hands full"
  shows. (The mate case is core/03, pairing.)

**Holding**
- H06 When you hold several items, then the newest is active, drawn big right of centre, the others tucked small
  to the left; the wheel (LB/RB) steps through them and wraps; with one item nothing changes.
- H21 When you hold G, then the view eases in (75 to 50 degrees in 0.15 s), mouse look slows with it, and the
  active item comes close and large while tucked items keep their screen size; letting go puts it back. (Q2234)
- H22 When you hold R, then the active item turns where it hangs (a Sock about its long axis, one turn per 2 s)
  and keeps the angle when let go; looking, walking, clicking and the wheel still work.
- H23 When a Sock is held, then its Size letter shows. (The Design name and icon need the Sock Smarts and Sock
  Sense Upgrades: M4.)
- H28 When you press the right button with empty Hands, then nothing happens.

**Drop**
- H07 When you tap the right button (under 0.25 s) with the crosshair white, then the active item drops where the
  crosshair is, within reach, on a top flat enough (up to 25 degrees): the floor, a table, a shelf, a Heap.
- H08 When the crosshair is red (too far, a wall, a steep side, the ceiling, a gap narrower than 8 cm) and you
  release, then nothing drops, "Can't drop there" shows and the item stays; with empty Hands the crosshair is
  always white.
- H09 When the crosshair sees into an open cupboard or drawer, then a drop lands inside.
- H10 When a Sock is dropped, then after a 0.1 s flick from the hand it is let go 3 cm over the spot, falls as one
  physical body and lies where it settles; while it falls it cannot be aimed at or picked.
- H11 When dropped on a Sock, beside it, or half over a table's edge, then it settles or falls; it never floats or
  sinks into anything.

**Invariants** (from the survey's part 4)
- I.1 No Sock is lost or doubled: each is in exactly one place (lying, in the Hands, in flight), through every
  pick, drop and Throw.
- I.3 An item is in at most one player's Hands.
- I.6 Every resting Sock lies on what is drawn; none in a wall, floor or furniture; none aimable inside a shut
  container.
- T13 When a dropped Sock comes to rest, then it lies where its body stopped; a fall that never settles is put down
  after 6 s.
- I.7 A drop is accepted only where it would rest, within reach; otherwise refused and the item stays.
- I.8 Nothing flies through walls; every flight ends exactly once.
- Every Hands change is asked as a Command and decided by the Host of one (Q2212); the held items are decided
  state, a Sock in flight is the Host's physics body (Q2221, Q2222).

**Not in this ticket**
- The Throw (T01-T04, T07, T08, T11, T14; charge, ring, lob, speeds): core/08 (Q2250). A drop's falling body
  and its 6 s settle limit (T13) are here, because a drop needs them.
- Pairs (H04's mate case, H12 picking up a floor Pair, a Pair's drop and Throw): core/03.
- Shelving by Throw (T05, T06): core/04.
- Co-op, M0.6: hand-off and its refusals (H13-H15), no stealing (H16), the race (H17), Guest prediction (H18,
  Q2220, Q2221), a leaver's Hands (H24), saves and joiners (H25, H26), knocked down (H27), match cues (H29), a
  teammate in the way (H30), Throws hitting a teammate (T09, T10), watching a Throw (T12, Q2226), spin guard (T15).
- Upgrades, M4: Quick Grab, Big Hands, Long Arm, Quick Charge, Sock Smarts, Sock Sense (base values above stay).
- New Game, M4: the Guide card in the Hands (H05).
- Other features, M5: things that take the whole Hands (H19), the Upgrade station's top (H20).
- Sounds and rumble (T16's sounds): with the first audio ticket; the ring is core/08.
- The Mess as one bulk system (laying, Heaps, the wake budget of 512): M3 (Q2168). Here a handful of real Socks.

## Design
The co-op structure (`docs/migration/coop-structure-for-the-port.md`, sections 1, 4, 5, 6) already decides the
buckets: loose Socks are the **Mess**, one bulk system that is one Part; the **Hands** are per-player decided state;
a Sock in flight is a **Host-owned body**. This design builds the smallest true version of each, so M3 grows them
instead of replacing them. Old code: about 1,950 lines of Hands, 2,260 of flights, 4,400 of Mess; here about 600
in all, because the bulk machinery (MultiMesh per room, the settle stream, the wake budget, the 1,726-line layout
bake) waits for M3.

**What each piece of state is**
| State | Kind | Where |
|---|---|---|
| Each loose Sock: id, Design, state (lying, held, flying), pose | the Mess, one Part | `Mess` (records in packed arrays; the "big piece under one id" `parts.gd` already allows) |
| Each player's held items (ids, in order) and the active one | decided state | `Hands`, one Part for all players, keyed by player id (1 alone) |
| A Sock flying after a drop or Throw | Host-owned body | a `Flight` RigidBody3D added by a `MultiplayerSpawner`, removed when it rests; in M0.6 one synchronizer per body (Q2221) |
| The aim, the outline, the ring, zoom, turn, the held layout | looks of this machine | the player and a `HeldView` |

**Commands** (each a verb in its Part's `accepts()`, with args, rate and reach, as if a Guest sent it):
- `pick(sock)` to `Hands`: refused "far" (over reach), "gone" (not lying), "full", "soon" (grab interval).
  Granted, one answer changes two Parts: the Sock's record becomes held (Mess) and its id joins the Hands.
- `cycle(step)` to `Hands`: the active item steps and wraps.
- `drop(point, normal)` to `Hands` (core/08 adds `throw(dir, charge)` the same way): refused "far", "nothing", "no_spot" (the Host checks the
  spot again). Granted: the id leaves the Hands, the Sock becomes flying, and the Host spawns its `Flight`. When
  the body rests, the Host writes the Sock lying at that pose (a Host-only `rest` change to Mess).
- The crosshair's white or red, "Can't drop there" and "Hands full" are shown from the same checks the Host makes
  (one function, two callers), so the player sees the refusal before asking.

**The Sock's look and data**
- `SockLooks` scene: graybox now is the old game's `assets/sock/crew.glb`, copied unported and tinted by its
  Design's colour, scaled by Size (Q2249); the ported models replace it in M1. Its contract (`looks_contract.json`) names `Body`, `Outline` and an AnimationPlayer with `held` and
  `lying`; the outline and states play there, not in code (Q2213).
- The Designs: the old `data/designs.json` (605 Designs: id, name, colour, pattern, size, rarity, collection)
  converted once into a typed `DesignCatalogue` Resource of `SockDesign` entries, edited in the inspector (Q2248). A Sock's record holds the Design id only.
- Lying Socks are drawn one MeshInstance each in M0.5 (a handful); M3 switches to MultiMesh.

**The station** `game/zoo/stations/handling.tscn`: `SockSpot` markers (a Node3D with a Design id, placed in the
editor) that `Mess` turns into lying Socks when the level binds, then hides; a table, a shelf, a wall, a gap
narrower than 8 cm, the zoo's example cupboard (M15, H09). The zoo's player instance
overrides capacity to 3 (Q2244).

**Code sketch**
```gdscript
# game/mess/mess.gd: one Part for every loose Sock. M3 adds the MultiMesh, settle stream and bulk snapshot.
class_name Mess extends Part
enum State { LYING, HELD, FLYING }
@export_group("State")
@export var designs := PackedInt32Array()     # by Sock id
@export var states := PackedByteArray()
@export var poses := PackedFloat32Array()     # 12 floats a Sock (a Transform3D)

func sock_at(collider: Object) -> int: ...    # the Sock a ray hit, or -1; only LYING Socks have colliders

# game/hands/hands.gd: every player's Hands, keyed by player id.
class_name Hands extends Part
@export_group("State")
@export var held := {}                         # player id -> PackedInt32Array of Sock ids, newest last
@export var active := {}                       # player id -> index

func decide(cmd: Command) -> Dictionary:
	match cmd.kind:
		&"pick":
			var why := pick_refusal(cmd.by, cmd.args.sock)   # the same check the crosshair shows
			if why != "":
				return refuse(why)
			return {"ok": true, "changes": {
				mess.id: mess.held_patch(cmd.args.sock),
				id: held_patch_add(cmd.by, cmd.args.sock)}}
		...
```

**Numbers** (`HandsTuning`, typed Resource, each `# placeholder:`): reach 2.5 m, grab interval 0.35 s, capacity 1,
tap 0.25 s, drop slope 25 degrees, drop gap 0.08 m, drop lift 0.03 m, flick 0.1 s, settle limit 6 s, zoom 50 degrees in
0.15 s, turn 2 s a turn; the held layout from the old `held.json` (active at (0.2, -0.13, -0.55) scale 0.6,
tucked at (-0.3, -0.3, -0.55) stepping 0.075, scale 0.3), compared with `held-sock.png` (Q2246).

**Input**: `pick` (left click, pad A), `drop_throw` (right button, pad B), `zoom` (G), `turn` (R), `hands_next` /
`hands_prev` (wheel, RB / LB); `interact` moves to pad Y (Q2245). The kit's hands code in `player.gd` (the crate
carry) goes: the player asks `Hands`.

**Tests**: one case per behaviour line, named after it, plus the invariants (a count of Socks in every place after
each step). The real-path case loads `handling.tscn` with the player and, with real input actions, picks a Sock,
drops it on the table, picks it again and drops it into the open cupboard.

**Shared**: `player.gd` (core/01's body stays as it is; this adds the aim and the input). `Mess` and `Hands` are
used by core/03 (Pairs join the Mess and the Hands) and core/04 (shelving).

## Acceptance
- Every change to the Hands goes through a Command answered by the Host of one (Q2212).
- A Sock's look comes from a Looks scene (graybox now); held, flying and resting are states, not code animation where an AnimationPlayer can do it (Q2213).
- Tests follow the approved behaviour list, one case per line, plus a count of every Sock's place after each step
  (I.1).
- One real-path case: `game/zoo/stations/handling.tscn` with the player, real input actions: pick a Sock, drop it
  on the table, pick it again, drop it into the open cupboard. `kit/tools/run.sh` prints PASS.
- `kit/tools/asset_lint.py` passes for the Sock's Looks and its contract.

## Answers
- Zoom (G held: the view narrows 75 to 50 degrees over 0.15 s, eased; mouse look slows with it) is ported here, with the held Sock (Q2234, 2026-11-20).
- The behaviour list is approved as written (Q2243, 2026-11-20).
- Carry capacity is a field of the player's tuning, 1 by default; the zoo's player instance overrides it in the
  editor so H06 can be played (Q2244, 2026-11-20).
- Pad buttons as the old game: A picks (left click), B drops and throws (right button), Y is E (interact), X jumps,
  LB/RB the wheel (Q2245, 2026-11-20).
- The held items keep the old layout (active big right of centre, others tucked small left, G brings the active
  one close), taken from the old numbers and compared with the baseline still `held-sock.png` (Q2246, 2026-11-20).
- The design is approved: loose Socks live in a small `Mess` Part from now on (records, one mesh each; M3 adds
  the bulk parts), Socks placed in the editor as `SockSpot` markers (Q2247, 2026-11-20).
- The Designs become a typed `DesignCatalogue` Resource (Q2248, 2026-11-20).
- The graybox Sock is the old `crew.glb` tinted by Design colour, unported, until M1 (Q2249, 2026-11-20).
- The Throw is split off into core/08, built after this ticket (Q2250, 2026-11-20).

## Open follow-ups
- [later] Pad buttons (Q2245): `pick` has A, `drop_throw` B, `interact` gained Y; but `jump` still has A and
  `interact` still has X from core/01. Removing those two events is a project.godot change beyond added
  [input] entries, so it needs the lead (`commit.sh --allow-project`). Until then A both jumps and picks.
- [later] The Carriables station and the crate (`game/zoo/stations/carriables.tscn`, `game/entities/crate/`):
  the player no longer carries a Carriable (the kit's crate-carry hands are gone), but E on the crate still asks
  its `pick`, so the crate is then held by nobody visible and cannot be put down. Retire the station and the
  crate, or keep them for co-op demos (a lead/designer call; not this ticket's files).
- [later] `game/parts/session.gd` PROTOCOL: the station adds a spawnable scene (`game/sock/flight.tscn` on a
  MultiplayerSpawner); bump PROTOCOL in game/parts (not this ticket's files) before co-op is played with it.
- [later] M0.6: a Guest's capacity and reach (Hands read the HandsTuning of a player on this machine, else
  their own: a Guest gets capacity 1); a leaver's Hands (`Hands.left()` returns nothing, so a leaver's Socks
  stay HELD: H24); a Guest sees a falling Sock only as the spawned untinted body.
- [later] The zoo's cupboard entity is a solid box, so the station hollows its instance with overrides
  (walls, a shelf, the solid shape off). A hollow cupboard of its own belongs to the furniture port.
- [later] Looks: the outline is white and 4 mm (a look the designer has not set); the refusal line shows
  red with no wobble; held items have no cloth sway and no pick-up flight. Stills for `held-sock.png`
  were not asked for here.
- [later] `tests/handling_test.gd` is 640 lines (grep_rules notes over 600): split it when next touched.

## Built log
- 2026-11-20 (lead): handed to a ticket agent on Opus: the Mess and Hands Parts are the core data model and a
  Command that changes two Parts (the Models value: opus for hard netcode).
- 2026-11-20 (agent):
  - Changed: loose Socks are the `Mess` Part (records in packed arrays: Design, state LYING/HELD/FLYING, pose;
    SockSpots placed in the editor become the starting Socks); every player's Hands are the `Hands` Part
    (pick, cycle, drop as Commands; a pick and a drop answer change both Parts; the Host writes a fallen Sock
    lying with a Host-only `rest`). The player aims (outline, red crosshair, "Hands full", "Can't drop
    there" from the Host's own checks), zooms (G), turns (R), cycles (wheel), shows the Size letter; the
    HeldView draws the old layout; the kit's crate carry is gone. Designs: `DesignCatalogue` of 1005
    `SockDesign`s; graybox Looks is the old crew.glb (lying, held, aimed). Handling station; zoo player holds 3.
  - Files: game/mess/, game/hands/, game/sock/, game/player/, game/zoo/stations/handling.tscn, game/zoo/zoo.tscn,
    tests/handling_test.gd, tests/player_test.gd, tests/zoo_test.gd (co-op case opens a cupboard instead of the
    crate hand-over), tools/grep_rules_allow.txt, project.godot (actions added).
  - Verified: `kit/tools/run.sh --touched`: PASS 510 checks, 112 cases; grep_rules PASS; asset_lint PASS.
