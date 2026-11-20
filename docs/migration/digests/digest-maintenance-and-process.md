# Digest: maintenance tickets, and how we work

Source: docs/llm/maintenance/ (157 ticket files, `128-sweep-summary.md`), the 25 project memory files, docs/agents/*.md, read 2026-11-19. Tickets read in number order. Marks: `(Qnnn)` = a numbered designer answer; `(designer, date)` = a quoted or reported designer statement; `[mem:name]` = project memory file; `[agents/git.md]` etc. = the repo's agent docs. "Lead's reading" items are marked as such and are not the designer's words.
Native-move answers Q2143 onward in maintenance/131 get one line each, as asked.

# PART 1. Play, look, sound, wording and control rules decided in maintenance tickets

## 1.1 Graphics presets, shadows and performance targets

**What it is.** Low / Medium / High graphics presets (maintenance/04), the night shadow rule, the bench, and the low-end PC target.

**Rules that bind**
- Three presets: High is the then-current look; Medium and Low cut anti-aliasing, render scale, mesh detail, sun cascades, Mess shadows, lamp shadows, SSAO and glow. (Q352; maintenance/04)
- Mesh LOD only on Medium and Low; High keeps full detail. (Q353)
- First launch picks the preset from the GPU (integrated: Low, mid: Medium, dedicated: High); the setting is "auto" until the player picks; changeable later. Unknown adapters (VM, no name) get Medium (built, placeholder name list). (Q354; maintenance/04 Built log)
- Debug builds only: F3 frame-time overlay and `--bench` scripted fly-through per preset writing `user://bench.json`. (Q355) The F3 overlay is now Profily; our own frame overlay dialog was removed. (designer, 2026-11-12; maintenance/124)
- Low: sun shadows only, no lamp shadows and no Mess shadows. (Q1637, 2026-11-11)
- High keeps every lamp on the player's floor shadowed at night (`night_shadows: level`). (Q1638, 2026-11-11)
- On High at night only ceiling lights on your level within one doorway of your room cast shadows ("near"); the rest still light without shadow. (Q420, Q469; maintenance/08)
- A stair light you can see into from your room (flight starts on another level, opens onto yours) casts shadows too. (Q470; maintenance/08, 15)
- Light leaking through floors: "watch for it in the walkthrough". (Q471)
- Target machine for the low-end work: a 2015 laptop / GTX 1050 class. (Q1670, 2026-11-11; maintenance/109)
- The low-end budgets (30 fps at 1080p on integrated GPU or GTX 1050 class, i.e. a 33 ms frame; per room on Low: 0 shadowed lamps, at most 4 lit lamps, at most 350 draw calls, 140 k triangles; per tick on a settled heap at most 4 ms) are the agent's proposal, "a placeholder for the designer" (maintenance/25 Built log). Not confirmed by a Q.
- Aim chain rate: the designer asked to try the aim chain at every 2nd and 3rd tick; actions always aim fresh, only outline, prompts and crosshair may lag. (Q1672, 2026-11-11; maintenance/110)
- Fade, loading and spawn feel: see 1.2.

**Numbers**
- Preset table values (FSR scale 0.85 Medium, 0.7 Low; sun cascades 2 / 2048 Medium, 2 / 1024 max 10 m Low; Mess shadows within 4 m Medium): decided as placeholders "numbers in data" (Q352), keys `graphics.presets`, `graphics.detect`, `graphics.bench` in data/tuning.
- `loading.frame_ms` 14: shipped, designer not asked (open, see 1.11).
- `bench.settle_ms`, `settle_ticks`, `warmup_s`: placeholders (maintenance/25, 108, 111).
- `players.aim_every_ticks`: waits for the designer's pick of 1, 2 or 3 (maintenance/110, `data/tuning/players.json`).
- Jolt limits `max_body_pairs`, `max_contact_constraints` 65,536: decided (Q1474, 2026-11-10); principle: lowest limits that lose no Socks in the game's own biggest Mess; zoo and stress raise them for themselves. (Q1193, 2026-11-07)

**Decided against / parked**
- Occlusion culling: "Not now; parked. It may come with the move to a native Godot project." (Q1955, 2026-11-18; priority later Q1582)
- Merge lights / baked light for Low: not done; needs a look decision (open [later], maintenance/25).
- Aim chain "only while the view moves": not built, designer to say (maintenance/110 [later]).

**Open**
- [blocking] Which aim rate: 1, 2 or 3? Play `builds/review-aim-rate/every-2-ticks` and `every-3-ticks`. (maintenance/110, ready-for-human; Q1963 "keep waiting")
- [later] High's mesh detail: keep 1.0 or truly no LOD (3.5x cost)? SSAO "half size" on Medium equals High's: drop Medium's quality or raise High? Medium's dual-paraboloid lamp shadows are softer: keep or cube for the one light? Low's sun shadow shows stair-stepped edges. (maintenance/04)
- [later] MSAA 4x (flat/19) versus 2x in project and High preset: raise High to 4x? SSAO quality as a preset key? (maintenance/17)
- [later] Designer's choices in the fidelity report section 4 (GI path, day-cycle strategy, room ambient colours, colour grade, sun shafts, how lived-in, texture grain, DoF, FSR 2, creature-versus-world detail) were never answered. (maintenance/17)
- [later] Bench stop on the landing (7 shadowed lights); stairs opening onto any near room, not only your room. (maintenance/15)
- [later] Fixed seed so the heap bake can be shipped pre-baked? (maintenance/16; asks whether every New Game keeps the same Mess)
- [later] Teardown error "BUG, indexing did not unpair geometries from light" (engine-side, not fixed). (maintenance/25)
- [later] Per-system tick costs (Rig 0.84 ms of 2.00; Game.secrets_washes 0.15; SockWorld.move_movers 0.13) with cut ideas; designer decides which to cut. (maintenance/135)
- [later] Re-run the bench on the 4070 Ti and read `frame_split.tick` versus `plain` for the +3 ms on tick frames. (maintenance/111)
- Aim rate and bench numbers were measured on the designer's RTX 4070 Ti (Low 4.1, Medium 5.0, High 6.5 ms average, p95 11 to 14 ms; 2026-11-18 on a Ryzen 7 7800X3D 2560x1440). The low-end PC's own numbers (settled tick 3.98 ms, 90 % scripts) are in `docs/perf/low-end-report.md`, not digested.

## 1.2 Loading, fade, spawn hitch, respawn of lost items

**What it is.** The loading screen, the fade into play, new-floor Socks appearing, and items that leave the house.

**Rules that bind**
- The loading screen stays animated and responsive: work is sliced by a frame budget; "could the baking and stuff during loading happen on background so the loading is responsive?" (designer, 2026-10-31); answer "Frame budget + spike" (Q521).
- Loading into a game fades from the loading-backdrop colour into play over 0.5 s (`fade.seconds`); one reusable `ScreenFade` helper with a colour parameter (black for cinematics, backdrop colour for load); the fade covers everything including the HUD; no input lock (play starts at once); the knockdown return is unchanged. (Q1262-Q1266, 2026-11-08). "Fade looks good." (designer, 2026-11-08)
- A floor's Socks may appear a few frames to about 0.5 s after its door opens; no cutscene over it; no planning during the Part cutscene. (Q1673) The work may happen during the cutscenes (Q1668); the Socks appear as now, same look (Q1669); a Guest may see them a frame or two after the Host (Q1671). (2026-11-11; maintenance/109)
- Any Sock or Pair that leaves the flat comes back in front of the washing machine, scattered, settled, with a "pop": designer, "Any item that would fall off the map should be respawned in front of the washing machine." (maintenance/06). Lost means more than 0.3 m under the floor, above 2.7 m, or more than 0.1 m outside every room and doorway (`lost.below`, `lost.margin`, `lost.scatter`, `lost.front`; placeholders). Since physics/35 (Q1250, 2026-11-08) a Sock or Pair cannot be thrown out of a window at all: windows are walls to it.
- Dropped and thrown Socks settle physically where they land (Q333); draping later (Q335); on-end threshold goes to the balance round (Q477).
- A dropped Sock's cloth never dips below its ground (`cloth.ground_clearance` 0.002 m, placeholder). (maintenance/05)
- A Heap may spill after a pick: woken Socks rolling 0.33-0.77 m is fine. (Q966)
- Non-Sock items (gift, Pair, Guide card) fall as one light rigid body, then lie still and stop simulating; devices land upright. (Q956, Q957, 2026-11-05; the upright landing is not built for the Radio, Guide card, gift box, put-down devices: open in maintenance/29 closing summary)
- Prefer Jolt over custom physics wherever Jolt can do it. (Q1200, 2026-11-07) [mem:prefer-jolt-over-custom-physics]

**Open**
- [later] Loading screen content (tips, flat name, joiners, a real 3D Sock)? Landing glide of 0.15 s acceptable? Throw start along its length fine? Raise bake speed during loading? Do the pick pool of SockActors now? (maintenance/03)
- [later] Lost items: back onto the spill's heap OK? Window-opening margin 0.1 m? Visible return arc? Solid window panes? (maintenance/06; window part overtaken by Q1250)
- [later] Thrown Sock capsule radius 3.5 cm thinner than the Sock (dips 1-1.7 cm); touchdown feel quick slap or eased; low start onto surfaces higher than the Hands. (maintenance/05)
- [later] Spawn hitch: real-machine check on the GTX 1050 laptop with a debug build for GPU pipeline compiles. (maintenance/109)

## 1.3 Held items, Hands and the carry rules

**Rules that bind**
- Every held thing crouches the same way; no kind stays at standing height. (Q1104, 2026-11-06; maintenance/47) `hold.floor_clearance` 0.25 m is a placeholder for the designer to set in a build.
- A teammate's held Guide card faces its print to the player holding it; others see its back. (designer, 2026-11-06; maintenance/37)
- The Radio's push-back and a body glitch looking down: "Both are bugs to fix." (designer, 2026-11-06)
- Held-item fixes: the Collection's own icon, no drawer number, in the prompt row's style (designer, 2026-11-06; maintenance/36).
- The Laundry bin's prompt icon is 1.3x like the rest. (Q1186, 2026-11-07)
- A thrown Dirty Sock landing in the bin counts as binned. (Q1087, 2026-11-06) (Dirty Socks are switched off, see 1.10.)
- A held Sock turns (R) from its top-most point, not its middle: "Now it seems like it kinda squishes it". Hide control hints that do not apply to the held item (Turn when it cannot turn). Zoom (G) on a held Sock or Pair brings it close to the camera so its Design reads (Q1868). Show the size letter ("L", "M") both on hover and in the Hands. (designer, 2026-11-13; maintenance/130)
- Reversal: the clock-hand swing (Q1872: R swings a held Sock around its cuff in the view plane, face-on) "was worse: back to the earlier turn about the long axis, pivoting at the cuff (designer, 2026-11-13: 'The previous rotation was better')". The lead reverted commit 0e39534b, `turn_drag` back to 3.0. Q1872 no longer holds.
- Zoom placeholders `zoom_pos` [0, -0.02, -0.4], `zoom_scale` 1.6, `zoom_info_offset` in `data/tuning/held.json`. Without Sock Smarts the held Sock shows only the boxed Size letter; with it the full readout.
- Crouch of the bin, vacuum and cat before maintenance/47: `hold.<kind>.crouch` 0 (superseded by Q1104).

**Open**
- [later] Should a held Pair swing like the Sock; should the lantern and the book Zoom? (maintenance/130)
- [later] Joining player mid-drag is not told of the drag; a player joining while a Gift box, Radio or Cat spins in the drum finds it lying by the door. (maintenance/49)
- [later] A held vacuum nozzle follows its HoldPoint as drawn (visible only on high-refresh). (maintenance/38)

## 1.4 Controls: Input Map, keyboard, mouse and controller

**Rules that bind**
- Every key the game reads is a named InputMap action; since 2026-11-11 all 39 actions live in project.godot `[input]`, mouse buttons and wheel included; `controls.gd` shrinks to helpers. (Q1717, Q1718 designer's own project.godot edits committed first as ba544717, Q1719; supersedes maintenance/56's code-registered actions). A rebinding screen stays later, in maintenance/107. (Q1720)
- Controller support: first version plays the whole game on a pad, every menu included, focus never lost, own pad glyphs in every prompt (Q1550; designer, 2026-11-10 "a basic feature on main, not polished").
- One player per PC for now; same-PC second player (split screen) is a later feature. (Q1549)
- Final pad mapping (replaces Q1551): A picks up (A is the left mouse in full, Q1570), B drops (hold charges a Throw, Q1569), RT sprints and LT crouches, both held (Q1571), X jumps and Y interacts (Q1568), Turn moves to L3; the rest of the sketch (left stick move, right stick look, LB/RB cycle Hands, Start session menu, Select whiteboard, stick click pings) is taken as unchanged but Q1568-Q1571 do not restate it: unchecked. Start skips a cutscene; X only jumps. (Q1578)
- No toggles for crouch/sprint/zoom; pads use holds like the keyboard. (Q1552)
- Look feel: small deadzone, a response curve, a short speed-up at full tilt, a separate pad sensitivity slider, shared invert Y; zoom slows the stick like the mouse. (Q1553)
- No aim assist at first. (Q1554)
- Name and IP entry stay keyboard-only; later most likely Steam's text overlay. (Q1555, Q1576)
- Rumble with an Options toggle: on knocked down and dragged, Throw release, a Pair fusing, a completed Drawer or Collection. (Q1556)
- Pad icons are drawn in our own cream keycap style. (Q1557)
- Steam later, not now; plain Godot pad support; Steam Input a later ticket. (Q1558)
- The throwaway prototype covers play (move, look, pick, drop, throw, Hands) and one menu (the title) on the pad (Q1559).
- A pad-focused button stands up like the Upgrade menu's (lift, grow, glow) instead of the ink ring. (designer, 2026-11-10, prototype feedback)
- On a pad, left/right on an Options choice row changes the value directly, like a slider. (Q1577) The Upgrade tooltip card stays where it is. (Q1579)
- The pad drives only the focused window; keyboard or mouse drops the pad focus. (maintenance/106 hot-fix)
- The Wardrobe shows no focus without a controller: "Without a controller, the Wardrobe's UI shouldn't be focused (designer, 2026-11-12)"; its focus stops are the arrows and colours only (maintenance/123, 129).
- `ui_accept` keeps Enter, Kp Enter, Space plus pad A; `ui_cancel` is Escape only; B is `pad_back` in menus (Q1552).
- Two controls bugs (maintenance/120): clicks do nothing else (Q718 "that click does nothing else"); B also drops on release, X jumps.

**Open**
- [later] Rebinding screen must treat Space (jump / skip_cutscene), B (`pad_secondary` / `pad_back`), A, Start as one conflict group each; mouse and pad are separate actions for one verb; Wardrobe A/D logical vs walk physical on non-QWERTY; mouse side buttons no longer re-capture the mouse; Ctrl chords match `move_*`. (maintenance/115)
- [later] First pad focus: first colour swatch or first row's `>` arrow? Same no-focus-without-controller rule for every menu and the Lobby? (maintenance/129)
- maintenance/107 (polish the controls, needs-info): "Parked until the designer lists what to polish." (Q1962, 2026-11-18)

## 1.5 UI look (Theme, text, back buttons, Licence screen, save notices)

**Rules that bind**
- The UI stays built in code with one shared Theme resource, looking identical to before. (Q1192, 2026-11-07) "Merge the one ui theme." (designer, 2026-11-08). Reversed for the new project: screens become scenes on one Theme (Q2163).
- Look pass (Q1487 finish code, then look pass; Q1492 fixes proposed as mock shots, applied only after the designer picks): headings 44 px (Q1495); headings white with the dark outline, one style, two Theme variations H1 and H2 (H2 smaller) (Q1496); arrows orange everywhere, cream only for keycap hints (Q1498); panel padding 30 px (Q1499); body text 24 px, buttons stay 28 px (Q1500); the Coop firewall note is ink with no outline, every Options row 50 px apart (Q1501). (2026-11-10; maintenance/79)
- Back buttons: white text with a black outline: "the back buttons (esc, back from options) should have white text + black outline" (designer, 2026-11-10, after playing the batch build). Replaces Q1497 (ink text with darker orange on hover). (maintenance/89)
- Menus share two text sizes (28 and 24) in one place; same-value colour pairs become one name; the ~35 look timings stay in code (Q1736).
- Licence screen: a link to the Godot Engine licence and a link to Blender only; the full text ships as a file beside the exe (Q1520). Correction: the screen keeps the credits (CC0 and every other licence from credits.json); only the long Godot and Blender texts become links. (designer, 2026-11-10)
- Save safety wording: when the newest save cannot be read and the `.bak` can, load it and say "Loaded your previous save" (Q1188). When neither reads: tell the player, keep the unreadable file as `save.corrupt.json`, start a new game (Q1189); the notice is "Your laundry got lost in the wash. Starting fresh." and the file name only in the log (Q1502); both notices show once on the title's home page (Q1503). (2026-11-07/10; maintenance/65)
- Kinds with no open/close sound get the nearest existing sound (doors: the door sound; lids and crates: the drawer pool; car doors: a door sound); the designer reviews them in the batch build. (Q1491, 2026-11-10; maintenance/42)
- Jump tap shorter than one physics tick stays unbuffered. (Q1506) Ragdoll feel kept, only the dead Jolt `softness` setting removed. (Q1507)
- Keep the tick order Main before the Rigs, pinned by priorities and a test; no change in play. (Q1191, maintenance/63)

## 1.6 Debug menu, zoo, Profily, benches (play-adjacent debug rules)

**Rules that bind**
- F1 opens an in-game debug menu during a Run, debug builds only, Host only; F3 and F9 stay. It holds: debug Sock X-ray with "unstick", highlight the Cat, teleport to the Cat, unstick me (back onto the nearest walkable floor). (Q1931, Q1933, Q1934, 2026-11-18; maintenance/132) Wording is a placeholder.
- The zoo (debug builds, the F9 gate, a sandbox that never loads or writes a save): "Zoo - OK" to a separate showroom, "Free" as 100k Coins and max Upgrades, the Tab/F-key panel, F3 overlay over the Coin counter, rain/heap spawning and unguarded over-shelving. (maintenance/07, Q397). The panel key became F1 (maintenance/31).
- Zoo panel layout: tabs, 990 px, a tab rail on the left (Layout B, Q1242); no quick bar (Q1243); "Pick a draw" left out (progression/62 decides) (Q1244); clean up everything, rename unclear labels, drop ticket ids from headings, show on/off on toggles, Mark found / Reset touch the zoo's throwaway Profile only (Q1245). (2026-11-08; maintenance/74)
- Zoo polish 2026-11-19: "improve the ZOO UI and add what's missing ... There are currently a lot of buttons that are unnecessary, I want the zoo to be focused on the features." Keep tabs and trim; a batch of alike actions is one drop-down plus one button, no button per Upgrade (Q2050); dormant and one-off scenes leave the main view; Progress is its own section (Q2052); what is cut goes under one collapsed "More" (Q2053); proposed tabs "Yes, build this" (Q2054); Go to: "Nothing, go to the vacuum test-bench that we have in progress" (Q2055); built panel "Merge it" (Q2062); "More" stays a normal last tab (Q2063). (maintenance/145)
- Profily replaces our frame overlay; Profily is committed after a security review; release builds configure it all-off and free it (designer, 2026-11-12; Q1800). The release-filter advice was dropped (Q1809 reverses Q1805).
- Multiplayer zoo: both a multiplayer zoo and (zoo only) the panel in co-op (Q1729); everyone in the session can use the F1 panel (Q1730); never usable in a real World (Q1731); debug builds only (Q1732); panel applies to the multiplayer zoo only (Q1733); start right after the Lobby lands (Q1740). Parked: "the F1 debug menu (maintenance/132) covers the quick needs; this waits until the designer wants it." (Q1961, 2026-11-18; maintenance/119, 114)
- Zoo playground (parked, same Q1961): playground in the same zoo world off to the side, spawn there by default, a panel button or ground teleport pad to the house, one shared Main (Q1713); labelled stalls in a walk-through loop (Q1714); standing mannequin rigs each wearing a Trail or effect set, walking in place, plus the panel (Q1715); greybox grid floor with metre marks, plain sky, simple daylight (Q1716).
- Debug code leaves release exports: ready-for-agent (Q1747, maintenance/118); export_presets.cfg changes only with the designer's OK.
- Code map: a zoomable treemap, size = code lines; toggle "by purpose" / "by folder"; at a function: name, lines, category, why classed, file:line, no source; a "Code map" tab on the review page built by a script in `tools/`; search box and churn overlay (last 400 commits); functions under 6 lines collapse. (Q1707-Q1712, 2026-11-11; maintenance/113)
- Bench: ships a double-click `bench_lowend.cmd` with the next export (Q1978); the bench records the machine's details itself; Low and Medium only on purpose (Q1979); 720p/540p runs must take their own window size (`--bench-window`, maintenance/136, status stale: merged 20f3cd95).

**Open**
- [blocking] (maintenance/114, needs-info) Which stalls come first; washer stall; cat stall; do mannequins walk; how many mannequins. [later] house copy keeps everything; hour pinned at noon; playground-only start; what "effects" covers; where the playground sits.
- [blocking] (maintenance/74) check renamed labels in the review build.
- [later] zoo: collapsible state and last tab kept; Encyclopedia book and Upgrade trees' controls arrive with progression tickets; "Carry it" / "Carry one" actions; graybox tests' "in the zoo" cases.

## 1.7 Code-shape and engineering rules the designer decided (bind the code, not play)
These are decided and would bind a rebuild only if the same patterns are used; kept short.
- Feature folders under `game/` (Q1521); a static layers test: views depend on rules, never back (Q1524); `tests/` flat, giant suites split by feature (Q1525); warn above 1,000 lines (Q1526); no hook; code folder `game/` (Q1527); folder move after batches A and B in a quiet window (Q1522).
- Net code: a Command kind is declared in its feature's file (Q1528); events stay Dictionaries with declared fields plus a round-trip test (Q1529); one RPC node keeps every `@rpc` (Q1530); `game/net/` transport only, pings to `game/ui/` (Q1531); keep our own 20 Hz pose streams, no MultiplayerSynchronizer (Q1532); folded into batches A-E (Q1533).
- Refactor decisions (2026-11-05): delete the Mess, SockWorld is the one record (Q927); floor Pairs and gift boxes SockWorld items (Q928); the Flight reports contacts, Game's rules decide shelve / Hand-off / knockdown (Q929); the Hands hold anything a player carries (Q930); rules tests on a bare-floor SockWorld (Q931); drops go through the Flight (Q932); one Command seam with Host and Guest adapters (Q933); GLOSSARY: Mess stays a player word with no code module (Q935). Keep all 69 shot actions (Q925).
- Data: the four loaders (Tuning, FlatLayout, SockCatalogue, CabinetPools) read once; shared read-only copy, private copies for code that changes values; no extra guard rule (Q1700-Q1703); edit both in the Inspector and as text (Q1705); files the Blender builders read stay JSON (Q1706). Typed Resources are ideal after a proposal of how to split them (Q1701, Q1704); split not chosen (Q1721); maintenance/116 wontfix, folded into maintenance/131 (Q1956).
- ~25 play-feel numbers (player gravity 20, jump 5.5, reach 2.5, throw and Pair drag, Mess friction) go to data/tuning (Q1735); "merge whatever the analysis marks as a real duplicate, but not the maybes" (designer, 2026-11-11; maintenance/117).
- Tuning in one file per section (maintenance/92); manifest split per asset with union merge (Q993).
- Save: no save compatibility until the first outside play-test (Q1795).
- Tick order and view clocks follow the game's time (Q1191).
- Use native Godot where possible: "Try to use native stuff if possible." (designer, 2026-11-07; Q1170, Q1172 picked 53-56; JSON data parse sites deferred by the designer)
- Open all eleven maintainability follow-ups (Q1523).

## 1.8 The move to native Godot, Q2143-Q2178 (maintenance/131), one line each
Q2143 fresh project, not a rebuild; core loop first, whole architecture planned first, new test suite, tools reused, a new clean skill set, "Every line of code has to fight for it's life".
Q2144 switched-off features: "We will start from fresh project." (nothing deleted from today's game).
Q2145 "Core loop first ported."
Q2146 designer asked "What's the best for godot authoring co-op stuff?" for where state lives.
Q2147 state lives on the scene part (shape B), written only by the Host's Command answers; ADR-0006 amended for the new project.
Q2148 today's game: finish the vacuum device set (tools/24-30), then freeze, bug fixes only, as the playable baseline.
Q2149 new repository; port all props and assets first, then plug together.
Q2150 one planning artifact, cleaned up, plus a step-tracking page.
Q2151 a ported prop is "1 + models": cleaned model plus a behaviour-free scene.
Q2152 Blender scripts stay and build meshes only; placement, collision, Sock spots and settings move to Godot scenes.
Q2153 "improve" while porting is technical only, looks unchanged, proved by before/after strip.
Q2154 house hand-built from a modular kit; first milestone is the house from kit and props with no functionality.
Q2155 "1. In future 3.": today's rooms rebuilt from the kit; a new house design later.
Q2156 kit pieces are snapping scenes, not GridMap.
Q2157 milestone 1: editable, Play walks through with a throwaway walker.
Q2158 "I will create it and add to sandbox." (the designer creates the new repository).
Q2159 agents write, the designer approves each piece (design and grilling before, walkthrough after, merge on OK).
Q2160 co-op from the first game code: a Host, a Guest and a late joiner in the first slice's tests.
Q2161 first playable core loop: Mess, Hands and Throws, Pairs and Cabinets with Doors and Drawers; not Stages, Laundry day, menus, saves, lobby.
Q2162 asset order: everything (models, sounds, UI art) ported before any scene work.
Q2163 screens are scenes on one Theme (reverses Q1192 for the new project).
Q2164 numbers: typed Resources per feature; a placed prop's number is a field on that prop.
Q2165 designer approves a plain-words behaviour list before a feature is ported; tests from it; a test changes only with the designer's OK.
Q2166 carried over: assets, tools, glossary, short skills/brief/CLAUDE.md; not carried: ADRs and the ticket vault (fresh tracker pointing to the old).
Q2167 "Game and assets apart": `game/`, `assets/`, `data/`.
Q2168 the Mess's two-tier design stays, code rewritten clean, bench proves no slower.
Q2169 walkthrough page per piece on the artifact; approving is answering the dialog.
Q2170 step-tracking page: milestones with pieces, states planned / design agreed / built / approved.
Q2175 house on a half-metre grid, walls 0.5, 1, 2 m, rooms nudged up to 25 cm, not an exact copy.
Q2176 Sock spots: a bake button on the furniture piece, saved with the scene, editable dots.
Q2177 one shared material library; designer picks the surviving variant from a strip (oak: 9 variants in 39 models).
Q2178 things built by code today (Drum interior and water, Guide cards, gift boxes, padlock sign, dust sheet, Sock detector screen) become models or scenes.
Q2179 the 237 commits on main not on GitHub: "I will push." (the designer pushes, the lead does not).
Q2180 today's game goes into the new repository as a plain clone in an ignored folder `reference/it-socks/`.
Q2181 the new repository lives on the mounted drive next to it-socks; every merge is pushed; the git check and repair tools come along.
(Q2171-Q2174 device model picks are recorded in the asset inventory, not in this ticket; not seen here.)
Session scope (designer, 2026-11-19): "Let's not start doing any migration work - only preparations right now." Wanted first: "Definitely 1, then 3. Ideally before building everything, we could get a glimpse at some vertical slices for the hand-authoring." Also: "Also consider planned features in this project into the planning for the nativization, so something isn't left over."

**Open (maintenance/131)**: [blocking] do scenes replace the JSON or write JSON on save; tuning: all 62 sections typed .tres / only often-tuned / generic TuningSection / leave JSON; do the Blender generators keep running for house shell, furniture, avatar (meshes only); one house scene or one per floor. [later] avatar crouch: offsets or animation; cutscenes as AnimationPlayer; sound picker Resources or sounds.json; delete the Grotto before the move; `tr()` while screens move; SoftBody3D for held Socks under Jolt. Also from maintenance/150: 15 designer questions S1-S15, S1 (where a Door's "is it open" lives) the big one. maintenance/116 T1-T6 [blocking] (split, `_note` text 54 KB, colours, class defaults, Inspector ranges, players.json and gifts.json) are folded into 131.

## 1.9 Switched off / dropped / parked
- Hampers, the Grotto (lantern, ladder), Dirty Socks, the pairing machine (off since 2026-11-19): maintenance tickets that touch them (38 held lantern, 49 lantern leave, 46 Dirty Sock bin, 29g pairing machine carried, 145 "Carry one (Hamper, none stands while Hampers are off)") bind only while those features exist. Not otherwise digested here.
- wontfix: maintenance/27 ("Buffer argument is not a valid buffer" during picks; "Closed; reopen if the error is seen again in play." Q1960, 2026-11-18); maintenance/116 (folded into 131); progression/30 (superseded by progression/37, no door hold, Q1008, noted in maintenance/34).
- Parked 2026-11-18: occlusion culling (Q1955), controller polish (Q1962), zoo playground and multiplayer zoo (Q1961).
- Draping of Socks (Q335): later. Aim assist (Q1554): none at first. Steam / Steam Input (Q1558): later. Same-PC second player (Q1549): later. JSON typed move: deferred (maintenance/52).
- Our own frame overlay (FrameOverlay, maintenance/04, Q355) removed for Profily (maintenance/124).
- Q485 upgrade questions deferred to the upgrades batch; Q479 Steam and voice deferred; Q478 sound picks to a second sound hunt; Q477 placeholder numbers to a balance and feel round (maintenance/14).

# PART 2. How we work (decisions and corrections about process)

Format: one line, then source and date. "General:" names the lesson for moving another project the same way. Items from memory files and docs/agents are marked.

## 2.1 How questions are asked (grilling)
- Every designer question goes through the AskUserQuestion dialog, recommended option first, even in a grilling round; never numbered chat text. Why: "Grill me with the ask me a question please..." (2026-11-18) and "Why again you are not using the Ask me a question feature?" (2026-11-19); a rejected or interrupted dialog is not a request to switch format; more than 4 questions split over several dialogs. [mem:grill-with-ask-dialog] General: pick one ask channel at the start and never fall back.
- The designer decides every choice of play, look, wording, sound or cost; agents "build, verify and ask"; ticket agents cannot ask, so they list `## Open follow-ups` tagged `[blocking]` or `[later]` and never decide. [agents/agent-brief.md; Q825, 2026-11-04] Only the lead asks the designer; ticket agents write follow-ups. (Q1811, 2026-11-12) General: one asking voice; blocking vs later tag.
- Placeholder numbers go in data (`data/tuning/<section>.json`), never invented as decided; they are parked for a "balance and feel round". (Q477, Q485, 2026-10-31; agent-brief.md) General: label every number decided or placeholder from day one.
- "Grill me on any conflicting information." (designer, 2026-11-04, maintenance/28): conflicts found in an audit are asked, not resolved by the agent.
- Q numbers are one global sequence: next is the highest Q in tickets or git log plus one (Q900, 2026-11-04). In the starter kit they start at Q1 per project (Q1790). One answer section `## Answers`, each item ending `(Qnnn, YYYY-MM-DD)` (Q902). General: a global answer id makes digest, reversal tracking and citations cheap.
- Pre-flight: before a build agent starts on a feature with a play or look choice, a cheap read-only agent lists the design questions and impossibilities, the lead asks in one dialog, then the build starts. Picked by the designer ("1. 2." from the lead's list of workflow optimisations), 2026-11-19. Why: the sorting vacuum agent (tools/19) finished and only then reported four blocking questions. [mem:preflight-and-foundation-owner; maintenance/146] General: ask before building, not after.
- Proposal before code for anything structural: the designer asked "Maybe time to move this to resources?" and wanted "a proposal of how to split the tuning, to decide" (Q1701, Q1704, 2026-11-11); the net layout was researched and proposed before any refactor: "Before any of this maintenance starts: research how to structure net code well, inspired by existing projects with a good structure, and propose the net-code layout first" (designer, 2026-11-10).
- Look changes are shown as mock shots and applied only after the designer picks: "Nothing visible changes until the designer picks" (Q1492, 2026-11-10); the zoo layout was chosen from mock stills (Q1242, 2026-11-08). General: mocks before pixels.
- On hold means do not ask: "Don't ask the follow-ups below until then." (maintenance/131, 2026-11-18) until the designer calls a grilling session.
- Authorship in the new project: "Before a piece: its design (classes, fields, a code sketch) and a grilling. After: a plain walkthrough of the real code; it merges only on the designer's OK." (Q2159, 2026-11-19); walkthrough page per piece, approving is answering the dialog (Q2169).
- Triage priority: `priority: next` / `later` frontmatter; agents pick `next` first (Q1580-Q1583, 2026-11-11). [agents/issue-tracker.md]
- Questions waiting too long: parked tickets stay parked with a Q (Q1955, Q1961, Q1962, Q1963 on 2026-11-18); "Keep waiting" is a valid answer.

## 2.2 Review material and review builds
- Agents never export a review build on their own; the lead first asks the designer whether the scope merits one: "Could we stop with the extensive builds? Ask me whether the scope is enough for a build." (2026-11-08). Without a yes, a still or short strip is enough. Exports are slow and fill the disk. [mem:ask-before-review-build; agents/git.md] General: builds are costly; default to stills.
- Significant changes get a review first (engine or system swaps; feel or look changes: motion, camera, UI look, new art, sound) before merging. (Q898, Q906, 2026-11-04)
- Everything shown for one feature goes in one folder `builds/review-<name>/` in the main checkout: "it should go to the builds/NAME/ folder. Not scattered across places." (2026-11-08) Preview line-ups for modelling live next to the asset's art doc (designer, 2026-11-04). [mem:review-material-one-folder; CLAUDE.md] (the later rule governs features; art-doc line-ups stay for assets)
- Motion shows motion: animation, camera, effects tickets report a frame strip or short clip, not only stills. (Q825, 2026-11-04)
- Shot size stays 1920x1080 (Q473); crop first, `--size` optional (Q901) (token cost).
- Review builds after PASS; integrate exports a build on every merge (Q1803, 2026-11-12). Held look work may get a review build from its branch before merging (Q1812). Keep the old review builds in builds/ (Windows drive, not sandbox disk) (Q1813, 2026-11-13).
- A review build can win the designer over: "Review build looks and times the same: merge." (maintenance/54, 2026-11-07); "Fade looks good." (2026-11-08); "Merge the one ui theme." (2026-11-08); "Merge it" (Q2062).
- The designer plays the batch build and corrects it: back buttons white (maintenance/89, 2026-11-10), clock-hand turn rejected (maintenance/130, 2026-11-13), aim-rate review builds (maintenance/110, still unplayed on 2026-11-18, Q1963). General: the first real play of a batch is the cheapest place to find look regressions; schedule it.
- Before/after: `tools/png_strip.py` and shot sets with a before/after from an older commit (Q2045; "Could we make the create_png_strip a reusable tool?" 2026-11-19, maintenance/140). Skill `review-material` added (Q2057).
- Designer-facing pages are artifact pages (visual outline of the refactor waves, architecture review, the plan page): "Keep those" (Q923, 2026-11-05). General: a visual outline gets a faster yes than prose.
- Commands for the designer to run on the host go in a double-click `.cmd` file, not copied text (they cannot copy from the sandbox terminal). [mem:agents-safe-commands-only] (e.g. `bench_lowend.cmd`, Q1978)

## 2.3 What tests are for
- Designer, 2026-11-19: "tests should run with given scenes in future, for rules, but not necessarily for strict layouts. Basically important stuff is that - cat works, pairing works, aiming works, socks don't get lost, it's possible to add things to cabinets, interact with things. Not that something is exactly at place A or B. The player core loop should be the thing that's tested most extensively." Correction: "They can pin layout, but it shouldn't be the THING that's important." (maintenance/150) [mem:tests-assert-behaviour-not-layout] General: tests protect behaviour and invariants; pins are a tool; effort goes to the core loop.
- "The buttons shouldn't be action for the tests, the systems itself in the game should be. zoo shouldn't be tested, it should use the game features." (Q2056, 2026-11-19) General: no debug UI as a test handle.
- New project: a plain-words behaviour list approved by the designer before a feature is ported; tests written from it; a test changes later only with the designer's OK (Q2165); co-op from the first slice with Host, Guest and late joiner (Q2160).
- Run only the suites your change touches before your branch commit (Q899); agents never run the full suite; the lead's integrate run does (Q992); docs-only commits to main skip the suite (Q826). [agents/git.md, agent-brief.md] General: targeted tests per branch, one full run at merge.
- Tests first when refactoring shared code: a safety net suite (`carried`, 16 cases) before maintenance/39 and 40 (Q1150, 2026-11-07); it found a real bug (a save let a guest keep a vacuum nozzle).
- Wait on state, not on frame counts (maintenance/22, 57 step 3, 62: 123 long waits). Q1488 (remove stale 0.5 s grab-cooldown waits, the game has no cooldown) was corrected by Q1504 (the interval exists in `Rig.click`; tests wait on `Rig.can_grab()`). Rule in maintenance/126: fix flakes by type (frame wait: `_until`; wall time: `_budget`; order dependence: scrub); "never raise a budget".
- A failure that passes on its rerun alone counts as a pass, printed FLAKY and kept in a ledger (Q1185, 2026-11-07); single-process runs do the same (Q1806).
- A SCRIPT ERROR inside a case fails the case (maintenance/105; before it the verdict said PASS with script errors); "no verdict printed" is a failure. [CLAUDE.md]
- Test only what changed: `tools/run.py --changed` runs suites reachable from the diff (Q1184); the full suite stays at integration. `--only=<word>` matches a suite exactly, `suite:case` one case, substring needs `--grep=` (Q1807).
- Large stress tests (5,000/10,000-Sock rains) are on demand, out of the default full suite, with something small and representative kept (Q1474, 2026-11-10).
- Agents warn when the suite takes over 2 minutes, suggest and open tickets to speed it up, and raise it to the human (Q1794, 2026-11-12).
- Net tests run rule cases over a Game-level loopback and keep a few real ENet cases (Q924); rules tests run on a bare-floor SockWorld (Q931). For removed zoo tests "the full suite at merge is enough" (Q2064).
- Do not pin timing in wall-clock budgets inside correctness suites; perf lane separate (maintenance/57).
- Tests need isolation: static knobs reset between cases (maintenance/61), each class declares its own test knobs (maintenance/93), a finished Game must be freed (`freed` suite, maintenance/59).
- Godot's own doctest unit testing and GdUnit4/GUT considered, not adopted: tests/suite.gd already does what they do (maintenance/57, designer asked 2026-11-07).
- Save compatibility is not tested or kept until the first outside play-test (Q1795).

## 2.4 How agents are run and limited
- Model choice: Opus for Blender/modelling [mem:blender-work-uses-opus; designer 2026-10-28], for the refactor audit and slices (Q922, 2026-11-05) and hard netcode/debugging/big refactors; otherwise Sonnet: "What can run as sonnet should run as sonnet." (designer, 2026-11-07) [mem:prefer-sonnet-agents]. Mechanical refactor slices run on Sonnet (2026-11-05). Every spawn names its model. General: default cheap, escalate with a reason.
- Up to 5 agents in parallel (Q828); physics tickets first (Q827; the exact meaning "queue order" is an open [later] in maintenance/28); up to four other agents share the machine. [agent-brief]
- No Workflow tool: "Let's not use workflows further more, spawn subagents, workflows are token heavy." (designer, 2026-10-29) [mem:no-workflows]
- Resuming a finished agent re-sends its whole transcript (300-450k tokens); resume only for small follow-ups, spawn a fresh agent with a tight brief for regressions and new scope. Designer asked "did the agent now start with 400k tokens used?" (2026-11-05). [mem:resume-vs-fresh-agent]
- "Stop the subagents" must stop their helpers too; TaskStop does not; check ListAgents afterwards (2026-10-31). [mem:stop-agents-check-children]
- Safe commands only: the designer kept getting approval prompts for odd commands (pkill, git plumbing) and said "make it safe!" (2026-11-18, maintenance/137): agents run plain commands in their own worktree and the scratchpad; no kill/pkill, no `rm -rf` outside own temp files, no git plumbing, no sudo, no curl/wget, no edits under ~/.claude, /etc or the main checkout (except copying review stills). Rules live in `docs/agents/agent-brief.md` (Q1994); written rules, except destructive git which `.claude/settings.json` denies (Q1995); `rm -rf` and network commands ask each time (Q2000); the test runner stops its own leftover processes, nobody else kills (Q1998); `integrate.sh` honest exit code, `tools/*.sh` executable (Q1999). A Defender exclusion and moving agents off the shared drive are parked (Q2001). [mem:agents-safe-commands-only]
- Git glitch (Windows-mounted .git: "invalid object", "unable to read tree"): agents retry once and stop and report; only the lead repairs it (`tools/git_repair.sh`) and tells the designer in one line (Q1996); integrate and every agent check that commits read back (Q1997).
- Agent scripts: `tools/agent_start.sh` and `agent_finish.sh`, a suite runner (Q2043, Q2044, 2026-11-19); ticket tool skipped (Q2042); agent cost report `tools/agent_cost.py` shown on the ticket board (Q2048); house layout queries `tools/layout.py` (Q2047); tuning tool skipped until the tuning decision (Q2046). Why: agents kept rewriting one-off scripts: about 30 suite loops, 14 transcript readers, 39 layout digging scripts, create_png_strip (maintenance/140). The lead's count: agents' scratch folders of 26 sessions held 676 one-off Python and 120 shell scripts (test patching 111, tuning JSON 55, ticket edits 48, layout queries 39, image strips 33, shot runs 29). General: count one-off scripts per round and turn the top ones into tools.
- One owner for a fresh shared piece: three agents (tools/19-21) each extended the graybox kit in parallel and a fourth Opus agent reconciled them; rule: the foundation agent first collects each consumer's needs; later changes go through one owner, else one larger ticket (designer picked "1. 2.", 2026-11-19). [mem:preflight-and-foundation-owner; issue-tracker.md]
- One agent at a time on each part of the house (shell/layout, Elevator, exterior, each furniture piece); different parts in parallel. [CLAUDE.md] One MCP agent per server (maintenance/28).
- Blender agents iterate with Workbench half-res previews and per-piece rebuilds; EEVEE only for the final preview set (no GPU; each loop took minutes). (Q108, 2026-10-28) [mem:blender-cheap-previews]
- Agents delete only files they made; never delete another agent's /tmp files; remove own temp clones (disk about 4 GB free). [agent-brief]
- Every new declaration typed (maintenance/64); every new script has a tracked `.uid`; `project.godot` stays unchanged in agent commits. [agent-brief]
- Transcript volume: `~/.claude/projects` is a separate 2 GB volume; one long session's subagent transcripts (715 files, 1.6 GB) filled it (2026-11-08) and memory writes failed; with the designer's OK (Q1269) delete finished subagents' transcripts, check `df` between rounds. [mem:transcript-volume-2gb]
- Lead's duties: skip pre-flight for tooling, docs and bug tickets (lead's reading, not scoped by the designer). [mem:preflight-and-foundation-owner]

## 2.5 Merging and git
- The lead merges, with `tools/integrate.sh`; ticket agents never merge (Q898). integrate runs in its own worktree (`.claude/worktrees/integrate-<time>`), never in the main checkout (designer, 2026-11-10), runs the full suite there and fast-forwards main only on PASS: main always gets a green suite. Ends with one `RESULT` line, "read that line, never grep the log" (Q2049). Exit 0 once main moved. [agents/git.md]
- Batch merges: wait until parallel agents finish, merge them in one integrate run and export one build; agents test their areas only; the final merge runs the full suite (designer, 2026-11-09). Why: per-branch full-suite integrates took 10+ minutes each and failed on load-sensitive cases. [mem:batch-merges-targeted-tests]
- Never merge a branch whose ticket waits on a designer pick (review builds, `[blocking]` question, ready-for-human), even with a "no behaviour change" default. Designer, 2026-11-11, after the aim-rate branch was started merging: "Do not merge the aim-rate! I didn't approve this." [mem:no-merge-before-review-pick, no-merge-before-designer-pick] Held = ready-for-human or needs-info; neither merges until the designer's go (Q1810).
- Main is the point of truth for docs: "Main should be the point of truth", "this should be up to date, not scattered all over" (2026-11-12): answers and follow-ups stranded on unmerged branches (dungeon/01, /03, aim-rate 110, progression/71, proto/73, /77, /103) are copied to main as docs commits right away; `housekeeping.sh` lists stranded docs (only for held or 2+ day old branches with no running agent, Q1808). [mem:main-is-source-of-truth]
- Before a merge fast-forwards main in the main checkout, check the designer's uncommitted files the merge touches, above all `data/sounds.json` (sound bench picks written straight to the file); on 2026-11-13 the progression/87 merge rewrote it and the picks were lost with no copy. Never run `git read-tree HEAD` without checking unstaged designer edits. [mem:check-designer-edits-before-merge]
- Never `git commit -a` in the main checkout: on 2026-11-06 it swept the designer's uncommitted project.godot, export_presets.cfg and .import edits into a post-merge fix; caught and undone with `git reset --soft`. Add exact paths. [mem:no-commit-a-in-main-checkout]
- The designer's working copy: never stash, reset or checkout files; `project.godot` and `export_presets.cfg` carry uncommitted edits (CLAUDE.md). The editor's `.import`/`.uid` churn is the lead's, committed as `chore:` with the suite (Q904). Exception 2026-11-11: the designer's project.godot edits were committed (ba544717) so the Input Map could land (Q1718), and the designer's identical Profily copy replaced so main can fast-forward (Q1800).
- `integrate.sh --continue` keeps a two-file state (branch list, worktree) instead of matching the exact "Merge <branch>" subject; a commit to main mid-run broke the final fast-forward once (2026-11-11); mark merged tickets done (111/113/115/117 were left stale). Known timing flakes: `vacuum:hose_cost`, `hamper:pour_budget`, `net_devices:ride`. [mem:integrate-continue-quirks; maintenance/126]
- `Merged: <hash>` is written by integrate in one docs commit per batch; agents make no second "Record the commit" commit (Q1787, maintenance/126). "Never squash." Commits on ticket branches stay. [agents/git.md]
- Binaries go through Git LFS since 2026-11-10 (8fc33c05, designer's request; house.glb, voice wavs and hdr skies bloated the repo to 789 MB); a branch cut before it that changes a binary conflicts: re-add on main. [mem:git-lfs-binaries]
- Tags: `playtest-<version>` on every playtest build; `checkpoint/<feature>-<NN>-<what>` before risky work (e.g. `checkpoint/maintenance-88-start`). [agents/git.md]
- The folder move runs in a quiet window with no other branch open, after batches A and B (Q1522); a branch that edits integrate.sh runs it from a copy.
- Fix-now tickets after the kit audit: flakes + integrate --continue (126), housekeeping + stranded docs (127), doc drift + follow-up sweep (128) (Q1799, 2026-11-12).
- Worktrees start from current main (`agent_start.sh`); integrate warns when a merge base is more than 20 commits behind.

## 2.6 Costs, token budget, machine limits
- Tokens: no Workflow tool; fresh agents over resumed ones; quiet tools (`tail -3`, log to a file, grep the summary); crop first; never poll or sleep; touched suites only; shots only as proof; tight briefs. [skill token-budget summary in maintenance/28; designer-watched]
- Memory: the designer saw about 15 GB host memory used during test runs: "Fixed with priority, right after the current batch of branches merges." (2026-11-09, maintenance/77); each World bake holds about 1.1 GB; the runner had planned 0.5 GB a process, real 1.8 GB (4.5 GB for `mess`); Q1474 lowered Jolt limits, Q1475 pool back to 8 processes.
- Disk: test mirrors were 2.2 GB per run directory (maintenance/57); `docs/` was imported by Godot until `.gdignore` (235 png.import removed, maintenance/60); scripts delete their own /tmp copy on exit (maintenance/26); keep old review builds on the Windows drive (Q1813).
- Time: suite about 875 s of process time over 52 suites; `net` alone 267 s; parallel processes (GAME_TEST_JOBS); Q433 retro "Maybe try to improve the speed of doing stuff - external tools / commands, ..., working with godot." (2026-10-31).
- Review builds are slow and fill the disk (see 2.2).
- Blender iteration is expensive (17-35+ min tickets) hence Workbench previews (Q108).

## 2.7 Docs, tickets and the vault
- Answered follow-ups move under `## Answers` in the same ticket (Q432 retro, 2026-10-31); five cleanup passes were needed anyway: maintenance/10 (172 moved, 44 superseded), 13 (52 items), 14 (72 answered, 37 to balance round, 4 to sound hunt, 14 deferred, 25 closed), 128 (459 later and 34 blocking: 3 moved, 17 dropped, 439 + 34 left open). General: close the loop in the same commit, or the vault rots.
- Workflow guide compacted into the kit's skill shape: "For the workflow guide - try to compact it, keep important information, grill me on any conflicting information." (designer, 2026-11-04). Every rule has one owner file; CLAUDE.md 118 to 49 lines; TESTING.md 296 to 182; four project skills (Q905); another review round later added `review-material` (Q2057). General: one owner per rule; others point to it.
- Update the docs after workflow improvements: "update the docs after all the improvements to the workflow are done, so future agents know how to do stuff." (designer, 2026-11-19, maintenance/146); "Maintenance 146 can start."
- Architecture index under 5 KB, subsystem files in `docs/architecture/` (maintenance/75); house questions via `tools/layout.py`, not the 167 KB layout and 1.2 MB manifest (maintenance/143).
- Ticket kinds and areas documented (Q903); `status: done` only when acceptance is fully met; `ready-for-human` for held look work with stills in `builds/review-<name>/`.
- Triage 2026-11-18 found tickets done in code but not marked (25, 57, 61; 70's cache part merged) and tickets with a stale status (136 merged but ready-for-agent).
- Not carried to the fresh project: ADRs and the ticket vault; carried: assets, tools, glossary, short skills, brief and CLAUDE.md (Q2166). The migration also needs a journal "what was tried, what it cost, what was redone" (maintenance/139).
- The ticket board is a mod showing agent cost (Q2048); kit 7 will carry it (Q2058).

## 2.8 Tools the designer found useful, dropped or skipped
Kept or built: the zoo (Q397: "a separate scene with all the mechanics ... spawning many Socks"), `tools/run.py` with `--changed`, FLAKY ledger and slot pool (Q1184, Q1185), `png_strip.py`, shot sets (Q2045), `layout.py` (Q2047), `agent_cost.py` (Q2048), `housekeeping.sh`, `integrate.sh` RESULT line (Q2049), code map (Q1707), `bench_lowend.cmd` (Q1978), Profily (2026-11-12), the F1 debug menu (Q1931), the starter kit zip (Q1785).
Dropped or skipped: Workflow tool (2026-10-29); our own frame overlay (2026-11-12); quick bar in the zoo (Q1243); ticket tool (Q2042); tuning tool until the tuning decision (Q2046); Godot MCP "not yet" (Q1788); binaries zip (Q1784); ownership git hook (Q1527); Godot doctest / GdUnit4; wireframes forced (Q1791: only when asked); Defender exclusion (parked, Q2001); the Profily release filter (Q1809 reverses Q1805); the 40 of 69 unused shot actions are kept (Q925).

## 2.9 Retros and kits
- Retros: 2026-10-31 (Q432-433), 2026-11-04 (Q825-826, five new agent rules), 2026-11-05 (merge conflict hot files, maintenance/33). Kit rule: retro suggested by the lead after about 30 merged tickets, only after the designer's yes (Q1797, Q1802).
- Starter kit 4 from the compacted guides (Q907), kit 6 after two reviewer rounds (Q1784-Q1812: fetch-only binaries; kit stays a zip; Godot only; markdown vault; Q numbers from Q1; wireframes only when asked; parallel agents and models set at setup (Q1793); Blender opt-in (Q1798); no save compatibility until the first outside play-test; multiplayer-game-dev skill upgraded (Q1796); a short game README replaces the kit's after setup (Q1801); review builds after PASS and integrate exports on every merge (Q1803)); kit 7 tracked "Not now" (Q2058, 2026-11-19: new tools, agent safety and brief, ticket board mod, graybox kit idea).
- The move becomes a retrospective plus a set of skills (not one): "The whole process should result in a retrospective + a skill sets so other project can be transferred in a similar way." (designer, 2026-11-19, maintenance/139) Contents named by the lead: survey, digest of decisions, behaviour lists, risk register and vertical slices, asset port, core first, the designer's approval steps. Open: where the skill lives; write after three pilots or draft per phase.

## 2.10 The native-move planning process (2026-11-19), as process
- Research before grilling ("Research these topics before the grilling" and "Move the older research ... into `docs/research/nativize/` too", designer, maintenance/138); four reports; code map; unification estimate: the designer pushed back on the 8-11 % saving, "I feel like the 9-10% underestimates, I would expect 30% saving of code from all these refactors - the systems seem so interleaved together. Could you estimate more? And let fable do research on what to unify?" and "Try to think of the systems from high-level what can be unified, even scrapping or rewriting large parts of the code-base." (maintenance/148, designer 2026-11-19); result: four reports with four numbers (scenes and Resources only; plus unification; plus simplification; rewrite).
- The designer asked: "for the native godot move - propose how to move, I would ideally like to write tests separately one feature moved at a time - starting from CORE features - propose a plan how to do this, analyzing what's the core. Have a graph ready. New tab." (maintenance/149) and "Let's also define a shape of the code - what classes will be there, ... what's core what's not. Each class should behave standardly and have the same interface" with readable state fields, changes only by commands or functions, standard coding standards and encapsulation, and classes as behaviour objects, components or common bases (maintenance/150, 2026-11-19); 149's wave order is superseded by Q2143 (fresh project) and its test method by the 11-19 test statement.
- Preparation only this session; migration in another session; fresh ticket board for the new repository (designer, 2026-11-19).

## 2.11 Batches, triage and ordering answers (process-only Q numbers)
- Refactor 29 (2026-11-05): Q919 audit first, then slices; Q920 it blocks every open code ticket, modelling continues; Q921 small fixes allowed, each listed, behaviour stays the same; Q922 Opus for audit and slices; Q923 waves approved after the visual outline; Q924 net tests over a loopback; Q926 explore all seven architecture candidates; Q934 plan order A, B (after physics/11), C, all before physics/12; Q947 remove the placeholder cosmetic path; Q967 all four small cleanups go ahead; Q1026 check physics/12-20, flat/13, progression/30 against the code after the refactor.
- Hold and carry refactors (2026-11-06/07): Q1091 and Q1092 run the one-hold ticket next (the lantern pickup builds on it); Q1093 do 38-43, 41 alongside 38, the rest after; Q1109 run 39, 40, 42 after the lantern and climbing work lands; Q1147 split 39 into held record and prompt record; Q1148 split 40 into tests, save and guest-quit, and landing; Q1149 42 stays as is; Q1150 order: tests (49) first, then 39 and 40, then 48, 50, 42 after house/39.
- Triage 2026-11-08: Q1258 "Triaged: build it" for the audit tickets 59-66 and 69-71 (2026-11-08). 2026-11-10 maintenance batch: Q1480 (22, 60, 62), Q1481 (42, 63, 65), Q1482 (69, 70, 71 with the UI theme work 79), Q1484 and Q1485 (78: three small bugs ticketed and built); not in the batch: 25, 27, 64, 72 (Q1480-Q1484). Q1505 ticket all proposals A-G of the Godot rules audit. Q1523 open all eleven maintainability follow-ups. Q1581, Q1582, Q1583 priority next/later (2026-11-11).
- Controller prototype scope Q1559; Q1580 priority rule.
- Kit 6: Q1786 Godot only, Q1789 markdown vault, Q1792 netcode/UI/physics review rounds as skills the agent may use, Q1804 keep `godot-game-dev/reference.md`.
- Shots: Q474 measure parallel lavapipe options and pick the fastest total throughput; Q475 warm frames default OK; Q476 sfx layers check confirmed.
- Data loaders: Q1702 shared read-only copy; Q1703 no extra guard rule; Q1708-Q1711 code map nesting, detail, tab, extras.
- Not digested here (they are references to other features' questions, owned by those folders): Q2 (a numbered open question in maintenance/21), Q182, Q269, Q295, Q308, Q317, Q318, Q320, Q332, Q334, Q356, Q357, Q437, Q438, Q441, Q508, Q519, Q716, Q773, Q779, Q785, Q788, Q793, Q816, Q817, Q823, Q834, Q961, Q1034, Q1070, Q1144, Q1187, Q1218, Q1239, Q1241, Q1272, Q1443, Q1494, Q1581, Q1609, Q1652, Q1743.

# PART 3. Things that went wrong and the rule that came out of it

| Date | What went wrong | Rule that came out (source) | General lesson |
|---|---|---|---|
| 2026-10-28..31 | Missing bed and nightstand in the house: the Props mesh had 393 surfaces, Godot keeps 256 per mesh; found only because a night shot showed floating Socks (maintenance/12) | Test `room:furniture_drawn`; every placed piece has a drawn mesh | Engine hard limits need a test; a picture review found it, not the suite |
| 2026-10-31 | 431 follow-ups stale; grilling rounds start from noise (maintenance/10, Q432) | Answered follow-ups move under `## Answers` in the same ticket; sweeps 13, 14, 128 | Close the loop in the same commit |
| 2026-11-03..10 | Flaky tests under load (zoo:spawner, net:join_picker, vacuum:hose_cost, hamper:pour_budget, net_devices:ride), reruns every time (09, 18, 22, 76, 122, 126) | Wait on state; `_until`, `_budget`; never raise a budget; FLAKY ledger (Q1185); rerun alone | Make flakes visible (ledger) and fix by type |
| 2026-11-04 | Retro: suites hand-listed, test copies left in /tmp, review stills scattered (maintenance/26, Q825, Q826) | Auto-discovered suites, trap-cleanup, five agent rules, `[blocking]`/`[later]`, motion shows motion | Retro after each phase, written into the tooling |
| 2026-11-05 | Every hero-prop merge conflicted at the end of `blender_assets.json` and the pipeline table (maintenance/33) | Manifest split per asset, union merge (Q993, designer's idea) | Append-only shared files are conflict hotspots; one file per entry |
| 2026-11-05 | game.gd 3250 lines, three `match` blocks over the same commands, held items each with own code (29, 44) | Slices 29a-j; audit 44; one hold system, Carriable, Openable, Prompt (38-50) | Define the shared seam before features pile on |
| 2026-11-05/06 | A finished Game never freed (reference cycles) feeding OOM kills (58, 59) | Weak back-references; `freed` suite; lambdas read the Game through its owner | Ownership cycles need a test |
| 2026-11-06 | `git commit -a` in the main checkout swept in the designer's project.godot, export_presets.cfg and .import edits [mem:no-commit-a-in-main-checkout] | Exact paths only; check `git show --stat HEAD` | Protect the author's working copy by rule |
| 2026-11-07 | Test processes killed by the kernel at 4.4-4.6 GB; run.sh budgeted 0.5 GB; "no verdict printed by mess" read as a bug (57, 77) | Memory-aware slot pool in `tools/run.py`; `--changed`; lowered Jolt limits (Q1474) | Budget memory per process by measurement; OOM looks like a test failure |
| 2026-11-05 | Resumed the house/35 agent for a regression: 300-450k tokens re-sent [mem:resume-vs-fresh-agent] | Fresh agent with a tight brief for regressions | Resume only for tiny follow-ups |
| 2026-10-29 | Workflow tool used for batches [mem:no-workflows] | Individual Agent subagents | Prefer the cheapest orchestration |
| 2026-10-31 | "Stop the subagents" left a code-review agent's two helpers running [mem:stop-agents-check-children] | ListAgents after stopping | Verify stop; children are separate |
| 2026-11-08 | One long session's subagent transcripts (715 files, 1.6 GB) filled a 2 GB volume; memory writes failed [mem:transcript-volume-2gb] | Check `df` on `~/.claude/projects`; delete finished subagents' transcripts with the designer's OK (Q1269) | Know every volume the agents write to |
| 2026-11-08 | Extensive review builds exported by default: slow, disk filling [mem:ask-before-review-build] | Ask before a build; stills by default | Builds are a designer-paid cost |
| 2026-11-08 | Review material scattered (builds/xxx-mocks, docs/art, docs/screens) [mem:review-material-one-folder] | One folder `builds/review-<name>/` | One place for what the designer looks at |
| 2026-11-09 | Per-branch full-suite integrates took 10+ minutes and failed on load-sensitive cases while agents ran [mem:batch-merges-targeted-tests] | Batch merge, agents run touched suites, one full run at the end | Serialise the expensive check |
| 2026-11-10 | Script errors printed inside a case while the verdict said PASS (104/105) | A SCRIPT ERROR fails its case (`tests/script_error_logger.gd`) | A green verdict must not hide errors |
| 2026-11-10 | Q1488 removed "stale" grab-cooldown waits, but the interval exists (Q1504) | Tests wait on `Rig.can_grab()` | Check the game before declaring a wait stale |
| 2026-11-10 | Back buttons made ink text (Q1497); designer after play: white with black outline (maintenance/89) | Q1497 reversed; look passes show mocks first (Q1492) | Look decisions are confirmed by playing the build, not the mock |
| 2026-11-11 | Aim-rate branch started merging right after its review builds were exported: "Do not merge the aim-rate! I didn't approve this." [mem:no-merge-before-review-pick] | Never merge while a designer pick is pending | A neutral default is not an approval |
| 2026-11-11/12 | `integrate --continue` died on a hand-resolved merge subject; a docs commit to main mid-run broke the fast-forward; merged tickets left stale [mem:integrate-continue-quirks] | State file, `RESULT` line, no main commits mid-run, mark tickets done (126, Q2049) | Make the merge tool restartable and tell it plainly |
| 2026-11-12 | Answers and follow-ups stranded on unmerged branches: "Main should be the point of truth" [mem:main-is-source-of-truth] | Copy docs to main at once; `housekeeping.sh` stranded-docs check (127, Q1808) | One source of truth, checked by a tool |
| 2026-11-13 | Merge of progression/87 rewrote `data/sounds.json`, the designer's sound bench picks lost; git index rebuilt with read-tree on the glitchy mount [mem:check-designer-edits-before-merge] | Check the designer's uncommitted tool-written files before every fast-forward | Tool-written designer data needs a save point |
| 2026-11-13 | Clock-hand turn (Q1872) "was worse": "The previous rotation was better"; lead reverted (maintenance/130) | Q1872 reversed | A feel change needs a strip and the designer's yes before the second round |
| 2026-11-18 | Agents kept triggering approval prompts (pkill, git plumbing); designer: "make it safe!" (maintenance/137) | agent-brief.md, settings.json deny list, `git_check`, `git_repair`, Q1994-Q2001 | Write the agent's allowed command set into the repo from the start |
| 2026-11-19 | sorting vacuum agent (tools/19) reported four blocking questions only after finishing; three agents extended the graybox kit in parallel, a fourth Opus agent reconciled [mem:preflight-and-foundation-owner] | Pre-flight pass; one owner for a shared foundation (11-19) | Questions before code; a shared piece has one author |
| 2026-11-19 | 676 one-off Python and 120 shell scripts in agent scratch folders (maintenance/140) | Tools: agent_start/finish, suites.sh, shot sets, layout.py, agent_cost.py | Count scripts agents rewrite; promote the top ones |
| 2026-11-12 | Profily makes headless `--import` crash on exit about 3 in 16 (124, 125) | Import retried three times (126); Profily ships all-off in release (Q1809) | Third-party addons need a boot and import test |
| 2026-11-18 | The first `bench_lowend.cmd` run on the designer's PC used saved fullscreen options, so 720p/540p rows were wrong (136); bench had to guess CPU and V-sync (134) | The bench records the machine and takes its own window size | Record the environment in every measurement |
| 2026-11-10 | `integrate` suite blocked by uncommitted designer edits in project.godot; later Input Map move needed them committed first (Q1718) | Agents never commit project.godot; the lead applies lines at merge (Q1474) | Keep the author's config out of agent commits and give it one commit path |

# PART 4. What cost the most rework (ranked, with evidence from tickets and Built logs)

1. **Test reliability, memory and speed (about 17 tickets in 18 days).** Tickets 09, 11, 18, 22, 26, 45, 57 (a, b), 59, 61, 62, 67, 76, 77, 78, 104, 105, 122, 126, 133. Evidence: 9 OOM kills at 4.4-4.6 GB (57); suite 875 s of process time over 52 suites, `net` 267 s (57); `net_test.gd` 4,608 lines touched by 56 of the last 200 merges (94); the designer saw about 15 GB of host memory (77); each case-loop flake "costs reruns" (09); the verdict said PASS with script errors (105); Q1488 then Q1504 reversed one cleanup (62); `integrate --continue` flakes cost "a full extra suite run on 2026-11-11/12" [mem]. General: build a resource-aware parallel runner, a flake ledger, state waits and script-errors-fail on day one of the new project; measure memory per process before choosing the pool size.
2. **Code structure refactored again and again (about 45 tickets).** 29 (10 slices, 2026-11-05, game.gd 3250 lines), 38-50 (one hold system, held record, Carriable, landing, Openable, Prompt: the audit 44 on 2026-11-06 found per-feature duplication again), 52-56 (native replacements), 58-66 (best practice), 88-102 (feature folders, net layout, parts: main.gd 1,847 lines, rig.gd 1,786 to 770, sock_world.gd 3,023 to 996, session.gd 583), 112, 117, 121; then 2026-11-19 the decision to start a fresh project because "Every line of code has to fight for it's life" (Q2143). Evidence for repeated patterns: "Every new held item needs edits in 4+ places and one is always missed" (39); adding a Command edited three shared files (95); tuning.json conflicted 3 times and was touched by 64 of the last 200 merges (92); tests/runner.gd knob list had 10 recorded conflicts (93). General: decide the architecture and the shared seams (one record, one hold, one Command table, one Openable, feature folders) before features exist; measure conflict hot files from git history and give each feature its own file.
3. **Performance work measured on the wrong machine.** Tickets 03, 04, 16, 21, 25, 68-71, 73, 108-111, 134-136. The sandbox has no GPU (lavapipe on CPU), so numbers are relative only; the designer's 4070 Ti bench found a Low preset where all 18 lights still cast shadows (25 Built log: "all 18 lights cast shadows" under `night_shadows: none`), a bogus physics column (108: "maintenance/25's per-tick budget (4 ms settled) was set from the bogus column"), a warm-up artefact in the first row, and the later low-end PC run still needed a window-size fix (136). The real low-end machine (Q1670: 2015 laptop / GTX 1050) has not been run for the GPU pipeline compile check (109). General: pick the real target machine and a bench that records the machine on day one; never set budgets from sandbox numbers.
4. **The zoo / debug UI (about 8 tickets).** 07 (2026-10-31), 31 (every feature), 35 (overflow), 74 (tabs), 114 (playground, parked), 119 (multiplayer zoo, parked), 132 (F1 debug menu, 2026-11-18), 145 (quick polish, 2026-11-19), with Q2056 saying tests must not press zoo buttons and the graybox tests did anyway (145 open [later]). General: debug panels are built from game features, not tested, and stay small; decide their scope before agents add to them (every feature appended its own section; 97 moved zoo sections per feature).
5. **Docs and vault drift (about 8 passes).** 10 (172 moved, 44 superseded), 13 (52 items), 14 (72 answered), 28 (workflow guides compacted: 118 to 49 lines), 32, 75, 128 (sweep: 459 [later] and 34 [blocking] counted, 439 + 34 left open), 34 (stale ticket audit: physics/12-20 re-checked after the refactor). Status stale in many tickets (25, 57, 61 done in code but not marked, 136 merged but ready-for-agent). General: record answers and status in the same commit as the change; one owner file per rule; a sweep every ~30 tickets.
6. **Git, merge and working-copy friction (about 10 tickets and 6 memory rules).** 33, 91, 126, 127, 137, 141, the mounted-drive "invalid object / unable to read tree" glitch repaired by the lead, `commit -a` (2026-11-06), the aim-rate near-merge (2026-11-11), the sounds.json loss (2026-11-13), LFS conversion when .git reached 789 MB (2026-11-10), `.import`/`.uid` churn commits (Q904). General: keep the author's working copy separate from the agents' (own worktrees, a deny list, a merge tool with a state file); do not host the repo on a flaky mount.
7. **Decisions reversed after play (small but repeated).** Q1497 to maintenance/89 (back buttons); Q1872 reverted by the lead (held Sock turn); Q1551 replaced by Q1568-Q1571 after the pad prototype (pad mapping: A/B/X/Y/RT/LT swapped); Q1488 to Q1504; Q1805 to Q1809 (Profily filter); Q1192 (UI in code) reversed for the new project by Q2163; Q1250 (windows are walls to a thrown Sock) made maintenance/06's window follow-ups moot; `Controls.ensure()` (maintenance/56) replaced by the project Input Map (maintenance/115). General: show a strip or a prototype before the decision is final; expect one correction round after the designer plays.
8. **Starter kits (4, 5, 6, 7).** Kit 6 needed two reviewer rounds (36 + 19 fixes), `skills + CLAUDE.md 795 -> 712 lines` (125); kit 7 tracked "Not now" (147). General: write the reusable skill set once, from a finished retrospective, not per milestone.
9. **Agent mistakes that cost the designer attention:** approval prompts for odd commands (137), the designer's "What can run as sonnet should run as sonnet." (2026-11-07) after agents were defaulting to heavier models, token costs of resumed agents (2026-11-05), stranded docs. General: encode agent rules in the repo and in the settings, not in a temp brief.

# PART 5. Open process questions (verbatim from tickets)
- [later] Q827 "physics first" is recorded as "queue order: physics tickets first" (`ticket-agents`). Is that the meaning? (maintenance/28)
- [later] Tickets use areas the list does not name: `tests`, `rendering`, `physics`, `multiplayer` (beside `co-op`), `tooling` (beside `tools`), `tech`, `progression`, `meta`. Document them or retag them? (maintenance/28)
- [later] Where the skill lives: this repo's `.claude/skills/`, the user-level skills beside `godot-game-dev`, or part of `godot-game-dev`. Write it after the three pilots, or keep a draft from the research and grow it per phase? (maintenance/139)
- [later] `tools/export.sh --out` writes no `README.txt` or double-click `.cmd` for a review build; a template or an export option would make them uniform (designer's choice). (maintenance/146)
- [later] Only subagent runs are counted by `agent_cost.py`, not the lead's own session transcripts; say if a "sessions" row is wanted. (maintenance/144)
- [later] Housekeeping takes about 2 minutes (git on the mounted drive, 100+ branches); cache per branch tip if it bites. (maintenance/127)
- [later] Does the host keep the VM's freed memory after runs end? Wall time with the rounded 4 slots unmeasured. (maintenance/77)
- [later] Per-event typed classes in place of string-keyed Dictionaries (944 sites). (maintenance/58, 80)
- [later] `tools/run.py --reverse` forwarding (ticket 133, ready-for-agent). Remaining long frame waits (29 `# kept:` in net, 38 elsewhere). (maintenance/61, 76)
- Kit 7: "Let's track this for the improvements. Not now." (designer, 2026-11-19, maintenance/147; carries the new tools, agent safety and brief, the ticket board mod, the graybox kit idea; plus "the zoo is not what tests test").

# PART 6. Coverage

- Ticket files read: 157 in `docs/llm/maintenance/issues/` (numbers 01-150 with gaps 19, 20, 51 absent and sub-tickets 29a-29j), plus `128-sweep-summary.md` and the folder's other files. Read in number order. Method: each ticket's frontmatter, intro, Acceptance lines that carry designer answers, `## Answers`, `## Open follow-ups`, Built log (first lines per entry); long research and audit bodies were read for the sections that carry decisions (skipped sections were scanned for designer quotes and Q numbers only). Not read line by line: the bodies of 57, 58, 68, 72, 80, 88, 103 research text, 114 plan, 131 "Where things stand ... Estimated code size" sections (read only Answers, Open follow-ups, Research).
- Memory files read: all 25 .md files in the memory folder (24 topic files and MEMORY.md). docs/agents: agent-brief, agent-cost, domain, git, issue-tracker, triage-labels (all six).
- Count of `(Q` answer markers in the folder: 574 occurrences in the ticket files (grep `\(Q[0-9]`); distinct Q numbers mentioned anywhere in the folder: 327; distinct Q numbers cited in this digest (ranges expanded, so this overstates exact citations; 5 numbers, Q1263-Q1265, Q1709, Q1710, appear only inside ranges): 327. Gap 0: none.
- Gap reasons: many Q numbers appear in tickets only as references to other features' questions (listed in 2.11 as not digested); about 60 answers are batch membership, triage, ordering or "Opened with the other maintenance/88 follow-ups" and are folded into 2.11 rather than listed separately; ranges such as Q1262-Q1266 are cited as ranges.
- Not determined / unchecked: (1) whether the code still has `loading.frame_ms` 14, `fade.seconds` 0.5 and other tuning keys at the values the tickets state (no code or data was grepped, per the read-only brief, except ticket text); (2) pad mapping beyond Q1568-Q1571 (LB/RB Hands cycle, Start, Select, stick click ping) is carried from the sketch and unchecked; (3) the low-end PC budgets in 1.1 are the agent's placeholders and the actual low-end report (`docs/perf/low-end-report.md`) was not read; (4) Q2171-Q2174 (device model picks) are not in maintenance/131; (5) whether tickets 70, 87, 108, 118, 133, 136 statuses reflect the code (136 has a Merged line but status ready-for-agent); (6) `docs/llm/maintenance/issues/131` changed during this session (Q2179-Q2181 appeared late); (7) dates for a few memory-file facts rest on the memory file's own dates.

| Ticket | Title | Status | Q numbers in file | of which in this digest |
|---|---|---|---|---|
| 01-project-setup | Project setup from the starter kit | done | 0 | 0 |
| 02-sock-physics-and-performance | Sock physics and performance research | done | 9 | 9 |
| 03-sock-collision-and-loading | Sock collision, pick hitch and loading screen | done | 7 | 7 |
| 04-graphics-presets | Graphics presets and benchmark | done | 6 | 6 |
| 05-drop-floor-clip | A dropped Sock never dips through what it lands on | done | 0 | 0 |
| 06-respawn-lost-items | A Sock or Pair that leaves the flat comes back in front of the washing | done | 1 | 1 |
| 07-zoo | The zoo: a test scene with every mechanic and stress tools | done | 1 | 1 |
| 08-house-shadows | High shadows only from lights near you | done | 4 | 4 |
| 09-net-test-isolation | Net tests that never flake | done | 0 | 0 |
| 10-follow-up-cleanup | Close answered follow-ups across all tickets | done | 1 | 1 |
| 11-faster-tools | Faster tests, shots and imports | done | 5 | 5 |
| 12-missing-bed | The bed and nightstand are not drawn | done | 0 | 0 |
| 13-close-answered | Close the answered follow-ups | done | 0 | 0 |
| 14-question-cleanup | Question cleanup after the Q437-Q508 round | done | 8 | 8 |
| 15-stair-shadows-and-shot-sharing | Stairwell shadows; parallel screenshots share the machine | done | 2 | 2 |
| 16-responsive-loading | Responsive loading screen | done | 1 | 1 |
| 17-graphics-fidelity-research | Graphics fidelity research | done | 1 | 1 |
| 18-load-flaky-tests | Load-flaky tests | done | 0 | 0 |
| 21-profile-mess-physics | Profile the Mess physics | done | 2 | 2 |
| 22-flaky-tests-under-load | Flaky tests under load | done | 2 | 2 |
| 23-fade-into-game | Fade into the game after loading | done | 6 | 6 |
| 24-elevator-second-row | Socks can't be placed in the Elevator's second row | done | 1 | 1 |
| 25-rendering-audit-old-pc | Rendering and performance audit for old PCs | done | 6 | 6 |
| 26-retro-process-fixes | Retro process fixes | done | 2 | 2 |
| 27-render-buffer-errors | "Buffer argument is not a valid buffer" during picks | wontfix | 4 | 4 |
| 28-compact-workflow-guides | Compact the workflow guides into the kit's skill shape | done | 14 | 14 |
| 29-code-cleanup-refactor | Code cleanup and refactor | done | 19 | 19 |
| 29a-shared-test-fixtures | Shared test fixtures | done | 5 | 5 |
| 29b-shot-actions-table | Screenshot actions as a table | done | 6 | 6 |
| 29c-dead-code-sweep | Dead-code sweep | done | 6 | 6 |
| 29d-one-record-in-sockworld | One record per item in SockWorld | done | 13 | 13 |
| 29e-pick-on-sockworld | The crosshair pick lives on SockWorld | done | 6 | 6 |
| 29f-world-encoding | One World encoding for stream, join and save | done | 6 | 6 |
| 29g-flight-and-hands | The Flight and the Hands | done | 11 | 11 |
| 29h-command-seam | The Command seam | done | 8 | 8 |
| 29i-main-setup-split | Split main.gd's setup | done | 7 | 7 |
| 29j-split-game | Split game.gd | done | 6 | 6 |
| 30-small-cleanups | Small cleanups after 29c and the vacuum remodel | done | 3 | 3 |
| 31-zoo-everything | The zoo tries every feature | done | 1 | 1 |
| 32-docs-and-cleanup | Update the documentation and clean up | done | 1 | 1 |
| 33-merge-and-build-tooling | Fewer merge conflicts and quicker review builds | done | 2 | 2 |
| 34-stale-ticket-audit | Stale ticket audit | done | 4 | 4 |
| 35-zoo-panel-overflow | Zoo panel overflow | done | 0 | 0 |
| 36-held-and-hud-fixes | Held items and HUD fixes from the playtest | done | 0 | 0 |
| 37-radio-push-and-body-clip | The Radio pushes you back; the body glitches looking down | done | 0 | 0 |
| 38-one-hold-system | One hold system for everything in the Hands | done | 2 | 2 |
| 39-held-record-and-prompts | One "what is held" record | done | 3 | 3 |
| 40-carriable-save-and-landing | Carriable: one save and guest-quit path for carried things | done | 4 | 4 |
| 41-one-floor-unlocked-query | One floor-unlocked query (and the cat's bug) | done | 0 | 0 |
| 42-one-openable-base | One Openable base, with its sound | done | 3 | 3 |
| 43-small-dedupes | Small dedupes: reward recipient, tuning sections, test helpers | done | 0 | 0 |
| 44-duplicated-logic-audit | Duplicated logic audit (2026-11-06) | done | 5 | 5 |
| 45-pairing-view-error | PairingView._process errors on machines a load swapped | done | 0 | 0 |
| 46-dirty-sock-throw-error | Throwing a Dirty Sock into the laundry bin throws an error | done | 1 | 1 |
| 47-every-hold-crouches | Every held thing goes down with the crouch | done | 1 | 1 |
| 48-one-prompt-record | One prompt record | done | 3 | 3 |
| 49-carriables-survive-quit-and-join | Every carried thing survives a save, a guest quitting and a player joi | done | 3 | 3 |
| 50-finish-shared-landing | Finish the shared landing | done | 2 | 2 |
| 52-native-godot-audit | Audit: hand-rolled code with a native Godot replacement | done | 2 | 2 |
| 53-native-small-dedupe | Use Godot's smoothstep, ease and Performance monitors | done | 1 | 1 |
| 54-banner-and-coins-as-tweens | The complete banner and coin flights as Tweens | done | 1 | 1 |
| 55-countdowns-as-timers | Hand-counted delays as Timers | done | 1 | 1 |
| 56-keys-in-the-inputmap | Every key as an InputMap action | done | 1 | 1 |
| 57-test-runner-rework | A test runner that shares the machine: memory-aware, machine-wide, in  | done | 3 | 3 |
| 58-best-practice-audit | Audit: the architecture against Godot's best practices and the skills' | done | 0 | 0 |
| 59-break-game-reference-cycles | A finished Game is freed: break the Game and parts reference cycles | done | 1 | 1 |
| 60-gdignore-docs-art | Godot stops importing the documentation's preview images | done | 2 | 2 |
| 61-static-state-scrubbed-between-cases | Every static knob is reset between test cases, and shared statics are  | done | 2 | 2 |
| 62-long-frame-waits-in-tests | Tests wait on state, not on a count of frames (the 123 long waits) | done | 4 | 4 |
| 63-pin-tick-order-and-view-clocks | Main and its Rigs have the same process priority: trace and pin the ti | done | 2 | 2 |
| 64-typed-dependencies-not-string-calls | Dependencies are injected and typed, not reached by method name; nodes | done | 4 | 4 |
| 65-save-written-safely | The save file is written without losing the old one, and its errors ar | done | 5 | 5 |
| 66-one-theme-for-the-ui | The menus and the HUD share one Theme instead of 194 per-control overr | done | 1 | 1 |
| 67-faster-leaner-tests | Faster, leaner tests | done | 0 | 0 |
| 68-hot-paths | Hot paths and suggested optimizations | done | 5 | 5 |
| 69-ui-refresh-when-shown | The Upgrade menu and the HUD refresh only when shown and changed | done | 2 | 2 |
| 70-room-day-writes-on-change | The day cycle writes the lights only when they change | ready-for-agent | 3 | 3 |
| 71-per-event-mess-scans | No pass over the whole Mess on every pick and drop | done | 2 | 2 |
| 72-occlusion-culling | Occlusion culling for the house | needs-info | 4 | 4 |
| 73-sfx-ear-on-demand | The Sfx ear works only when something changed | done | 2 | 2 |
| 74-zoo-update | Update the zoo and clean up its panel | done | 4 | 4 |
| 75-split-architecture | Split docs/architecture.md by subsystem | done | 0 | 0 |
| 76-test-flakes | Co-op cases and perf budgets that fail only under load | done | 0 | 0 |
| 77-test-memory | Test runs use too much memory | done | 2 | 2 |
| 78-small-bugs-after-batch | Three small bugs found at the 2026-11-10 merge | done | 1 | 1 |
| 79-ui-theme-unification | The UI looks and is styled the same everywhere | done | 9 | 9 |
| 80-godot-rules-audit | Audit: does the code use anything Godot's documentation forbids? | done | 3 | 3 |
| 81-ray-queries-in-tick | Every space query runs in the physics tick (widen physics/33) | done | 3 | 3 |
| 82-ragdoll-jolt-cleanup | The ragdoll sets no property Jolt ignores | done | 3 | 3 |
| 83-queue-free-in-tree | Nodes in the tree are freed with queue_free | done | 2 | 2 |
| 84-session-shutdown | A co-op session shuts down cleanly | done | 2 | 2 |
| 85-godot-rules-checklist | The Godot rules are checked at every merge | done | 2 | 2 |
| 86-json-read-helper | One helper reads JSON files | done | 2 | 2 |
| 87-measure-interpolated-and-aabb | Measure interpolated transforms and the MultiMesh AABB | ready-for-agent | 2 | 2 |
| 88-maintainability-proposal | Proposal: a feature-folder layout and the refactors that cut merge con | done | 14 | 14 |
| 89-back-buttons-white | Back buttons are white with a black outline; the Licence screen is two | done | 2 | 2 |
| 90-netcode-structure | Proposal: the net-code layout, before the maintenance starts | done | 6 | 6 |
| 91-uid-cleanup | Every script has its .uid and every .uid its script | done | 2 | 2 |
| 92-tuning-per-section | Tuning in one file per section | done | 1 | 1 |
| 93-test-knobs-by-class | Test knobs declared by their class | done | 2 | 2 |
| 94-split-net-test | net_test.gd split by feature | done | 3 | 3 |
| 95-parts-register-commands | Game parts register their own Commands | done | 4 | 4 |
| 96-main-installs-features | Main installs features | done | 3 | 3 |
| 97-shot-and-zoo-per-feature | Shot actions and zoo sections per feature | done | 1 | 1 |
| 98-rig-in-parts | Rig in parts | done | 2 | 2 |
| 99-sockworld-in-parts | SockWorld in parts | done | 1 | 1 |
| 100-folder-move | The folder move to game/ | done | 5 | 5 |
| 101-guard-rails | Guard rails for the layout | done | 6 | 6 |
| 102-session-in-parts | Session in parts | done | 5 | 5 |
| 103-controller-support-research | Research: controller (gamepad) support | done | 19 | 19 |
| 104-vacuum-gone-suck-crash | A "gone" vacuum_suck event crashes `SockVacuums._apply_suck()` | done | 0 | 0 |
| 105-script-error-fails-run | A SCRIPT ERROR inside a case fails the run | done | 0 | 0 |
| 106-pad-focused-window | Hot-fix: the pad drives only the focused window; keyboard or mouse dro | done | 0 | 0 |
| 107-controller-polish | Polish the controls (pad, keyboard and mouse) | needs-info | 4 | 4 |
| 108-physics-tick-spikes | Physics tick spikes in the bench | ready-for-agent | 1 | 1 |
| 109-floor-spawn-hitch | A new floor's Socks hitch the game for 100 to 290 ms at the Fix | done | 5 | 5 |
| 110-aim-rate | Aim chain at a lower rate | ready-for-human | 2 | 2 |
| 111-tick-frame-cost | Why a tick frame costs 3 ms more than a plain one, and the plain-frame | done | 0 | 0 |
| 112-data-load-once | Read the game's data files once: Tuning, FlatLayout, SockCatalogue, Ca | done | 7 | 7 |
| 113-code-map | Code map: a zoomable treemap of game/**/*.gd | done | 6 | 6 |
| 114-zoo-playground | The zoo's playground: a plain walk-through area beside the house | needs-info | 5 | 5 |
| 115-project-input-map | Every action in the project's Input Map | done | 6 | 6 |
| 116-typed-tuning-resources | Move game-only tuning from JSON to typed Resources | wontfix | 7 | 7 |
| 117-constants-cleanup | Constants and duplicate small functions: merge the real duplicates, sh | done | 2 | 2 |
| 118-debug-out-of-release | Leave the debug code out of release exports | ready-for-agent | 1 | 1 |
| 119-multiplayer-zoo | A multiplayer zoo | needs-info | 7 | 7 |
| 120-controls-bugs | Two controls bugs from the controls report | done | 1 | 1 |
| 121-sockworld-flight-tuning | SockWorld and Flight constants to tuning (maintenance/117 leftover) | done | 1 | 1 |
| 122-net-devices-ride-flake | net_devices:ride "full size again" flake | done | 0 | 0 |
| 123-wardrobe-focus | Wardrobe focus: arrows and colours only | done | 0 | 0 |
| 124-profily | Profily replaces the frame overlay | done | 2 | 2 |
| 125-starter-kit-6 | Starter kit 6: the designer's answers on kit 5 | done | 29 | 29 |
| 126-flakes-and-integrate-state | Known flakes, integrate state file and merge hashes | done | 3 | 3 |
| 127-housekeeping-and-stranded-docs | Housekeeping check and stranded docs | done | 2 | 2 |
| 128-doc-drift-and-followup-sweep | Doc drift and the follow-up sweep | done | 1 | 1 |
| 129-wardrobe-focus-pad-only | Wardrobe focus only with a controller | done | 0 | 0 |
| 130-held-sock-turn-zoom-hints | Held Sock: turn from its top, Zoom, and only the controls that apply | done | 2 | 2 |
| 131-scenes-and-resources-plan | Move the game to scenes and Resources | needs-info | 37 | 37 |
| 132-in-game-debug-menu | A basic debug menu in the game | done | 3 | 3 |
| 133-run-py-reverse | Forward --reverse through tools/run.py | ready-for-agent | 0 | 0 |
| 134-bench-records-the-machine | The bench records the machine, and a low-end bench script | done | 2 | 2 |
| 135-tick-cost-by-system | Where the tick's script time goes | done | 0 | 0 |
| 136-bench-lowend-window-size | bench_lowend.cmd: the 720p and 540p runs ran at the saved fullscreen s | ready-for-agent | 0 | 0 |
| 137-agent-safety | Agent safety: rules in the repo, destructive git blocked, git repair i | done | 9 | 9 |
| 138-nativize-research | Research for the move to native Godot | done | 0 | 0 |
| 139-nativize-godot-project-skill | A skill of its own: "nativize godot project" | needs-info | 1 | 1 |
| 140-development-tools | Reusable development tools, so agents stop rewriting one-off scripts | done | 8 | 8 |
| 141-agent-start-finish-and-suite-runner | Agent start and finish scripts, and a suite runner | done | 2 | 2 |
| 142-shot-sets | Shot sets: named shot recipes, with before/after from an older commit | done | 1 | 1 |
| 143-layout-queries | House layout queries | done | 1 | 1 |
| 144-agent-cost-report | Agent cost report, shown on the ticket board | done | 1 | 1 |
| 145-zoo-panel-quick-polish | Zoo panel: quick polish, focused on features | done | 9 | 9 |
| 146-workflow-docs-and-skills | Docs and skills for the new workflow tools | done | 2 | 2 |
| 147-starter-kit-7 | Starter kit 7: carry over the workflow improvements | needs-info | 2 | 2 |
| 148-unification-estimate | How much code would unification and a rewrite really remove? | done | 0 | 0 |
| 149-move-plan-core-first | The move to native Godot: a plan, core first, one feature at a time, t | done | 0 | 0 |
| 150-target-code-shape | The shape of the code after the move: classes, one standard interface, | done | 0 | 0 |
