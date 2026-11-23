---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: soon
created: 2026-11-23
done:
blocked_by: [core/58-main-menu-and-saves]
notes: ["Q2578"]
terms: []
---

# An ESC close button at the top right of every dialogue

Every dialogue (Options, Licence, Multiplayer, Join, the ESC menu and any later one) shows a close button at its top
right, always in the same place: the ESC keycap icon (the old keycap look core/58 uses for "Back"), clicking it or
pressing ESC closes the dialogue (Q2578). One shared piece on the Theme, not built per screen; a pad's B does the same.

## Acceptance
- Real path: open each dialogue, click the top-right button: it closes; open it again, press ESC: it closes.
- A new dialogue gets it by using the shared piece (a case checks every dialogue scene has it).
- Stills for the designer of each dialogue (`builds/review-esc-close/`); the look is reviewed before the merge.
