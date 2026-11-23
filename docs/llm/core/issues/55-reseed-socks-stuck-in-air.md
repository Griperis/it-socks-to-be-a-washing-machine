---
type: ticket
status: done
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["designer's play of the Sock generator station, 2026-11-23; Q2531"]
terms: [Mess, Sock]
---

# After a reseed in the Sock generator station, Socks hang frozen in the air

## What happens
The designer played `game/zoo/stations/sock_generator.tscn` and pressed the reseed button: the new Socks spawn
stuck in the air and stay there, frozen, instead of lying on the floor or the heap.

## Reproduce
Reproduce before you diagnose: the station's real path, press reseed once and several times, log every Sock whose
lowest point is more than 1 cm over what is under it (ray down). The lead's guess, unproven: the new Mess is laid
while the old Socks' bodies still stand (the rays land on them), the old ones are then removed, and the new lying
records are frozen, so nothing pulls them down. Check also the first generation at start, and the house (house/05
places areas there in parallel).

## Acceptance
- The cause written up in the Built log.
- A reseed lays the new Mess only onto the world without the old one (Q2531).
- A laid Sock that has nothing under it (its support removed, a reseed, a piece moved) wakes and falls, or lands on
  the heap, through the Mess's usual Moving path; it never stays frozen in the air (Q2531). A case for each.
- Real path: the station, reseed 5 times: after each, every Sock rests on something (none over 1 cm in the air) and the
  preview and the laid Socks still agree for the first generation.
- core/52's cases still pass.

## Open follow-ups
- [later] The editor preview shows a Heap's stacked Socks up to a few cm higher than they lie in the game
  (the preview knows no Designs, so it cannot know the real heights). x, z and turn stay exact. Is that
  acceptable, or should the preview guess the heights some other way?
- [later] The laying treats a player's body as part of the house (the player's CharacterBody3D is on layer 1),
  so a reseed keeps Socks out of where a player stands, and the result then differs from the preview there.
  Should a reseed ignore players (Socks may appear under their feet), or keep clear of them as now?

## Built log

### 2026-11-23
- Cause: not the old Socks. The laying's rays see only the house layer, so the old Socks never stood in the
  way. A Heap stacked its Socks on the *place box* (the biggest Sock's box, 0.375 x 0.0325 x 0.225). A smaller
  Sock underneath, or a leg-and-foot shape that missed the Sock above, left 15-20 % of the station's Socks
  hanging up to 0.36 m in the air, at start and after every reseed. Lying records never check what is under
  them, so they stayed frozen.
- Changed: `records()` now brings each stacked Heap Sock down onto the real leg and foot boxes under it once
  its Design is known (`SockLaying.restack`). Height only changes, and only down. Next tick the Host checks every
  Sock a generator lays (at the start, or an `add` "lying" as a reseed makes) and what lay over any lying Sock
  taken out. If nothing is within `support_reach` (1 cm, placeholder) under one, it falls through the Moving path
  (`fall`). SockSpots and loads are not checked: other suites set Socks pressed or floating by hand on purpose.
  Measured: 0 hanging at start and after 5 reseeds, down from 7-20 each.
- Files: game/mess/sock_laying.gd, sock_generator.gd, mess.gd, mess_bodies.gd, mess_tuning.gd, mess_drawing.gd
  (sock_points static); tests/sock_generator_test.gd (G09 and G12 real path, G10 support taken out, G11 laid in
  the air; the preview check now allows a stacked Heap Sock
  to lie at its dot's height or lower); docs/architecture/mess.md, sock-generator.md.
- Verified: PASS 17740 checks, 457 cases (--touched); rules PASS; asset_lint PASS. Before the fix the same probe found 7-20 hanging Socks at start and after each reseed. A piece moved while the game runs has no path today (only Doors and drawers move, and they sweep, M09); a piece moved before a reseed is G12.
- Merged: 1662ff97 (2026-11-23, branch core/55-reseed-socks-stuck-in-air)
