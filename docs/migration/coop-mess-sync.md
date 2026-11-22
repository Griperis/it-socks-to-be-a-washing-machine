# The Mess in co-op: how the old game synced it, how the port differs, the plan

Written 2026-11-22 by the lead, on the designer's word: "the socks mess should be well optimized for co-op.
Inspire in the base game, flag differences, then try to update it, make it good" (Q2472). Behaviour lines:
`m06-lists/03-mess-throw-coop.md` sections A to C (approved for the Mess half by Q2472). Facts:
`coop-structure-for-the-port.md` section 5, `docs/research/coop-flight-sync.md`, `docs/architecture/mess.md`.

## How the old game did it (v0.1.1)
- **Join:** one reliable welcome with the gzip of the whole World in a compact codec, 25 bytes a Sock
  plus 12 if it moves (about 30 KB raw for 1,200 Socks; about 40 KB measured for 1,000).
- **Decided changes:** Host events about one Sock at a time (pick, drop, spill, shelve...), reliable, ids
  chosen by the Host. Never the whole Mess.
- **Rests:** one reliable batch per tick of the rows of every Sock that came to rest on the Host
  (`settle_stream.gd`), nothing when none rested.
- **Moving Socks (woken, falling, poured, swept):** never streamed. Each machine simulates them itself
  from the same events, for looks, and snaps them to the Host's rest rows (Q2222 keeps this). A Sock the
  Guest moved and the Host did not goes back.
- **Thrown bodies:** the only stream: one row per body per tick, unreliable, stamped, played 0.1 s behind.
- **Doors and drawers:** tracked on every machine, so every machine sweeps its own Socks.
- **Drawing:** local MultiMeshes; nothing of it travels.

## How the port does it today (main 92e1676)
- **Join:** `Parts.snapshot()` with the Mess's packed arrays, whole, as Variants (not compressed).
- **Decided changes:** each answer's patch carries the Mess's **whole** `states`/`poses` arrays (about
  100 KB an answer at 2,038 Socks, coop/01). A respill or a pour makes thousands of answers: the reliable
  channel backs up (the suspect of coop/07).
- **Moving Socks:** only the Host has bodies. Woken flights are spawned nodes (up to 512 over the
  spawner) with no synchronizer, so a Guest sees a Sock vanish and appear again where it rests.
- **Thrown bodies:** the same spawned node, no stream yet.
- **Doors and drawers:** swept on the Host only.

## The differences, flagged
| | Old | Port today | Plan |
|---|---|---|---|
| A decided change | one Sock's event | the whole arrays | the changed records only, compact (coop/07) |
| Rests | one batch a tick, reliable | inside each answer, whole | one batch a tick of changed records, reliable (coop/07, coop/08) |
| Woken, falling, poured, swept Socks | simulated on every machine, snap at rest | Host only, invisible on a Guest | every machine simulates its own bodies from the same wake and fall records, snaps at rest (coop/08) |
| Thrown bodies | stamped stream, 0.1 s behind | invisible on a Guest | spawner plus one synchronizer per thrown body with a stamped row (coop/01 Option A; coop/09) |
| Flights spawned on a Guest | none (local bodies) | up to 512 nodes over the spawner | none for woken Socks (local bodies); the spawner only for Throws |
| Doors and drawers | swept on every machine | Host only | every machine sweeps its own bodies, looks only on a Guest (coop/08) |
| Join | gzip of a compact codec | Variants, whole, uncompressed | the compact codec, compressed, moving Socks with their velocity (coop/08) |
| A Guest's Mess | could be moved and put back (`take_before`) | read-only | read-only for records; local bodies are looks only and never wake, write or rest anything shared |
| ENet throttle | held at full | held at full (coop/03) | kept |

## Why this shape (not the per-body stream for everything)
coop/01 measured about 4.8 KB/s per flying body on its own synchronizer. A pour or a big wake has up to
512 bodies at once: about 2.4 MB/s, far too much. Mass motion is cheap to simulate and only its end matters
to the game, so it stays local with a reliable rest snap, as the old game did; only Throws, a few at a
time and watched closely, get the stream. Bandwidth then grows with how many Socks change, not with how
many exist.

## Budgets the build is measured against
- A respill or a 2,000-Sock pour with a Guest: the Guest stays connected, its Mess equals the Host's once
  all rest, at 0 ms and 50 ms one way.
- Reliable bytes a second during a 2,000-Sock pour: measured before and after (target: under 64 KB/s
  average with a burst cap; the number is a placeholder until measured).
- Join of a 2,000-Sock Mess: under 100 KB on the wire (old: about 40 KB a 1,000).
- A Guest's frame time during a pour within the Host's (the same local bodies, budget 512).

## Tickets
- coop/07 (running): reproduce the disconnect; answers carry changed records only; rests batched a tick.
- coop/08: local bodies on every machine for woken, falling, poured and swept Socks, snapping to the
  rest batch; Doors and drawers swept on every machine; the compact compressed join with moving Socks.
- coop/09 (batch 3's other half): Throws on the stamped stream, the Guest's pick and Throw stand-ins
  (Q2220, Q2221), the Hands keyed by player id.
