---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: core
priority: next
created: 2026-11-23
done:
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

## Built log
