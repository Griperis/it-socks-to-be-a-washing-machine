---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[163-radio-carried-and-thrown]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 3", "suggested model: opus"]
terms: [Sock detector, Hands, Throw, Hand-off, Teammate, Mess]
suites: [detector, carry, coop_carry, knockdown, coop_knockdown, save, zoo]
---

# The Sock detector

The one shared handheld finder: picked into empty Hands, it beeps towards the nearest loose Sock on any floor, faster
the closer, its screen showing one to three bars in the band's colour and an up or down arrow when that Sock lies on
another floor; put down, handed off or thrown by the shared rules. Build `docs/architecture/devices.md` "The Sock
detector", draft 150-E:

- `sock_detector.tscn` (`Carriable` `throwable` and `handable`, `hold_slot_detector.tres`: bigger and closer, the old
  "beeper" hold), graybox Looks and contract (`Screen`, `Speaker`);
- `DetectorScreen` (a view on every machine for whoever holds it: every 0.2 s the nearest LYING Sock from the holder's
  eyes, its band `far_m` 10 / `near_m` 3, another floor by the floor's height band), `detector_screen.tscn` (three bar
  panels, two arrows) in a SubViewport on its face; the bars dimmed when no loose Sock is left;
- the beep `beeper_beep` (3D at the model, -6 dB, the ping's pool) at a gap from 0.12 s (within 0.5 m) to 1.6 s (from
  20 m), linear between, only while held, heard by the holder and anyone near;
- lying, its body is not in a Sock flight's mask (no Mess collider); not into the drum (Q2699);
- `DetectorTuning`; the detector station filled (shell from core/154 at x = 250): loose Socks at 0.5, 3, 10, 20 m, one
  on a raised second floor, a board of the bands, a "Take all Socks" switch.

Its spot in the house is core/174's, its ride core/175's.

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V40, V41 (the thrown knock, core/163's rule), V42, V43, V44, V45 (no Mess collider; not into the drum),
V47; its word "Sock detector". V46 (moved into the Drum at the pull) is batch D's.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`DetectorTuning` (`near_m` 3, `far_m` 10, `update_every` 0.2, `close_m` 0.5, `beep_far_m` 20, `interval_near` 0.12,
`interval_far` 1.6, `volume_db` -6, the three band colours) and the hold slot in the inspector, `# placeholder:` the
old; the screen in nodes (Q2658), its band and arrow states node visibility; Looks graybox, then assets/26.

## Acceptance
- Real path: in the detector station the player left-clicks the lying detector, walks toward a loose Sock 3 m away; the
  screen shows three red bars and `beeper_beep` plays at gaps of about 0.12-0.6 s; a right click aimed at the floor
  puts it down.
- A Throw at full charge at a Teammate knocks them down (co-op case); a weak one drops at their feet.
- With a Sock in the Hands the pick reads "Hands full"; a Sock on the raised floor shows the up arrow; "Take all Socks"
  dims the bars; a falling Sock passes through the lying detector.
- Saved and joined (carrier, spot, turn, flight); a Teammate holding it beeps on every machine.
- Placeholders: `DetectorTuning`, the hold slot.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The vacuums and the detector as the old; the beep is the ping's pool; the pad placeholders until batch D (Q2698,
  2026-11-26).
- The detector rides the Elevator like the Radio; putting it into the drum waits with the Secrets (Q2699, 2026-11-26).
- A thrown detector that hits a Teammate: full charge knocks down, weaker bounces to their feet (Q2700, 2026-11-26).

## Open follow-ups
