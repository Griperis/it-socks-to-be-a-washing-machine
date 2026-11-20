---
type: spec
feature: mvp
status: needs-info
created: 2026-11-20
---

# It Socks: the port

It Socks is a first-person 3D co-op incremental game: the players tidy **the house**, a detached family
house on four levels covered in a **Mess** of Socks. Every Design in play has exactly two Socks, so every Sock's
mate lies somewhere in the house, a walking distance away that grows with progress and rarity.
A player picks two matching Socks into their **Hands** to make a **Pair**, and shelves it in its **Cabinet**,
drawer by drawer. Shelving earns **Coins**, spent at the **Upgrade station**.
The Mess starts when the first dirty bin goes into the washing machine: it breaks and sprays the first batch
of Socks into Heaps, onto furniture and into Hiding spots; each floor's Fix lays a new batch.
The run ends when every Pair is shelved and the **Final wash** is done.
In co-op the Host runs every rule; Guests and late joiners see the same house, the same Mess and the same
Cabinets. Words follow `GLOSSARY.md`; the behaviours are listed in `docs/migration/behaviour-core-loop.md`.

This project rebuilds the running game fresh in Godot, piece by piece. What is known, decided and planned
(milestones, decisions, the reference clone): `docs/migration/README.md`.
