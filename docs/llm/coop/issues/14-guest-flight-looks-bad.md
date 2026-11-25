---
type: ticket
status: ready-for-agent
kind: bug
area: coop
feature: flight
priority: now
created: 2026-11-25
done:
blocked_by: []
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

## Open follow-ups

## Built log
