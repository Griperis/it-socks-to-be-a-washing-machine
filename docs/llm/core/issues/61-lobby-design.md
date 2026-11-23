---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: next
created: 2026-11-23
done:
blocked_by: []
notes: ["designer 2026-11-23: prepare the Lobby while M3's lists are written", "Q2561: the World list, Continue/New Game and Delete come with the Lobby"]
terms: [Host, Guest, World, Group, Part]
---

# M4's second piece: the Lobby (design)

core/58 put the title, Options, saves and one loading screen on main; Solo and Host go straight into the house
(Q2561). The Lobby is next in M4: where Worlds are chosen and players gather before the house. A design ticket:
findings and a proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks` (grep; never commit there): the Lobby (catalogue B61: `game/lobby/`,
`game/net/lobby.gd`; pedestals, ready state, countdown, the Wardrobe page, stats card, the World settings sidebar
drawer, the greyboxed giant sock drawer scene), Worlds and Groups as the Lobby shows them (B62: the World rows,
Continue / New Game / Delete, the Group lock the designer dropped, Q2553-Q2563), what the Lobby offers after an
ending (B23, P36), its leftovers (P73) and Steam's part (P40, P75: friends-only lobby of 4, "Invite friends"; Steam
itself stays later). Write `docs/migration/m4-lists/02-lobby.md` in the shape of `01-main-menu-and-saves.md`: every
line, every motion, glide, pop and sound (Q2277), with its old file:line; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/lobby.md` (proposal): the Lobby as a scene on the one Theme; how it sits between the title,
core/58's `Worlds`/`SaveStore` and the house's loading screen; the Host / Guest flow in the co-op shape (scene Parts,
the Host authoritative; ready and countdown as Part state; what a Guest sees while the Host is in a menu); how a
World row is shown and deleted; the Wardrobe and stats card (port now, or split out). Say what core/58's code is
reused and what changes. Split the build into tickets of one mergeable piece each, in order. End with the choices
for the designer, 2-3 options each with a recommendation; read `docs/migration/decisions.md` first and do not ask
what is answered.

## Acceptance
- `docs/migration/m4-lists/02-lobby.md` and `docs/architecture/lobby.md` exist; every old detail is listed or
  named as dropped with its Q.
- The choices are `[blocking]` Open follow-ups here, each with options and a recommendation.
- No game code changed.

## Open follow-ups

## Built log
