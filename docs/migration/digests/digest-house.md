# Digest: the house, its rooms, furniture, Doors, Elevator, exterior, light and look, art pipeline, graphics

Folders: docs/llm/flat (85 tickets), docs/llm/house (46), docs/llm/pipeline (15), docs/llm/graphics (6).
Vocabulary: GLOSSARY.md. Where the glossary still says "the flat", this digest says "the house" (the rename is decided, Q411/Q1954; see Open).

How to read the tags at the end of a rule:
- `[H]` holds for the house: confirmed in GLOSSARY.md, in data/tuning or in the code (I say which when I checked).
- `[F]` died with the flat: only true in the old L-shaped flat; not a rule for the house.
- `[S]` superseded: a later answer changed it; the later answer is named in the same line.
- `[?]` unchecked: answer exists, I could not confirm the built game still matches.
No tag = a design rule with no code check needed (look, wording, process).

---------------------------------------------------------------------------------------------------
## 1. The house (layout, levels, size, plan)

**What it is.** A detached family house with a garden, four play levels (basement, ground floor, first floor, attic) joined by a U stair, rooms joined by doorways with Doors. The garden is scenery seen from the windows, never play area. New Game starts in the basement laundry beside the washing machine. (Q383, Q387, Q384, Q390; house spec) [H, GLOSSARY "The flat"]

**Rules that bind**
- Floor area is about 2.5-3x the old flat; "about 3x is OK". Built: basement 66.9, ground 67.3, first 66.8, attic 52.9 (from 1.0 m high) = 253.9 m2 (3.02x) before the 10% growth below. (Q400-Q403 plan review; house/01)
- Levels: basement y -2.9, ground 0, first 2.9, attic 5.8. Ceilings 2.7 m (basement and ground checked in tools/blender/make_house.py; "keep the 2.7 m ceiling" Q180 was the flat's, the house keeps ceiling heights, Q995). [H]
- The house is 10% roomier (Q995, 2026-11-05): each room is 10% wider and 10% deeper (about 21% more floor); furniture, doors and ceilings keep their size; the roof keeps its ridge height (pitch 40 -> 37.4 deg); a review build came first (Q906). Inside is 10.1 x 8.34 m. [H]
- Basement (Q384, Q390): laundry (washing machine, the spill, the lost-item return spot), workshop, boiler room, and the old "storage" which became the garage with the car (Q431). New Game starts in the laundry.
- Ground floor (Q388, Q428, Q429): hall with the main stair, kitchen with dining, living room. No WC (Q428); the hall takes its space (Q429); the hall is one 2.12 x 4.70 m room (before the 10% growth).
- First floor (Q389, Q400): landing, parents' bedroom (Wardrobe Station, mirror), kids' room, family bathroom, and a home office (desk, office chair, bookshelf, printer, a filing cabinet as an openable) instead of the planned sewing room (Q400).
- Attic (Q391): a junk loft: sloped beams, a dormer window, trunks, a rocking horse, low ceilings to crouch under. The sheeted sofa is dropped (Q430); the sheeted wardrobe and its dust-sheet lift are gone too (house/12, reverses Q413). Attic eaves floor keeps Socks from 1.0 m high (Q440).
- Stairs are real stairs; walking speed on them is the same as on the flat (Q385, plan review). Built as a ramp over real steps. [H]
- No dryer is needed in the laundry (plan review Q400-Q403).
- Walkable rooms (designer, house/05, 2026-10-31): the parents' bedroom must be walk-through (the gap between the bed and the Elevator hatch was too narrow); the family bathroom's vanity must not block the way in; every room needs at least the player capsule width plus margin (about 0.8 m) on the paths from each doorway to the room's pieces, with a test sweeping the capsule from every doorway.
- The front door stays shut and decorative, does nothing (Q438, house/01; same as Q179 in the flat). [H, GLOSSARY: only the room Doors open]
- Street is north, garden south (Q419, house/08). Kitchen window, light well and drying-rack shifts of house/03's plan are kept (Q418); the Wardrobe Station stands on the parents' bedroom west wall.
- An item that ends up inside a floor slab is pushed up onto the floor above, not counted as lost and returned to the washer (Q439, house/18). The basement floor slab counts down to `lost.below` 0.3 m, deeper is lost. [H]
- The stair glass must not clip through a floor slab (designer, house/11).
- The Newel (stair wall cap) collides as drawn so a Sock cannot balance on an undrawn ledge (house/36 newel-collider).
- The ground floor has a third Cabinet spot (Q1154, Q1155, 2026-11-07). The designer asked: "Couldn't we move stuff in the hallway and move the kitchen door and put it next to the main entry door?" (Q1174) then "Could we put it in the HALL?" (Q1175); built H1 (Q1179): the Cabinet on the hall's east wall, the coat nook moved to the west wall by the front door, the plant to the living room. Later the hall plant is removed entirely (Q1228, 2026-11-08, reverses Q458's tall hall plant). GLOSSARY says the hall's Cabinet spot is cut (Q1438; progression/71, outside this digest). [S: Q1438 later than Q1179; kitchen and living room remain]

**Numbers.** Level shares of the Mess 0.25 each (placeholder, `spill.level_shares`, Q442); 10% growth decided (Q995).

**Decided against.** CC0 asset packs and a realistic look for the house (Q404). A ground-floor WC (Q428). A dryer. The "sheeted" attic furniture and its dust-sheet lift (house/12). Bikes in the garage (house/12, house/13 wontfix Q1146).

**Open**
- [house/07, status ready-for-agent, priority next Q1583] Rename "the flat" to "the house" everywhere incl. code (FlatLayout, flat_layout.json, make_flat.py); Q1954 (2026-11-18) answered "full rename including code". NOT DONE: GLOSSARY.md still says "the flat" 8 times; code still has FlatLayout. [verified]
- house/06 (untagged): "Socks on the stairs: the plan puts no Sock on a stair zone ... Should the spill lay some on the steps on purpose, keep them off, or allow only what rolls there?" (answered by Q441: lay some on purpose, see section 5).
- house/37: `docs/art/house/plan.py` (house/01's proposal picture) still draws the old plan.

---------------------------------------------------------------------------------------------------
## 2. Look: the stylised house and its furniture

**What it is.** Every main furniture piece is a soft, cosy, stylised model, one glb per piece, placed from a data list.

**Rules that bind**
- Stylised for every main piece, the soft cosy look of the style trial's left column (tools/blender/style_trial/); no realistic look, no CC0 packs (Q404).
- About 4-6k triangles per big piece, no subdivision, round silhouettes and bevels kept (Q405).
- The parents' bed duvet is dusty pink (Q406).
- The sock creature's cream stripe trim appears here and there on soft furnishings and pots, not on everything (Q407).
- Furniture colours are approved (Q416). Every flat piece was swapped for the stylised set and every piece placed (Q410).
- The washer, Wardrobe Station, radio and clock got the stylised look; the Cabinets keep theirs (Q415). Radio PowerLight kept (Q463); Wardrobe on a closed plinth (Q464); washer colours OK (Q465).
- Every door, lid and drawer of a piece is an openable that hides Socks (Q412, house/05). Chests, trunks and the toy chest that hold Socks are hollow with a real inside (designer house/12: "chests should be hollow if there are items inside"). The kitchen sink is a real basin and Socks may be laid in it (Q499). The oven is hollow (designer flat/35: "the oven should be hollow"), no bulb or light in the house oven.
- Attic trunks face the loft's middle so they open towards the centre (designer, house/12). The printer is static, not openable. The ironing board top is a flat plank with a rounded pointed nose (Q501). The dining table stands by the south window, two chairs per long side (Q497); kitchen worktop block kept (Q498); swing angles OK (Q499); office chair move, chest bands, emptied spots and leftover sofa files kept (Q500). Kitchen L layout kept (house/05).
- No door, lid or drawer may meet another, a wall or other furniture when everything is open at once (test room:openables_clear) (designer, house/12).
- The drying rack is out of the basement for now, piece kept (designer house/34: "Remove the wet clothes hangar for now from the basement."). Bikes are out of the garage (designer house/12: "remove the bicycle model and mark it for improving"); the remodel ticket was closed as no longer wanted (house/13, Q1146).
- The piano goes in the back of the living room behind the sofa, not in front of the TV (designer house/32); the Armchair and SideTable were removed, Plant and FloorLamp stay. Placed at [7.8, 7.28], facing the room (yaw 180) (pre-growth coordinates). [H, per house_layout at ticket time; ?: coordinates after the 10% growth]
- House furniture is split into parts: shell (make_house.py -> house.glb + house_layout.json), exterior, Elevator, and one model per furniture piece with its own colliders, resting tops and Openable data; moving a piece is a one-line data edit with no Blender rebuild (Q553, Q555, house/25). One agent at a time on each part (CLAUDE.md). [H]
- The Whiteboard's old model stays: the remodel (white board in oak frame on a sage easel) was merged (Q981) then reverted because "the old board looked better" (designer 2026-11-05); only its lettering got a font, Patrick Hand (Q983) (pipeline/09).

**Numbers.** Triangle budgets: prop 2000, furniture 8000, appliance 12000, large 20000, colliders 512 (Q770 accepted); Sock 320, sock ball 540 close-ups (provisional, Q-g).

**Decided against.** The realistic and CC0 styles (Q404). Mirror on the Wardrobe itself (Q973: the wall mirror beside it stays the one mirror).

---------------------------------------------------------------------------------------------------
## 3. Doors (room doors) and locks

**What it is.** A real door leaf in every room doorway except the open-plan kitchen/dining/living room/hall; a click opens or shuts it for everyone. (Q401, Q403; GLOSSARY "Door") [H]

**Rules that bind**
- Doors click open/shut, synced in co-op (host decides), saved; it never moves by itself (Q401, house/21; GLOSSARY). [H]
- About a third (3 of 8) start shut at New Game, picked at random each time (Q518, `doors.shut_share` 0.333), so rooms are discovered. The save keeps them. [H, data/tuning/doors.json]
- A swinging Door pushes Socks, Pairs and the Radio out of its way and stops short when blocked (Q403). Pushed items pop radially past the leaf (no slide). A lying Guide card is not pushed by a Door (house/70 note); the Radio is. [H partly: GLOSSARY lists Socks, Pairs, Radio]
- Shut, a Door stops the player and the light like a wall and muffles the Radio, TV and the house's sounds behind it; pings and X-rays still show through (Q519; GLOSSARY). [H]
- Look: off-white, two raised panels a face, brass lever handles (house/21 agent pick, not answered). Every Door swings into its room, except the garage's into the stair lobby.
- The attic's lock is a small, cute, house-style baby gate at the foot of the stairs up to the attic, with padlock, chain and the "Please the washing machine" hint; it opens once the attic's Stage is unlocked (a Fix, Q1008); an invisible wall over it to the ceiling holds the player (players jump about 0.76 m) until it opens (Q1040, designer 2026-11-06). The landing keeps an open doorway and no window; no door or door frame stands on the U landing (Q1132). [S: replaced the first idea, an attic door in the middle of the U landing (designer 2026-11-05, option b)]
- The car's two front doors open separately; the Boot is unchanged; the cabin stays one Hiding spot reachable through whichever door is open (designer 2026-11-06, house/39). [H]
- The garage has a shut up-and-over door on the street side with a ramp down to it outside; it never opens (Q453). The car stands so its open west door clears the doorway (Q456). Car doors open 40 deg (Q454). Garage shelves moved OK (Q455). Light wells get grates (Q461).

**Numbers (placeholders in data/tuning/doors.json)**: swing 0.6 s, muffle -9 dB with a 900 Hz low-pass, shut_share 0.333, reach 0.12 m.

**Open (house/21, untagged)**: a player in a swinging leaf's way (built: leaf moves through, physics nudges the player out); swing sides and hinges (agent's picks); the bake runs with every Door open and the shut ones swing shut after it; sounds door_open/door_close are placeholders from the wardrobe's candidates.

---------------------------------------------------------------------------------------------------
## 4. Elevator (was the dumbwaiter)

**What it is.** A small service lift beside the kitchen's Food cabinet, through all four levels: stainless car about 0.6 m a side behind a hatch, sill at waist height. GLOSSARY "Elevator" is the full current description. (Q385, Q386, Q509-Q516, Q532-Q534, Q645, Q834-Q836, Q984-Q991) [H]

