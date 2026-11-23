> Behaviour list for core/42 (the Hand-off between players), written from the reference on 2026-11-23, for the designer to approve. Step 1 of the `migration-port` skill: nothing is built. The open choices are `[blocking]` Open follow-ups in `docs/llm/core/issues/42-hand-off.md`.

# M3 piece 2: Hand-off between players (behaviour list, draft)

Words follow `GLOSSARY.md`. Paths are in `reference/it-socks/` (tag v0.1.1) unless they start with `game/` or `docs/` of the port (a line says "port" then). "Old" is the game at tag v0.1.1. A line is one thing the designer can keep or drop. Nothing is left out as minor. Abbreviations: **RD** `game/player/rig_drop.gd`, **RA** `game/player/rig_aim.gd`, **HR** `game/hands/hands_rules.gd`, **G** `game/core/game.gd`, **FR** `game/world/flight_rules.gd`, **HV** `game/hands/held_view.gd`, **HO** `data/tuning/hand_off.json` (placeholder: bounce 0.25; the two glow numbers belong to Sole Mates, M4), **P** `data/tuning/players.json` (body_radius 0.3, reach 2.5).

What it is: a right click aimed at a Teammate hands them the active item (progression/11 and multiplayer/07, Q244, Q255, Q652, Q658, Q663). A Throw that hits a Teammate without a full charge is the same Hand-off by flight ("caught"); a full-charge Throw knocks down instead (list 04 of M0.6, built in coop/10). Only the giver hands over: nobody takes from another player's Hands (Q244). Scope here is **a loose Sock or a Pair** in the Hands (the port's only held things today). What the old game also hands over (the Radio, the Beeper, a Guide card, the lantern; the Cat, a Gift box, a Part and a Laundry bin refuse or go down) waits for those things (section I).

Scope tags: **(zoo)** can be shown in the zoo with two players today; **(needs X)** waits for another piece.

## Behaviour list

### A. Aiming at a Teammate

