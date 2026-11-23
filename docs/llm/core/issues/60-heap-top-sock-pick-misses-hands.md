---
type: ticket
status: done
done: 2026-11-23
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-23
blocked_by: []
notes: ["found by house/09 (2026-11-23)"]
terms: [Mess, Sock, Heap, Hands]
---

# Picking the top Sock of a Heap in the kitchen never reaches the Hands

## What happens
house/09 changed the laying, and the kitchen real-path case then aimed at the top Sock of a Heap. The pick
never reached the Hands. house/09 switched the case to a Sock lying on the floor and did not look into why.
In play this may be a Sock on a Heap that cannot be picked up.

## Reproduce
On main after house/09's merge, point the kitchen real-path case (house suite) back at the top Sock of a Heap
and run it alone.

## Acceptance
- Reproduced first; the cause is written up in the Built log (the aim ray, the Heap's bodies, the pick filter?).
- Fixed: a Heap's top Sock can be picked through the real input path; a case covers it.
- The kitchen real-path case may go back to the Heap pick if that is the truer path.

## Built log

### 2026-11-23
- Reproduced: the kitchen case aimed back at a "top" Sock of a Heap (119) picked Sock 287 instead, never 119.
- Cause: no fault in the game. The test's `_open_sock` probe cast its ray up from 6 cm over the Sock's
  origin; in a Heap that start lies inside the Sock stacked on it (287, origin 6 cm higher), so the ray
  from inside missed it and a covered Sock passed for the top. The crosshair rightly rested on 287, the
  nearer Sock (R03). The aim ray, the pick filter and the tread layer play no part; real tops pick fine.
- Changed: `_open_sock` (house and save suites) asks the Mess what rests on the Sock (`resting_on`) and
  probes up from the Sock's top; the house suite's `_spot_aiming` keeps a spot only where AimFinder
  names the target. The kitchen real-path case is back on a Heap's top Sock and checks the crosshair.
- Files: tests/house_test.gd, tests/save_test.gd
- Verified: PASS 543 checks, 48 cases (`run.sh --touched`); PASS rules
- Merged: 83c69fef (2026-11-23, branch core/60-heap-top-sock-pick-misses-hands)