**Rules that bind**
- Kitchen shaft next to the Food cabinet, through all four floors (Q509). Small car about a 0.6 m cube; hatch sill at waist height about 0.8 m (Q510, Q511). Look: a metal service hatch, stainless, restaurant-like (Q516).
- Call button beside each hatch; about 2 s per floor; the last call wins, it turns round (Q512 call part, Q513). Each hatch shows only its one brass call button (designer 2026-10-31: "The dumbwaiter should have only one button to call it to the floor, but the other code can stay." house/23) [S: reverses Q512's "at the hatch you choose a floor"; rider letters inside the car came later, Q988].
- Left click on the closed hatch or on the call button calls it; both get the normal Highlight; if the car is already there, clicking the hatch opens/shuts it (Q533).
- The hatch closes before the car leaves and pushes items on the sill inside; it never cuts or loses items (Q514).
- While a hatch is open, items fall in physically; once shut they are frozen and carried as data, no car simulated or drawn moving; on arrival they are back exactly where they lay (Q534).
- Sounds: bell on arrival, rope/pulley creak while moving (heard through the shaft), hatch sliding, button click (Q515; placeholders).
- Rename Dumbwaiter -> Elevator everywhere (Q532).
- Players ride it (designer 2026-11-01: "it should be possible for the creatures to travel through the elevator (enter it and leave it)."): the 0.6 m car stays; the creature shrinks, climbs through the hatch and rides curled up with a short animation both ways (Q645); first person, low and curled inside, framed by the car's walls, a short dim ride with a rumble, then the hatch opens on the new level (Q834); the car is called from the other floors, and a player can also climb in and ride; Hands stay with them (Q835); two players can squeeze in together with a funny squeeze animation (Q836); a dragger can pull the dragged body in as the second rider and the drag holds through the ride (Q984); a rider counts as "someone inside" so the car is solid while anyone is in it (Q816); solo riding by floor letters inside the car: aim at a letter and left click sends the car there, a locked floor shows locked and refuses with the usual Refusal, the car's floor is lit, any rider sends it, host-decided (Q988); Space stays the climb key (Q989); blend the dragged body's ragdoll into the curl, riders in the join snapshot, a placeholder rubbery squeak (Q991). Locked levels refuse the ride. [H, GLOSSARY]
- With two riders either can press a letter; a teammate in the car does not block the aim of a rider (house/46, designer bug 2026-11-18; Q508 for Stations outside the car still blocked).
- Every rider climbs out automatically where the car arrives; Space climbs out where it stands open. [H GLOSSARY; the [later] question "keep?" was recommended-keep and is built]
- The Elevator is not a stop to the Lost Sock Grotto (ladder only). [Grotto off, section 16]

**Numbers (data/tuning/ride.json, elevator.json; placeholders):** floor time about 2 s; climb 0.8 s (a lying body first lifted 0.5 s), shrunk to 0.33, curled 70 deg, 0.3 m hop over the sill, eyes 0.3 m over the car floor, riders 0.24 m apart, squeeze 0.7 s at 0.25, dim to 0.6 in 0.4 s, 12 mm rumble shake, out at 0.8 m from the hatch, reach 1.6 m, letters 0.12 m apart from 0.12 m up; hatch slide 0.5 s; car inside 0.6 x 0.58 x 0.54.

**Open (house/35, tagged [later])**: "Every rider climbs out where the car arrives" (built, recommended keep); the letters' wall (column on the +z side wall, B at the bottom, A on top) keep or move to whichever end is the back; sounds `elevator_ride`/`elevator_squeeze` are placeholders, no climb sound; a lying body far from the hatch is lifted then hops in (keep).
**Open (house/17, untagged)**: should the bake put a few Socks in the car at New Game (built empty, open at the kitchen); guest button click round-trip.
**Open (house/26, untagged)**: all "recommended" defaults built, never answered: whole door highlighted; the call button where the car stands with the hatch shut opens it (never shuts it); the hatch click plays the button's click; hatch hint E only.

---------------------------------------------------------------------------------------------------
## 5. The Mess, Heaps and Hiding spots (house side)

**What it is.** A hidden physics bake spills the Socks; they freeze as MultiMesh Socks; GLOSSARY "Mess", "Heap", "Hiding spot", "Crawl space". Since the first wash the Mess waits for the first wash's burst (progression/86; outside this digest).

**Rules that bind**
- Any Sock the crosshair reaches can be picked standing, under furniture included; no crouch rule (Q168 reverses Q145; designer flat/15, flat/24, 2026-10-29). Taking one lets Socks resting on it re-settle. [H, GLOSSARY]
- Socks under furniture lie only near its open edges (not at a wall side) so they are pickable; under low furniture (bed, sofa) right by the edge (designer flat/15). The coffee table gap is a hiding spot too (Q176).
- No hint on covered Socks (Q142). Keep Jolt as the physics (Q147). The Mess density was "keep, tune after playtest" (Q141); 160 Socks out of the washer was enough in the flat (Q186) [F].
- Socks are spread roughly evenly over the four levels (Q408), heaps still thickest near the washer; Mate distance is walking distance through doorways and stairs, not a straight line (Q409; reverses Q140's straight line, flat/10). [H, GLOSSARY "Mate distance"]
- Level shares 0.25 each, judged in a playtest (Q442, `spill.level_shares`).
- Rare Designs may place their mate on another level as a rule, not a bigger Mate distance cap (Q446, house/20); built: `mess.mates_across_levels` share rare 0.5, uncommon 0, common 0 (30 of the 60 rare Pairs), `levels_apart` 1 (placeholders).
- Socks that are too big to fit an inside slot trade places with a Design that fits (Q445).
- The bake collides with each static piece's real drawn mesh (trimesh, Jolt); resting spots on tops are found by sampling the drawn surfaces; hand-written spots only for openable insides and crawl spaces; a piece a simple collider cannot follow is flagged to the designer, never removed; live physics uses the same shapes (Q434, Q437, house/16; designer 2026-10-31: "socks on boxes ... don't lie exactly on them", "socks on sheets and stuff like that or in the car are not placed correctly (overlapping seat, ...)").
- Lay some Socks on the stairs on purpose: a few on steps and landings and a trail between floors (Q441, placeholders `spill.on_stairs` 6, `spill.stair_trail` 6). [H]
- A Sock baked into a drawer (or any moving part) rides with it while it opens and closes with no pop; Socks a player dropped in ride too (Q447); floor Pairs (sock balls) ride with the drawer (Q448); door shelves and lid trays: not now (Q449); aiming at the end spot during the slide is acceptable (Q450) (designer 2026-10-31: "socks in drawers (not placed) should animate when the drawer moves").
- Baked Socks rest within 1 cm of the drawn geometry and a dropped Sock never dips 3 mm into what it lands on (tests mess:rest_fit seeds 1-10, cloth:drop_clearance) (house/22).
- The oven, basket and cupboards open with a click and hide Socks; the basket (with a lid) lives in the laundry beside the washer (Q417); no openable dresser or bedside drawers in the flat (to avoid confusion with Cabinets) [F, flat spec].
- The Car is a Hiding spot inside and under (ground clearance 0.22 m, Q457); Socks may lie on its roof/bonnet/boot (house/16 open, unanswered).
- Top rules (placeholders, `make_house.py` SPOT_*): slope at most 25 deg, at least 5 cm over its floor, 12 cm free above, spot 6 cm in from every edge, seen from outside the piece (house/16).
- Garage: with ShelfRackB gone, `mess.hiding_weight.rare` goes 2.5 -> 3.0 (Q1540). [H data/tuning/mess.json]
- Four lesson Socks on the washer (two matching Pairs: one Basic Design, one picture Design, side by side) wait on the washer top so the player learns matching (designer flat/37 2026-10-29: "add two pairs of socks directly on the washing machine - that match, so it's a lesson for the player."; Q218, Q219). Socks lying on a Station's surface are aimed, outlined and picked by a left click; a left click on the Station with no Sock in the way still opens it; E always opens it (designer flat/40: "Let's fix the socks can be picked up on the washing machine, now it always opens the washing machine."). [?: `SockLayout.with_washer_lesson` is still called in Game.new_game; but with the campaign on the Mess is only the basement stage's Basic Pairs and waits for the first wash, so whether the lesson Socks still lie on the washer in play is unchecked]

**Decided against.** The crouch rule (Q168). Hints on covered Socks (Q142). A bigger Mate-distance cap for rare Designs (Q446: a level-crossing rule instead).

**Open**
- house/16 (untagged): Socks on the car's roof, bonnet and boot lid, "Keep, or keep the car's outside free"; piece areas for placing Socks (bunk bed 1.7 m2, workbench 1.4, bed 1.4, kitchen table 1.0, shelf racks 0.9, sofa 0.65): "OK?"; a Sock that leaned on a car door stands on end once it opens: "Re-settle them?"
- house/18 (untagged): a pushed-up item makes no pop: "Should it pop, or make another sound"; whether the whole ground under the house should push up; a Throw entering a ceiling from below bounces (lost:ceiling), "Fine?"
- house/20 (untagged): "Should uncommon Pairs cross too, and at what share?"; "Should it lie deeper into the other level?"; random vs latest-found rare Pairs.
- house/22 (untagged): a Sock found shut in on a top under a shelf (workbench under its tool rack) goes to open floor: "Should `find_tops()` skip such tops"; a Sock sunk in a drawer no 30 cm move frees goes to floor (1 in 30 seeds): "Keep?"
- flat/37 (untagged): the four lesson Socks come out of the Mess so the total stays; "confirm".

---------------------------------------------------------------------------------------------------
## 6. Mirrors

**Rules that bind**
- The Wardrobe Station mirror and the bathroom mirror show a real planar reflection of the room, teammates and the player's own sock creature (hat, held items; no name tag) (Q350, Q435, flat/48, house/15; designer house/15 2026-10-31: "mirror in the bathroom doesn't work").
- The mirror renders only while its glass is on screen; Low preset shows a soft fake gradient instead (Q350; Q352 wired to `Graphics.setting("mirror")`). [H, data/tuning/mirror.json]
- [S] Q443 (bathroom mirror always reflecting, no distance limit) and Q444 (bedroom mirror keeps its 7 m limit) are reversed by graphics/02: both mirrors now render only within 4.5 m (Q1939, 2026-11-18). [H, mirror.json `range` 4.5, `bath_range` 4.5]
- Mirror budget: looking at a mirror costs at most 1 ms per frame on High against mirrors off (Q1941); all cuts acceptable: lower resolution, no MSAA, update less often, simpler reflected world (no shadows, fewer lights, no Mess Socks, shorter far), render only up close (Q1939). Look accepted, designer measures on their PC with the next export (Q1992).
- The own reflection turn on R is local only; the held Radio's dial is frozen in the mirror (flat/50 FYI).

**Numbers (data/tuning/mirror.json, placeholders):** size 256 px (was 512), far 6 m (was 12), range 4.5 m, update_every 3, msaa 0, lamp_shadows false, mess_socks false. [H checked]

**Open (graphics/02, [later])**: the designer re-measures the 1 ms budget (High, stops mirror_bedroom/mirror_bath, `--bench-mirrors=on,off`); if over, next knobs update_every 4+, size 192, far 4, range 3, or "render only while the player stands still" or a baked picture (design choices).
**Open (house/15, untagged)**: the reflection reads paler than the room: "Keep, or tint/darken it?"
**Open (flat/48, untagged)**: door swing OK?; "Bigger or lower mirror?".

---------------------------------------------------------------------------------------------------
## 7. Piano

**What it is.** An upright piano against the living room's back wall behind the sofa. Its key lid opens and shuts like a cupboard door; with it open, aiming at a key and left clicking plays it. GLOSSARY "Piano". (Q542, Q544-Q546; designer house/33 2026-11-01) [H]

**Rules that bind**
- Click keys only: aim and left click plays; no play mode (Q544). E on an aimed key plays too (built; question open).
- All 88 keys (A0 to C8) play from a sampled real piano; the drawn keyboard has no dead keys (designer house/33: "Remove the notes and the thing on top of the piano as well. Make all keys playable."). [S: reverses Q545's 2 playable octaves] The book of music, runner and metronome on top are gone; the music desk ledge stays.
- Co-op: everyone hears it, 3D at the piano, muffled behind a shut Door; pressed keys dip for all; several keys ring at once (Q546).
- Socks rest on its top, hide under its keyboard (4 under the keyboard, `mess.spill.under.UnderPiano`) and in the key well under the shut lid (none baked, 7 cm high). Sounds must stay CC0/sampled.

**Numbers (placeholders, data/tuning/piano.json)**: a note rings 1.6 s then fades over 1.2 s; replaying a ringing key cuts it in 0.08 s; 12 notes at once; default instrument the Remeau upright; bench candidates beskhu upright, TEDAgame's, detuned old upright; size 1.42 x 0.61 x 1.25 m.

**Open (house/28, untagged)**: "Which living-room wall"; bench to compare instruments plays only middle C: "a short phrase?"; the key lid shares the kitchen cupboard's sounds: "give the lid its own candidates?"; E on a key.
**Open (house/32, untagged)**: the unused `armchair` piece: "keep it for another room or drop it?"; "The bench in front of the piano is 0.8 m from the sofa's back: tight enough?"

---------------------------------------------------------------------------------------------------
## 8. Garage, Old Tree, Cabinet spots

**What it is.** The garage (3.7 x 8.3 m, basement) holds the car, wall shelving, one shelf rack, a ski bag, the garage Cabinet spot and the Old Tree. (Q431, house/45) The Old Tree is the Upgrade station (GLOSSARY "Old Tree", "Upgrade station").

**Rules that bind**
- The Upgrade station becomes a forgotten artificial X-mas tree, half-packed, pulled half out of its torn box in a garage corner, with the decorations box beside it (designer 2026-11-10; Q1509); it looks the same all game, buying shows nothing on it (Q1510); it is called "the Old Tree" (Q1516); a tangled light string with a few bulbs still glowing warm (Q1517).
- Garage relaid out as Plan A (back-left corner, `builds/review-old-tree/plan_A_*.png`) with ShelfRackB leaving the garage entirely (Q1534); ShelfRackA does not move, its gap to the Car stays (Q1535); the tree must not clip out of its box: trunk and lower tiers sit inside the torn box, nothing passes through its walls from any side (Q1539); room for up to 4 Hampers beside it (switched off, see section 16).
- The garage layout was picked from 2-3 mock plans with shots, each plan a question (Q1512, process).
- The Cabinet spots are spread across floors, each in a room that fits its theme, so shelving means walking (Q393). Cabinet placement "OK" at the plan review (Q400-Q403); the Cabinets keep their look (Q415, Q415 restyle).

**Open**: house/44 [later] the coat nook's shoes' colliders fill its crawl space, so Socks hide under it only by chance: "Thin the shoes' colliders or space the shoes out ... if it should be a sure Hiding spot."

---------------------------------------------------------------------------------------------------
## 9. Exterior (outside the windows)

**What it is.** A simple modelled low-poly outside seen from every window: lawn, garden, fence, trees, bushes, neighbours' houses, a quiet street, lit by the day cycle, neighbours' windows glowing at night; only what is visible from inside is built. No photographed ground in the sky. (Q326 flat/45, rebuilt round the house Q419 house/08)

**Rules that bind**
- Rebuilt round the house: ground level at the ground floor (lawn y -0.3), plinth and front step, a light well (pit, gravel, grate Q461) outside each of the five basement windows, street north, back garden south, neighbours (Q419). Layout kept, plus the garage door and ramp (Q459, Q453). Attic gables face the neighbours (Q460). 38.6k triangles is fine (Q462). Casts no shadows, a few materials, about two draw calls per side. [H]
- The sky is the day cycle's HDRI blend (section 10); none of the HDRI ground shows (Q326).
- The ramp is steep (about 32 deg), the garage's north light well is gone, the front-garden flower bed gave way to the ramp, mailbox moved, picket fence has a gap, drain grate on the apron (house/19 agent choices, never answered).

**Open (house/19, untagged)**: "Keep, move the street about 8 m north for a gentler ramp, or turn the ramp along the house front?"; garage door look (2.4 x 2.1 m, teal, horizontal ribs): "Look OK?"; "Keep, or a narrow window beside the door?"; car moved 0.45 m north: "Enough?"; hall plant model (moot after Q1228).

---------------------------------------------------------------------------------------------------
## 10. Light and time of day

**What it is.** An in-game day with sun, sky, interior lamps and a night; lamps and shadows per level; HDRI skies. (flat/25, flat/28, flat/30, house/27-31)

**Rules that bind**
- The sun aims low through the windows (warm patches on floors) and follows an in-game day; the time of day is saved; a full day with night: the interior lamps carry the light and the windows go dark blue (Q169, Q171, Q172, Q173). A day lasts 20 real minutes (`day.length_minutes` 20, placeholder) and a New Game starts at 9:00 (Q199, `day.start_hour` 9). No HUD clock (Q202). Evening light falls on the walls only, no west window (Q200). [H data/tuning/day.json]
- Interior lamps are off by day and switch on at dusk with a soft switch sound, off again in the morning (Q198); lamps on 19:30, off 7:00 (placeholders `DayCycle.LAMPS_ON` 19.5, `LAMPS_OFF` 7.0). [H code] Exception: the basement lamps (every light that lights only the basement) stay on by day and their shades glow (designer house/30: "Could we make the basement lamps on in day?"; `day.basement_lamps_by_day` true).
- Lamp light is a neutral warm white (1.0, 0.88, 0.70), so night reads cosy-yellow, not pink (Q201). The globe ceiling shades glow, translucent and non-shadowing (Q203) [F: the house has new lamps; "shades" in the house still glow].
- Basement by day (Q549, Q550, Q600): dim, only the light wells light it, no sky or ambient fill below ground; lamps are the real light. After the designer's "Warm fill, a bit brighter" (Q600): `day.basement_ambient` 0.35, `day.basement_tint` #ffd4a0 (placeholders). [H data/tuning/day.json]
- At night no flicker or popping shadows and no light leaks through walls or floors (Q549); each level's lights on a render layer of its own, the shell parted by level; the lights of the levels a stair zone reaches keep their shadows so stepping off the basement flight does not pop (Q470 stairwell rule, house/31); a ceiling light keeps its night shadow 1 s after it stops qualifying (flat/72). On High only nearby lights cast shadows (Q420, "level" setting).
- The sky outside is three CC0 Poly Haven 2k HDRIs blended by the day cycle: Suburban Garden (day), Stuttgart Suburbs (dusk/sunrise), Street Lamp (night), credited in assets/sky/SOURCES.md; they also light ambient and reflections (Q211; placeholders). The sun always comes from the day cycle.
- Render polish (Q150, flat/19): AgX tonemapping with a light grade, MSAA 4x + FXAA, SSAO, soft glow, shadows on each room's ceiling light and a low warm sun, a fabric rim sheen on Socks. Values are the balance round's (Q477). [H partly: presets decide what is on, section 18]
- The zoo has a "Time of day" slider (0-24 h) (house/31, designer 2026-11-01).

**Numbers (placeholders)**: day 20 min; start 9:00; lamps 19:30/7:00; basement_ambient 0.35; basement_tint #ffd4a0; night shadow cost on High about +51% for the "level" setting (lavapipe).

**Open**
- flat/28 [kept open]: "Re-judge day and night in the house, including the lamps-on time (kept from flat/27, flat/28 and flat/31): since ticket 27 the ceiling lights really light their rooms."
- flat/28 (untagged): should lamps snap on at 19:30 or fade in; "the music starts on a random pick of the two, then alternates. Should it always start on the same one, or have a gap between tracks?" [moot: the Radio is the music, section 13]
- flat/30 (untagged): "Keep, pick a matched set from one place, or other scenes?" for the three HDRIs; "Keep the slow blend, or switch faster?" (crossfade double exposure 18:00-21:30); "Should the sky light's tint follow the hour (warmer at dusk, bluer at night)"; "Fine, or 4k for the day HDRI (about 26 MB)?"
- house/27 (untagged): "How dim is dim ... Should it be tinted"; "Is it acceptable?" night shadow cost; Medium ("room") and Low ("none") still leak through walls on your level: "Acceptable for the cheaper presets?"
- house/30 (untagged): "With the lamps lit by day, should the warm fill (house/29: 0.35, #ffd4a0) go back down? The designer judges in the build."
- house/31 (untagged): "Is the shadow cost next to a stairwell on High acceptable?"

---------------------------------------------------------------------------------------------------
## 11. Hands, holding, dropping, throwing, controls (from the flat tickets)

**What it is.** How carried items sit in the Hands and how they leave them. GLOSSARY "Hands", "Throw", "Flight" hold the full current text. Verified against GLOSSARY and `data/tuning/upgrades.json`, `hands.json`, `game/hands/thrower.gd`.

**Rules that bind**
- The newest held item is active; the mouse wheel cycles the active item, wheel down = next, wrapping; after a drop or shelve the newest remaining item becomes active (Q61-Q64, Q111). In 3D the active item hangs big and centred-right, the others tucked smaller lower-left; no HUD slot strip (flat spec; Q129 stack superseded). Right-click drop and Throw act on the active item. [H]
- A Pair is a sock ball (two socks rolled, one cuff folded over) in the Hands, on the floor and in Drawers; a rigid ball with a soft squash on landing, no spring bones (Q59, Q60, Q92). A dropped Pair lies on the floor as a ball (Q109). [H]
- Cloth: heavy, damped droop, settling under 0.5 s with almost no back-and-forth swing (Q53, Q110 "keep, tune after playtest"). A held Sock's cloth reacts to the player's movement, not to turning the view (designer playtest, flat/14); a turn must barely move it.
- A dropped or thrown Sock grows smoothly from its held size to its floor size in flight, no pop on landing (flat/17). Only the flying actor shows during a drop's flight; the Sock appears and is pickable only once it has landed, exactly where it landed (designer flat/32: "the sock mesh should be placed only afterwards the animation finishes. It should be possible to place socks on the meshes, otherwise they can stay hidden inside."). Drops and Throws settle physically like a one-Sock re-settle (Q333). [H]
- Drop (designer flat/66, 2026-10-31: "the sock should land where the cursor is; if it cannot reach, or is not landable, don't allow dropping the sock, so you can't accidentally hide it behind cabinets and unreachable spaces."): a drop lands where the crosshair meets a landable surface within pick reach (Q522: drop reach = pick reach, beyond that no drop). Landable = a flat-enough top you can see: floor, furniture tops, open drawers and insides, Heaps, a lying Pair; not walls, steep sides, ceilings, nor gaps behind or under furniture you cannot see into (Q523). While holding an item the crosshair turns red where it cannot drop; pressing drop plays the refuse sound with "Can't drop there" (Q524). Throws are unchanged: they fly freely, the lost-item rule still applies (Q525). Applies to Socks, Pairs and the Radio, in co-op (Host decides, Guest predicts). [H GLOSSARY] [S: the earlier 1 m drop range of flat/32 is gone, Q522]
- The crosshair (picks, drops, pings, Stations) meets furniture as drawn; walking keeps the boxes (designer flat/66: "the workshop storage has a collider that I can't reach the sock if it's inside one shelf."). [H]
- Throw (Q65-Q68, Q100, Q214-Q217, Q122-Q125): hold the right button past a short moment to charge (a ring fills round the crosshair), release to throw the active item along the aim with a gravity arc from the held item's spot through the crosshair point (Q122); a shorter click is a drop, right click always drops on release before and after Throw is bought (Q215); no cancel, releasing a charge always throws (Q217); Q is gone entirely (Q216; designer flat/36: "Adjust the throw so once unlocked, it can be done by holding the right click (short press drops, long hold charges throw), not q."). Thrown items rest where they land, furniture included, and can be picked up there (Q124); they do not collide with floor Pairs or Mess Socks (Q125). A Pair that touches its own Cabinet shelves itself; a Pair bouncing off the wrong Cabinet shows the wrong-Cabinet message (Q123); anything else bounces and falls. [H]
- [S] The flat's Throw was an Upgrade at about 150 Coins with levels; GLOSSARY now says Throw is free from the start but weak (Q1344) with Long Arm / Quick Charge as the Personal upgrades; the `upgrades.throw` numbers in data/tuning/upgrades.json are `hold_to_charge` 0.25 s, `charge_time` 1.2, `tap_charge` 0.15, `lob_speed` 3.5, `lob_lift` 2.0, `min_speed` 3.0, `max_speed` 5.0, `speed_per_level` 4.0, `restitution` 0.35, `friction` 0.6 (placeholders; the flat's 0.8 s full charge is [S]).
- G zooms (hold G zooms in a little, eased; designer flat/33 2026-10-29: "switch the G to zoom and right click to drop."), reversing Q148 (G drops, RMB zoom). Zoom about 1.5x over 0.15 s (Q149), 75 -> 50 deg (placeholders `view.fov`, `view.zoom_fov`, `view.zoom_time`); look speed scales with it; held items keep their on-screen size while zoomed and track the zoom instantly (Q165, Q196). [H]
- R turns the active held item where it is held (designer flat/53 "examine the Socks in hand"): a loose Sock spins slowly about its own long axis (cuff to toe) (designer flat/55: "the sock rotates weirdly, it should rotate around it's Z-axis in hand"; Q425 flutter OK), a held Pair tumbles toward you about a horizontal side-to-side axis (Q548); letting go leaves the item at its angle (designer flat/65: "the R key should leave the sock at what its rotation is"); it resets when another item becomes active, on a new pick or Pair; the turn is local only: a Teammate never sees it (Q374, Q378, Q381, Q377, Q379, Q380). Everything else keeps working while R is held. `held.turn_*` placeholders. [H]
- The Radio is 1.5x bigger (Q547). [H]
- Held info beside the active item (right of centre): the boxed Size, the Design name and Collection icon, the sock icon (ball icon for a Pair), N/Carry capacity, and a wheel icon once 2+ items are held; always shown, no option (Q153, Q154, Q167, Q197 it follows the Sock's sway; designer flat/79 Q892 "always on, with no customisation" reverses Q535's Off-by-default option; designer 2026-11-01 flat/71: show the sock name and Collection icon). Nothing shows with empty Hands. [H, GLOSSARY and flat/79 built]
- Under the crosshair an aimed Sock or floor Pair shows only the boxed Size ([S] [M] [L]) (designer 2026-10-29, flat/16); no floating 3D text anywhere in the world. [H]
- Key hints (designer flat/20 2026-10-29: "The G key looks good, could we make all keys like that?" and "Add hint to right click to zoom as well."; Q151, Q152, Q155, Q166): every hint is a keycap and the mouse icons are chunkier mice in the keycap style; a hint shows only when it would do something now; Space (Jump) and Ctrl (Crouch) hints always show; E stays the station prompt. Hints in use: [RMB] Drop, and once Throw is unlocked one hint "[RMB] Drop / hold: Throw" (flat/72); [G] Zoom; wheel Cycle with 2+ items; [R] Turn while holding; Shift Sprint once owned; the `[1] Show pair` hint was dropped because the ability icon carries its key (flat/72); the ping shows just "[MMB] Ping" (designer flat/51: "remove the double description for the ping and emoji, have just ping."). [H partly checked]
- Messages (flat/34, Q213): short and cosy, with keycap/mouse icons inline, no full stops. [S] flat/34's wrong-Cabinet message "Wrong Cabinet: these go in <Collection>" (naming the right place) is replaced by the plain "Wrong Cabinet" in the code and GLOSSARY "Refusal" ("It says only what is wrong, never what to do"); "Throw is an Upgrade: find it at the washer" and "<Kind> X-ray is an Upgrade: find it at the washer" are stale (Throw is free; the washer is not the station). Messages still binding: "Hands full  [RMB] drop one" [?], "Paired!", "Pair socks first, then shelve them here" [?], "Maxed out", "Need (coin) N", "Debug: +1000". [?: exact wording unchecked beyond "Wrong Cabinet", `game/campaign/cabinets.gd:373`]
- The paired moment (Q324, designer flat/43): picking the second Sock of a Pair makes the new Sock fly to the held one, line up, fold and roll into a sock ball in front of the camera (about 0.5 s) with a soft sparkle burst, a "pop" and the "Paired!" sound; Teammates see a small burst at that player's avatar hand; the Hands' state changes instantly, presentation only. A Pair made by a Hand-off or caught Throw plays it too. Bigger and juicier (Q541): stronger squash-stretch, more sparkles in the Collection's colour, a small ring/shockwave, slightly louder pop (`paired.pop_scale` 1.45, 44 sparkles, pop +3 dB). [H: `game/hands/paired_moment.gd`, `data/tuning/paired.json`]
- A debug build has F9 adding Coins (`debug.cheat_coins` 1000); release exports ignore it (designer flat/41: "add debug money cheat"). [H]
- Walking speed: base 4.0 m/s (flat/76 reverses flat/73's halving); Speed Upgrade per level 5% (`per_level_pct` 0.05, max 8 levels +40% in flat/76; GLOSSARY has since split it into Footwork/Quick Grab, Q1234); Sprint multiplier 1.3 (designer flat/76: "Make the base speed as it was default, but the upgrades should be 50% less powerful."). [H player.gd `speed := 4.0`, upgrades.json]
- The ping is a co-op tool but works in a co-op session even when the player is alone in it; solo Play has none; no discoverability hints (Q363, flat/49). A Ping that is off-screen (or behind the camera) shows an arrow at the screen's edge in the pinger's colour, with the ping's emoji beside it for an emoji ping, and pings always win an arrow slot over the other arrows (max 4); it covers teammates' pings and your own when you turn away (designer 2026-11-18: "pings should be also highlighted by some indicator if it's around the screen"; Q1929, Q1930, flat/82). The ping sound is the bubble alone, no bell (designer flat/60: "Only bubble should player here."). Pings last 4 s (`ping.json seconds`, placeholder). [H]

**Decided against.** Q as the Throw key; a drop range of 1 m; a HUD slot strip; the Held info as an Option; a held-item HUD stack (Q129).

**Open (flat)**
- flat/36 (Q218-Q221 numbers reused, untagged): "Q219: a 'tap' lob now needs the 0.25 s hold first ... Should a lob still exist, and is the lob window right?" "Q220: nothing shows during the first 0.25 s of a hold with Throw bought ... Should the ring or a sound hint earlier?" "Q221: opening a menu (the player freezes) while the right button is held: a running charge throws ... Keep that?"
- flat/66 (untagged): "Make `drop_gap` about a Sock's width (0.12?), or are those fine?" (placeholders `drop_slope` 25 deg, `drop_gap` 0.08 m); "Should it shelve a matching Pair instead, or be refused (shelving stays E)?" for a drop aimed into an open Cabinet Drawer; "Bigger or another shape when red?" for the red crosshair; "White while charging?"; "Wanted for crawl spaces too?" for as-drawn picking; the Host's check of a Guest's drop allows 0.5 m more.
- flat/32 (untagged): "Is that wanted everywhere, or should some tops (Cabinet tops, the fridge) still shed thrown items?"; in-flight Mess Sock not re-settled if its support is picked.
- flat/21, flat/28 (untagged): the generic cream sock icon with an orange cuff: "Keep it?"; held info follows the middle of the Sock: "Should it follow another point (the toe ...)".
- flat/43 (untagged): fold direction ("sideways ... or should they roll towards the camera"); sparkle colour reads white over pale walls; "Should a teammate's pairing also play the pop"; "is that enough?" for the teammate seeing no fold.
- flat/65 (untagged): "Does the kept turn reset when the item stops being the active one ..." (today yes), on drop and re-pick (yes), shelved or Paired (yes); "Should the kept angle show to a Teammate and in the mirror?" (today no).
- flat/53 (untagged): "should your own reflection turn too?"
- flat/68 (untagged): "Does the bigger Radio change its Carry capacity cost? (Default: no; unchanged.)"; Q-A could not reproduce why held info vanished.
- flat/82 [later]: the arrow's emoji placement is a placeholder look (no shot).

---------------------------------------------------------------------------------------------------
## 12. Cabinets, Drawers, shelving and the payout effects (look and feel from the flat tickets)

**What it is.** The look and the click rules for Cabinets and Drawers; counts, pools, Rows and Stages are other folders (progression) and GLOSSARY "Cabinet", "Drawer" win over the flat's numbers.

**Rules that bind**
- A Drawer holds 25 sock balls in a 5x5 staggered tray; Cabinets stay 0.5 m deep and drawers pull out about 0.45 m (Q115, Q116); no floating Cabinet name label, the aim prompt names it (Q117). Cabinets carry no icon plaques; the player learns which is which by refusal (flat spec). The Cabinets keep their stylised look in the house (Q415).
- Remodelled Cabinets (pipeline/04): "Merge as built" (Q968); keep every built look: Basic's arched steel D-pull on two round roses, Space's planet knob with a ring tilted 38 deg, Sport's dark rails between drawers, Animals' extra-round 6 cm corners where the others have 3 cm (Q969, nothing ticked); the per-model triangle budget is fine, Basic stacked to 6 Rows about 7,600 triangles is OK (Q970). Winter's snow cap keeps round drips (built, in the "keep every built look" reading, [?] not separately ticked).
- A left click on a Drawer shelves every held Pair of that Cabinet's Collection into the aimed Drawer; if it is full (25) the rest go to the nearest Drawer of that Cabinet with room (a tie goes to the lower one) and each Drawer used pops its own coins (Q220, Q193); the outline goes on the aimed Drawer and takes a "full" tint when it has no room for held Pairs (Q221); thrown Pairs fill drawers bottom up (Q222). [H GLOSSARY "Drawer"] The tint shows only while holding Pairs; empty-handed a full drawer gets the plain outline (flat/38 built, never answered).
- Coin reward (Q187-Q195, flat/26; designer 2026-10-29: "a coin reward should not be text"): a big "+N" with a coin icon pops over the Drawer that took the Pair (one per Drawer used, Q193), holds about 0.5 s, then bursts into one coin icon per Coin (Q188) that curve to the Coins counter top left, staggered, the whole stream within about 1.5 s whatever the amount (Q191); each arrival ticks the counter up by 1 and pulses its icon, with a soft clink per arrival (Q189); coins can only be spent once landed, the bank shows and Upgrades use only landed Coins, a save counts every Coin earned (Q192); a Drawer behind you pops at screen centre, an off-screen one is clamped to the edge (Q195). A refused buy keeps "Not enough Coins (N needed)" even while coins fly (Q194, wording later "Need (coin) N"). Timings placeholders in data/tuning/coins.json. [H, flat spec]
- Collection complete (designer 2026-11-01, flat/69, flat/77; Q538, Q588): a house-wide moment for every player, once per Collection, synced: the Cabinet's drawers wave open/shut, gold confetti, a 3D fanfare at the Cabinet (everyone hears it in 3D, the shelver too), a gold star on the Cabinet, a short gold screen flash; on every screen the Collection's icon pops up big over the banner (back-ease) then the "<Collection> complete!" text bounces up and down (elastic) until the banner fades, and the screen confetti is in the Collection's colour (designer: "Could the complete effect have color matching confetti + an icon that scales up in the screen and then the text scale-bounced up and down?"). The fanfare keeps the designer's pick `cc0/mintodog_clear`. Placeholders: banner 3 s, flash 0.45 s, star stays, icon 0.2 of screen height, bounce 0.12 at 1.5 Hz. [?: GLOSSARY does not mention it; a celebrate hook exists in game/core/main.gd and game/ui/ending_screen.gd]
- A Cabinet drawn in the flat for each of eight Collections with fixed drawer counts 6/4/3/3/2/2/2/2 [F, replaced by Rows per Stage and the Cabinet pool, GLOSSARY "Cabinet"]; the flat's Cabinet rooms table [F].

**Open (flat/04, 09, 28, 38, 69, 77, untagged)**: the motif list (12 per picture Collection, 8 coats) is the agent's pick: "review names and choices"; atlas 3072x2048 lossless 33 MB VRAM: "VRAM compression would cut that by 4-8x at some cost to the outlines"; "Collection icons bake their colour into the SVG ... Fine, or should they follow the data?"; two neighbouring "+N" pops sit 90 px apart: "Keep, or spread or stagger them?"; the Collection bonus pops over the Drawer that took the last Pair: "Keep, or over the Cabinet's top?"; banner hard to read for grey Basic and dark Space (options: keep / lighten / gold text with a coloured outline); the banner overlaps the gold "+N" for the shelver (move lower?); "Should the gold flash and the Cabinet's confetti/star also take the Collection's colour?"; the bench's 3-7 candidate cap vs hunted jingles.

---------------------------------------------------------------------------------------------------
## 13. Socks: shapes, balls, prints, collections (art side, flat tickets)

**What it is.** How a Sock and a sock ball look. Design counts and Collections are GLOSSARY's (17 Collections, 605 Designs); the flat's "eight Collections, 500 Designs" [S].

**Rules that bind**
- Four rigged Sock shapes: ankle (Basic), crew (Casual, Animals, Superhero, Food, Space), tube (Sport, heel-less, Q134), chunky knee, much thicker (Winter). Nine sock balls, one cuff style each: ankle, crew-plain (fallback, Q138), crew-scallop (Food), crew-rolled (Space), crew-cape (Superhero, cape uses trim colour, Q136), crew-ears (Animals, round bear ears, Q135), crew-stripe (Casual, three stripes, Q138), tube-rib (Sport), chunky-fold (Winter, stays big, balls may overlap in the tray, Q137). Balls in closed drawers are not drawn; open drawers use a ~500-triangle ball past a few metres (Q139). [H partly: GLOSSARY lists shapes]
- Real proportions after flat/44 (Q325): heel turn, heel cup, wedge toe, ribbed cuff of real height; sock balls are lumpy ovals with a wider ribbed pocket-fold band; cloth detail per Collection: cotton (Basic, Casual, Sport, Superhero, Food, Space) smooth with no stitches drawn (Sport's tube ribbed over the whole upper leg), wool (Winter) big knit V stitches heathered with a light fuzzy sheen, fuzzy (Animals) blotchy pile; every Sock a ribbed cuff. Soft stylised look kept (ADR-0003), shape lengths kept, UV contract (UV0 print, UV1 TrimMask) and rig contract (Cuff, Leg, Heel, Foot, Toe) kept. Widths: ankle 0.107, crew 0.18, tube 0.13, chunky 0.24 m; crew ball 0.112 x 0.096 x 0.084 m.
- Prints are flat cartoon stickers with bold outlines (white die-cut rim), about 12 motifs per picture Collection plus 8 seamless Animals coats; a Design is a motif plus a layout (one big, two, band, cuff) plus colours; motifs keep their drawn colours (Q119); superheroes are homages pushed further from their sources (cowl ears, helmet faceplate, colour mix), never real logos or names (Q118); keep the cuff and band layouts (Q120); true deeper Mess colours (Q121); rarity shows as a word after the name ("· Rare", Q133, label only when shown).
- Sock labels read `[L] (icon) Food · Pizza duo`: boxed Size letter, Collection icon and name in the Collection colour (lighter tint with a shadow, icons exact colour, Q131), short Design name; icons get a light outer rim, the coin shows a star (Q130); an outline thicker and brighter, see-through (Q132). [H partly; the aimed Sock shows only Size, flat/16]
- LOD chain (pipeline/03; Q809, Q810): same silhouettes; Socks close ~300 / mid ~80 / far ~16 triangles (far = flat card), balls ~500 / ~60 far, all with the same UV mapping; LOD switch at 64 px / 24 px of longest side (`ModelLods.MID_PX`, `FAR_PX`, placeholders, kept Q854); the far card's wider print and simple far balls are fine (Q855); size drift (chunky Sock 1.6 mm lower, chunky ball 2 mm shorter) and the refitted collider boxes are kept (Q856); Socks standing on their cuff is a bug, folded into physics/07 (Q857); cap and cheapen the cloth (Q858, physics/25). [H]
- Sock flying into a vacuum is the Sock's second-lowest LOD (`lod1`) with its full Design (designer pipeline/14 2026-11-04: "the proxies flying towards the vacuum (the socks) these could be the LOD with almost lowest quality socks, still preserving designs."); the Socks inside both machines' windows (vacuum and pairing machine) are the same low-LOD Socks piled loosely up to the fill level (designer 2026-11-05: "For the vacuum, inside also the low lods should show."; Q939); the pile is a settled heap, each flying-in Sock drops on top and settles, hand-mode takes the top one (Q1490); matched Socks waiting in the pairing machine show joined as a Pair in the heap (Q1493). `window.sock_scale` 0.6, `drop_time` 0.35 s (placeholders). [?: pairing machine is off, section 16]
- Avatar leg Socks: a Socks piece puts a little sock over each stubby foot, cuff up to the ankle, in the Design's pattern; the body stays the Player colour (designer 2026-11-04: "for the creature, 'Socks' means what it wears at the legs, not what is the creature skin."; Q870); a taller cuff that flares out below the body's base so a band of pattern always shows (Q887); your own Socks show in first person looking down (Q888); keep the trim-coloured cuff band and toe cap, no heel patch, and the motif size (Q889); drop the body's unused Sock UV maps (Q890). [H GLOSSARY "Socks piece"]

**Open (pipeline/13, [later])**: "Flare wider, past the body's silhouette, or keep?"; "Keep, or add a thin trim edge at the flare's mouth"; "Enough, or should the belly cut or set-back change so more of the Socks show?"
**Open (flat/44, untagged)**: cloth mapping sign-off ("Should cotton show a fine jersey knit up close (it shimmered ... so it is off), or another Collection be fuzzy or wool?"); heel turn "Crisper L, straighter, or as is?"; "Do they still fit the drawer grid as you want, and is the oval/lump amount right?"; "Check motifs read well on the chunky and ankle Socks."
**Open (pipeline/14, [later])**: "If a flying Sock should be lighter still (`lod2`) or the close-up, say so."
**Open (pipeline/15, [later])**: a Pair in the heap is the lowest-LOD ball not two Socks; Socks with Mates show loose until the run ends: "Should they show joined from the start of the run?"; "Should a hand load drop in too?"

---------------------------------------------------------------------------------------------------
## 14. X-rays and abilities

**What it is.** Two once-bought abilities with keys 1 and 2: the Sock X-ray ("Show pair") and the Cabinet X-ray ("Show drawer" renamed). GLOSSARY "X-ray", "Cabinet X-ray". [H]

**Rules that bind**
- Only "Show pair" stays of the flat's three X-rays; the Size and Collection X-rays are removed (designer flat/67 2026-11-01: "X-rays were too easy"; Q536). The bought Upgrade unlocks an ability used with an icon with a cooldown, key 1 (Q539); it shows only the active item's mate through walls, Heaps and furniture for 10 s, then cools for 50 s (Q536, Q540); cycling the Hands moves the glow (built, never asked). Each player has their own cooldown; works in a Teammate's Hands too. [H xray.json duration 10, cooldown 50]
- The ability icon is at the bottom left of the HUD with its keycap (decided in the order Q543 bottom centre, flat/72 corner, Q1967/Q1969 centre, Q2014 back to bottom left, 2026-11-18) [S: later wins, bottom left]. It is hidden until bought, a radial sweep while cooling, pushed down while on (Q2016). Round cream keycap icons (Q1987).
- Cabinet X-ray (designer flat/75: "Can we add second upgrade that will x-ray the cabinet for the active sock in hand in similar way?"; Q601-Q604): a second ability with its own icon and cooldown beside Show pair, key 2; shows where the active Sock or Pair belongs; 10 s on, 30 s cooldown; one level, 200 Coins; follows the active item (nothing active, nothing glows); only its user sees the glow. Shows the WHOLE Cabinet (Q1964, Q1971), not the Drawer (this reverses Q602 / Q605's lowest Drawer); outline only, no box glow (Q2040, `cabinet_xray.box_glow` false) [H]; the Laundry bin glows too.
- Looks (designer 2026-11-01 flat/74: "make the x-ray effect more visible + pulse the outline"; 2026-11-18 Q1964-Q1971): Sock X-ray cyan (#33d6ff), Cabinet X-ray amber (#ffa826), both outline glows pulsing at 1.5 Hz (Q1965, Q1968); while one is on a light tint and edge vignette in its colour covers the screen, fading out over the last seconds (Q1966; `screen_tint` 0.06, `screen_vignette` 0.45 from 0.45, `screen_fade` 3 s); real silhouette outlines from one outline shader shared with the interaction highlight (Q2015; `xray.outline_width` 1.5x the crosshair's, pulse grow 0.6 / bright 0.4 / fade 0.45). [H data/tuning/xray.json, cabinet_xray.json]
- Readiness: the icon greys out whenever pressing would do nothing (empty or unfitting Hands, nothing to show, cooling down); before the Upgrade is bought it is hidden; a soft sound and one pulse when a cooldown ends, picking up a Sock just lights the icon (Q1967, Q1988); pressing with nothing to show does nothing and spends no cooldown (Q2010); the cue `xray_ready` is picked on the sound bench (Q2012). Hint texts "Sock X-ray on" and "Cabinet X-ray on" (Q1989). Stills approved (Q1991); "icons back left, the pressed look and the Sock X-ray outline are good to merge as built" (Q2041).
- Only the ability icons moved; the Hands and held-item info stayed where they were; the icons follow the existing UI style (UiBits keycaps, cream, outlines) (Q1969, Q1970).

**Open (flat/67, flat/75, flat/84 untagged / [later])**: "What happens when the Hands are empty and key 1 is pressed?" (built: nothing; later Q2010 confirms); "A Pair is the active item ... nothing"; "Want a separate 'ready again' sound?"; "Look of the icon ... Keep, or redraw?"; the Cabinet X-ray names/placement (Q606 name "Cabinet X-ray"/"Show drawer", Q607 own slot, Q608 reuse sounds, Q609 box 4% larger) built as recommended; `xray_ready` borrows the Sole Mates match cue's pool (no pick) [later]; a cooldown ending while nothing fitting is held gives no pulse [later]; "Outline width (0.02 m + 0.03 m pulse) and brightness are placeholders; tune by eye in the zoo"; "Does the outline look right on a teammate's held Sock?" (not shot).

---------------------------------------------------------------------------------------------------
## 15. UI style, menus, cursor, Options, key look

**Rules that bind**
- Keycap look: ink-outlined cream keys with a shaded lip; every keycap, button and cream panel (HUD, menus, prompts, stage bar, Upgrade menu, Wardrobe, guide card, end summary) is a solid block seen from up-left with the darker edge on its right as well as its bottom, joined by diagonal corner edges at top-right and bottom-left, rounded corners following the extrusion, one shared style (`UiBits.KeycapStyle`) (designer 2026-11-04, Q891: "make everything feel 3D, add outline to the right sides as well"; flat/80: "Could you try fixing perspective of the 3d buttons and UI elements?"). Pressed, the face sinks (two thirds of the lip) and its label and icon move down with it, with no layout jump (designer flat/59: "The text on the elevated buttons should move down to look like it's actually pushing the button and the text is painted on top of the button. The style is OK."). [H]
- Colours: cream #fff4e0 panels, warm dark-brown ink outline #3b2a22, orange accent #f29b4b for hovered/affordable row and buy button, same fonts and sizes as the HUD labels; an unaffordable or maxed row reads clearly (dim or "Max"); coin icon next to every price and the balance; "[ESC] Close" keycap (designer flat/29: "Add icons for the coins in the upgrade menu and ESC button. Stylize the upgrade menu according to the keys and other parts of the application.").
- Main menu: Play, Coop, Options, Exit, each keycap with an icon beside the text; Exit stays red; Licence is an icon-only orange keycap in the bottom-right corner of the main menu only (designer flat/54: "add licence as a button in main menu in bottom right corner (just an icon), remove from the main buttons, add icons to the buttons"; Q424, Q427). Every way out is a red keycap (main menu Exit, ESC menu Leave / End session / Back to title, the End confirm) (designer flat/52: "Could the exit buttons be colored red instead?"; Q372). [H, GLOSSARY "Options", "Licence"]
- Cursor: pure white arrow with the dark ink outline (no orange point, no highlight, no halo) (designer flat/52: "Could the cursor be pure white with outline?"; Q373 [S: Q361's cream-with-orange arrow]); one cursor everywhere, no hover variant (Q362). The title screen frees the mouse on arrival (flat/49 playtest).
- Options (Q340, Q341; main menu and ESC menu; live, per machine, never in the save or profile): graphics preset, a volume per bus (Master, Music, Effects, Ambience, UI), mouse speed and Invert Y, fullscreen/windowed, V-sync, FPS cap; a separate SSAO On/Off row named "SSAO" (not "Corner shadows", key `graphics.ssao`; Q1403, Q1409). Options start at 100% and multiply the designer's mix (flat/46; `audio` tuning Master 0.6 ...).
- Menu sounds: every menu button clicks softly on press and ticks very quietly on hover, also the emoji wheel's slices (Q336); a colour refused by the Host stays silent (Q505).
- Licence page lists every third-party work from `data/credits.json` (Q339); credit lines "It Socks", "A game by Zdenek Dolezal", "Built with Godot Engine" were a draft (open).
- Coop/title flow of flat/46 (Q338, Q342, Q343: Coop page, Colour & Wardrobe page after it, Wardrobe Station shows the same page) [S: replaced by the Lobby, GLOSSARY says "no title page since lobby/03, Q1661"].

**Open (flat/46, flat/29, untagged)**: sliders scale the mix: "OK, or should the sliders show the mix itself?"; UI bus carries only menu clicks: "Move some of them to UI?"; "Want a tick per slider step?"; "Option ranges ... OK?"; "Licence wording ... what should they say, and who else is credited?"; "drop unpicked candidates from builds later?"; Upgrade menu (all "stays open Q485"): text colour on cream (white with ink outline vs ink-brown), "Dim maxed rows too?", "Light every hovered row?", "Show [E] as well" as a close hint; flat/36 Q218 menu wording "Throw (hold right click)".
**Open (flat/80, [later])**: "A separate side tone: the block's right side a step lighter or darker than its bottom would read more like a lit block ... Try one?"; "Pressed depth: ... Fully flat (the flat/78 look), or a different share?"

---------------------------------------------------------------------------------------------------
## 16. TV, Radio, sound, ambience

**What it is.** The two Stations (TV, Radio) and the sound system. GLOSSARY "TV, Radio", "Carrying the Radio", "Channel", "Theme channel".

**Rules that bind**
- E turns the knob Off -> channel 1 -> ... -> Off; shared by the whole Session, the Host decides every turn, everyone hears the same Channel roughly in step; devices play in 3D from where they stand; a TV is heard near it (Q344-Q349, Q359). [H]
- TV: a modern widescreen flat-screen set on a walnut-and-cream console (Q402); shows redrawn 16:9 with the retro filter (scanlines, glow) kept (Q414); picture 428x240; set 1.5 x 0.446 x 1.22 m; channels in this order: Sock puppet show (two sock creatures bob and talk gibberish in looping skits), Sock shopping (a real Design on a turntable, price ticker, jingle; a new Design every 16 s, made-up price "%d.99" by Rarity), Weather (a sock presenter in a bow tie beside a weather map, "sock showers in the bathroom"), Test card (colour bars, "IT SOCKS TV", 1 kHz tone); static between channels (0.6 s per turn from Off; switching off has none, the picture collapses to a line and the knob clicks); the picture renders only while the TV is on and in view; all in-engine (Q344, Q348). A playing TV never quiets the Radio (Q371). [H data/tv.json]
- Radio: the game's only music, heard in every room at the Music bus level, a little louder (up to 3 dB) and panned toward it near it (within 1 m fully near, none from 3 m; Q364). Channels: Theme (the game's own cosy songs, playlist, the channel at every New Game), Lo-fi, Jazz 78s (only three real public-domain 78s: 1918, 1923, 1923; the two synthesised placeholders dropped, Q426), Funk, Metal, Rock, then Off (Q365, Q368, Q370). The background music layer is gone. Tracks are CC0 or public domain (CC-BY with credit only for metal/rock), each credited in data/credits_radio.json.
- The Radio is carriable (Q366, Q367, Q369): a left click with empty Hands picks it up, the Hands hold nothing else, E still turns the dial; a right click puts it down where aimed (floor, table, shelf, any surface a Sock can be dropped on); with Throw it can be thrown (lands with a clunk, keeps playing); a Teammate gets it only by Hand-off aimed at them into empty Hands, never by grabbing; seen in the carrier's hands; a leaver drops it; its spot and channel are saved and in the join snapshot; anything falling off the map returns lying in front of the washer. [H GLOSSARY] ("A thrown Radio hitting a teammate is not caught (flies through)" was open in flat/50; GLOSSARY says only Hand-off; [?] unchecked.)
- The radio music was made much louder: Music bus mix 0.35 -> 0.8 (about +7.2 dB) and the TV -7.2 dB to stay as before (designer flat/61: "The radio music should be much higher."). 
- Sound bench (flat/22, flat/57; Q156-Q162, Q398): CC0 clips plus richer synthesised variants (layered noise, filters, envelopes), 3-7 candidates per event; picks saved in data/sounds.json; each event keeps a pool of 2-4 picked clips played at random with about ±5% pitch (Q160); world sounds are 3D (drawers, openables, fridge, clock, ball bounces, thrown items); Hands, UI, footsteps and music flat (Q161); buses Master, SFX, Ambient, Music (+ Ambience, UI later), `-` and `=` nudge Master (Q162). Footsteps one step every about 1.4 m walking (designer flat/28: "the footsteps should be much slower"; Q209). Every downloaded clip is CC0 or public domain, with source URL and author in assets/audio/SOURCES.md and data/credits.json.
- Ambient: outside ambience (park and birds) plays in 3D from each window as its own source, full beside it and gone about 3 m into the room (designer: "the ambient sounds should be only when close to windows"; Q205, Q210), calmer: rarer chirps, quieter, shorter reach (designer flat/56: "the ambient sounds (birds, ...) near windows should be much more slow"; Q382); a ticking wall clock in the living room carries the tick (Q204); a positional fridge hum in the kitchen (Q157). A window is heard only in its own room, or a room open to it. 
- The ping sound is the bubble alone (flat/60). Wardrobe doors swing open (80 deg, 0.7 s) while anyone is in the Wardrobe and shut when the last one leaves, with a soft creak and a wooden thud, 3D, for teammates (Q337, Q309; flat/48).
- Sound hunt 2 (flat/64, Q478, status ready-for-agent, priority later Q1580): NOT built: CC0 candidates for knockdown, tv_static, lid_open/close (Q451: lids use the cupboard sounds today), car_door_open/close. [unbuilt]

**Open (flat/47, untagged)**: "Is that enough per channel, and are these the right picks?" (3 CC0 tracks per non-Theme channel); "Should it show what E will turn to next instead?" (hint shows the current channel); "Should a save keep the channels?" (flat/50 later saves Radio channel; TV [?]); own bus for devices?; "Are those the right lengths and feel?" static; "Rewrite any of it?" show contents (puppet skit lines, shop ticker, weather forecasts); "Make it bigger, closer or lit more strongly" shopping Design; "Keep this order and these names?"
**Open (flat/50, untagged)**: "Are these the right picks? Should the short loops play twice before the next song?" (Theme); "Should 'near' stop at the edge of its own room, or reach further?"; held Radio placement; "Should either say something else?" Hands full text; Throw at a teammate hand it over?; "Should picking the Radio up let the Socks on it fall?"
**Open (flat/58, flat/57, untagged)**: "Keep 7 as the bench's limit?"; "Should a picked bed get the synthesised gibberish voices mixed over it, or stay as it is?"; "Is that enough for where the game ships?" (US public domain only claimed); user:// fallback for picks in an exported build; flat/62: TV spot (1.5 m console reaches in front of the north window): "Keep it there, set it square to the wall, or move it to another wall?"; delete the old retro TV assets?; "Should it be sharper?"
**Open (house/17, untagged)**: placeholder sounds shared from other events (button = the device click, hatch = the oven's metal, creak = the basket's).

---------------------------------------------------------------------------------------------------
## 17. Guide card

**What it is.** A held card (GLOSSARY "Guide card" holds the current two-page text). [H]

**Rules that bind**
- Every player has one in their Hands at New Game (a player joining later gets one); it takes a Hands slot like an item; it can be dropped or thrown and stays where it lands; held up close as the active item, G brings it closer; look: clean printed instructions, IKEA-style line drawings on a white printed card glued to cardboard (Q526-Q531, designer 2026-11-01).
- Four numbered panels, a short line + a drawing each (Q1776, Q1777, Q1782: redraw in the same script `tools/guide_card.py`): Q1778 explain both Coins and the team's Drawers (panel 2, Q1780); Q1779 say "floor"/"house", never "flat"; Q1781 panel 4 Drawers -> Part -> machine. Built captions: 1 "Match two Socks: they roll into a Pair." 2 "A Pair in its Cabinet pays Coins. A full Drawer pays the whole team." 3 "Spend your Coins at the Old Tree in the garage." 4 "Fill every Drawer on the floor, take the Part to the washing machine: the next floor opens." (Q1783: merge as is; the drawings and the one-card rule stay open.) Later pages (first-wash page, R turns the page) are other folders.
- Anyone can pick up any lying Guide card, not only its owner (designer 2026-11-12) [S: reverses Q528/Q530's "one card per player" and the owner-only build]; a pair of Hands holds one card ("You have a Guide card"), it is never handed to a Teammate (GLOSSARY, placeholder). A lying card rides the Elevator; a swinging Door does not push it (house/26 note). `held.guide_*` and `GuideCard.PRINT_GLOW` 0.25 are placeholders.

**Open (flat/81, [later])**: "With anyone able to pick any card up, a player can hold two cards. Fine, or should a second card be refused? Can a card now be handed to a Teammate (flat/70 said never)?"; "Panel 4's Part is drawn as the first floor's new filter and the next floor as an open door with an up arrow; the Old Tree is drawn as the tree half out of its box ... Keep the look and wording?"
**Open (flat/70, untagged)**: "Keep them?" captions; "At the start capacity of 1 the card fills the Hands: nothing can be picked until it is dropped. Intended?"; placement/zoom placeholders.

---------------------------------------------------------------------------------------------------
## 18. The art pipeline (Blender MCP) and the remodelled props

**What it is.** Assets are modelled live through the Blender MCP in the bundled headless Blender, sources kept as .blend, exported to glb with automatic checks. How it works: docs/art/pipeline_mcp.md. (designer 2026-11-04: set up Blender MCP, "remodel also other props + socks. Try to optimize them as well.")

**Rules that bind**
- Blender runs headless in the sandbox with the add-on's socket server (`tools/blender/mcp/serve.sh`) (Q767); one MCP agent at a time as a queue, because the tools drive one Blender (Q811); an Opus agent models through MCP (Q807); hero props first, then the rest of the furniture in batches by floor (Q808).
- Sources live in `assets_src/blender/<asset>.blend` (plain git, no LFS then; Git LFS since 8fc33c05 per memory), `tools/blender/export.sh` checks and exports, the Godot suite `blender_assets` checks the result (Q768). Checks: unit scale, origin, applied transforms, triangle budget, materials, texture sizes, collider naming, naming.
- Triangle budgets: prop 2k, furniture 8k, appliance 12k, large 20k, colliders 512 (Q770). Colliders are separate simple meshes (`-colonly` trimesh, `-convcolonly` convex); render meshes never collide (Q771). Origin: bottom centre of the footprint, front facing Blender -Y (Godot +Z) (Q772); a piece that hangs or whose handles stand out sets `origin_xy`/`origin_z` false in its manifest.
- Every remodel saves its preview line-ups next to the asset's art doc, so the designer sees the in-between steps (lead, 2026-11-04). The remodel keeps the node names and parts the code uses.
- Washing machine (Q804-Q806, Q866-Q868): same stylised style, 0.70 x 0.70 x 0.95 m, truly remodelled (rounded body, real porthole glass, door hinge and latch, detergent drawer, dial, hose, light wear), mint, cream, steel colours, 11,014 triangles; the rogue face (eye with iris, eyelids, brows) is built in as separate named parts hidden by default and shown by the game (angrier each level), kept visible in the source and the eye in the drum (Q866); the Upgrade station's box stays the collider and the lamp's red glow is fine; Socks lying on top of the machine must move with it while it shakes and hops (Q867, rogue-machine/02); the iris is brighter (yellow-white at the high levels) so it reads against the red light, no texture wear (Q868). Assets at `assets/washing_machine/washing_machine.glb`, snake_case names.
- Wardrobe (Q971-Q974): merged as built; keep every new detail (garments turned 16 deg, hat box and red slippers, arched plinth with four bun feet, brass hinges and keyhole; nothing ticked); no mirror on the Wardrobe (the wall mirror beside it stays the one mirror); keep the house cream #EDD6A8 doors.
- Radio (Q975, Q976): house colours (terracotta, cream, brass, pink stripes), merge as built; keep every built detail (cream face plate ringed by a brass bead, dark grille with two pink stripes in a brass rim, terracotta knobs with brass caps, back vents); a chubby 1950s tabletop set (0.155 x 0.108 x 0.083 m before the 1.5x, Q547).
- Clock (Q977, Q978): merge as built; keep brass bezel, a little pink Sock mark above 6, dark minute ticks, terracotta batons at 3, 6, 9 and a pair at 12, charcoal spade hands, no seconds hand; no collider (5.5 cm off the wall, above head height); size 0.36 across, 0.055 deep.
- TV (Q979, Q980): merge as built: walnut and cream console, slim charcoal panel on a brass pedestal; keep every built detail (no frame round the panel, a niche of five records, the vase and soundbar on top, the standby lamp bottom centre, red when off, amber on); the glass exactly 16:9 (1.08 x 0.6075 m); 1.5 x 0.446 x 1.22 m.
- Collection board / Whiteboard: the remodel was reverted, the old board stays (Q981 merge, then designer 2026-11-05 "the old board looked better"); Patrick Hand for its lettering (Q983).
- Appliance family (pairing machine and Sock vacuum): 1950s kitchen gadget style with soft pill and capsule shapes, chrome trim and chunky round buttons (Q908); one product family with the same body colour, trim, button style and maker badge (Q909); pastel mint body with chrome trim and cream details (Q910); designer 2026-11-04: "It should be more rounded, stylish."; the badge stays mark-only, no lettering (Q938); queued after progression/09's cosmetic pieces on the single MCP server (Q911). Vacuum: cream ribbed hose with chrome cuffs at both ends, stays dynamic (Q936); keep the mode colours (blue hand mode, orange spit mode) (Q937); window 2 cm off centre (Q940); the nozzle hangs vertically along the side in a clip, touching nothing (Q941). Pairing machine: keep the collision box (Q942); 12 count lamps lit as the fraction of the hopper that is full, so any hopper size fits (Q943). [vacuum H; pairing machine off, section 20]
- Cabinets: section 12 (Q968-Q970). Socks and balls with LODs: section 13 (Q809, Q810, Q854-Q858). Avatar leg Socks: section 13 (Q870, Q887-Q890).

**Open (pipeline/05-08, [later], never ticked; Q972/Q976/Q978/Q980 "keep every built detail")**: each lists options with the built one recommended (Wardrobe mirror/garments/hat box/plinth/hardware/cream colour; Radio colours/front/grille/knobs/back; Clock bezel/sock mark/minute ticks/hour marks/hands/collider; TV colours/set/glass/console/dressing/lamp/old leftovers `docs/art/house/furniture/living_room.png`). Treat as decided: keep as built.
**Open (pipeline/04, [later])**: Basic handles, Winter snow, Space knobs, Sport rails, Animals corners, per-kit triangle check (Q969 "keep every built look" covers them).

---------------------------------------------------------------------------------------------------
## 19. Graphics presets and effects

**What it is.** Low/Medium/High presets (`main/graphics.gd` now `game/...`, `data/tuning/graphics.json`); effects belong to the presets with no separate ambient setting (Q1391).

**Rules that bind**
- Ambient effects look-test (designer 2026-11-09, Q1386-Q1391): SSAO tried and switchable; glow on light sources only if its frame cost allows; dust motes; light shafts; colour grading by the hour with a vignette. After review: the grade by hour plus the vignette go ahead into the presets (on in High and Medium, off in Low) (Q1402); SSAO gets its own on/off switch, an Options row "SSAO" (Q1403, Q1409); dust motes were reworked over three iterations and judged moving in a review build (debug key F7 cycles off/v1/v2/v3, Q1407); "The dust motes should be really small and move super subtle (they jerked like crazy); maybe with a texture or simple shape." (designer, Q1408); then the dust motes are REMOVED for now and the rest merged without them, "they need more polish later" (Q1415, 2026-11-09); stronger glow and the light shafts not taken further; volumetric fog dropped as too costly and flattening the windows (Q1404); laundry fluff, the basement's own mood and small moving things (curtains, steam) not picked for now (Q1391); a review build comes first before the merge (Q1406).
- Low-end target: a steady 30 fps on Low with no freezes on a low-end PC (Intel UHD 620) (Q1972). Low render scale 0.6 (was 0.7) (Q1974); Low's sun shadow is one hard cascade, atlas 512 px, 8 m distance (Q1976); keep the cap of 3 physics ticks a frame, slow motion below 20 fps (Q1977); stills approved, merge (Q2002). [H graphics.json]
- Compile shaders before play: `shader_baker/enabled` in the export (the lead makes this edit to the designer's export_presets.cfg with the designer's OK) and every material pre-drawn behind the New Game / join loading card, mirrors rendered once at load (Q1973). [unbuilt, status ready-for-agent]
- A fourth preset "Lowest" (render scale 0.5, bilinear instead of FSR, no FXAA, sky radiance 32, the cheap sun shadow; auto-detect for the oldest integrated GPUs) is wanted "after the 720p and 540p runs confirm" (Q1975). [unbuilt, needs-info, blocked on maintenance/134's extra low-end bench runs]
- Mirror cost: section 6.
- Socks glow in dim rooms (designer 2026-11-18: "why the socks glow so much?"): suspects the rim light (`RIM` 0.45-0.85 with `RIM_TINT`), the fabric sheen (`col * 1.35 + 0.03`), and shadows on the Mess multimesh; check shadows first; shot sets in `builds/review-sock-glow/`; the designer picks by eye ("Socks still easy to spot is the other half of the choice"). The pick is not decided: "idk yet" (Q2061, 2026-11-19); the branch stays unmerged. [unbuilt/undecided]

**Numbers (placeholders, data/tuning/graphics.json)**: Low render_scale 0.6; Low sun one cascade, hard filter, atlas 512, distance 8; High night shadow setting "level".

**Open**: graphics/01 [later]: dust motes as one house-wide effect (a world-fixed cloud of specks around the player lit by the real lights) polished before shipping; "Which presets get which effects, and their strength"; "Whether effects react to gameplay (e.g. fluff bursts at the Vacuum): later." graphics/05 [blocking]: "The low-end PC's extra bench runs (maintenance/134)." graphics/06: the stills pick.

---------------------------------------------------------------------------------------------------
## 20. Switched off / dropped (rules kept for a return)

**Lost Sock Grotto (hidden since Q1873; the Drum is the fifth floor, ADR-0012; code kept behind one tuning switch)**
- The hatch is a floor hatch on the workshop floor (Q1053), no lock, no tooltip, stays shut silently until the attic's Stage is complete, then a click opens or shuts it (Q996, Q1088); once open it gets its own outline and prompt "[LMB] Open the hatch" / "[LMB] Shut the hatch", before that the leaf is quiet (Q1096); climbing the ladder always needs E, walking into it does not grab (Q1089); E reach 1.4 m (Q1099); players climb with forward and back (house/38).
- The look (Q997): a cave under the basement where every lost Sock in the world ends up; a small maze of timbered mineshaft tunnels with a few branches, dead ends and a collapsed passage, the ladder coming down inside the maze, the shrine's cave at the end (not visible from the ladder), a glowing Sock-shaped crystal on an old stone shrine, low mist, soft blue light (Q1052); no piles of Socks; mood: a dim blue lantern and glow mushrooms in niches, dripping water with puddles, a pickaxe and a shovel, a faded "KEEP OUT" board, planks over the timber caps; NO rails, NO cart (Q1057).
- A floor like the others (Q998): own Mess, Cabinet and Rows, Stage; the Lost Socks Collection (about 50 Designs, crew shape, crystal teal #2fa3a8, 12 motifs: Odd sock, Darn patch, Moth, Lost button, Treasure key, Map X, Compass, Lantern, Crystal, Keyhole, Question mark, Ghost sock; Q1029, Q1054, Q1100 kept unseen). Hiding spots: openable crates and barrels (Q1058), rock cracks and low niches seen from the right angle, rubble; rarer is deeper: Common near the ladder, Uncommon in the side tunnels, Rare in dead ends, the collapse and the shrine's cave (Q1059); more hidden than the house's floors, its Socks spawn only there, no mates across levels (Q1060); the softener appears glowing on the shrine when its Rows are full (Q1055); crates and barrels face the walkway (Q1086); the last Stage spawns only Lost Socks, no Dirty Socks (Q1085); not on the Elevator (ladder only).
- The lantern (Q1061-Q1065, Q1083-Q1084, Q1092, Q1112-Q1114): one shared lantern hangs by the ladder's foot; it takes a Hands place and counts toward Carry capacity; light real for everyone; goes anywhere upstairs too; thrown it flies like a Sock, stays lit, a teammate can catch it, a full-charge lantern Throw knocks the teammate down; held it hangs plumb from its top handle and swings as a damped pendulum; a fallen lantern lies as it fell, on its side too, nothing rights it, picking it up rights it in the hand (designer 2026-11-06, replacing Q1114's landing on its base). Held readout names it "Lantern".
- Climbing: Avatar on the ladder has no hands, only the feet step and the body sways (Q1119); teammates near the shaft hear the climber's rung sounds in 3D (Q1120); drops fall from the ceiling with a drip sound (Q1090).
- Numbers (data/tuning/grotto.json, placeholders): lantern pale white #d8e6ff energy 0.7 range 4 m; Grotto blue lights 0.45; crystal 1.0; softener glow 1.5; climb 1.6 m/s; grab 0.7 m (E reach 2x `ladder_reach`, 1.4 m); 70% of its Socks in Hiding spots; `stages.pairs` 50.
- Open (house/38, house/40, house/41, [later] unless stated): the prompt wording "[E] Climb down/up"; [designer] the ladder's E reach placeholder; [designer] "Two crates face along the tunnel only 1.0 m of floor ahead"; the unseen Lost Socks proposals (12 stickers, Cabinet look, HUD icon a teal Sock with "?", cotton cloth, plain crew ball, no Wardrobe gift pieces); lantern swing numbers (`hold.lantern.swing`); "A thrown lantern lies on its base or flat on its side ... Is that 'as it falls' enough?"; mess:rest_fit floats one Sock in seeds 2 and 10 since the catalogue grew to 605.

**Pairing machine (off since 2026-11-19, `data/tuning/pairing.json enabled false`, tools/26)**: none placed, a save loads none, its four Upgrades hidden and unbuyable, the Old Tree does not speak tip_pairing, the zoo hides its buttons. Look rules kept in section 18 (Q908-Q910, Q938, Q942, Q943) and section 13 (Q939, Q1493).

**Hampers (off, `hamper.json enabled false`, progression/78)**: house/45's garage plan keeps room for up to 4 beside the Old Tree (Q1511 in GLOSSARY).

**Dirty Socks / Laundry bin single bin**: off (Q1817); none of my tickets add rules beyond house/40's "no Dirty Socks on the Grotto's Stage" (Q1085).

**Dropped / wontfix**: flat/12 (art touch-ups; closed 2026-11-07, no longer wanted), house/13 bike remodel (Q1146, 2026-11-07).
**Unbuilt but still wanted**: flat/64 sound hunt 2 (priority later), house/07 the rename, graphics/03, graphics/05, graphics/06 pick.

---------------------------------------------------------------------------------------------------
## 21. Reversals and "decided against" (so they are not proposed again)

- Q168 (2026-10-29) reverses Q145: no crouch rule for Socks under furniture. Q409 reverses Q140: Mate distance is walking, not straight.
- flat/33 reverses Q148: G zooms, RMB drops; flat/36: Q key removed, RMB hold throws.
- Q522 (2026-10-31) removes flat/32's 1 m drop range; Q524 red crosshair and "Can't drop there".
- flat/67 removes the Size and Collection X-rays; flat/75 adds the Cabinet X-ray; Q1964/Q1971 reverse Q602/Q605: whole Cabinet, not a Drawer; Q2040 reverses Q2013: outline only, no box glow; Q2014 (2026-11-18) puts the ability icons back bottom left, reversing Q1967/Q1969's bottom centre.
- flat/79 (Q892) reverses Q535: held info always on, no option.
- flat/76 reverses flat/73: base speed back to 4.0, upgrades half as strong.
- house/12 reverses Q413: the dust-sheet lift and the sheeted wardrobe are gone; Q430: sheeted sofa dropped.
- house/23 reverses Q512's floor-choosing buttons: one call button; house/33 reverses Q545: all 88 piano keys.
- Q373 reverses Q361: the cursor is pure white.
- Q426 reverses the jazz placeholders; Q364/Q371: the Radio replaces the background music and the TV no longer ducks it.
- graphics/02 (Q1939) reverses Q443/Q444: mirrors render only within 4.5 m.
- Q1228 reverses Q458: no hall plant. Q1132 removes the U-landing doors; Q1040/gate replaces the attic door (2026-11-06).
- flat/81 (2026-11-12): any player picks up any lying Guide card, reversing Q530 owner-only.
- pipeline/09: the Whiteboard remodel reverted (2026-11-05).
- Hold R turn: flat/65 reverses flat/53's ease-back; flat/55 removes the end-over-end spin.
- Q1415 removes the dust motes for now.
- Rejected outright: realistic and CC0-pack furniture (Q404); volumetric fog and light shafts (Q1404); rails and a cart in the Grotto (Q1057); a WC (Q428); a dryer; the old 1 m drop range; a cancel for the Throw charge (Q217); per-slot HUD stack for held items.

---------------------------------------------------------------------------------------------------
## 22. Late additions found after the first read, and the flat-era leftovers

**Room Doors, the answers that sit after the Built log of house/21 (so section 3 holds)**: every room gets a real door; the open-plan kitchen, dining, living room and hall stay open arches (Q517); about a third start shut, picked at random each New Game, saved with the game (Q518); a shut door blocks light like a wall and muffles sound (radio, TV, ambience quieter and muffled); pings and X-ray still show through (Q519); doors never close by themselves, only players and pushed items move them (Q520). [H]

**Open lines found in late sections (verbatim)**
- house/33 (untagged): "Q569 (house/28: only C3-C5 play, the rest dead) is moot now: every key plays. Close it in house/28?"; "The detuned upright's pack has only A3-C5 ... Options: (a) keep it as the odd candidate (recommended ...); (b) drop it from the bench; (c) let it play its own range only"; "Is the bass's long ring cut too early by `piano.note_s` (1.6 s) + `release_s` (1.2 s), or should low notes ring longer than high ones?"; "Key hint: every key shows 'Play <note>' (e.g. 'Play A#0'). Keep note names, or something plainer ('Play')?"; "File size: 2.8 MB of piano notes (79 files). Trim the bench candidates ... if size matters?"
- house/34 (untagged): "Should the piece be deleted for good, or kept for a later return ('for now')?"
- flat/49 (untagged): "Should text boxes (name, address) also use the arrow instead of the I-beam?"; "Cursor size 36 px at any resolution: fine on 4K screens, or should it scale?"
- flat/71 (untagged): "Should a Pair show both Collection icons/names when the two Designs differ?"; "Layout: name before or after the sock icon, and a smaller font for the name?"
- flat/72 (untagged): "Flicker cause not reproduced headless ... If it still flickers in a playtest, say where (stairs, a lift ride, a doorway) and which lights."; "More zoo effects wanted (Show pair, Pair pop, Upgrade bought, ping)?"
- flat/73, flat/76 (untagged): "Read as: walking halved, sprint bonus halved. If 'sprint 50% slower' meant sprint speed only half of what it was (3.2 m/s), the multiplier should be 1.6 unchanged." (flat/73, then reversed by flat/76); "The speed Upgrade (+10% per level) is untouched; at 2.0 m/s it may feel weak."; flat/76 "Placeholders; tune in the balance round or the upgrades batch."
- flat/74 (untagged): "Outline width (0.02 m + 0.03 m pulse) and brightness are placeholders; tune by eye in the zoo."; "Does the outline look right on a teammate's held Sock?"
- flat/77 (untagged): "Should the gold flash and the Cabinet's confetti/star also take the Collection's colour?"; "the dark text outline reads weakly on dark Collection colours (Space)"; "The icon and banner still sit over the '+N' Coins bonus (Q588)."
- flat/85 ([later]): X-ray outline numbers placeholders (`outline_width` 1.5, pulse grow 0.6, bright 0.4, fade 0.45); pressed look placeholders (`PRESS_DEPTH` 0.7 of the lip, `PRESS_SHADE` 0.4, `PRESS_TIME` 0.08 s); "The Sock X-ray's outline is the glow's colour round a glow of the same colour, so it reads as a brighter rim more than a separate line ... a different outline tint would be a new look."; "No still of the Laundry bin's outline".
- flat/35 (untagged): "The wire rack holds Socks in the heap bake but has no collider in the room, so the crosshair reaches through the wires ... Keep that, or should the rack block like the cupboard shelves do?"; "The door's window stays a dark painted panel; should it be see-through glass now that the oven is hollow?"
- flat/48 (untagged): "Door swing ... OK?"; "Bigger or lower mirror?".

**Flat-era answers kept for completeness (mostly [F] or [S])**
- The old flat (about 80 m2, L-shaped, washing machine in the bathroom) and its first design round Q53-Q107: heavy damped cloth (Q53); Pair as sock ball (Q59, Q60, Q92); Hands model (Q61-Q64); Throw (Q65-Q68, Q100); eight Collections of 500 Designs and shape/colour table (Q54-Q58, Q81-Q96, Q103) [S: 17 Collections, 605 Designs, GLOSSARY]; the flat's layout, hiding spots, Mess spill, eight Cabinets by room (Q75-Q80, Q83-Q90, Q102, Q104, Q105) [F]; UI label and held info and coin rewards (Q97-Q101) [S by later tickets above]; "Delivered all at once, the designer merges at the end" (Q106) [process]; Q107; Q77 "only uncovered Socks pickable" [S: flat/15, Q168].
- Blender iterations use Workbench at half resolution, one piece at a time, EEVEE only for final previews (Q108). Blender work runs on Opus with cheap previews (flat/28 Q203).
- Held X-ray rules of the flat (Q112 only Held sees through; Q113 keep the Held glow; Q114 soft click on toggle, icon lit by its keycap, not saved; Q69, Q74; Q252) [S: flat/67 one X-ray].
- UI rules of the flat (Q126 floor Pair label led by the ball icon, later Size only; Q127 list every held item; Q128 contextual key hints; Q129 stack) [S: flat/16, flat/21].
- Heaps (Q143 keep the bake message, later a loading screen Q356; Q144 drops land physically, built Q333; Q146 keep the basket and hiding; Q185 rare Designs prefer hiding spots, moved to the balance round Q477).
- Flat model rules (Q170 keep Cabinet walls; Q174 keep bedroom size; Q175 keep crawl gaps and tucked-in chairs; Q177 keep every extra resting surface; Q178 palette approved; Q181 one click opens both doors of cupboard B) [F: the house replaced them; Q412 every door opens]; Q182 no mesh LOD for now, later only on Medium and Low presets (Q353; Q327 mesh detail 4 on Low); Q183 Design names and the Animals split fine; Q184 leave the sofa as it is [F, the house replaces it, Q396]; Q190 the Collection bonus is its own bigger gold "+N" with a banner.
- Sound bench details (Q158 event groups: Hands, Movement, Furniture, UI and Upgrades; Q159 the bench is `tools/sound_bench.tscn` saving picks to `data/sounds.json`; Q206 jump plays its first candidate; Q207 two music loops alternate as a playlist [moot: Radio]; Q208 bounce plays for dropped balls and a thrown item's last hop; Q212 the Sprint hint is already shown; Q399 the designer picked on the bench).
- Radio music (Q345 recorded tracks per channel; Q346 E cycles). Q351 the laundry basket truly hollow [S: house/05 stylised basket with a lid in the laundry, Q417]. Q392 Mess size scales with area (about 2.5x placeholder). Q293 the catalogue grows. Q295 a leaver carrying the Radio drops it where they stood. Q310, Q328, Q329 the creature's own body wears nothing and has no arms [S: Q888 own leg Socks show in first person]. Q334 each Sock's three fitted collision boxes. Q396 "better plants, a rounder and nicer sofa, a better bed, new furniture for every room" (the look brief for the house).
- Process numbers: Q436 the Elevator was queued right after house/12 and house/16 (house/17); Q452 loosened tests are checked in the code review; Q466-Q468 car colours keep, three doors OK, see-through glass alpha 0.3; Q527/Q529 guide card (see section 17); Q554 (order of the Oct-Nov round, in Process lessons); Q603 Cabinet X-ray 10 s on, 30 s cooldown (section 14); Q639/Q667 the Whiteboard on a wheeled easel with a hand-drawn lines area (pipeline/09); Q766 the first asset was the washing machine; Q805 the face built into the model; Q833 house/01 closed as done (every plan question answered); Q899 touched suites only, the full suite runs at integration (agent process); Q990 Elevator riding "reviewed: good to merge"; Q992 remodel checkpoint after the first Workbench line-up; Q1056 Grotto checkpoint 2 approved; Q1098 crate at (4.9, 7.65) kept with about 1.0 m of floor ahead; Q1109 car doors run after the lantern and climbing work; Q1113 held lantern keeps the plumb hang; Q1165 and Q1171 the house agent proposes the third ground-floor Cabinet's place (candidate C kitchen east wall south of the Elevator, superseded by H1); Q1387-Q1390 glow, motes, light shafts and colour grade were look-tested (Q1402-Q1404 decide); Q1484 pipeline/15 was in the 2026-11-10 maintenance batch.
- flat/42 Windows build: a committed Windows export preset and `tools/export.sh` build `builds/windows/ItSocks.exe` as a debug export (F9 cheat on) or `--release` (designer: "How do I export this as a build with the debug cheats included? Could you prepare windows build for me?"); open: no game icon yet.
- The Wardrobe Station doors, the mirror and the hollow basket: sections 6 and 16.

---------------------------------------------------------------------------------------------------
## 23. Process lessons (what the designer said about HOW to work)

- Blender: iterate with Workbench at half resolution, one piece at a time; EEVEE only for the final previews; use `-t 4` and `LP_NUM_THREADS=4`; Blender work goes to an Opus agent (Q108; flat/12, flat/28, flat/35, house/33).
- A remodel or look change gets a review build or stills before the merge: "No merge before the designer looks" (flat/81, Q1782), review build first for a look/feel change (Q906 house/37; house/42; graphics/01 Q1406; graphics/04 "not merged before the designer picks"); stills go in `builds/review-<name>/` (flat/81, flat/84, flat/85, graphics/04, graphics/06).
- Ask before modelling or building a big thing: the floor plan was proposed first for review (house/01), the Elevator "Grill the designer on placement, size, call buttons, speed and sounds before building" (house/17), doors "Grill the designer on details first" (house/21), the third Cabinet spot is proposed with a line-up before building (Q1165, house/44), the garage layout comes as 2-3 mock plans each a [blocking] question (Q1512, house/45), the Grotto stops after the first Workbench line-up for the designer's go (Q992) and after a second checkpoint (Q1056).
- Design choices an agent made while building are listed under Open follow-ups for the designer to keep or change; the agent never decides them (house/16, 19, 20, 21, 22; flat/80: "Don't pick it alone; it's a design choice and goes under Open follow-ups").
- "Merge as built" with "nothing ticked" means keep every built detail (pipeline/04-08, Q969, Q972, Q976, Q978, Q980).
- Designer reply "idk yet" on a pick keeps the branch unmerged (Q2061, graphics/06).
- Fix causes, not thresholds: no re-seeding and no looser test (house/22, house/36-newel-collider); a bug report is confirmed by a failing test first (house/46); "Tests loosened: check them in the code review" (Q452).
- Touched suites only per agent, the full suite at integration/merge (Q899; house/33 "the lead runs the full suite at merge").
- One agent at a time on each part of the house (shell+layout, exterior, Elevator, each furniture piece); different parts may run in parallel; one MCP/Blender agent at a time as a queue (Q555, Q811, house/25).
- Work order of the 2026-11-01 round (Q554): house split first; then in parallel Elevator rework+rename, basement/night lighting, X-ray to Show pair; then small fixes (Radio, Pair turn, held info toggle, crouch Highlight, pings); effects (pairing, Collection); guide card; piano; the walkthrough/code review, house/07, flat/64 and the bike after.
- Stay in runtime code when another agent is rebuilding the bake (house/18).
- Sounds: agents add CC0/public-domain candidates and credit them; the designer picks on the sound bench (flat/22, flat/57, flat/58, flat/64); every downloaded clip credited (flat/22, flat/58).
- Firewall: list blocked hosts and stop, do not work around the block (flat/30 Blocker; house/02).
- The designer's own PC is the measuring place for performance numbers (Q1992, graphics/02, graphics/04); the sandbox (lavapipe) is relative only.
- Edits to the designer's files (`export_presets.cfg`, `project.godot`): the lead makes them with the designer's OK; the agent says what to set (Q1973, graphics/03).
- Motion: frame strips for animation and effects (house/35 "Tune with the strips"; flat/77 shots; the Q825 rule is in the tracker).
- Shader changes show a screenshot per case (flat/04 "A screenshot showing every Collection's prints (shader rule)"; flat/08 "one screenshot per X-ray").
- Triage: `priority: next`/`later` (Q1580, Q1583).
- Pre-flight design questions before a build; answers recorded in the ticket (Q1100 "kept as proposed, unseen" shows unseen proposals are accepted but flagged).
- Playtest feedback arrives as one-line designer quotes (quoted in sections above); agents turn each into a ticket with acceptance lines.

---------------------------------------------------------------------------------------------------
## 24. Coverage

Read order: every ticket file in number order (flat 01-85, house 01-46 incl. both 36s, pipeline 01-15, graphics 01-06) plus the four folders' spec.md (flat, house, pipeline; graphics has none), GLOSSARY.md and docs/agents/issue-tracker.md. Built logs were read in the cut that shows what was built or changed a rule (first 300-1500 characters, longer for flat/66, 84, 85, house/38, 35); sections that sit after a Built log (Answers/Open follow-ups) were read in a second pass (house/21, house/33, flat/85 and others listed in section 22).

Counts (grep over the four folders' .md files):
- `(Q` markers: 561 (flat 194, house 241, pipeline 92, graphics 34). Of these about 152 have the full `(Qnnn, YYYY-MM-DD)` form and 32 the `(designer, YYYY-MM-DD)` form; the rest are `(Qnnn)` cross-references or answers dated by their heading.
- Unique Q numbers named anywhere in the folders: 525. All 525 appear in this digest (three, Q467, Q1388 and Q1389, only inside a range written "Q466-Q468" and "Q1387-Q1390"); many are cross-references to answers owned by other folders (progression, knockdown, physics, tools) that are named here only to show what a rule depends on.
- Answers used: about 590 designer answers and quoted words (every `## Answers` item in flat 01-11, 12-85, house 01-46, pipeline 01-15, graphics 01-06, plus the designer's quoted playtest words that open tickets). Gap: none dropped on purpose; items I marked [F] (died with the flat) are kept in section 22 so they are not asked again.

| Ticket | Title | Status | Q ids in Answers part | `(Q`/`(designer` markers |
|---|---|---|---|---|
| flat/01-flat-model.md | The flat model | done | 10 | 9 |
| flat/02-themed-cabinets.md | Eight themed Cabinets | done | 4 | 4 |
| flat/03-sock-shapes-and-balls.md | Four Sock shapes and the sock balls | done | 6 | 0 |
| flat/04-print-atlas.md | Print atlas for the picture Collections | done | 4 | 0 |
| flat/05-eight-collections-data.md | Eight Collections and 500 Designs | done | 0 | 0 |
| flat/06-hands-and-feel.md | Soft cloth, sock balls and the active item | done | 5 | 6 |
| flat/07-throw.md | Throw (Q) Upgrade | done | 8 | 5 |
| flat/08-xrays.md | Size, Collection and Held X-rays | done | 3 | 4 |
| flat/09-ui-icons-highlight.md | Icons, labels and the interaction highlight | done | 8 | 9 |
| flat/10-heaps-and-hiding.md | Physics heaps and hiding spots | done | 16 | 15 |
| flat/11-integration.md | Flat integration and performance | done | 5 | 5 |
| flat/12-review-art-touchups.md | Art touch-ups from the review | wontfix | 1 | 1 |
| flat/13-review-code-polish.md | Code polish from the review | done | 1 | 1 |
| flat/14-held-sock-swing.md | A held Sock stays calm when the view turns | done | 1 | 1 |
| flat/15-pick-what-you-see.md | Pick any Sock the crosshair reaches | done | 2 | 2 |
| flat/16-aim-shows-size.md | Under the crosshair only the Size; no floating station text | done | 0 | 0 |
| flat/17-drop-scale.md | A dropped Sock keeps its size in flight | done | 0 | 0 |
| flat/18-zoom-and-drop-key.md | Right mouse button zooms; G drops | done | 3 | 3 |
| flat/19-render-polish.md | Cheap render polish | done | 5 | 2 |
| flat/20-key-hints.md | A key hint for every action; mouse icons match the keycaps | done | 4 | 0 |
| flat/21-held-info.md | Held info sits beside the held item: Size, Sock or ball icon | done | 4 | 2 |
| flat/22-sound-bench.md | Sound bench: candidates for every event, the designer picks | done | 15 | 9 |
| flat/23-held-zoom-size.md | Held items keep their size while zoomed | done | 1 | 1 |
| flat/24-no-crouch-rule.md | No crouch rule; the coffee table hides Socks | done | 3 | 0 |
| flat/25-day-cycle.md | The sun follows an in-game day, night included | done | 10 | 6 |
| flat/26-coin-flight.md | Coin rewards fly to the bank | done | 10 | 5 |
| flat/27-polish-integration.md | Integrate polish tickets 20, 21, 23, 24, 25, 26 | done | 1 | 1 |
| flat/28-polish-followups.md | Polish follow-ups from tickets 21–27 | done | 22 | 7 |
| flat/29-upgrade-menu-style.md | The Upgrade menu matches the keycaps and icons | done | 1 | 0 |
| flat/30-hdri-sky.md | HDRI sky outside the windows and for reflections | done | 2 | 1 |
| flat/31-polish-integration-2.md | Integrate tickets 28, 29, 30 | done | 0 | 2 |
| flat/32-drop-landing.md | Dropped Socks appear only once they land, and land on what i | done | 5 | 4 |
| flat/33-swap-zoom-drop.md | G zooms, right click drops | done | 1 | 0 |
| flat/34-message-polish.md | Short, current hint messages with inline key icons | done | 2 | 0 |
| flat/35-hollow-oven.md | The oven is hollow | done | 1 | 1 |
| flat/36-rmb-throw.md | Hold right click to throw; Q is gone | done | 9 | 1 |
| flat/37-washer-lesson.md | Two matching Pairs wait on the washer | done | 2 | 0 |
| flat/38-aimed-drawer.md | Pairs go into the drawer you aim at | done | 4 | 2 |
| flat/39-integration-3.md | Integrate tickets 30–38 | done | 0 | 0 |
| flat/40-pick-on-station.md | Socks lying on a Station can be picked | done | 0 | 0 |
| flat/41-debug-coins.md | Debug money cheat | done | 1 | 1 |
| flat/42-windows-build.md | Windows build with the debug cheats | done | 0 | 0 |
| flat/43-paired-moment.md | The paired moment | done | 2 | 1 |
| flat/44-sock-meshes.md | Real Sock shapes, better sock balls and cloth detail | done | 1 | 1 |
| flat/45-exterior.md | A modelled outside seen through the windows | done | 2 | 1 |
| flat/46-menus-options-licence.md | Main menu, Coop flow, Options, Licence and UI sounds | done | 8 | 6 |
| flat/47-tv-and-radio.md | A TV and a radio in the flat | done | 13 | 8 |
| flat/48-wardrobe-basket-mirror.md | Wardrobe doors, hollow laundry basket and bathroom mirror | done | 8 | 4 |
| flat/49-menu-cursor.md | Free mouse on the title, the game's own cursor, ping in a lo | done | 3 | 0 |
| flat/50-radio-music-source.md | The Radio is the music source, and it can be carried | done | 9 | 0 |
| flat/51-one-ping-hint.md | One Ping key hint | done | 0 | 0 |
| flat/52-red-exits-white-cursor.md | Red ways out, a white cursor | done | 2 | 0 |
| flat/53-turn-held-item.md | Turn the held item | done | 6 | 0 |
| flat/54-title-icons.md | The Licence in the corner, icons on the main menu | done | 2 | 0 |
| flat/55-turn-long-axis.md | Turn the held item round its long axis only | done | 1 | 0 |
| flat/56-calmer-window-ambience.md | Calmer window ambience | done | 1 | 1 |
| flat/57-sound-bench-picks.md | Sound bench: every event, and picks that stick | done | 1 | 1 |
| flat/58-cc0-sound-hunt.md | CC0 sound hunt: real candidates for the newer events | done | 0 | 0 |
| flat/59-pressed-label.md | A pressed keycap's label goes down with it | done | 0 | 0 |
| flat/60-bubble-ping.md | The ping is the bubble alone | done | 0 | 0 |
| flat/61-louder-radio.md | The radio music much louder | done | 1 | 1 |
| flat/62-widescreen-tv.md | Widescreen TV shows with the retro filter | done | 2 | 1 |
| flat/63-drop-jazz-placeholders.md | Drop the jazz placeholder tunes | done | 1 | 1 |
| flat/64-sound-hunt-2.md | Sound hunt 2: knockdown, TV static, lids and car doors | ready-for-agent | 2 | 2 |
| flat/65-turn-stays.md | The turned item stays where R left it | done | 0 | 0 |
| flat/66-drop-where-aimed.md | A drop lands where the crosshair is, or is refused | done | 4 | 3 |
| flat/67-show-pair-ability.md | X-ray rework: only the Show pair ability stays | done | 4 | 2 |
| flat/68-held-fixes.md | Held fixes: Radio size, Pair tumble, held info toggle | done | 3 | 4 |
| flat/69-pairing-and-collection-effects.md | Bigger pairing pop and house-wide Collection-complete moment | done | 2 | 4 |
| flat/70-guide-card.md | Guide card | done | 6 | 1 |
| flat/71-held-info-name-collection.md | Held info shows the Design name and Collection icon | done | 1 | 1 |
| flat/72-hints-spell-corner-zoo-effects.md | Hints, spell corner, zoo effects, stair light flicker | done | 0 | 0 |
| flat/73-slower-walk.md | Slower walking and sprint | done | 0 | 0 |
| flat/74-xray-more-visible.md | X-ray glow: more visible, pulsing outline | done | 0 | 0 |
| flat/75-cabinet-xray.md | Cabinet X-ray: second ability (key 2) | done | 9 | 1 |
| flat/76-speed-upgrades-halved.md | Base speed back, Upgrades half as strong | done | 0 | 0 |
| flat/77-complete-icon-bounce.md | Collection complete: matching confetti, icon, bouncing text | done | 0 | 1 |
| flat/78-ui-3d-right-edge.md | UI panels and keycaps get a 3D right edge too | done | 1 | 1 |
| flat/79-held-info-always-on.md | Held info is always on | done | 2 | 1 |
| flat/80-ui-edge-perspective.md | Fix the perspective of the 3D UI edge | done | 0 | 0 |
| flat/81-guide-card-update.md | The Guide card, updated | done | 8 | 14 |
| flat/82-ping-edge-indicator.md | Pings shown at the screen's edge | done | 2 | 3 |
| flat/83-xray-looks-and-readiness.md | Sock X-ray and Cabinet X-ray: own colours, better effects, c | done | 8 | 9 |
| flat/84-xray-looks-and-readiness-build.md | Sock X-ray and Cabinet X-ray: own colours, clear readiness | done | 9 | 9 |
| flat/85-xray-outlines-and-pressed-buttons.md | X-ray: real outlines, one shared outline shader, icons back  | done | 5 | 5 |
| flat/spec.md | Flat: the sock-spill flat, eight Collections, Throw and X-ra | in-progress | 32 | 10 |
| house/01-floor-plan.md | Floor plan proposal for the house | done | 10 | 8 |
| house/02-art-style-trial.md | Art style trial: sofa, bed and plant three ways | done | 5 | 5 |
| house/03-house-shell.md | The house shell, playable | done | 11 | 11 |
| house/04-stylised-furniture.md | Stylised furniture for every room | done | 9 | 7 |
| house/05-furniture-swap.md | Swap in the stylised furniture everywhere, every piece opena | done | 11 | 9 |
| house/06-mess-across-levels.md | The Mess across four levels: an even spread, walking Mate di | done | 6 | 6 |
| house/07-rename-house.md | Rename the flat to the house | ready-for-agent | 2 | 3 |
| house/08-exterior.md | The outside around the house | done | 6 | 6 |
| house/09-restyle-stations.md | Restyle the washer, Wardrobe Station, radio and clock | done | 4 | 4 |
| house/10-car-model.md | A stylised car for the garage | done | 5 | 5 |
| house/11-plan-revisions.md | Plan revisions: no WC, a garage, the stair glass | done | 12 | 12 |
| house/12-furniture-fixes.md | Furniture fixes: wardrobe, trunks, sink, ironing board, dini | done | 6 | 10 |
| house/13-bike-remodel.md | Bike remodel | wontfix | 1 | 1 |
| house/14-drawer-socks-ride.md | Socks in an openable ride with it | done | 4 | 4 |
| house/15-bathroom-mirror.md | Bathroom mirror reflects | done | 3 | 2 |
| house/16-sock-rest-fit.md | Socks rest exactly on furniture | done | 3 | 3 |
| house/17-dumbwaiter.md | The dumbwaiter | done | 11 | 1 |
| house/18-mess-runtime-rules.md | Sock balls ride drawers, stuck items push up | done | 2 | 0 |
| house/19-garage-and-hall-layout.md | Garage door and ramp, car moved, hall plant, grates, plinth | done | 6 | 5 |
| house/20-rare-mates-cross-floors.md | Rare mates on other floors | done | 1 | 1 |
| house/21-interactive-doors.md | Interactive room doors | done | 2 | 0 |
| house/22-robust-rest-fit.md | Baked Socks rest on what is drawn, whatever the layout | done | 0 | 0 |
| house/23-one-call-button.md | One call button per Dumbwaiter hatch | done | 0 | 0 |
| house/25-split-house-model.md | Split the house into shell, furniture, exterior and Elevator | done | 3 | 3 |
| house/26-elevator-rework.md | Elevator rework: rename, hatch click, items carried as data | done | 5 | 6 |
| house/27-basement-light-and-night-glitches.md | Basement light and night lighting glitches | done | 3 | 2 |
| house/28-playable-piano.md | Playable piano | done | 4 | 1 |
| house/29-warm-basement-fill.md | Warm basement fill | done | 1 | 1 |
| house/30-basement-lamps-by-day.md | house/30: Basement lamps on by day | done | 1 | 1 |
| house/31-stairwell-shadows-zoo-clock.md | Stairwell shadows stay; zoo time-of-day slider | done | 0 | 0 |
| house/32-piano-behind-sofa.md | Piano behind the sofa | done | 0 | 0 |
| house/33-piano-all-keys.md | Piano: all keys playable, music and top clutter removed | done | 3 | 2 |
| house/34-remove-drying-rack.md | Remove the drying rack from the basement | done | 0 | 0 |
| house/35-elevator-creatures-ride.md | Creatures travel through the Elevator | done | 10 | 8 |
| house/36-attic-door-placement.md | Move the attic door off the rails | done | 2 | 7 |
| house/36-newel-collider.md | The Newel's collider matches its drawn cap | done | 0 | 0 |
| house/37-roomier-house.md | The house 10% roomier | done | 2 | 3 |
| house/38-lost-sock-grotto.md | The Lost Sock Grotto under the basement | done | 19 | 25 |
| house/39-car-doors-separately.md | The car's doors open separately | done | 1 | 3 |
| house/40-grotto-fixes.md | Grotto fixes: only Lost Socks, crates face the walkway, the  | done | 7 | 7 |
| house/41-lantern-like-any-item.md | The lantern is an item like any other, and it swings | done | 6 | 12 |
| house/42-climbing-pose-and-drips.md | A climbing pose on the ladder, and falling drips | done | 3 | 4 |
| house/43-remove-landing-door.md | Remove the leftover door on the attic stairs' U landing | done | 1 | 1 |
| house/44-third-ground-floor-cabinet.md | A third Cabinet spot on the ground floor | done | 8 | 10 |
| house/45-garage-old-tree.md | The Old Tree in the garage, and the garage relaid out around | done | 9 | 15 |
| house/46-elevator-letters-with-two-riders.md | The Elevator's letters can't be pressed with two riders | done | 0 | 2 |
| house/spec.md | House: a family house on four levels |  | 42 | 43 |
| pipeline/01-blender-mcp.md | Blender MCP and the asset pipeline | done | 5 | 0 |
| pipeline/02-washing-machine.md | The washing machine through the Blender MCP pipeline | done | 8 | 1 |
| pipeline/03-sock-meshes.md | Sock and Pair-ball meshes with LODs, through the Blender MCP | done | 10 | 1 |
| pipeline/04-cabinets.md | Remodel the Cabinets through Blender MCP | done | 7 | 5 |
| pipeline/05-wardrobe.md | Remodel the Wardrobe through Blender MCP | done | 8 | 6 |
| pipeline/06-radio.md | Remodel the radio through Blender MCP | done | 7 | 4 |
| pipeline/07-clock.md | Remodel the wall clock through Blender MCP | done | 6 | 4 |
| pipeline/08-tv.md | Remodel the TV through Blender MCP | done | 7 | 6 |
| pipeline/09-collection-board.md | Remodel the Collection board through Blender MCP | done | 8 | 8 |
| pipeline/10-pairing-machine.md | Remodel the pairing machine through Blender MCP | done | 12 | 16 |
| pipeline/11-sock-vacuum.md | Remodel the sock vacuum through Blender MCP | done | 13 | 17 |
| pipeline/12-creature-leg-socks.md | The Avatar's leg Socks: a Socks piece goes on the feet, not  | done | 8 | 7 |
| pipeline/13-leg-socks-cuff.md | Leg Socks that show: a flared cuff, and your own feet | done | 5 | 11 |
| pipeline/14-vacuum-flight-lod.md | Socks flying into the vacuum use a low-LOD Sock with its Des | done | 0 | 1 |
| pipeline/15-vacuum-window-lod.md | The Socks inside both machines' windows show as low-LOD Sock | done | 4 | 7 |
| pipeline/spec.md | Blender MCP asset pipeline |  | 13 | 0 |
| graphics/01-ambient-effects.md | Ambient effects | done | 14 | 20 |
| graphics/02-mirror-performance.md | Mirrors cost too many frames | done | 3 | 6 |
| graphics/03-shaders-compiled-before-play.md | Compile shaders before play | ready-for-agent | 2 | 2 |
| graphics/04-cheaper-low-preset.md | A cheaper Low preset | done | 5 | 5 |
| graphics/05-lowest-preset.md | A fourth graphics preset: Lowest | needs-info | 1 | 1 |
| graphics/06-sock-glow.md | Socks glow in dim rooms | ready-for-agent | 1 | 3 |

Not determined / unchecked (list):
- Whether the washer-lesson Socks (flat/37) still lie on the washer in the campaign build (code still lays them; the Mess now waits for the first wash).
- Exact wording of the stale messages in flat/34 other than "Wrong Cabinet" (code and GLOSSARY confirm only that one).
- Whether the Collection-complete moment (flat/69, flat/77) and the TV shopping details still run as described (code hooks exist; not run).
- Piano position after the 10% growth (house/32 coordinates are pre-growth).
- Whether a thrown Radio hitting a teammate is caught (flat/50 open; GLOSSARY says only Hand-off).
- Which of flat/70's Guide card captions survive on page 2 (GLOSSARY gives the current four lines; flat/81 built the captions above).
- Statuses: tickets with an empty `kind` and `done` in flat/71-77 have no Acceptance; their rules come from the one-line designer quotes and Built logs only.
