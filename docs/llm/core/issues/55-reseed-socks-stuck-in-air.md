---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-23
done:
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
