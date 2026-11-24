---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done:
blocked_by: [core/65, core/66]
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2277", "suggested model: sonnet"]
terms: [Host, Guest, World, Part, Roster]
---

# The Lobby details (M4)

Build "Core/67" of `docs/architecture/lobby.md`: the pad route over the Lobby and the drawer, the keys' captions and hints, the
wording from one place, the Ready tick, the narrower-than-16:9 camera, the status line, the "Invite friends" hook (hidden until a
transport can invite). Then walk the list `02-lobby.md` line by line and report each as built, dropped by a Q, or later.

## Acceptance
- The pad reaches every key and the drawer's rows and walks back; the first selection is the "i" key when there is one, else Back.
- Ready ticks and does not click; the captions show as the list says and keep their line.
- `NetTransport.can_invite()` is false for ENet and the key is hidden; a test transport that can shows it.
- A walkthrough note in the Built log: every line of `02-lobby.md`, its state.

## Open follow-ups

## Built log
