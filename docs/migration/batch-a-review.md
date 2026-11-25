# Batch A review sheet

What the designer plays at the end of batch A (the run and the washer, Q2606), in one session (Q2605), and what the
agents settled on their own along the way (Q2604). The build order: `docs/migration/milestones.md` "Batch A". The
designs: `docs/architecture/stages.md`, `run-ends.md`, `washer.md`, `voice.md`.

## How to use it
Play a house New Game from the title, Solo first, then with a Guest, through to the Final screen and back to the Lobby
(the debug "Pairs per Drawer" slider at 1 makes the run short). For each line say yes, or what to change; a change
becomes a ticket. The asset line-ups are in `builds/review-assets-<NN>/`.

## What you play, by ticket

| Ticket | What to look for |
|---|---|
| core/76 Stages | a New Game starts at Stage 1, only the basement's Cabinets unlocked; the garage Cabinet sheeted; the World's row in the Lobby names the floor |
| core/77 A Stage's Socks | only the basement holds Socks at first; after each Fix the new Socks lie over every open floor in even shares (Q2617); with two players a few lie on high spots |
| core/78 Carrying | a Part and a bin take the whole Hands, ride steady in front, go down at the crosshair turned as held, into a Teammate's empty Hands |
| core/79 Machine Parts | the Part pops out of the Cabinet that took the last Pair, turns and bobs with its glow; the readout names it |
| core/80 Floor locks | the door and the gate, the padlock's hint "Please the washing machine", the pop, the chain, the swing, the lamps |
| core/81 Cabinets grow | the new Drawers drop in at once with a thunk and dust (Q2620) |
| core/82 Stage bar | "Wash the laundry" before the First wash; "Stage 2: Ground  83/175"; full until the Fix; the fold into "Wash clothes n/3" (wording: the lead's reading of Q2621, the old was "Laundry bins loaded: n/3") |
| core/83 Tallies | the Whiteboard and Tab: Pairs shelved, Socks picked, Coins earned per player |
| core/84, core/85 Voice | every washer line's subtitle, timing and mouth in the Voice station; the muffle behind a shut Door; the music duck in cutscenes |
| core/86 Washer | where it stands, the stare comments (silent before the First wash, Q2636), the comment sets by Stage, Stage 4's in the Laundry day (Q2635) |
| core/87 Broken looks | sparks, smoke, buzz and the drum light's flicker by mood, calmer each Fix |
| core/88 Cutscene frame | the shots and cuts, the fades, nothing but the washer drawn, the Host's skip, the respawn |
| core/89 Spray | the spray of Socks out of the door at the First wash and after Fixes 1-3 |
| core/90, core/93 Laundry bins and Laundry day | the seven bin spots (placed by eye), the tip, the pile behind the porthole, the refusals |
| core/91 The house's run | the whole run in the house, Stage by Stage |
| core/92 Fix scene | cutscene_2 to cutscene_5, each whole (cutscene_5 mentions the cave system: Q2634) |
| core/94 First wash | the calm wash, the break, cutscene_1, the spray, the bin still full in the Hands |
| core/95 Final screen | columns of the players at the end (Q2630), the Pairs popping in, the totals, the skip; stills of 1, 2 and 4 players and a long name in `builds/review-final-screen/` |
| core/96 Final wash | the happy wash, the push-in, cutscene_6 whole, the Final screen on every machine |
| core/97 Back to the Lobby | Continue from a Guest; the finished World as a record; Start asks before replacing it |
| core/98 Knockdown wash | drag a knocked Teammate to the door: the spin, the burst out |
| assets/10-15 | the line-ups: floor locks, Cabinets at six Drawers, the Parts, the Laundry bin, the washing machine, its subtitle icon |

## The lead's readings to confirm
- Voice level (Q2638): no game gain, so every line plays at 0 dB; the old comments were +6 dB because the clips are
  quiet. They will sound quieter than the old until the recordings are fixed at the source.
- The Laundry day's bar text "Wash clothes n/m" (Q2621's example taken as batch A's wording).
- The Machine Part goes into a Teammate's Hands by core/42's Hand-off too; the bin does not (core/71's proposal).

## Settled by the old game (Q2604)
Each agent adds a line here for an open choice it met and settled by the old game's answer (or the nearest): the
ticket, the choice, what it did, the old file:line. The designer confirms or changes each in play.

| Ticket | The choice | What was done (the old answer) | Designer |
|---|---|---|---|
| core/100 | Jolt penetration slop (Socks under a heap sink up to about 1 cm) | kept Jolt's default 0.02 m, the watch counts only pushes | reference/it-socks/project.godot:257-260 (no slop set) |
| core/87 | Spark count and burst gap at mood 1: the old scale ran mood 1 to the angriest; the Looks know only `damage` | the floor is 1 / `zoo_levels` (the old five Parts), so mood 1 gives the old minimum (6 sparks, a burst every 2.4 s) | reference/it-socks/game/devices/washer_damage.gd (`refresh`) |
| core/87 | The buzz has two picks (a, c) and a world loop is one stream | the first pick loops (synth/washer_buzz_a); both are in the catalogue event | reference/it-socks/data/sounds.json `washer_buzz` |
| core/87 | The rumble has no pick | the first synthesised candidate (rogue_rumble_a) loops, -36 to -12 dB by anger times wiggle | reference/it-socks/data/sounds.json `rogue_rumble` |
| core/87 | Flash light's level and length (old code number) | 3.0 for 0.08 s per burst, placeholders in `washer_tuning.tres` | reference/it-socks/game/devices/washer_damage.gd (Flash) |
| core/78 | What `Carriable.handable` switches (the docs say the bin refuses core/42's Hand-off, yet its behaviour line says a right click at a Teammate puts it in their Hands) | built as the switch of that right click: on, into their empty Hands or at their feet ("Hands full" for them); off, a plain drop at the crosshair. On by default and on the stand-in crate, since the old game handed both a bin and a Part over that way (`game/campaign/laundry.gd:507-513` decide_drop, `game/player/rig_drop.gd:47-52`); core/72 sets the bin's | |
| core/78 | A carried thing's crosshair row and corner hint | carried: its name with no key; lying: its name with the left-click key only for empty Hands; the corner says "Drop" with the right button (no Zoom, Turn, Throw) (`game/ui/prompts.gd:24-26`, `:101`) | |
| core/78 | Which way a thing laid at a full Teammate's feet or by a leaver turns | at the turn it last lay, as the old (`game/campaign/laundry.gd:530-536`, `:746-755`) | |
| core/78 | Where a thing put down rests | at the crosshair's point on the top (the drop's own place check); the old found the highest top under the thing's whole footprint (`game/world/landings.gd:190-223` landing_of) | |
| core/84 | The old untagged comments (stage_4 B and C, stage_5 B and C): in the new JSON an empty `triggers` means the line never plays in a game | each is given all four comment triggers (washer_stare, washer_progress, washer_hit, washer_idle), as the old picker took an untagged line for any trigger | reference/it-socks/game/audio/voice_director.gd:51-66 (`suits`: tagged with it or with nothing) |
| core/84 | Segment times with no transcription installed: the old lines' hand-corrected times live nowhere in the planned JSON | an optional `timing` per recording in the speaker's JSON (`{"<file>.wav": [[start, end], ...]}`), hand-editable and used over the bake's own; the washer's 21 lines carry the old times | reference/it-socks/tools/voiceover/voiceover.py:132-152 (hand-edited `segments` kept on a rerun); data/voiceover/*.json `segments` |
| core/84 | The credits for the washer's recordings (every asset needs an entry; the old credits had none for them) | one "Made for It Socks" entry, "The washing machine's voice (its comments and cutscenes)", author It Socks, part of the game, covering `assets/voice/washer/*`, as the other made-for-the-game entries | reference/it-socks/data/credits.json (no voiceover entry) |
| core/85 | How long a `waits` line waits for a higher voice (the old game dropped every blocked line, no waiting) | `VoiceTuning.wait_hold` 10 s placeholder, then dropped; no line of batch A waits, the Old Tree's will (batch B) | the old had no wait (`game/audio/voice_player.gd:85-104`) |
| core/85 | A picker with only one fitting line left that was the last said | it repeats (never the last, unless it is the only one) | `reference/it-socks/game/audio/voice_director.gd:56-69` |
| core/85 | A trigger no comment line has: which lines the fallback may take | any comment line (one with a comment trigger) of the set; the cutscenes' lines never fall into a comment | voice_director.gd:56-69 (the old had no cutscene lines in the stage sets) |
| core/85 | Which canvas layer the subtitles are on | 2 (above the HUD, below the menus), 26 while a cutscene plays (the old kept 26) | `voice_player.gd:248-274` |
| core/85 | What ducks the music | the cutscene channel playing (the ticket and the build plan), not the old's whole cutscene view; core/88's frame may take it over | `game/audio/music_duck.gd:1-30` |
| core/81 | Where the dust puff starts (the behaviour line says "its top seam") | the thunk is at the new Drawer's top, the dust from the seam the module lands on (its bottom, 0.05 m toward the front), as the old (`game/campaign/cabinet.gd:200-230` `_land`, `_dust`) | |
| core/81 | A Cabinet that had no Rows shown and gains some (a Cabinet first unlocked) | stands at its Rows at once, no drop; only a Cabinet that already showed Rows drops (`game/campaign/locks_view.gd:143-149`, `was[0] > 0`) | |
| core/81 | A floor opening while an earlier drop still plays | the unfinished drop lands at once, then the new Drawers drop (the old killed the tween and left the unlanded modules unplaced, `game/campaign/cabinet.gd:131-134`) | |
| core/89 | The old step's two hard-coded numbers (0.7 sideways grip at a bounce, 0.3 m/s last bounce) | made `floor_grip` and `rest_speed` in `SockSprayTuning`, with the old values, so every spray number is in the Resource | reference/it-socks/game/devices/first_wash_spit.gd `_process` (vel.x *= 0.7; vel.y < 0.3) |
| core/89 | The zoo's Spray pillar: shown to every machine or only the presser | plays on the pressing machine only (looks only, nothing asked of the Host); the real First wash plays it on every machine from the Host's answer (core/94) | the old spit was a local effect started by the cutscene timeline (first_wash_spit.gd `play`) |
| core/82 | How the bar knows the First wash is still to come (core/72 is not built; the old HUD had no goal line, Q2625 is new) | the group `stage_bar_goal` of nodes with `goal_pending()`: none in a level (the zoo's mini run) starts at the Stage; core/72's First wash joins it | no old equivalent; the old bar showed once `stages.on` (reference/it-socks/game/ui/hud.gd:258-296, game/campaign/campaign.gd:71-85) |
| core/82 | The StagePanel's numbers (the behaviour list's "radius 6, 14 padding, 3 edge, 10 shade" read in the wrong order) | the old call `keycap_style(CREAM, CREAM_SHADE, 6, 14, 3, 10)` is lip 6, radius 14, edge 3, padding 10: built as that, on the Theme's `StagePanel` | reference/it-socks/game/ui/ui_bits.gd:103, :323 |
| core/82 | The fold's sound (the list's "cheerful sound, `pop`, placeholder") | `pop` plays as the fold begins, as the old rig did on the bar's `stage_folded` | reference/it-socks/game/player/rig.gd:260, game/ui/hud.gd:331 |
| core/82 | The bar's look during a Stage-to-Stage reset when the Stage's icons are unchanged | the icons pop in again anyway (the old always rebuilt them on a Stage change) | reference/it-socks/game/ui/hud.gd:411-425 |
| core/82 | One bar for every phase (the old had two boxes, the Stage bar and the counter) | one box that folds, shrinks, redraws as the next phase and pops; the look is the same | reference/it-socks/game/ui/hud.gd:337-356 |
| core/90 | The bin's `handable` (core/78 left it to this ticket) | on: a right click at a Teammate puts the bin in their empty Hands, else at their feet, as the old; core/42's Sock Hand-off still refuses a carried bin (`game/campaign/laundry.gd:507-513`, `:534-541`) | |
| core/90 | The graybox heap has no blend shape (assets/13 brings the model) | the heap is scaled by the fill, shown above 0.001, hidden when empty, eased at 0.8 a second; with the model the blend shape `empty` = 1 - fill takes over by name, no code change (`game/campaign/laundry_view.gd:133-148`) | |
| core/90 | The tip's curve | the old lean, sampled into the `tip` animation: 105 degrees at most, `sin(pi f) * 1.6` clamped to 1, over `tip_seconds`, leaning toward the washer (`game/campaign/laundry_view.gd:166-186`) | |
| core/77 | Which floor a generator lays for when its `floor` is not set (the Stages station's scene is not edited this wave) | below 0 it takes its place among its level's generators in tree order (Ground = floor 0, Platform = 1); the house sets all four | the old levels were the list order (`game/world/sock_layout.gd` planned levels) |
| core/77 | The washer lesson's Designs | the first two common Designs of Simple come first in Stage 1's Socks, as the old game did with the campaign on (`Game.staged`) | reference/it-socks/game/world/sock_layout.gd:1643-1650 |
| core/77 | Stage Socks and the stair trails | a Stage's Socks are laid on the generators' areas only (a trail's Socks are the starting Mess's, not a Stage's) | reference/it-socks/game/campaign/campaign.gd:197-270 (stage_designs has no trail) |
| core/77 | A Pair no place was found for | landed without it and not laid again (logged); the old forced a place | the nearest: the generator never forces a Sock (docs/architecture/sock-generator.md "Gotchas") |
| core/77 | The seed of a laying | `hash([the World's seed, stage, floor, generator index])`, so two floors' laying never repeat each other (the ticket named only seed and stage) | reference/it-socks/game/campaign/campaign.gd (one seed per spawn; the floors differ by their levels) |
| core/77 | Rounding of the high spots and of the floors' shares | `round(Pairs * high_share)` per generator, taken off its first areas; the shares deal Designs round-robin so every floor gets a mix of Collections, the remainder to the newest floor | reference/it-socks/game/world/sock_layout.gd:1234-1265 (level_shares) |
| core/77 | How core/94 tells the New Game to hold Stage 1's Socks | a node in the group `first_wash_wanters` under the level with `wants_first_wash()`; none: laid at once. `lay_first` only releases the hold | the ticket's `LaundryDay.wants_first_wash()` |
| core/77 | Dirty Pairs and the Drum's Lost Socks in a Stage's Designs | not in batch A (the Laundry day draws its own, the Drum is batch D) | reference/it-socks/game/campaign/campaign.gd:206-207, 245-250 |
| assets/12 | The `lying` motion's numbers and shape (the design names a spin and a bob; core/79's ticket reads the bob as 2.2 Hz) | keyed in each Looks as the old code moved it: a turn of 1 rad/s about up, a bob of `0.035 * (0.5 + 0.5 * sin(2.2 t))` m (2.2 rad/s, so never under the floor), one 10π s loop (5 turns, 11 bobs) that wraps seamlessly (`game/campaign/part_view.gd:12-14`, `:134-135`) | |
| assets/12 | Which node the outline draws | the turning `Part` and its model only, never the glow (core/79's), as the old aim outlined the Part node (`game/player/rig_aim.gd:197`); the Looks has `Part/Model` and `Part/Outline` | |
| core/79 | Where a Part's pop spot goes when gift boxes lie there (the old pushed it clear of them) | not built: Stage presents are batch B's (Q2612), so no gift box exists yet; the spot is `ahead` m in front of the Cabinet's front on the floor, one ray (reported to the lead) | reference/it-socks/game/campaign/gifts.gd:152-169 pile_spot |
| core/79 | The lying spin and bob (the ticket's tuning list vs assets/12's hand-over: they are keys of the Looks' `lying`) | keys only: `MachinePartTuning` has ahead, pop, arc, glow colour and sparks; the bob rate is the old 2.2 rad/s, each Part starts its loop at a phase of its own (the old `+ id`), `RESET` plays while it is carried or flies | reference/it-socks/game/campaign/part_view.gd:128-176 |
| core/79 | The graybox Looks' file names | `looks_<kind>_graybox.tscn` (nodes `Part`, `Model`, `Outline`, `AnimationPlayer`, `lying`, `RESET`, assets/12's contract), so assets/12 merges with no add/add conflict; the four kind `.tres` name them and take assets/12's `looks_<kind>.tscn` at that merge | assets/12 looks_contract.json |
| core/79 | What the washer prompt says while a Part is carried | "Fit the new filter" with the left-click key (the Part's name lower-cased), none otherwise; a refusal reads "The washing machine is busy" | reference/it-socks/game/ui/prompts.gd:35, game/campaign/campaign.gd:823-826 |
| core/79 | A Part picked up while it still flies | the flight ends at once and the Part is carried (the old showed the held pose over the flight) | reference/it-socks/game/campaign/part_view.gd:101-108 |
| core/79 | How far from the slot a player may fit | 4 m, `MachinePartSlot.reach` (the old fit had no reach of its own) | reference/it-socks/game/campaign/campaign.gd:799-841 |
| core/86 | Where the wide shot's "0.95 m up" is measured from | from the machine's middle, as the old (the box's centre, 0.475 m over the floor): the marker stands 1.425 m over the floor, 2.0 m out, 0.35 m to the machine's +X, looking at the middle 0.05 m up; the close shot likewise from the face (0, 0.57, 0.3) (`game/devices/rogue_machine.gd:351-405`, `data/tuning/rogue.json`, `voice.json` close_shot/close_up) | |
| core/86 | Where the four respawn spots stand ("side by side", Q745) | 1.2 m in front of the door, 0.6 m apart (the Host's `beside`), filled alternately from the middle: 1 and 2 beside the middle, 3 and 4 outside them (the old washer spawn's alternating steps, `game/net/coop_tuning.gd` `beside`) | |
| core/86 | What counts as "the run's last Pair" for the silent progress comment (Q1413) | the shelved Pair that fills the last Stage's bar says nothing; every earlier one asks a progress comment (`game/audio/voice_triggers.gd:5-6`) | |
| core/86 | What a "hit" is (the old: a thrown thing lands within 1.4 m on the floor plane) | any Sock or Pair that comes to rest within 1.4 m of it on the floor plane, read from the Mess's `rest` answer; the old counted only a thrown thing, the port cannot tell a throw's landing from a Sock woken by a knock at that point (`game/audio/voice_triggers.gd:39-45`, `data/tuning/voice.json` hit_radius) | |
| core/86 | The washer's drum light when a line ends mid-ease | the shown glow eases to the wanted one at the old rate a second (6) both ways, so a line's end fades back to the idle glow instead of cutting (`game/devices/washer_face.gd` glow lerp) | |
| core/86 | The zoo's Stage and mood overrides live on the washer's Part (a zoo-only Command each), not as a Command on `Stages` | the ticket named `Stages`, but core/79 works the Stages station and `stages.gd`; the zoo's washer station has no run of its own, so the washer holds the zoo's Stage (`zoo_stage`) and mood (`zoo_mood`) as state and "From the run" gives them back (the old zoo had a "Mood" setting, `game/debug/zoo/washer_section.gd:13-29`) | |
