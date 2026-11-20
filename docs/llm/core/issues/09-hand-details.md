---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[04-one-cabinet]]", "[[10-one-mess-for-the-zoo]]"]
notes: []
terms: []
---

# Hand details: cloth, glide, pick fly-up, shelving flight

Milestone M0.5, the last ticket before it closes. core/02 and core/08 ported the Hands without the old game's
small motions (core/02's `[later]` follow-up); the designer wants them as the old game has them (Q2272, Q2273).
Looks of this machine only: nothing here writes a Part. The old code: `reference/it-socks/game/world/sock_actor.gd`
(the cloth, ADR-0004 in `reference/it-socks/docs/adr/`), `game/hands/held_view.gd` (glide, fly-up),
`game/hands/thrown_item.gd` (a thrown cloth Sock); the numbers: `data/tuning/cloth.json`, `held.json`.

## Behaviour list
Approved (Q2276, 2026-11-20). Numbers are the old game's.

**Cloth** (ADR-0004: spring bones on the Sock's own skeleton, not a cloth simulation)
- D01 When you hold a Sock, then it droops from its cuff and settles quickly (heavy, fully damped: it follows its
  balance point with a short lag, 0.06 s, and never swings past it).
- D02 When you walk, stop or jump with a Sock held, then it lags a little behind the move and settles again.
- D03 When you turn the view (or turn the item with R), then the Sock is dragged back against the turn.
- D04 When a Sock is dropped or thrown, then it flops as it flies, and lies flat as it slows (under 0.6 m/s,
  `flat_speed`), so it reaches the floor in the flat pose the Mess draws: nothing pops when it comes to rest.
- D05 When a flying or settling Sock is near what it lands on, then its bend gives way and no part dips below that
  surface.
- D06 A Pair (a sock ball) is rigid: no cloth.
- D07 Cloth runs only where it is seen: the Socks in your Hands and the 4 nearest flying ones (`flying_cap`); others
  fly rigid and still lie flat on landing.

**Switching**
- D08 When the active item changes (wheel, a pick, a drop, a pairing), then every held item glides to its new place
  (eased, `follow_rate` 14) instead of jumping; the zoom stays no glide.

**Picking up**
- D09 When a pick is granted, then the Sock flies from where it lay into its place in the Hands in 0.3 s on a small
  hop (0.18 m), easing in; the Hands already hold it (the fly is looks only).
- D10 When the picked Sock completes a Pair, then the pairing moment's second Sock flies in from where it lay, as
  D09, not on the fixed path (Q2274; replaces Q2270).

**Shelving** (Q2283)
- D11 When Pairs are shelved by a click, then each flies from the Hands into its slot (0.45 s, 0.06 s later for each
  next slot, arc 0.22), and the drawer shows its balls when all have landed (`game/campaign/campaign_installer.gd:82`,
  `data/tuning/cloth.json`).
- D12 When a drawer slides open or shut, then it eases out both ways, as the old tween did
  (`game/house/openable.gd:187`); today the AnimationPlayer played backwards eases in when it shuts.

**Invariants**
- Looks only: the Hands and the Mess decide; a Guest sees its own picks and Throws the same way.
- The Sock's Looks keeps its contract; the cloth is on the Looks' skeleton (the stand-in `crew.glb` has one), so the
  M1 models drop in.
- Godot's own node first: `SpringBoneSimulator3D` if it can do D01-D05; the old hand-written springs only where it
  cannot (a `research` question at design).

## Design
Draft for the designer (facts: `docs/research/sock-cloth-spring-bones.md`, tried on 4.7.2). Everything here is looks of
this machine: no Part, Command or `PROTOCOL` change. Numbers go in typed Resources, the old ones marked as ported.

**Cloth (D01-D07): Godot's `SpringBoneSimulator3D` doing what it does by itself** (Q2286, Q2287). In each Sock Looks,
a `Cloth` node (`SpringBoneSimulator3D`) under the `Skeleton3D`: chain `Leg` to `Toe`, `extend_end_bone`, `drag` 1
(no overshoot), `stiffness` and `gravity` tuned by eye to the old droop and lag (placeholders until the designer's go
on the still). Its centre stays the world, so the Sock bends with its own speed and turn: it stays bent while you
walk and swings as you go (D02, D03 as the node does them; the old "bend only on a change of speed" is in the polish
backlog). A small script on the Looks, `sock_cloth.gd` (one class), each physics tick:
- ramps `influence` to 0 under `flat_speed` 0.6 m/s, so a Sock lies in the flat rest pose the Mess draws (D04);
- puts a `SpringBoneCollisionPlane3D` at the surface under the Sock (one ray down); the joints slide and may crumple
  at the contact, a small poke between joints allowed (D05 as the node does it; the old straightening is in the
  polish backlog);
- is switched on (`active`) for held Socks and the 4 nearest flying Socks to the camera, a ranking run once a tick
  over the `sock_cloth` group (D07); off, the Sock is rigid and costs nothing.
The known one-tick jump when a Sock's cloth is switched on after moving is hidden by turning it on at `influence` 0
and ramping up. A Pair's ball has no `Cloth` (D06). `looks_contract.json` gains `Cloth`.

**Glide (D08)**: `HeldView` keeps each item's drawn place and eases it to its new place each frame
(`follow_rate` 14, the old exponential follow); the zoom is applied on top, unglided.

**Pick fly-up (D09)**: on a new id in the Hands, `HeldView` starts that item at the Sock's last world pose from the
Mess and flies it to its slot in 0.3 s (smoothstep, 0.18 m hop), then hands it to the glide.
**Pairing fly-in (D10)**: `pair_moment.tscn`'s picked Sock sits under a `FlyIn` node; the moment starts `FlyIn` at the
offset from its slot to where the Sock lay and shrinks the offset to nothing over the fly's first part, so the
AnimationPlayer keeps the line-up, fold, roll and pop as they are.

**Shelving flight (D11)**: when a Pair leaves the Hands into a drawer, `HeldView` hands its last drawn transform to
the drawer's Looks, which flies a ball from there to its slot (0.45 s, 0.06 s later each slot, arc 0.22) and shows
the drawer's balls when all have landed. **Drawer slide (D12)**: the drawer Looks gets a `shut` animation with its own
ease-out; `_show` plays `open` or `shut` from the current pose, so a reverse mid-slide stays smooth. Contract gains
`shut`.

**Tests** (one per line, the real path through the handling station): bones read in `modification_processed`
(reading poses from outside returns the unmodified pose, a research pitfall).
**Owns**: `game/hands/held_view.gd`, `game/sock/` Looks and `sock_cloth.gd`, `game/sock/pair_moment.tscn`,
`game/entities/cabinet/` drawer Looks. Model: Opus.

## Acceptance
- Each behaviour line has a test named after it; the real-path case: the player picks a Sock in the handling
  station, walks, turns and throws it, and its bones bend and come back flat at rest.
- A strip for each of cloth, glide and fly-up in `builds/review-core-09/`, stopped at the first still for the
  designer's go.

## Answers
- All three are ported: cloth (held and thrown), the glide on switching, the pick fly-up (Q2272, 2026-11-20).
- Built right after core/04, before M0.5 closes; each detail stops at its first still (Q2273, 2026-11-20).
- The pairing moment's second Sock flies in from where it lay, like a pick (Q2274, 2026-11-20; replaces Q2270).

- The behaviour list is approved as written (Q2276, 2026-11-20).
- D11 and D12 (the shelving flight, the drawer slide ease) are added (Q2283, 2026-11-20).
- The cloth bends with the Sock's speed, as Godot's node does by itself (Q2286, 2026-11-20).
- At the ground the node's own collision: the Sock may slide and crumple at the contact (Q2287, 2026-11-20).
- The design is approved (Q2288, 2026-11-20).

## Open follow-ups
- [later] The designer says what else looks different about the Throw after seeing the cloth (Q2275).

## Built log
