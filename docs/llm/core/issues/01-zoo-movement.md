---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: []
notes: []
terms: []
---

# The zoo and movement

Milestone M0.5. The flat graybox zoo scene with the game's first-person player: walk, jump, crouch as the old game has them (`docs/migration/behaviour-core-loop.md`, controls; reference `game/player/`). The kit's zoo template and graybox player are the start; the player becomes the game's own.

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
Read from `reference/it-socks/game/player/player.gd` (the body, look, walk, jump, crouch),
`data/tuning/players.json`, `view.json`, `upgrades.json`, `audio.json`, `game/core/settings.gd`, and the cases
`room:walk, look, jump, crouch, stairs`. Numbers are **today's values, not decisions**: each becomes a field of
a typed Resource marked placeholder until the designer sets it. "Untested" = no old case asserts it.

**Look**
- L01 When the mouse moves (mouse captured), then the view turns: sideways turns the whole body, up and down
  tilts only the head. Today 0.0025 rad per pixel, times the Options sensitivity (1.0), with Options' Invert Y.
  (room:look; sensitivity and invert untested)
- L02 When looking up or down, then the tilt stops at 85 degrees either way. (room:look)
- L03 When the window is clicked, then the mouse is captured (that click does nothing else); Esc frees it; while
  it is free the view does not turn. (untested)
- L04 When the body moves between physics ticks, then the camera is drawn smoothly between them, and a mouse turn
  shows on the very next frame, never waiting for a tick (physics interpolation on). (untested; old physics/03)
- L05 The field of view is 75 degrees. (untested)

**Walk**
- W01 When W A S D are held, then the body walks that way relative to where it faces at 4.0 m/s; a diagonal is
  no faster than straight; it starts and stops at once (no run-up, no slide). Walking goes on in the air (full
  steering while jumping or falling). (room:walk)
- W02 When it walks into a wall or furniture, then it stops at it and slides along it; it never passes through.
  (room:walk)
- W03 When it walks up or down a slope or stairs (stairs are ramps over the steps' noses), then it keeps the
  floor's pace. (room:stairs; there are no stairs in the flat zoo, so M0.5 tests a ramp)
- W04 When it walks off an edge, then it falls under gravity, today 20 m/s² (twice Earth's: snappy).
  (untested alone)

**Jump**
- J01 When Space is pressed while standing on the floor, then the body leaves the floor at 5.5 m/s (with gravity
  20: about 0.76 m high, about 0.55 s in the air) and lands where it would. (room:jump)
- J02 When Space is pressed in the air or while crouched, then nothing happens (no double jump, no crouch jump).
  (room:jump: crouched; in the air untested)

**Crouch**
- C01 When Ctrl is held, then the body crouches at once (no easing): 1.7 m tall to 1.0 m, the eyes 0.1 m under
  the top (1.6 m to 0.9 m), walking at half pace. Letting go stands up at once. (room:crouch)
- C02 When Ctrl is let go under something lower than standing height, then the body stays crouched until there
  is room to stand. (untested)

**The body**
- B01 The body is an upright capsule 0.35 m round its middle, 1.7 m tall, its origin at the feet.
- B02 When a menu is open (or anything else that freezes the player), then look, walk, jump and crouch are
  ignored and any held key is dropped; closing it frees them. (avatar:*, debug_menu:* through menus)

**Pad** (Q2235)
- P01 The pad's bindings for these actions are in the InputMap: left stick walks, right stick looks, X jumps,
  LT crouches. The stick look's deadzone, curve and speed-up come in a later ticket.

**Invariants**
- The body never passes through a wall, floor or furniture, and never stands up into a ceiling.
- Walking speed is never above the pace (walk, half when crouched) on the flat.
- The head's tilt never leaves +-85 degrees.
- M0.5 is a Host of one: the body is continuous state this machine owns, not decided state; nothing of movement
  goes through a Command. In M0.6 others see it through a synchronizer and avatars eased every frame (Q2223).

**Not in this ticket** (each named with where it goes; the old player held them all in one 800-line file)
- The crosshair: reach 2.5 m, what it aims at, the outline: ticket 02 (handling Socks).
- Sprint (Shift, x1.3) and Footwork (+5% walking speed a level): with the Upgrades in M4 (Q2233).
- Zoom (G held: 75 to 50 degrees over 0.15 s, eased; look slows with it): ticket 02, with the held Sock (Q2234).
- The pad's look tuning (deadzone, curve, speed-up) and RT sprint: a later ticket (Q2235).
- Sounds: a footstep every 1.4 m (wood or tile by floor), a landing after a fall of 3 m/s or more, jump, crouch:
  with the first audio ticket.
- Co-op body rules, M0.6 or later: teammates' soft push apart (0.6 m), standing on and riding a teammate's back
  (stacking), slipping off a knocked-down teammate, dragging one (slower), the knockdown itself.
- M5 features: the Grotto ladder, the Elevator ride, the cutscene freeze, a heavy Hamper (no sprint or jump).

**Where the kit's graybox player differs today** (it is the start, not the reference): jump 4.5 m/s, gravity
the engine's 9.8, look 0.003 rad per pixel, tilt limit 80 degrees, no crouch.

## Design
<Step 2.>

## Acceptance
- The zoo is a scene edited in the editor, one station per feature, and Play starts in it.
- Movement matches the approved behaviour list; its numbers are a typed Resource, each marked decided or placeholder.
- The player is a Host of one: nothing here blocks a second player in M0.6.

## Answers
- The behaviour list is approved as written (Q2232, 2026-11-20).
- No sprint in M0.5; it comes with the Upgrades in M4 (Q2233, 2026-11-20).
- Zoom moves to ticket 02, handling Socks (Q2234, 2026-11-20).
- Pad: the movement actions get their pad bindings now; the stick look tuning gets its own later ticket
  (Q2235, 2026-11-20).

## Open follow-ups

## Built log