1. When the local player's crosshair line meets a Teammate's body within reach (`players.reach` 2.5 m, shortened by the first wall the line meets), then that Teammate is "aimed". The line is tested against the segment from 0.1 m over their feet to the top of their body height (crouch counts), within `players.body_radius` 0.3 m; the point where the line enters the body counts, not their middle. (zoo) (ref: RA:25, 224-253; P body_radius, reach)
2. When a Teammate stands in front of a Sock, a floor Pair or a Station, then the Teammate is aimed first if nearer; the Hand-off is chosen only when no other right-click target (a drawer drop-in, the washer, a worn or carried device) takes the click first. For a Sock or a Pair in the Hands the only competing target is the plain drop. (zoo) (ref: RD:14-60; RA:25)
3. When two players are in the Elevator's car, then neither blocks the other's aim. (needs the Elevator, M5) (ref: RA:238-240)
4. When the aimed Teammate is knocked down or in the drum, then the old code does not exclude them: they are aimed like anyone (a knocked body is a ragdoll in the port; see Questions). (needs coop/10, built) (ref: RA:232-253 has no down test; `handoff_mate()` RA:213-220 tests only the giver)
5. When the player is not the local one (a Teammate's puppet), then no Hand-off is aimed there; only the local player hands over. (zoo) (ref: RA:214 `rig.remote`; RD:50)

### B. When the click is a Hand-off

6. When the right button is released after a short click (a hold with Throw bought charges a Throw instead), then the drop runs. (zoo) (ref: PL:14-19; RD:23-60)
7. When the player holds an item (the Hands are not empty, or a plain-drop thing is carried), then the click may hand off or drop; with empty Hands nothing happens at all. (zoo) (ref: G:697-699 `lets_go`; RD:56-57)
8. When a Teammate is aimed and the player holds a Sock or a Pair, then the click is a Hand-off of the **active** item only (one item per click). (zoo) (ref: RD:49-52; HR:198-220)
9. When the click hands off, then it is never also a drop: the item does not land at the crosshair. (zoo) (ref: RD:49-52)
10. When a right click is aimed at a Teammate by a Guest, then the Command goes up and nothing changes on the Guest until the Host answers (no ghost, no prediction). (zoo) (ref: HR:287-290 `predict_hands` returns {} for a Hand-off)

### C. What may be handed over

11. When the item is a fused Pair (a ball), then it may always be handed over, whatever the receiver holds (Q663). (zoo) (ref: G:1056-1059; HR:211)
12. When the item is a loose Sock, then it may be handed over only if it completes a Pair there: the receiver holds its loose mate (Q652, Q658). Socks lying on the floor stay free for anyone; only Hands to Hands is restricted. (zoo) (ref: G:1056-1062; hands.gd:138-142 `pick_result` == PAIRED; progression/spec.md "Hand-off rule's edges")
13. When the item is a Dirty Sock, then it goes over like any Sock, up to the receiver's Carry capacity (Q1049). (needs the Dirty Sock, M5) (ref: G:1058; progression/38)
14. When the loose Sock would complete no Pair there, then the Hand-off is refused: the Sock stays in the giver's Hands, the giver sees the red refusal "Not their mate" (wobbling, with the "refuse" sound), and the receiver sees and hears nothing. (zoo) (ref: HR:212-213, 278-279; G:245 `NOT_MATE`)
15. When a Dirty Sock is aimed at a Teammate who carries the Laundry bin, then it is refused with "Hands full" to the giver and the Sock stays (the bin takes their Hands; left click puts a Sock into a bin) (Q1103). (needs the Laundry bin, M5) (ref: HR:208-210, 280-281; progression/45)
16. When the Hand-off to a Teammate is refused, then there is no outline change: the Teammate stays outlined while aimed and the click is refused with the text. (zoo) (ref: progression/11 open follow-ups "The Highlight on a refused Hand-off", built as option (a))
17. When a Guide card is handed over, then it goes over like any Sock-kind item. (needs the Guide card, M5) (ref: G:1058 `Hands.is_guide`)

### D. What happens to the item

18. When the Hand-off is allowed and the receiver can take it, then the Host moves it: the active item leaves the giver's Hands and goes into the receiver's. "Can take" means: nothing is carried in their Hands (a Bin, device or Cat), and for a Pair the Hands are not full, for a Sock a place is free or it pairs. (zoo) (ref: HR:214-216, 513-517; hands.gd:109-115 `can_take`)
19. When the item leaves the giver, then the giver's "drop" cue plays (for everyone: the Teammate's drop sound in 3D at their feet plus 1.2 m, list 02 line 106), and the giver's Hands close up as in any drop (the new active item per the Hands' rules). (zoo) (ref: HR:513-517; audio/sound_installer.gd:10, 41-52)
20. When the item enters the receiver's Hands, then it goes in like a pick: a Pair or Sock plays "pick"; a Sock that pairs there plays "pair" and shows "Paired!" to the receiver; a new Pair goes to the end of the Hands and becomes active (Q2304). (zoo) (ref: G:1454-1467 `pick_into`; HR:517)
21. When the pick-in plays, then the receiver also hears the "pick" or "pair" in the Hands' usual way, and everyone else hears it at the receiver as a Teammate's cue. (zoo) (ref: G:1458-1464; sound_installer.gd:10, 41-52)
22. When a loose Sock goes into a Teammate's Hands while another Teammate holds its mate, then the "match" (Sole Mates) signal fires for each holder. (needs Sole Mates, M4; nothing shows without the Upgrade) (ref: G:1465-1466 `matched`; campaign/sole_mates_view.gd:189)
23. When the receiver cannot take it (their Hands are full, or a place is not free), then the Host lays it down at the receiver's feet as a lying Sock or Pair (not a flying body), and the **receiver** sees the red refusal "Hands full" and hears "refuse"; the giver sees nothing. (zoo) (ref: HR:217-219, 266-275; G:1445-1448; the receiver gets the text, `game.refuse(int(ev["to"]), "Hands full")`)
24. When the item lands at the receiver's feet, then the landing is decided by the same lay rules as a drop at their feet (square to the giver, no R turn, Q2304). (zoo) (ref: HR:217-219 `landings.decide_lay`; Q2304)

### E. How it looks

25. When the Hand-off goes through, then the item is drawn flying from where the giver's hand held it into the receiver's Hands: the receiver's held view is told the start point (the giver's item transform origin) before the Hands rebuild, then the item flies in over `cloth.pick_time` 0.3 s. (zoo) (ref: ui/teammate_news_installer.gd:38-42; rig.gd:281-283; HV:136-138, 291-296; data/tuning/cloth.json pick_time)
26. When the flying item starts, then it starts flat with a random turn about up at the Sock's size, and its start point is the giver's hand, not the Mess. (zoo) (ref: HV:291-296)
27. When the item flies, then its position eases with smoothstep from the start to the receiver's hand, its turn eased too, with a 0.18 m arc over the straight line (`0.18 * 4u(1-u)`). (zoo) (ref: HV:485-492)
28. When the flying item is a Pair that makes a new ball in a Teammate's hand, then it plays the small sparkle burst and ring once the ball reaches their hand (the old teammate version of the paired moment). (zoo) (ref: HV:290, 502-512; port: `game/hands/mate_sparkle.gd`)
29. When a Sock pairs in the receiver's own Hands, then the receiver sees the full paired moment (the two Socks roll into a ball that pops with a sparkle burst) on their screen. (zoo) (ref: HV:280-289; list 03 J04)
30. When the giver is aimed at a Teammate holding something, then that Teammate's avatar is outlined in the Hand-off reach (the Highlight: every visible mesh of the avatar except the held items, the Trail and the outline's own copies), in the usual warm white, never red, never saying right or wrong. (zoo) (ref: RA:163-170; Q507; list 02 line 96)
31. When no other target is aimed and the click would be refused as a drop (nowhere to drop), then the crosshair turns red; with a Teammate aimed it does not (a Hand-off is possible). (zoo) (ref: RA:112)
32. When the giver aims a Teammate, then the corner prompt says "Drop" (or "Drop / hold: Throw" with Throw bought) as for a plain drop: there is no "Hand over" text. (zoo) (ref: ui/prompts.gd:93-96; weak, see below)

