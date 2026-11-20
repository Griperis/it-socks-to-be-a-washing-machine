# Open questions for the designer, about the move

Everything still waiting on the designer, verbatim from its source file (which one is named at each heading). Each group waits for its milestone. The old game's own open questions
(60 `[blocking]` follow-ups) are in `feature-catalogue.md` part 3 and are not repeated.
Ask only through the dialog (`designer-grilling`); move an answered question to its ticket and strike it here.

## A. Setup and slices: all answered
The twelve setup questions and the nine slice questions of the first hand-off were answered or dropped on
2026-11-19 (Q2196-Q2216 in `decisions.md`). Three remain, none urgent:
- Does the old repository keep its tickets and skills for the freeze period? (recommended: yes)
- A budget or stop point for the whole move? (recommended: set it from the measured cost of M0.5)
- When a room does not fit the half-metre grid, what gives? Asked when M2 starts. (recommended: the odd parts get a
  fixed piece off the grid; furniture moves before the house bends)

## B. Asked at the design of the core (M0.5, M0.6 and M3)
### B1. From `state-and-coop.md` section 5
For the dialog: at most four options each, the recommended one first.
**Status on 2026-11-19, after the starter kit's scene parts were built and the co-op answers given:** 1 is decided
(Commands and one snapshot for decided state; Godot's synchronizers for a body or a thing in motion; `decisions.md`
"Co-op structure"). 2 and 3 are how the kit's `Part` works (a "State" group in the inspector; the rule in the part's
`decide()`): confirm them at the first design rather than asking afresh. 4: node paths now, stable ids with kit 7.2.
5: answered by Q2220-Q2222 (looks only). 6: the Mess is one Part (the lead's mapping; grilled in M3). 10: the kit
has both the test-suite check and the Host's guard. 7, 8 and 9: answered 2026-11-20, all as recommended (Q2251-Q2253, now a rule in `CLAUDE.md`).

1. **Network.** How should a Door's state get to the other players? (a) Our own messages and one snapshot (recommended) (b) Godot's MultiplayerSynchronizer on each thing (c) Ours up to the Host, Godot's back down
2. **Marking state.** How does a part say which fields are its state? (a) A "State" heading in the inspector (recommended) (b) A written list at the top of each part (c) A name prefix or custom code per part
3. **Where a rule lives.** Where is the rule "a locked Door won't open" written? (a) In the part's own script, beside its fields (recommended) (b) In a separate rules file next to each part (c) In one script per feature that decides for all its things
4. **Ids.** How does each placed thing get its name for saves and the network? (a) From where it sits in the house now, an editor tool when saves come (recommended) (b) From where it sits in the house, always (c) Typed by hand on each thing (d) Filled in by an editor tool from the start
5. **Prediction.** Should a Guest's click show before the Host answers? (a) Later, once the core loop runs (recommended) (b) Now, for picking up and putting down (c) Never
6. **The Mess.** How do Socks take Commands? (a) Through the same path, under one id "mess", with their own data (recommended) (b) Through a path of their own
7. **Inheritance.** How deep may classes inherit? (a) One step: Part, then Openable; nothing under Openable (recommended) (b) Two steps, so a Drawer can extend Openable
8. **One class per file.** May a file hold more than one class? (a) No: one class, one file, named alike (recommended) (b) Small helper classes may sit inside a file
9. **Things without a script.** May a thing like the Door be a scene with no script of its own, only parts? (a) Yes, a thing gets a script only when no part can do the job (recommended) (b) No, every thing's root gets a small script
10. **Who writes state.** How strictly is "only the Host's answer writes state" kept? (a) A test-suite check: no part script assigns its own state, and all machines must agree after every test (recommended) (b) That, plus a guard in the game that stops any other write while playing (c) Code review only

---

### B2. From `behaviour-core-loop.md` section 6 (answered by approving the behaviour list, M4)
Each has 2 or 3 options in plain words; my recommendation is first.

### Mess
1. **Does the Mess grow with the players?** Today the Mess is the same size for 1 to 4 players, and a share (5%) of each floor's batch is put on high spots only if two or more players are in the game at the moment the batch lands. So a late joiner or a leaver changes what the next floor holds. Options: (a) fix it by the Group's size when the World is first played; (b) keep it as today (whoever is in the game when the batch lands); (c) add more Pairs for each extra player.
2. **Should the first port start with the Mess already lying, and add the first-wash intro later?** Today a normal New Game has no Socks until the first bin goes into the washing machine, which breaks and sprays the first batch. Options: (a) port the core loop with the Mess lying at the start and port the intro as its own later feature; (b) port the intro with the core loop; (c) never show the Mess before the intro, even in tests.
3. **Where does a Sock go when it ends up outside the flat or sunk into a floor?** Today it is put in front of the washing machine, scattered, with a pop; one sunk in a slab is pushed up onto that floor with no pop. Options: (a) keep both; (b) always back where it was dropped from; (c) refuse the drop earlier so it cannot happen.
4. **How is a Sock's mate hidden?** Today rare Designs hide more, lie farther away, and half the rare mates are on another level. Options: (a) keep, tune later (numbers are placeholders); (b) all Designs hide equally in the first port; (c) mates always on the same level.

### Hands
1. **Should the Guide card take the player's only Hands place?** Today every player starts holding it, so with one place a Sock is refused until it is put down. Options: (a) the card is not a Hands item (it lives on its own key); (b) start with two places; (c) keep as today.
2. **What should a refusal say?** Today clicks that fail say a short line ("Hands full", "Can't drop there", "Not their mate"), a Throw that is not caught bounces with no line, and a click sooner than the 0.35 s grab interval does nothing. Options: (a) clicks say a line, physical outcomes (a bounce) and too-quick clicks stay silent; (b) everything says a line; (c) nothing says a line, only sounds.
3. **Should a Guest's hand-off show at once like their pick, drop and Throw?** Today it waits for the Host's answer, so with a laggy line it feels slower than everything else. Options: (a) keep it waiting (it needs the receiver's Hands); (b) show the item leaving the Hands at once and undo if refused; (c) make a hand-off a Throw only.
4. **What if your Hands are full and you click a Sock that is not a mate?** Today it is refused ("Hands full"). Options: (a) refuse, as today; (b) swap it with the active item; (c) drop the active item and take the new one.
5. **Is the 0.25 s right-button tap the right line between a drop and a Throw?** Someone who holds a little long throws by accident. Options: (a) keep 0.25 s; (b) longer hold (0.4 s); (c) a separate key for Throw.

### Throws and catching
1. **Is Throw free from the start?** The glossary calls it an Upgrade; the game and tests make it free and weak (3 to 5 m/s today), Long Arm and Quick Charge only improve it. Options: (a) free from the start, fix the glossary; (b) locked until bought; (c) free but only at a short range until bought.
2. **Where does a thrown Pair shelve and what does a failed shelve say?** Today it goes into the lowest drawer with room whatever drawer it hit, and a wrong, locked or full Cabinet bounces it with no message. Options: (a) as today; (b) into the drawer it hit; (c) as today plus a short line for locked or full.
3. **Is the full-charge knockdown part of the first port?** Today a full-charge Throw at a teammate knocks them down for a moment. Options: (a) no: port Throws with catch and hand-off only, knockdown later as its own feature; (b) yes, with Throws; (c) remove it.
4. **Should a charge be cancellable?** Today there is no cancel: releasing always throws. Options: (a) keep; (b) a left click cancels; (c) moving the crosshair to red cancels.

### Pairs
1. **Should a Hand-off or catch only ever complete a Pair?** Today a loose Sock is only given or caught if its mate is in the receiver's Hands ("Not their mate"); a Pair always goes if there is room. Options: (a) keep; (b) any Sock may be handed over; (c) only Pairs may be handed over.
2. **Can a held Pair be split back into two Socks?** Today never (only an undone prediction does it). Options: (a) no; (b) a key splits it; (c) a drop splits it.
3. **Should Pairs on the floor fall when what they lie on is taken away?** Today they do, as drops do (physics/38). Options: (a) keep; (b) only for stacks of Pairs, not a Pair on a Sock; (c) a Pair stays put.
4. **Should a teammate see the full pairing moment?** Today only the player sees the full 0.5 s moment; others see a small burst at the hand. Options: (a) keep; (b) everyone sees it; (c) nobody, only the sound.

### Cabinets, Drawers, Doors
1. **Should a click shelve every held Pair or only the active one?** Today a click shelves all held Pairs of the Collection, a Throw one. Options: (a) keep; (b) a click shelves only the active Pair; (c) a click shelves the held Pairs of that drawer's Collection but only to the aimed drawer, no overflow.
2. **What does a click on a drawer say when you hold only loose Socks?** Today it silently opens or shuts it ("Pair socks first" exists but is never shown). Options: (a) keep opening; (b) say "Pair socks first"; (c) nothing, keep it shut.
3. **Cabinets carry no icon (you learn by the refusal). Keep?** Options: (a) keep; (b) a small plate; (c) a colour trim per Collection.
4. **Which Doors start shut?** Today about a third at random each New Game, except the laundry-to-garage way. Options: (a) keep; (b) a fixed set each time; (c) all open.
5. **When a Door swings, Socks in its way jump out of it at once (the same on every machine) instead of being swept along.** Options: (a) keep, because it is identical for everyone; (b) sweep them physically; (c) block the Door while something lies in the way.

## C. Later, from the old plan: `131-scenes-and-resources-plan.md` "Open follow-ups"
The first five are marked answered there; the `[later]` ones remain.
- [answered by the fresh-project decisions, Q2154, Q2164] Do the scenes replace the JSON (read at load into the same data; recommended) or write
  JSON on save?
- [answered by the fresh-project decisions, Q2164] Tuning: all 62 sections as typed `.tres`, only the often-tuned ones (drum, cat, stages,
  upgrades), a generic `TuningSection`, or leave it JSON?
- [answered by the fresh-project decisions, Q2152] Do the Blender generators keep running for the house shell, furniture and avatar (meshes
  only), or stop entirely?
- [answered by the fresh-project decisions, Q2154, Q2157] One house scene, or one per floor?
- [later] Avatar crouch and bend: keep per-point offsets, or a Crouch animation (looks slightly different)?
- [later] Cutscenes as AnimationPlayer scenes (each rebuilt from today's code)?
- [later] The sound picker: write Resources, or keep `sounds.json`?
- [later] Delete the Grotto before the move?
- [later] Start `tr()` while screens move into scenes?
- [later] Try `SoftBody3D` under Jolt for held Socks?

## D. Process questions, from `digests/digest-maintenance-and-process.md` part 5
- [later] Q827 "physics first" is recorded as "queue order: physics tickets first" (`ticket-agents`). Is that the meaning? (maintenance/28)
- [later] Tickets use areas the list does not name: `tests`, `rendering`, `physics`, `multiplayer` (beside `co-op`), `tooling` (beside `tools`), `tech`, `progression`, `meta`. Document them or retag them? (maintenance/28)
- [later] Where the skill lives: this repo's `.claude/skills/`, the user-level skills beside `godot-game-dev`, or part of `godot-game-dev`. Write it after the three pilots, or keep a draft from the research and grow it per phase? (maintenance/139)
- [later] `tools/export.sh --out` writes no `README.txt` or double-click `.cmd` for a review build; a template or an export option would make them uniform (designer's choice). (maintenance/146)
- [later] Only subagent runs are counted by `agent_cost.py`, not the lead's own session transcripts; say if a "sessions" row is wanted. (maintenance/144)
- [later] Housekeeping takes about 2 minutes (git on the mounted drive, 100+ branches); cache per branch tip if it bites. (maintenance/127)
- [later] Does the host keep the VM's freed memory after runs end? Wall time with the rounded 4 slots unmeasured. (maintenance/77)
- [later] Per-event typed classes in place of string-keyed Dictionaries (944 sites). (maintenance/58, 80)
- [later] `tools/run.py --reverse` forwarding (ticket 133, ready-for-agent). Remaining long frame waits (29 `# kept:` in net, 38 elsewhere). (maintenance/61, 76)

## E. Where the sources conflict
1. **Milestone numbers:** `new-project-start.md`, `risks-and-slices.md` and `feature-catalogue.md` part 5 each number differently; `milestones.md` governs.
2. **Throw and the glossary:** `behaviour-core-loop.md` says the glossary calls Throw an Upgrade and the code makes it free; `digests/digest-house.md` says the glossary now says Throw is free from the start. The glossary's Throw entry opens "An **Upgrade**:". B2, Throws and catching, question 1 settles it (also `GLOSSARY.md` "To review").
3. **Commits not on GitHub:** Q2179 says 237, `new-project-start.md` measured 235. The designer pushes; the reference clone has whatever was pushed (check `git -C reference/it-socks log -1`).
4. **Design counts:** `feature-catalogue.md` and the glossary say 605 Designs in 17 Collections, the glossary's Collection entry nine Collections (555 plus 50 Lost Socks), `assets-inventory.md` found 1,005 Designs in `data/designs.json`. Check before any count is copied.
5. **Shape A or B:** `code-shape.md` picked shape A; Q2147 chose B. Binding: B (`decisions.md`).
6. **Q2162 (all assets before any scene work):** replaced by Q2213 and Q2214.
7. **Sources not fully read by their authors:** `risks-and-slices.md` part F, `new-project-start.md` part F and `assets-inventory.md` section 6 list what no one checked; read them before relying on the numbers marked judged.
8. **The planning page's own question lists** ("Still to ask", "Decisions for the grilling" A-G, and the lists H1-H8, M1-M9, S1-S15 named in tickets 148-150 of the reference clone) were written before Q2143 made the move a fresh project. Many are answered or moot; check each against `decisions.md` before asking it again.
