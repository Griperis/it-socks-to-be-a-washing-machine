---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: coop
priority: next
created: 2026-11-22
done:
blocked_by: ["[[05-teammates-seen]]"]
notes: ["M0.6 batch 2 (Q2466); a gap the M0.6 behaviour lists left out"]
terms: [Avatar]
---

# Your own body in first person

Looking down, the player sees their own sock body as in the old game, not the M0.5 grey capsule
(`game/player/player.tscn` node `Mesh`).

## Behaviour list (from the reference, `reference/it-socks/game/player/avatar.gd`; every line to build)
- When the player is in first person, then their own body is the avatar model with only the `player`
  surface below `belly_cut` 0.8 m drawn, its cut a smooth line along the plane and closed by a flat top
  skinned like its edge (`avatar.gd:216-260`, `belly_mesh`; data/tuning/avatar.json:26).
- When looking down, then the belly sits `belly_back` 0.22 m behind the eyes so its front curve shows
  (`avatar.gd:224`; avatar.json:27).
- When the own belly is drawn, then only its outside is drawn (cull back), so looking straight down never
  shows the inside or anything through it (`avatar.gd:373-374`, maintenance/37).
- When in first person, then the pupils are hidden and do not turn; no eyes, no name tag, no hat or
  clothes (`avatar.gd:225-226`, :201, :406-408, :910-911).
- When in first person, then the belly and the feet cast no shadow (`avatar.gd:227-228`, :467-468).
- When in first person, then the feet (`FootL`, `FootR`) show and stay planted, rocking with the waddle as
  a Teammate's do (the old `feet.glb` and the avatar's feet are the same places).
- When the player crouches, then the belly follows the `Crouch` shape key; when they look up or down,
  the belly edge curls with the look bend (`avatar.gd:22-25`).
- When the player is tinted by their Roster colour, then the own belly and feet are tinted the same, the
  trim darkened as on a Teammate (`avatar.gd:362-375`).
- The leg Socks on the feet (Q888) come with the Wardrobe (M4); not built now.
- Mirrors show the whole player (house, M2); not built now.

## Design
The own body is the same `AvatarLooks` scene with a first-person mode (one Looks, two uses): the mode
cuts the belly at load (a mesh made once at load from the imported mesh, not by hand), sets the offset,
hides the pupils, tag and attachments, turns shadows off and keeps the motion code driving it from the
local player. The capsule `Mesh` in `player.tscn` goes (the collision capsule stays). The numbers
`belly_cut` and `belly_back` are typed Resource values (decided: the old values, Q2466).

## Acceptance
- Real path: in the zoo, the player looks straight down (input: mouse look): the camera sees the belly's
  outside and the two feet, tinted the player's colour, and no capsule; a case checks what the camera sees
  (the belly mesh in view, its surfaces cull back, the pupils hidden, no shadow casting).
- Crouch: the belly's `Crouch` goes to 1 with the player's crouch.
- Looking straight down at the cut never shows a back face or a hole (a shot from the eye, straight down,
  for the designer: the first still; no test of the look itself, Q2421).
- The local player's network Avatar stays hidden on its own machine (no double body).

## Answers
- Q2466, Q2467 (2026-11-22).

## Open follow-ups

## Built log
- 2026-11-22 lead: model opus (mesh cutting and avatar motion, CLAUDE.md "Models").
