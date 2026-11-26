---
type: ticket
status: ready-for-agent
kind: maintenance
area: maintenance
feature: coop
priority: next
created: 2026-11-26
blocked_by: ["[[130-personal-upgrades]]"]
notes: ["suggested model: sonnet", "left by core/130's agent, 2026-11-26; batch B wave 7, beside core/139"]
terms: [Upgrade, Hands, Host, Guest]
suites: [coop_join, coop_hands, coop_hand_off, hand_off, upgrades, personal_upgrades, lobby]
---

# Drop the Hands numbers a player used to say

Since core/130 the Host derives every player's Hands numbers from the Upgrade levels (`Hands.tuning_of()`). The
old path where a machine said its own Hands numbers is dead but still wired:
- `SessionGate.clamped_hands()` and `own_hands()` always return `{}`;
- `Session._house_ready(protocol, layout, hands)` still carries a `hands` argument, which `SessionHouse` checks,
  keeps in `_hands` and hands to `Roster.hands_said()` in `take_into()`;
- `Roster.joined(..., hands, said)` still takes `hands` and stores it in the entry; `Roster.hands_said()` and its
  `HANDS` key exist only for this.

## Do
1. Remove the `hands` argument from `_house_ready` and `ready_said`, `SessionHouse._hands` and its clears, the
   `hands_said` step in `take_into()`, `clamped_hands()`, `own_hands()`, `Roster.hands_said()`, and the `hands`
   parameter and entry field of `Roster.joined()` (and `HANDS` if nothing else reads it). Update the callers in
   `session.gd`, `session_peer.gd` and `session_house.gd`, and the doc comments.
2. The RPC's arguments change, so bump `Session`'s PROTOCOL (core/130 left it, since `session.gd` was off-limits).
3. Remove or rewrite any test case that drives the said-Hands path; keep core/130's `coop_hands:guest_big_hands`.

## Acceptance
- No `clamped_hands`, `own_hands` or `hands_said` left in `game/` or `tests/`.
- Real path: a Guest with bought Hands Upgrades joins a hosted level and picks up a Sock with the Host's derived
  numbers (core/130's `coop_hands:guest_big_hands` still passes).
- Older builds are refused at the gate by the bumped PROTOCOL.
- The suites named pass.

## Answers
- Personal Upgrades: the Host derives Hands from Upgrade levels (core/130).
