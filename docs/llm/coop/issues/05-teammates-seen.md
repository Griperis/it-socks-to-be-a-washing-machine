---
type: ticket
status: ready-for-human
kind: build
area: core
feature: coop
priority: next
created: 2026-11-22
done:
blocked_by: ["[[03-host-join-roster]]", "[[04-avatar-model]]"]
notes: ["M0.6 batch 2 (Q2436); look and feel: one round on how it moves before it is handed out (designer-grilling rule 10)"]
terms: [Teammate, Avatar, HoldPoint]
---

# Teammates seen and heard

Everything a player sees and hears of another player: the body following every frame with light easing,
head look, crouch, waddle and squash, pupils, the held item at the HoldPoint, the Teammate's colour and
name tag, the Teammate's sounds and footsteps at their body.

## Behaviour list
`docs/migration/m06-lists/02-teammates-seen.md` (approved, Q2460), with: easing 12/s, crouch 6/s (Q2450);
a snap over 1 m (Q2451); steps and land as the local player's clips in 3D, full up close, 3 m to 20 m, a
step every 1.4 m (Q2452); pick, pair, drop, shelve, throw as loud as the local player's, 3D at 1.2 m over
their feet (Q2453); no held turn or zoom shown (Q2454); pupils follow the nearest player (Q2455); a
Teammate's Throw leaves the hand at once (Q2439).

