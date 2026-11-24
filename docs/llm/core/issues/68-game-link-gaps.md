---
type: ticket
status: done
kind: bug
area: core
feature: core
priority: next
created: 2026-11-23
done: 2026-11-24
blocked_by: [core/63-lobby-scene-and-state]
notes: ["from core/62's and core/63's [later] follow-ups (2026-11-23)", "model: opus (netcode)"]
terms: [Host, Guest, Session, Roster]
---

# The game link's three gaps: a third player's spawn, the F5 join path, a Lobby Guest's Hands numbers

## What happens
- With three or more players, a Guest still loading the house receives another Guest's avatar spawn (core/62
  filtered the synchronizers, not the spawner). It matters at the Lobby's Start, where every Guest loads at once.
- A Host started from the title cannot reach a Guest started in the house with F5 and `--join=`: their Sessions sit
  at different paths, so RPCs miss.
- A Guest who joins in the Lobby sends no Hands numbers; the Host uses its own for it.

## Acceptance
- Each reproduced first in a case (three machines in one process for the first; a title Host and an F5-style
  `--join=` Guest for the second; a Lobby join for the third), then fixed; the cases pass at 0 and 50 ms.
- No save id or Part id changes; PROTOCOL raised once if the wire changes.

## Open follow-ups
- [later] `game/parts/session.gd` is now 842 lines (core/62's note asked for a split when next touched); not split here
  while core/41 and core/42 touch it. For the lead to ticket.

## Built log
- 2026-11-24
  - Changed: each gap reproduced first (l07: the third machine got the other Guest's avatar spawn and its Sync with
    no house to put them in; l08: the F5 Guest's RPCs missed `GameLink/Session` and it ended "Could not reach"; l09: the
    Lobby Guest's Roster entry had no Hands numbers), then fixed. Every avatar has a Host-owned empty `Gate`
    synchronizer under the house filter, so a spawn goes only to Guests in the house; the Host tells every Guest who is
    in its house (`_houses`), and a Guest's own avatar syncs only to those (`sees_house` on a Guest); the Avatars
    update the Gates at `house_changed` so the spawns go first. A level with no link that is the scene its machine
    shows (F5, `--scene=`) makes its own link beside itself at the machine's root (`GameLink.machine_root`,
    `is_shown_by`, `made_by`), the title's path, and closes and frees it as it leaves (`Session.leave()`).
    `house_ready` carries the Guest's Hands numbers; the Host clamps them into the Roster (`Roster.hands_said`,
    kind `hands`) as it takes the Guest in. PROTOCOL 18 (main 17 after core/41). No save id or Part id changed.
  - Files: game/parts/session.gd, game/parts/avatar/avatar.gd, game/parts/avatar/avatar.tscn,
    game/parts/avatar/avatars.gd, game/net/game_link.gd, game/net/roster.gd, game/level/level_runtime.gd,
    tests/game_link_test.gd (l07, l08 real path, l09, each at 0 and 50 ms), docs/architecture/coop.md, lobby.md
  - Verified: PASS 18826 checks, 540 cases (--touched)
- 2026-11-24 (main merged again: core/41)
  - Changed: main merged; `PROTOCOL` 18 (main 17); the avatar keeps core/41's Back and riding pose beside the Gate.
  - Files: game/parts/session.gd, this ticket
  - Verified: PASS 19009 checks, 551 cases (--touched)
