---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[04-one-cabinet]]"]
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
To come after the behaviour list is approved.

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

## Open follow-ups
- [later] The designer says what else looks different about the Throw after seeing the cloth (Q2275).

## Built log
