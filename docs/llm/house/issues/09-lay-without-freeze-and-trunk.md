---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done:
blocked_by: [house/05-mess-in-the-house]
notes: ["Q2542, Q2544; house/05's [later] notes"]
terms: [Mess, Sock]
---

# The house's Socks laid without a freeze; the attic trunk's inside

From house/05 (2026-11-23):
1. **Laying freezes the game ~1.7 s** in one frame when the house loads (measured headless). Lay a slice per frame
   within a frame budget behind a short loading screen reading "The washer bursts open..." (the old text,
   `reference/it-socks/game/core/main.gd:647`), with a progress bar as the old (0.1 once planned, then the share laid);
   the Socks still appear all at once when it lifts (Q2523, Q2542). The result is the same Mess for the same seed however
   many frames it takes. The loading screen is a scene on the game's Theme (a placeholder look; M4 restyles it).
2. **The attic trunk's inside sits 10 cm over its real floor,** so every try there fails and the attic gets no Socks
   inside furniture. Fix the trunk's `Inside` box (and any other piece found the same way: check every furniture
   piece's `Inside` against its mesh floor and list the ones fixed).

## Acceptance
- Real path: F5 shows the loading screen, no frame over the budget while laying (measured, in the Built log), then the
  house with its Socks; a Guest joining mid-lay waits and gets the full Mess.
- The same seed gives the same Socks laid in 1 frame and over many (a case).
- The attic has Socks inside its trunk; a still for the designer (`builds/review-house-09/`), with the loading screen.
