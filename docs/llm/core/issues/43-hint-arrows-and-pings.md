---
type: ticket
status: needs-info
kind: build
area: ui
feature: core
priority: next
created: 2026-11-21
done:
blocked_by: []
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M3", "triaged to M3, soon (Q2533, 2026-11-23); to shape with its behaviour list"]
terms: []
---

# Hint arrows and pings

Port of the old game's edge arrow pointing to an off-screen hint target (progression/76) and the pings: middle-mouse bubble, emoji wheel, edge marker, teammate outlines through walls (catalogue B65).

## Acceptance
- Step 1 (2026-11-23): the behaviour list `docs/migration/m3-lists/03-hint-arrows-and-pings.md` (the `migration-port` skill, step 1:
  every line, motion, glide, pop and sound with its old file:line; what was weak) and its open choices as
  `[blocking]` Open follow-ups. Then the designer approves the list and the ticket is shaped for its build.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).

## Open follow-ups
- [blocking] Pinging when playing alone (list 03, line 2). Old: works in any co-op session, even with no Teammate yet (Q363). Options: (a) keep (recommended); (b) only with a Teammate present.
- [blocking] What a ping may outline (lines 16, 19, 22-24). Old: a Sock, a floor Pair, a Teammate, an Upgrade station, Drawer or Openable; other furniture gets a ring. Options: (a) anything with the Outline component (recommended: the port's one outline, Q2292, Q2298); (b) the old short list.
- [blocking] A ping into empty space (line 17). Old: nothing happens, nothing shows. Options: (a) keep (recommended); (b) the "refuse" sound with no text; (c) a ring at the farthest point.
- [blocking] One sound for all (line 41). Old: one blip for a highlight and every emoji. Options: (a) keep, a per-emoji sound tracked to M1.1 (recommended); (b) a per-emoji pitch or sound now.
- [blocking] How soon the pinger sees it (co-op section). Old: on the Host's answer, a round trip after the click. Options: (a) keep (recommended: as old, looks only on the answer); (b) the pinger's own ring at the click as a looks-only ghost.
- [blocking] The arrow's scope here (section G, lines 53-55). Only pings feed it until M4. Options: (a) build the arrow Control with the ping source and an open source list now (recommended); (b) build it with the X-ray piece in M4.
- [blocking] The hold-emoji hint (line 56). Old multiplayer/19 had "[MMB] hold: Emoji"; the current list shows only "Ping". Options: (a) only "Ping" (recommended: as the current old game); (b) show both.
- [blocking] Wheel for a keyboard-only player (weak points). Old: none. Options: (a) keep (recommended); (b) keys 1 to 5 while the wheel is open.

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/03-hint-arrows-and-pings.md` (56 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). Pings (A-F, H), the hint arrow (G) and the co-op split. Eight open choices. No game code.
- Files: `docs/migration/m3-lists/03-hint-arrows-and-pings.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.
