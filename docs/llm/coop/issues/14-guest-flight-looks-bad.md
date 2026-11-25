---
type: ticket
status: done
kind: bug
area: coop
feature: flight
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
suites: [coop_hands, coop_flight, flight_start, throw, teammates]
notes: ["suggested model: opus", "designer 2026-11-25, Windows build: 'on guest, still the flight looks bad' (after coop/11 and coop/13)"]
terms: [Host, Guest]
---

# On a Guest, things in flight still look bad

The designer, playing the Windows debug build with a Guest: "on guest, still the flight looks bad." coop/11 (a weak
throw ghost) and coop/13 (a Guest's throw, drop and heap differ) worked on this before. It still isn't right.

## What to do
1. Reproduce with numbers: the same throws, drops and knocked things seen on the Host and on a Guest, and the
   Guest's own throw and the Host's throw. Strips of both machines side by side, and a trace of the drawn position
   against the Host's true path per frame: lag, jitter, snaps, a missing ghost, wrong spin.
2. Say what "looks bad" is, for each case, and its cause: interpolation buffer, the synchronizer's rate, the ghost
   handing over to the real body, physics on the Guest fighting the synced pose, no rotation sync.
3. Fix within the co-op shape: the Host decides, prediction is looks only
   (`docs/migration/coop-structure-for-the-port.md`). Use Godot's synchronizer settings where they do the job.

## Acceptance
- On the Guest, a throw and a fall look as smooth as on the Host. Strips before and after in
  `builds/review-coop-14/`; look work stops there: `ready-for-human`.
- The trace numbers before and after are in the report (snaps per throw, largest jump in cm, delay in ms).
- The co-op flight and throw suites pass, nothing flaky. The network cost (kit/tools/net_shot.sh or coop_cost.sh)
  is no worse, or the change is named.

## Answers
- A Teammate's Throw on the other machine is drawn from the real launch point: the Sock pops from the avatar's belly
  to head height at release; no easing rise out of the avatar's hand (option C). (Q2685, 2026-11-25)

## Open follow-ups
- [later] For the designer (look, Q2685 built): the pop at release is one frame of 0.69 m (the Host's Throw on a Guest,
  a flat Throw from standing) and 0.48 m (a Throw down at the floor); stills in `builds/review-coop-14/`
  (chart_throw.png, throw_frames.png).
- [later] Not reproduced on the designer's Windows build: everything here is two headless processes (and a rendered
  pair under Xvfb, about 7 frames a second) on one Linux machine at 0 and 50 ms, 60 and 144 frames a second, and
  frames capped unevenly between 30 and 144 (`UNEVEN=1`). The Guest's own Throw, drop, knocked and poured Socks
  measured smooth before and after; if the designer meant those, a two-window run of the merged build would say.
- [later] Technical, seen while measuring: under heavy load (the rendered run, 8 physics ticks a frame) a Guest's
  drop ghost was drawn up to 1.2 cm under the floor's top for two ticks, and Teammates' Pair landings were never
  squashed on a Guest before this ticket (fixed here, not measured in a run).

## Built log
- 2026-11-25 agent (coop/14): Reproduced with numbers. `tools/coop_probe.sh` got `CASE=flight`: the Guest throws and
  drops by input, the Host throws by input, throws into the Under/Over pair (two knocked Socks) and drops, then pours
  6 (a fall); each machine logs every Sock in the air as drawn each frame (`S` lines, the interpolated place) and the
  Host its true body (`T` lines); `tools/coop_probe.py` fits the delay and counts snaps (a frame whose change of step
  differs from the true body's by more than 1 cm). `GUEST_FPS`/`HOST_FPS`, `UNEVEN=1` (frames capped 30-144),
  `SHOTS=<dir>` (rendered under Xvfb, both machines shoot the Host's Throw and drop from one camera).
  What looks bad, each case (50 ms one way, 144 frames a second, before -> after):
  1. The Host's Throw on the Guest (and a Guest's on the Host): drawn from the avatar's hand 0.6-0.7 m below the
     real launch, so it rises 0.39 m out of the hand (0.43 after) where the real Throw never rises; worst 68.5 cm
     off the true body (the hand lead, both); snaps 0 -> 2 (the release kick of the new ease), largest 1.0 -> 3.6 cm;
     drawn 172 -> 162 ms behind the Host (the 0.1 s stream lag, Q2439, and the 50 ms). Cause: the two hands
     (coop/13); open above.
  2. The Host's drop on the Guest: rose 0.29 m out of the avatar's hand before falling -> falls straight onto its
     spot (0.00 m rise); snaps 0 -> 1, largest 0.8 -> 1.3 cm. Cause: a time ease of a 0.6 m upward gap on a body
     that only falls.
  3. A late answer (seen with uneven frames: the Throw's copy came 150 ms before the answer letting the Sock go):
     the copy was drawn a frame at the launch pose beside the Sock still in the avatar's hand (a 68.5 cm jump), and
     the lead was skipped (the copy already played), so it popped from the hand to mid-flight. Now not drawn until
     the answer, and the lead starts then.
  4. A row quicker than any before moved every copy a whole tick in one frame (`stream_offset` only drops); not
     seen in these runs (one offset a run), a real link's jitter would. Now `play_offset` catches up 5 per cent.
  5. A Teammate's Pair landing on a Guest: the copy is frozen, its velocity zero, so the squash never played. Now
     read from the rows (`FlightRow.velocity`).
  Smooth before and after: the Guest's own Throw (0 snaps, 0.2/0.5 cm mean/worst off the Host's body, drawn 54-80 ms
  ahead: prediction), its own drop (3.1/3.7 cm, at most 2.4 cm a frame), the knocked Socks (0 snaps), the fall
  (0 snaps, 0.6 cm, 72 ms behind). The interpolation, the synchronizer's rate (60 rows a second) and the rotation
  sync (rows carry the turn, slerped) were not at fault.
- Changed: `Mess` leads (`_ease_leads`): a copy not yet playing stays in the avatar's live hand; a Throw's lead eases
  `(1 - u)^2` over `hand_over_time`; a drop's by its height over what is under it; neither grows back; computed once
  a tick, drawn between ticks (`_lead_left`); a copy before its answer is not drawn (`_early_copy`) and a late
  answer still leads from the hand (`LEAD_LATE` 0.5 s). `Mess.play_offset` follows `stream_offset` at
  `GhostTuning.stream_catch_up` (0.05 tick a tick, placeholder). `FlightRow.velocity`; `BallLanding` reads it on a
  copy; the first row's place resets the copy's interpolation. No change on the wire (no synchronized property,
  RPC or PROTOCOL), so the network cost is as before.
- Files: `game/mess/mess.gd`, `game/sock/flight_row.gd`, `game/sock/ball_landing.gd`, `game/hands/ghost_tuning.gd`,
  `tests/coop_hands_test.gd` (new case `teammate_throw_seen_real_path`), `tools/coop_probe.{gd,sh,py}`,
  `docs/architecture/mess.md`. Not touched: `game/hands/` beyond `ghost_tuning.gd` (core/118).
- Review: `builds/review-coop-14/` chart_throw.png, chart_drop.png (height over time, before/after/true),
  throw_frames.png, drop_frames.png (rendered, both machines, before and after).
- Verified: `coop_hands:teammate_throw_seen_real_path` PASS 14 checks (on main it fails its surge check: 2.04 cm a
  frame against 0.82 cm now); `run.sh --touched` PASS 22998 checks, 724 cases; grep_rules PASS.