## Design
- **Pose** (continuous state one machine owns: the Avatar's synchronizer, player as authority, as today):
  add `pose_pitch` and `pose_crouch` to `pose_position` and `pose_yaw`; sent every network frame, not 20 a
  second (Q2223: `replication_interval` 0), unreliable. Riding, climbing and suction are not built (player
  stacking is core/41, not planned). The Host drops a non-finite or out-of-bounds pose in the setter on its
  copy (the old bounds: 30 m outside the zoo on x/z, y -50 to 100).
- **Follow** on other machines: position, yaw and pitch ease at 12/s, crouch at 6/s (Q2450); a jump over
  1 m in one update snaps (Q2451). Numbers in a typed Resource beside the Avatar.
- **Looks** (`AvatarLooks`, the swappable child from coop/04): every old motion derived on each machine
  from the drawn motion, with the old numbers from the list (Q2461): waddle and bob from speed, sway, the
  look bend from pitch on the four bones, the jump and land squash, feet rocking, crouch through the
  `Crouch` shape key, pupils turning to the nearest player (Q2455). Continuous motion is code in Looks
  driven by the pose (the old game had no animations; an AnimationTree only if it does the job with less).
- **Colour and tag:** the `player` surface tinted by `Roster.colour_of(...)`, the trim darkened as the old
  game; a name tag "Player" in that colour at `Head` (Q2462). Unmarked when far or hidden (Q2463).
- **Held:** a Teammate's held things shown worn at their `HoldPoint`, true size, several clustered in small
  steps, a Pair as the ball (Q2464); others never see the held turn or zoom (Q2454). A Teammate's Throw
  leaves from that hand at once (Q2439). Reads the Hands Part; nothing new is sent.
- **Sounds:** the Teammate's steps and land with the local player's clips, 3D at their body, full up close,
  fading from 3 m to 20 m, a step every 1.4 m (Q2452); their pick, pair, drop, shelve and throw at 1.2 m
  over their feet, as loud as one's own (Q2453); a leaver's drop at their last place (coop/03 follow-up).
  The Host's own body on a Guest's machine is the same Avatar.

## Acceptance
- Real path: two zoos (Host, Guest, own profiles); the Host walks forward: on the Guest the Host's avatar
  follows within a frame-eased lag, waddles (its bones move while walking, rest when still) and faces the
  Host's way; the Host crouches: the avatar's `Crouch` goes to 1 and back. Driven by input actions.
- The Host picks a Sock: on the Guest it hangs at the Host avatar's `HoldPoint`, and the Guest hears "pick"
  at the Host avatar (a 3D player at 1.2 m over its feet). Two held cluster; a Pair shows as the ball.
- A Teammate's footsteps play at their body every 1.4 m of walk, and nothing at 25 m away.
- A jump over 1 m snaps; a small move eases at 12/s (a case each).
- The Guest's avatar is tinted the Guest's Roster colour on the Host, its tag says "Player" in that colour.
- A late joiner sees both others posed, tinted and tagged at once.
- A forged out-of-bounds or non-finite pose is dropped on the Host.
- Numbers: the easing, snap, step and fade values are typed Resource values (decided by Q2450-Q2453); the
  old motion numbers carry over as decided (Q2461).
- A strip of two players side by side (walk, crouch, look up and down, hold) for the designer; no test of
  the look itself (Q2421).
- A zoo station for the avatar (Q2468): `game/zoo/stations/avatar.tscn`, instanced by hand under `Stations`: the
  real Avatar standing still and a stand-in Teammate that walks a loop, crouches, looks up and down and holds a
  Sock, driven only through the pose properties a real Teammate's synchronizer writes; tested only for loading
  and the stand-in moving its pose.

## Answers
- Q2439, Q2450-Q2455, Q2460 (2026-11-22).
- Look and feel (rule 10): every old motion with the old numbers (Q2461); name tag "Player" in their colour at the cuff top (Q2462); a far or hidden Teammate unmarked (Q2463); held things as old (Q2464). Additions nobody asked for (wind-up cue, release squash, blink, wave) are not built (list question 8: report only).

## Open follow-ups
- [blocking] Look round (Q2461-Q2464): the strip `builds/review-teammates/teammates-strip.png` (README beside
  it) waits for the designer's go on how a Teammate moves, is coloured and tagged and holds. Built after the go:
- [later] the Teammate's steps and land in 3D (Q2452), their pick, pair, drop, shelve and throw at 1.2 m over
  their feet (Q2453), a leaver's drop at their last place (coop/03 follow-up), and the acceptance line "footsteps
  every 1.4 m, nothing at 25 m"; "the Guest hears pick at the Host avatar" is not yet built.
- [later] a Teammate's Throw leaving from their HoldPoint at once (Q2439) needs `Hands.hand_of`/`eyes_of`
  (game/hands/hands.gd, outside this ticket's Owns) to start from the avatar's HoldPoint: lead to say who.
- [later] behaviour 60: the small sparkle burst and ring at a Teammate's hand when their pick makes a Pair
  (the worn view swaps to the ball with no moment, as old, but the burst is not drawn yet).
- [later] the jump squash and the pupils are built (old numbers) but not in the strip: the Avatar station
  shows the hop and the pupils turning to each other.

## Built log
- 2026-11-22 lead: model opus (netcode and avatar motion, CLAUDE.md "Models").
- 2026-11-22 agent: look round, stopped at the first strip (Look work). Changed: the Avatar's pose adds pitch
  and crouch, sent every network frame; each copy that receives a pose drops a non-finite or out-of-area one
  in its setter (the Host's too); the puppet eases at 12/s (crouch 6/s) and snaps over 1 m (AvatarTuning,
  `avatar_tuning.tres`); AvatarLooks moves as the old avatar.gd (waddle, bob, sway, look bend on the spine,
  crouch key and points, squash and stretch, pupils to the nearest player, idle drift seeded by the peer),
  tints player and trim (body and feet) and shows the "Player" tag from the Roster; HeldView gains a worn mode
  (the Teammate's Hands at their HoldPoint, true size, clustered by `worn_step`, a Pair as the ball, no turn,
  zoom or moment). The Avatar station (Q2468) with `TeammateStandIn`; ZooNet.where() places the stand-in for
  the reach rule. The `teammates` shot action and set. Files: game/parts/avatar/*, game/hands/held_view.gd,
  game/zoo/avatar/teammate_stand_in.gd, game/zoo/stations/avatar.tscn, game/zoo/zoo.tscn, game/zoo/zoo_net.gd,
  tests/teammates_test.gd, tests/avatar_test.gd, tools/shot_hooks.gd, tools/shot_teammates.gd, tools/shots/sets/teammates.txt,
  tests/scene_parts_test.gd (a forged pose is now dropped where it lands), docs/architecture.md. The stand-in
  plays only with the camera within 10 m, so other stations' tests see its Sock lying.
  Verified: PASS 15628 checks, 368 cases (--touched); PASS rules; PASS asset_lint.
