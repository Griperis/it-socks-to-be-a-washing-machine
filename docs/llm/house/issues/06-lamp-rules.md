---
type: ticket
status: done
kind: build
area: house
feature: house
priority: soon
created: 2026-11-23
done: 2026-11-23
blocked_by: [house/04-shell-details]
notes: ["Q2515"]
terms: []
---

# The old house's lamp rules

house/04 lights every lamp at noon. The old house switched all but the basement's lamps off by day and lit each
floor only with its own lights (light layers). Port both (Q2515), by examination of the old code (grep the old
house's lights and layers in `reference/it-socks/game/house/`).

## Behaviour list (old `game/house/room.gd`, `day_cycle.gd`, `flat_layout.gd` light_levels, tuning `day.json`; B = built here, N = not here)
- B01 Lamp kinds: a ceiling light per room (and two in the loft) and a small lamp per lamp piece; the Grotto's blue
  lights are the Grotto's (N, no Grotto in the port yet).
- B02 Each light has the levels it lights: its room's level; a stair room's ceiling light lights its own level and the
  next one up (its flight climbs into it and the light hangs over the top): stairs_basement lights basement and
  ground, stairs_ground ground and first, stairs_first first and attic.
- B03 Each level has a render layer of its own (old: bit 15 + level index, layers 16-20; the fifth is the Grotto's).
  A light's cull mask is every layer but the other levels', plus its own levels': it lights its floor and whatever is
  on layer 1, and nothing of another floor, shadowed or not (no light through a floor).
- B04 Every drawn thing (shell parts, furniture, Cabinets, Doors) whose bounds lie in one level goes on that
  level's layer. The level bands are cut halfway through the slab between a ceiling and the next floor (old: the
  midpoint), with 3 cm of slack. Things that span levels (floors and ceilings slabs, stair solids, walls through a
  slab) and whatever travels (the Elevator's car, Socks, players) stay on layer 1, which every light lights; a thing
  already on a layer of its own (a mirror's glass) is left. Lights and probes are never moved.
- B05 By day only the basement's lamps are lit: every light that lights only the basement (the five basement rooms'
  ceiling lights; not the basement stairs' light, which lights the ground floor too). The others are hidden (no cost
  for shadowed lights by day), the basement's stay at full energy.
- B06 Lamp colour (1, 0.88, 0.7), energy, range and shadows: house/04's, unchanged.
- N01 The day cycle itself: lamps on 19:30, off 7:00, the energy keyframes, dusk fade, the `lamps_switched` signal
  and its soft switch sound, the globe shades' glow (the port's shell has no shades), the neighbours' windows and
  the street lamps' glow, the window panes darkening: the port has a fixed noon (the day cycle is its own piece).
  Built for it: one switch, `HouseLights.night` (false: by day), that shows every lamp when true.
- N02 The basement by day: a ReflectionProbe fill (`day.basement_ambient` 0.35, tint #ffd4a0) so the basement is dim
  with only its lamps and the light wells' sun; ambient, not a lamp rule, and the port has no probe (see Open follow-ups).
- N03 Locked floors' lamps dark and their reveal fade (progression/03), the rogue washing machine's flicker, the
  night-shadow presets and a ceiling light's 1 s shadow linger (graphics): campaign, rogue machine and graphics pieces.

## Acceptance
- A behaviour list of the old lamp rules, every detail (Q2277), in the ticket before building; open choices to the lead.
- Built as the old: by day only the basement lamps lit; a lamp lights only its own floor.
- A look change, so no test (Q2421): a strip of each floor, old | house/04 | this ticket (`builds/review-house-06/`).

## Open follow-ups
- [later] N02: the old basement by day had a warm ReflectionProbe fill (`day.basement_ambient` 0.35, tint #ffd4a0) so
  it was dim with only its lamps; the port's basement still gets the noon sky's ambient, so it reads brighter than
  the old one (strip: floor-1). It is ambient, not a lamp rule: port it with the day cycle, or now?
- [later] N01: the day cycle (lamps on 19:30 / off 7:00, dusk fade, switch sound, globe shades' glow, neighbours'
  windows) is not here; `HouseLights.night` is the one switch it will set.
- [later] The first strip's kitchen view looks into a door's back (the old camera point); same as house/04's.

## Built log

### 2026-11-23
- Changed: `HouseLights` (`game/house/house_lights.gd`) on `House/Lights`: each light's `lit_levels` metadata (a stair
  room's light its own and the next level) sets its cull mask; one render layer per level (bits 15-19); at load
  every drawn thing of Shell, Furniture, Cabinets and Doors within one level goes on its level's layer; by day
  only the five basement rooms' ceiling lights are lit (`night` true shows all). Addition nobody asked for: the
  `night` switch. No test (look change, Q2421).
- Files: game/house/house_lights.gd (+ .uid), game/house/house.tscn, docs/architecture/house.md, this ticket.
- Verified: see the commit's suite line. Strip `builds/review-house-06/floor-1-basement.png` .. `floor-4-attic-outside.png`
  (old | house/04 | house/06; the old and house/04 columns are cut from `review-house-04`).
- Merged: 99ff1552 (2026-11-23, branch house/06-lamp-rules)
