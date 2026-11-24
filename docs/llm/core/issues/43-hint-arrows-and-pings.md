---
type: ticket
status: in-progress
kind: build
area: ui
feature: core
priority: next
created: 2026-11-21
done:
blocked_by: ["[[42-hand-off]]"]
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M3", "triaged to M3, soon (Q2533, 2026-11-23)", "suggested model: opus (co-op netcode and HUD)"]
terms: []
---

# Hint arrows and pings

Port of the old game's edge arrow pointing to an off-screen hint target (progression/76) and the pings: middle-mouse bubble, emoji wheel, edge marker, teammate outlines through walls (catalogue B65).

## Acceptance
- Built from `docs/migration/m3-lists/03-hint-arrows-and-pings.md` as answered (Q2590). Blocked by core/42 for the shared aim-at-a-Teammate test (list 03 line 16, list 02 lines 1-5).
- A `click_middle` input action (`python3 kit/tools/input_actions.py add`) and pad R3: a tap under 0.25 s pings, a hold opens the wheel; works in any co-op session, alone or not (lines 1-8).
- The wheel (lines 9-15): five keycaps Here, Help, Yes, No, Nice, 150 px ring, 40 px dead centre, chosen slice orange and 1.18 times, dark disc, hover tick and click sounds; the mouse steers the pointer, not the view.
- What a ping targets (lines 16-21): a Teammate, a Sock or a floor Pair, then anything with the Outline component, else a ring on the surface; into empty space nothing happens; range 30 m.
- Highlight (lines 22-30): outline in the pinger's colour, through walls, 2.2 times as wide, 4 s, a ring on bare spots, pop-in 0.15 s, fade over the last second; nothing drawn on the pinged Teammate on their own machine.
- Emoji (lines 31-39): the sticker bubble over the target and a small copy beside the pinger's head, 3 s, hidden behind walls; one ping per player, a new one replaces the last; one soft blip at the spot for everyone (lines 40-43).
- Hint arrows (lines 44-55): an edge arrow for each off-screen target (behind the camera too), margin 56 px, size 34 px, at most 4, ping arrows first then nearest, sliding along the edge clear of the HUD's parts, the emoji beside it; an open source list, the ping its only source now.
- The corner hint "Ping" with the middle-mouse icon when pinging works (line 56).
- Real-path case (kit/docs/TESTING.md "The real path"): a pressed middle-mouse action held past 0.25 s opens the wheel, a mouse move toward Help and the release place an emoji ping on a Sock under the crosshair on the second player's machine (bubble, outline, blip), and with the target off screen an arrow points to it in the pinger's colour.
- Co-op cases at 0 ms and 50 ms one way (two machines in one process): a ping made by the Guest and by the Host is seen on the other machine at 0 ms and 50 ms with the same target, emoji and end time; a Guest sees its own ping only on the Host's answer; a ping on a Sock picked up meanwhile stands at its spot; pings are not in the join snapshot.
- Small details kept (Q2277): every numbered line of the list is built, or named in the ticket as dropped by the designer; each carries a typed Resource number marked `# placeholder`. Look and feel numbers get no test (Q2421); its station shows them.
- A zoo station for the feature (the `zoo-design` skill), then it lands in the main scene; `kit/tools/run.sh --touched` ends PASS.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).
- Q2590: every recommended answer stands: pinging alone works; a ping outlines anything with the Outline component; empty space does nothing; one blip for all (a per-emoji sound tracked to M1.1); the pinger sees it on the Host's answer; the arrow is built now with pings as its first source; only the "Ping" hint; no keyboard keys for the wheel (2026-11-23).

## Open follow-ups
- [answered, see Answers] Pinging when playing alone (list 03, line 2). Old: works in any co-op session, even with no Teammate yet (Q363). Options: (a) keep (recommended); (b) only with a Teammate present.
- [answered, see Answers] What a ping may outline (lines 16, 19, 22-24). Old: a Sock, a floor Pair, a Teammate, an Upgrade station, Drawer or Openable; other furniture gets a ring. Options: (a) anything with the Outline component (recommended: the port's one outline, Q2292, Q2298); (b) the old short list.
- [answered, see Answers] A ping into empty space (line 17). Old: nothing happens, nothing shows. Options: (a) keep (recommended); (b) the "refuse" sound with no text; (c) a ring at the farthest point.
- [answered, see Answers] One sound for all (line 41). Old: one blip for a highlight and every emoji. Options: (a) keep, a per-emoji sound tracked to M1.1 (recommended); (b) a per-emoji pitch or sound now.
- [answered, see Answers] How soon the pinger sees it (co-op section). Old: on the Host's answer, a round trip after the click. Options: (a) keep (recommended: as old, looks only on the answer); (b) the pinger's own ring at the click as a looks-only ghost.
- [answered, see Answers] The arrow's scope here (section G, lines 53-55). Only pings feed it until M4. Options: (a) build the arrow Control with the ping source and an open source list now (recommended); (b) build it with the X-ray piece in M4.
- [answered, see Answers] The hold-emoji hint (line 56). Old multiplayer/19 had "[MMB] hold: Emoji"; the current list shows only "Ping". Options: (a) only "Ping" (recommended: as the current old game); (b) show both.
- [answered, see Answers] Wheel for a keyboard-only player (weak points). Old: none. Options: (a) keep (recommended); (b) keys 1 to 5 while the wheel is open.
- [later] The X-ray, Mate Radar and Laundry bin arrow sources plug into the open source list in M4 and M5 (lines 54-55).

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/03-hint-arrows-and-pings.md` (56 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). Pings (A-F, H), the hint arrow (G) and the co-op split. Eight open choices. No game code.
- Files: `docs/migration/m3-lists/03-hint-arrows-and-pings.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.

### 2026-11-23 (shaped)
- Changed: shaped for building after Q2588-Q2591: answers, checkable Acceptance, model, status ready-for-agent. Docs only.
- Files: this ticket.
- Verified: docs only.