### F. Hand-off by Throw (the catch)

33. When a Throw below full charge hits a Teammate's body in the air (a sphere against the body's cylinder, within 0.3 m plus the Flight's radius), then the Host asks the same rule as a Hand-off. (zoo) (ref: world/flights.gd:283-297; rig.gd:687-692; FR:293-317)
34. When that Throw is a Pair, or a Sock completing a Pair there, and the receiver can take it, then it is caught into their Hands exactly as a Hand-off: the flight ends, the item flies in from where it hit (the pick-in start point is the hit point), and the pick sounds play as in lines 20-21. (zoo) (ref: FR:312-313, 320-325; game.gd pick_origin)
35. When that Throw is a Sock that would complete no Pair there, then it bounces off the body at `hand_off.bounce` (0.25) of its speed, falls, and lands later by the Host's word like any Flight. Nobody sees a message or a refusal. The Flight's model is drawn from where it hit, not gliding there; a Guest's own predicted Throw eases in from where it was drawn over `release.predict_blend` 0.2 s. (zoo) (ref: FR:308-311, 326-327, 204; world/flights.gd:300-313; HO bounce)
36. When the receiver cannot take the caught item (no room), then it is laid at their feet and the receiver sees "Hands full" with "refuse" (as line 23). (zoo) (ref: FR:314-316, 328-330)
37. When the Throw is a full charge, then it knocks down instead and no Hand-off is asked (knockdown list 04, coop/10). (already built) (ref: FR:333-349)
38. When a Throw hits the thrower, a down player, a player in the drum or an Elevator rider, then nothing happens for the catch (the knockdown exemptions, Q2484); the old catch has the down/drum/car test only for objects (Radio etc.), so a down Teammate could catch a Sock by Throw (see Questions). (zoo) (ref: FR:297-306 vs 338)
39. When the Radio, the Beeper, a Guide card or the Cat is Thrown (below full charge) at a Teammate, then it bounces off, drops at their feet and is never caught (Q1936). (needs those things, M5) (ref: FR:299-306)

### G. The Host and a Guest

40. When a Hand-off is asked, then only the Host decides it; the Command carries the receiver id and the giver's feet position; the Host refuses it if `to` is not another player in the game or the giver's Hands are empty. A Guest's Command for any other player's Hands is ignored (Q244). (zoo) (ref: HR:198-210; G:1122-1124; multiplayer/07 built log)
41. When the Host answers, then every machine applies the same event: the item leaves and enters Hands by the player ids in the event, and the lay-down at feet is the same pose everywhere. (zoo) (ref: HR:257-283)
42. When a Guest's Command has no answer after 2 s, then the old game keeps waiting; the port's rule for a pick, drop or Throw (Q2477, Q2482: back to the Hands, "refuse" only) may be extended to a Hand-off. (zoo) (ref: decisions Q2477, Q2482; the old game has no timeout for a Hand-off)

### H. The small details of the receiver's side

43. When a Teammate hands the receiver a Sock, then the receiver gets no message line naming who gave it ("A Teammate gave you a Sock" does not exist). (zoo) (ref: ui/teammate_news_installer.gd:38-42 shows only the flight)
44. When a Teammate hands over, then no pad rumble goes to either player for the Hand-off itself; the receiver's pair buzz plays when a Sock pairs. (zoo) (ref: audio/sound_installer.gd:42-44)
45. When the item is handed over, then no one takes from another's Hands (no "take" verb, no grab from a Teammate's Hands). (zoo) (ref: multiplayer/07 Q244; m06-lists/03 I12)

### I. Hand-off of things the port does not hold yet (for the record)

46. When the Radio is carried and the click is aimed at a Teammate with empty Hands, then it is handed over (Q367); with anything in their Hands it goes down at their feet and they see "Hands full". (needs the Radio, M5) (ref: devices/radio_rules.gd:82-120)
47. When the Sock detector (Beeper) is carried, then the same as the Radio. (needs the Beeper, M5) (ref: devices/beeper_rules.gd:108-125)
48. When the lantern is thrown at a Teammate, then it is caught or lands at their feet. (needs the Grotto lantern, M5) (ref: FR:60-63; house/lantern_rules.gd:141-168)
49. When a Gift box is carried, then it is never handed over (it goes down where aimed). (needs Gifts, M5) (ref: RD:39-46)
50. When a Part, the Cat or a Laundry bin is carried, then a Hand-off is refused or goes down as a plain drop. (needs those things, M5) (ref: HR:30; progression/45)

