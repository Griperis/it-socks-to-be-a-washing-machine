> Index of batch C's behaviour lists (core/148), 2026-11-26; drafts for the designer to approve. The proposals
> (architecture docs, draft tickets, waves) follow the designer's look as their own tickets, as core/120-122 did for
> batch B.

# Batch C: the lived-in house

Batch C (Q2614, `docs/migration/milestones.md` "The rest of the port"): the exterior with the dusk and night skies, the
Elevator, the Cat and the litterbox, the X-rays, the vacuums, the detector, the TV and the Radio. The guide card is
not ported (Q2695: the HUD goal line stays).

## The pieces

| List | Piece | Catalogue | Behaviour lines | Open questions |
|---|---|---|---|---|
| `09-vacuums-and-detector.md` | the Sock vacuum, the Backpack vacuum, the Sock detector | B30, B32, P01-P07 (the Splitter P04 not ported, Q2599) | 53 | 15 |
| `10-x-rays.md` | the Sock X-ray and the Cabinet X-ray | B37 | 31 | 6 |
| `11-elevator.md` | the Elevator and its riders | B12 | 46 | 9 |
| `12-cat-and-litterbox.md` | the Cat and the litterbox | B40, B16 | 40 | 10 |
| `13-tv-and-radio.md` | the TV and the Radio, the music | B14, B71 | 33 | 9 |
| (no list) | the day cycle | M1's dusk and night skies | settled by the lead's grilling: Q2693 | - |
| (no list) | the exterior view | M1's exterior | settled by the lead's grilling: Q2694 | - |

The two settled pieces (see `docs/migration/decisions.md`):
- **The day cycle (Q2693):** the old 20-minute day: the sun's path, the dusk and night skies, the moon, and the lamps
  on and off by the clock (19:30 and 7:00), the old `data/tuning/day.json` numbers as placeholders; nothing else of
  the old day.
- **The exterior view (Q2694):** the old outside (garden, fences, trees, street, light wells) seen through the windows
  only; the front and garage doors stay shut (Q2514).

The 16 Upgrades batch B shows "Coming soon" (Q2669) are all in three lists: the eight X-ray ones in 10, the three
Elevator ones in 11, the five vacuum ones in 09. The Cat, the TV, the Radio and the detector have none.

## The seams between the pieces

- **The Elevator carries things (11 with 12, 13):** the car carries what lies in it, the Radio (13) and the Cat asleep
  (12) among them; the Cat naps in the open car, rides it, wakes on arrival, opens a shut hatch itself, and fills the
  car ("Elevator full") for riders. One carry rule for everything in the car, not one branch per thing (the old
  `carry_along`). The Sock detector does not ride (09, question 12); the hose is not pushed by the car (09).
- **Things that take the whole Hands (09, 12, 13; batch B's book):** the nozzle, the container, the Backpack vacuum,
  the detector, the Radio and the Cat each take the whole Hands, come only into empty Hands, and are dropped, handed off
  and (but the vacuum parts) thrown by one rule. An Elevator rider keeps what they hold (11). The detector's New Game
  spot is beside batch B's encyclopedia book on the workbench (09).
- **Thrown things knock down (09, 12, 13):** M0.6 left the knock of the Radio, the detector and the Cat to this
  milestone (Q2483): the old rule is one (a full-charge Throw knocks down, a weaker one bounces off to the feet, never
  caught; an Elevator rider is never hit, Q2484). One question each in 09, 12, 13; best asked together.
- **The floor locks (11, 09, 12; batch A's core/80):** the Elevator's stops read the floors' locks (`stages.md`
  "Elevator's stops read `floor_open(floor)`"; core/80 built every lock "all but the Elevator's"); its padlock signs and
  "OUT OF ORDER" plaques drop by the floor opening and by Elevator Repair. The vacuums stand behind the ground floor's
  lock; the Cat waits on the couch until the ground floor opens and roams only open floors.
- **The Upgrade grid (09, 10, 11; batch B's core/129):** each piece sets its Upgrades' `stat` and they stop being
  "Coming soon"; Fast Elevator and Roomy Car need Elevator Repair; Roomy Car is co-op only.
- **The Old Tree's tips (09, 11; batch B's core/132, core/133):** `tree_tip_vacuum` (due when the ground floor opens)
  and `tree_tip_elevator` (due when Elevator Repair is bought); the recordings are copied, the triggers come with these
  pieces.
- **The day cycle and the rest:** the day's lamps (on at 19:30, off at 7:00) meet core/80's rule that a locked floor's
  lamps stay off and come on at its reveal (`HouseLights.reveal(floor)`, the lamps' level per lamp, old
  progression/03): one rule must say which wins. The old lamps' switch sounds share the X-ray's on and off pools
  (`lamp_on` shares `xray_on`, `lamp_off` shares `xray_off`: 10). The exterior's neighbours' windows and street lamps
  glowed with the lamps (old `game/house/room.gd`:55). Neither the TV nor the Radio cares about the hour (13); the
  Cat's "sunny patch" naps are fixed spots by the low windows, not tied to the sun (12).
- **Shared sound pools:** the Elevator's button shares the TV and Radio's knob click (`device_click`); the Elevator's
  bell and the detector's beep share the ping's pool; `xray_ready` shares batch B's Sole Mates match cue.
- **The washer's drum (12, 13; Secrets, later, Q2682):** the drum loads of the Cat (its coat change) and the Radio
  (playing muffled) are the Secrets subsystem's (secrets/02); list 12 asks whether the Cat's drum cycle comes earlier.
- **The Secrets that hang here (Q2682):** Elevator Duet (11), Radio Dance (12, 13), Cat on the Piano, Clock Stare, Fur
  Fetch and Cat Cradle (12): listed, not built.
- **Batch D:** the detector is moved into the Drum at the pull (09); the pad bindings of the Spit, the Pour and the
  wheel (09, question 15) may belong to the controller work.
- **Models:** none of batch C's moving things is ported yet (the Elevator's car, the Cat, the TV, the Radio, the Sock
  vacuum, the Backpack vacuum, the nozzle's display pod, the detector); the litterbox is (assets/07). Each list asks
  whether the old model is ported by the port rules.

## A suggested grouping into design tickets

1. **The house's machines: the Elevator (11), with the day cycle and the exterior view (Q2693, Q2694).** They share
   the floor locks and the house's lights (core/80), and the Elevator is the carrier the other pieces ride.
2. **The devices in the Hands: the vacuums and the detector (09), the TV and the Radio (13).** One whole-Hands rule,
   one thrown-knock rule, the Upgrade grid's vacuum row, the Old Tree's vacuum tip.
3. **The Cat and the litterbox (12).** Built after 1 (it naps in the car) and 2 (the Radio, the shared Hands and
   knock rules); its Secrets wait (Q2682).
4. **The X-rays (10).** Independent of the rest but for the Upgrade grid, the outline and the hint arrows: it can go
   in any wave, or join 2.
