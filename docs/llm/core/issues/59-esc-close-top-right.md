---
type: ticket
status: done
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

## Built log
### 2026-11-23
- Changed: one shared close key, `game/ui/close_button.tscn` (+ `CloseButton`, Theme variation `CloseButton`): the ESC keycap, icon only, top right of the panel. It replaces every bottom-left "Back" (Options, Licence, the ESC menu, the title Multiplayer and Join pages: one key on the title panel, shown on those pages) and the End-session question Cancel (the key, like Esc, cancels the question first). Esc and a pad B stay each dialogue `ui_cancel`.
- Files: game/ui/close_button.{gd,tscn}, game/look/theme.tres, game/ui/{title,options,licence,esc_menu}/*, tests/menus_test.gd (X01-X03), tools/shot_hooks.gd, tools/shots/sets/esc-close.txt.
- Verified: agent_finish run; stills builds/review-esc-close/ (six dialogues).
