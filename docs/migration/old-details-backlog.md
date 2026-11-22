# Old details not yet ported

Details of the old game that `main` does not have yet, each with the designer's answer on when it comes (Q2277:
every small detail is explored and only the designer drops one). First written from core/01, 02, 03 and 08 on
2026-11-20; brought up to date at the M0.5 close-out (2026-11-22). A ticket that builds a line moves it out of here.
What M0.5 itself left for later, by system, is in `m06-backlog.md`.

## M1.1 Sound (Q2278, Q2434): plug-and-play, the old clips and numbers
- Every old sound event the core does not use yet (about 80), and the catalogue's `silent`, `layers` and `playlist`
  modes, the window ambience, the music duck and the UI jitter (core/17 follow-up; none dropped, Q2434).
- The room tone stays silent, as the old game (Q2432; core/47).

## M0.6 Co-op (Q2316)
- The knock rumble (`player/pad_rumble.gd`, `pad.json`), with the knockdown.
- The co-op match glow, a teammate's burst and shelving flight.
- A Guest hears the bounces (today only the Host plays them).

## Decided elsewhere (for the record)
- The Cabinet's "+N" Coins pop and flight to the bank, a filled drawer paying the team's Drawers, and new Rows
  dropping in with a thunk and dust: M4 (core/04 C06; `game/player/rig.gd:653, 661`, `game/campaign/cabinet.gd:125-209`).
- Pad stick curve and speed-up: a later ticket (Q2235). Held count, Collection and Design name: Sock Smarts, M4
  (Q2243). The Sock's knit look and the ball's print: M1 (Q2249, Q2263).
- The cloth bends with the spring-bone node, not the old "gravity minus acceleration" (Q2286), and uses the node's
  per-joint ground plane (Q2287).

## Ported in M0.5 (moved out of this list)
- Sound (core/17, core/25): footsteps by floor, the landing, pick, drop, cycle, refuse, pair, pop, the lost pop,
  throw charge and swish, drawer, Door and cupboard open and shut, shelve, bounce; rumble on Throw and pairing.
- Screen (core/11, core/15, core/16): the crosshair prompt and key hints, the aimed Size, "Paired!", the boxed held
  Size, the outline, the refusal wobble.
- Motion (core/09, core/16, core/27): the ball's squash, hop and roll; the pairing fold's curl; the eased flick and
  catch-up; a thrown Sock's held bend; the lost Sock's scatter and pop and the sunk Sock pushed up; the shelved
  ball's landing and the thrown Pair's flight into its slot.