## Co-op: what the Host decides, what a Guest predicts (`docs/migration/coop-structure-for-the-port.md`)

- **The Host decides everything:** whether the Hand-off is allowed (the rule of lines 11-17), whether the receiver can take it, who ends up holding what, where the item lies when it does not fit. The Command is addressed to the Players Part (per-player Hands state lives there, "Hands and what a player carries" in the structure file); its answer carries who gave, who received, which item, whether it was refused and why.
- **A Guest predicts nothing:** no ghost, no early removal from the Hands. Looks only means the Hands change on the answer (F1 of the structure file); a Hand-off was never predicted in the old game either (line 10).
- **A Teammate's view is looks only:** the flight of the item into the receiver's Hands is drawn on every machine from the Host's event (lines 25-29); it changes no state.
- **By Throw (section F):** the Host owns the flight body; the thrower flies a looks-only ghost (Q2573, Q2481), and the Host decides catch or bounce from the body it runs. The catch needs the hit test of coop/10 (knockdown list 04 lines 12-26); the same test serves both.
- **Leavers:** a player who leaves drops everything where they stood (Q2486); no Hand-off is pending across a leave.
- **Late join:** a Hand-off is an instant event; nothing of it is in the join snapshot.

## Already in the port

- `game/hands/hands.gd`: per-player Hands state keyed by player id, pick, cycle, drop, throw with sequence numbers; no Hand-off Command, no `can_take`, no teammate-aimed drop.
- `game/hands/held_view.gd`, `game/hands/mate_sparkle.gd`: a Teammate's held items and the small burst at their hand when their pick makes a Pair (coop/05); the flight-in of a pick exists for the own Hands.
- `game/player/player.gd`: the refusal line (`show_refusal`) and `KNOCKED_BY_UNKNOWN`; `game/ui/hud.gd` the wobble (`_wobble_at`).
- `game/outline/`: the Outline component and `OutlineStyle`; no Teammate-aimed outline.
- Aim: `game/hands/aim_finder.gd` finds Socks; it does not find Teammates (no `mate_at`).
- The sounds `pick`, `pair`, `drop`, `refuse` and the Teammate cues exist (core/17, coop/05); the `match` sound is M4.

## What was weak in the old game (for the designer to weigh)

- The right click names no Hand-off: the key hint reads "Drop" while a Teammate is aimed (line 32).
- The refusal "Hands full" goes to the receiver, who did nothing; the giver sees nothing and the item has landed at the receiver's feet (line 23).
- A refused loose Sock by Throw gives no message to anyone (line 35); a refused Hand-off gives "Not their mate" only to the giver (line 14).
- A knocked-down or drum-bound Teammate can be handed to (line 4), and a down Teammate can catch a Throw of a Sock (line 38), while the knockdown has exemptions.
- A Guest waits for the Host with no timeout for a Hand-off (line 42).
- With the start Carry capacity 1 (data/tuning/hands.json start_capacity 1) "Hands full" is the common outcome until the Carry Upgrade; the port's start capacity decides how often.
- Nobody is told who gave them something (line 43).

## Questions for the designer

1. **Is the catch by Throw (section F) part of this piece?** It shares the rule and the hit test with the Hand-off and with knockdown. Include now (recommended), or only the right-click Hand-off and a bounce for any Throw that hits a Teammate?
2. **Does the old restriction stay?** A loose Sock is handed over only when it completes a Pair (Q652, Q658, Q663 decided it in the old game). Keep, or allow any Sock?
3. **The refusal text and where it shows.** Old: "Not their mate" to the giver; "Hands full" to the receiver. Keep, or also tell the giver that the receiver's Hands were full?
4. **Who may be handed to.** Old: anyone aimed, a knocked-down Teammate included. Keep, or refuse a knocked-down Teammate (as the knockdown's exemptions do)?
5. **A refused loose Sock by Throw.** Old: it bounces with no text. Keep, or tell the thrower "Not their mate"?
6. **The corner hint.** Old: "Drop" while a Teammate is aimed. Keep, or show "Hand over" (a text addition)?
7. **Telling the receiver who gave.** Old: nothing. Keep, or a line like the join toast in the giver's colour ("<Name> gave you a Sock")?
8. **A Guest's Hand-off with no answer.** Old: waits. Keep, or the 2 s timeout of Q2477 (the item stays in the Hands, "refuse")?
