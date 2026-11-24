# Menus and UI

## The pad's and keyboard's selection (core/75, Q2647-Q2650)

A control the pad or keyboard selects lifts 5 px, grows to 1.08 and gets a gold glow behind it (`game/ui/pad_focus.gd`,
numbers in `game/ui/pad_focus_tuning.tres`); the Theme's focus styles are empty. A mouse click never lights it. `UiSounds`
drives it from the root viewport's `gui_focus_changed` and the window's input, and re-applies it after the parent
container's layout.

**How to add a button: add a Button (or slider, text field) in the editor on the Theme; nothing else.** A control that
lights itself (a Lobby plinth) carries the meta `own_lit`. Licence links take focus (`focus_mode = 2`).
