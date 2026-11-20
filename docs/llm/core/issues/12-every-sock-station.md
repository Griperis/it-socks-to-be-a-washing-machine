---
type: ticket
status: ready-for-human
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[10-one-mess-for-the-zoo]]"]
notes: []
terms: []
---

# The every-Sock station

A zoo station that lays out every Sock of the game on the ground (Q2290), at the end of the zoo. With one Mess for the
zoo (core/10), Designs repeat across stations; this station shows the whole catalogue in one place.

## Behaviour list
From the designer's answers (Q2290, Q2294, Q2295).
- E01 The station lays out both Socks of every Design in `game/sock/designs.tres` (about 1,000 Designs, so about
  2,000 Socks) in rows by Collection, one row (or block of rows) per Collection with the Collection's name at its
  start, the Designs in id order, each Sock beside its mate.
- E02 In front of each Sock lies its info as text: the Design's id, name, Collection, Size and rarity (the first still
  shows the wording; the designer may change it).
- E03 The Socks are real Socks of the zoo's one Mess: you can pick, pair, throw and shelve them like any other.
- E04 The zoo is never saved and always starts fresh: nothing of this station (or any station) is written to a save,
  and each start lays every Sock back in its place.
- E05 It stands at the end of the zoo, off the grid, clear of the other stations' pads (the zoo test's check); the
  zoo's floor grows to hold it if it must.
- E06 A new Design added to `designs.tres` appears at the station with no other change (the layout is made from the
  catalogue, not placed by hand).

## Design
Built as follows (agent draft, core/12).
- **Made from the catalogue at run time, not baked.** `EverySockStation` (`game/zoo/every_sock_station.gd`, the root script of
  `stations/every_sock.tscn`) builds the SockSpots and labels in `_enter_tree`, before any Mess reads `Spots`, so it runs
  alone (its own Mess) and in the zoo (joined by `ZooStations`) with no change to either. Order: Collections by their first
  Design's id, Designs in id order, so Sock ids are the same on every machine. SockSpots are named `d<id>_a` / `d<id>_b`
  (a Design's two Socks are neighbouring Sock ids); labels `d<id>`; names `Name_<collection>`.
- **Layout** (all numbers in `every_sock_layout.tres`, placeholders for the designer's eye): 25 Designs a row, 1.0 m a cell,
  0.7 m a row, the two Socks 0.4 m apart, the info label 0.3 m in front, the Collection's name 2.2 m left of its first row.
  One block per Collection (17 blocks, 42 rows, about 38 m deep).
- **One label a Design, not a Sock.** The info lies between and in front of the two Socks (3 lines: `id name`, Collection,
  `size, rarity`), one `Label3D` a Design (1,004 labels), as both Socks of a Design have the same info. The ticket said "in
  front of each Sock"; one label for the pair is readable at 1 m (a label per Sock would be 0.3 m wide). [later] the designer
  may want two.
- **Place.** The station's root sits at (0, 0, -14) in its scene (off the grid, beyond the grid's first row); its pad is
  36 x 42 m. The zoo's floor grew from 40 x 40 to 40 x 80 m (centre z -20) and the zoo Mess's bounds with it
  (AABB -20,-2,-60 .. 40 x 8 x 80).
- **E04.** The game has no save code at all today (no `user://` writes outside tests), so nothing of the zoo is saved; a test
  holds it (the zoo writes nothing to `user://`; a Sock taken in one zoo lies in its place in the next).
- **Cost** (headless, 300 frames after 60 warm-up, this sandbox; the F3 overlay and a GPU were not available, so drawing is
  not measured):

  | | Socks | nodes | Zoo + all Socks drawn | process / frame | physics tick |
  |---|---|---|---|---|---|
  | before | 21 | 756 | 75 ms | 0.14 ms | 3.3 ms |
  | after | 2,031 | 44,000 | 360 ms | 9-10 ms | 39-40 ms |

  Without the 1,021 labels the figures do not change: the cost is the Socks. Suspect (not tested): each lying Sock's
  `looks_graybox.tscn` is about 20 nodes with a Skeleton3D and an AnimationPlayer; 2,000 of them are 44,000 nodes. The old
  plan for this (the Mess's MultiMesh, "M3" in `mess.gd`) would remove it. A 39 ms physics tick is over a 60 Hz budget:
  the zoo with this station will stutter on a slower machine. [later] decision for the designer / a core ticket.

## Acceptance
- One test per behaviour line; the real-path case: the player walks to the station, picks a Sock and its mate and
  they pair.
- The zoo's frame time and load time before and after, in the report.
- A still of the station (an overview and a close-up of one row with its labels) in `builds/review-core-12/`, stopped
  for the designer's go.

## Answers
- Designs may repeat across stations; this station shows every Sock (Q2290, 2026-11-20).
- Rows by Collection, the name at the start, Design order, each Sock beside its mate (Q2294, 2026-11-20).
- Real Mess Socks; the zoo is never saved and always starts fresh; each Sock's info as text in front of it (Q2295,
  2026-11-20).

## Open follow-ups
- [later] The zoo's frame cost with this station (above): 39 ms a physics tick headless. Needs the Mess's MultiMesh
  (or a cheaper lying Sock Looks) before the zoo is comfortable; or the station is switched off by default.
- [later] A label per Sock rather than per Design (see Design).
- [later] Sock ids of every other station shift (the Cabinet's first, then this station's 2,008, then the rest, file-name
  order); `Session.PROTOCOL` is not bumped (no Part id, spawnable or shape changed), the lead may want it bumped.

## Built log
- Model: Sonnet (lead): layout and data from the catalogue, no new rules.
- 2026-11-20, agent: first still, waiting for the designer's go.
  Changed: the every-Sock station (built from `designs.tres` at run time), its layout Resource, the zoo's floor and Mess
  bounds (40 x 80 m), a shot action `every_sock` (overview, row), `tests/every_sock_test.gd` (E01-E06 and the real path).
  Files: game/zoo/every_sock_station.gd, every_sock_layout.gd, every_sock_layout.tres, stations/every_sock.tscn, zoo.tscn,
  tools/shot_hooks.gd, tests/every_sock_test.gd. Stills: builds/review-core-12/overview.png, row.png.
  Verified: see the commit.
