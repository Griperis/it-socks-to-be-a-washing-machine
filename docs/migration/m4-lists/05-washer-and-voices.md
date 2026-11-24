> Draft behaviour list for batch A's washer and voice piece (core/73), written from the reference on 2026-11-24; for
> the designer to approve. The proposals built on it: `docs/architecture/voice.md` (the build plan) and
> `docs/architecture/washer.md`. The voice findings it extends: `docs/migration/voice-findings.md` (core/56).

# Batch A piece: the talking washing machine and the voice system

Draft behaviour list (catalogue B34 Washing machine and rogue machine; the voice parts of B21 First wash and B20's
Fix; the old zoo's washer section). Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start
with `port:`. Short forms: RM = `game/devices/rogue_machine.gd`, RI = `game/devices/rogue_installer.gd`,
WF = `game/devices/washer_face.gd`, VP = `game/audio/voice_player.gd`, VD = `game/audio/voice_director.gd`,
VT = `game/audio/voice_triggers.gd`, VL = `game/audio/voice_lines.gd`, WD = `game/campaign/washer_damage.gd`,
CA = `game/campaign/campaign.gd`, MD = `game/audio/music_duck.gd`, WS = `game/knockdown/washes.gd`,
MF = `tools/blender/make_washing_machine_face.py`, VO = `tools/voiceover/voiceover.py`, BR = `tools/voiceover/brows.py`,
TV = `data/tuning/voice.json`, TR = `data/tuning/rogue.json`, TB = `data/tuning/broken.json`, TW = `data/tuning/wash.json`,
SB = `data/sounds.json`, DG = `docs/migration/digests/digest-devices-cat-story.md` part D. Every number under TV, TR,
TB and TW is a placeholder in the old game too.
"(71)" marks a line whose trigger core/71 (Stages) owns, "(72)" one core/72 (First wash, Laundry day) owns; the washer
only answers it. "(D)" a line of batch D (the Drum finale, Q2615), "(C)" one of batch C (the lived-in house, Q2614),
"(B)" one of batch B (the Old Tree, Q2614). The lines say what the player sees and hears, not the old code's shape.

## Behaviour list

### Where it stands and what it is
- When the house loads, then the washing machine stands in the basement laundry where the old layout put it, its door
  facing into the room; it is a solid box 0.7 x 0.95 x 0.7 m that players and Socks meet. (ref: `game/house/room.gd`:22,
  :239-243; `game/house/flat_layout.gd`:99-104; port: `game/house/house.tscn` marker `Washer`, house/05)
- When the crosshair is on it, then it is outlined and named "Washing machine"; it has no use of its own (E does
  nothing), only what a held thing does at it: a Part shows "Fit the <part>" (71), a full Laundry bin "Load the washing
  machine" (72). (ref: room.gd:239-242 `hint_only`; `game/ui/prompts.gd`:33-37)
- When it stands, then its look is the retro appliance (pipeline/02) with the talking face: no eye; the round door is the
  mouth on a side hinge, swinging sideways like a real washer door, not a jaw (Q1392); two thick, dark, chunky, rounded
  brows over the door (Q1374); a dark perforated drum without paddles, lit from behind its holes, with dark laundry lumps
  in silhouette against the glow (Q1400); a clearer porthole glass (Q1401, alpha 0.07). (ref: MF:1-47, :85; DG)
- When a Sock or item lies on its top, then it rides the body: the machine's body in the Socks' space follows its model
  (rogue/03, Q867; the motion is only the talking bob and lean since Q1470). (ref: RI:28-31)
- When a Sock or Pair leaves the house, then it comes back in front of the washing machine's door, scattered round that
  spot (already ported from the marker, core/16; Q2559 for loads). (ref: `data/tuning/lost.json`; flat_layout.gd:316-325)
- When a New Game lays the Mess, then the house thins out with the walking distance from the washing machine (already
  ported from the marker, Q2528). (ref: flat_layout.gd:754-759)

### Its mood and repair (how broken it looks)
- When a run is under way, then the machine has a mood: the angriest (one step per Part, 5 in the old run) once the First
  wash has broken it, one step calmer per Part fitted, calm (0) once fixed; before the First wash it looks fine (72).
  (ref: CA:396-407; `data/tuning/parts.json`)
- When the machine is broken, then blue-white static sparks burst off the top of its back panel and off its cable low on
  its side, small grey smoke puffs rise off its back, a small flash lights each burst and an electric buzz loops at it;
  all as strong as its mood: sparks 6 to 40 a burst, a burst every 2.4 to 0.5 s, smoke 0.8 to 4 puffs a second, the buzz
  -22 to -6 dB, from mood 1 to the angriest; nothing when calm. The bursts come on a fixed clock with fixed seeds. (ref:
  WD:1-40, :158-272; TB; SB `washer_buzz` picks synth/washer_buzz_a, _c)
- When the machine is broken, then its drum light is dim and flickers: at the first Stage 0.3 of its strength, flickering
  0.8 deep (a new level every 70 ms), steadier and brighter with each Part, steady at full once fixed (Q1411). (ref:
  WF:213-245; TV `repair_dim`, `repair_flicker`)
- When it is silent, then the drum's lining glows its idle colour (warm 0.9, 0.75, 0.5 at 0.6) and the light inside the
  drum is off; the light lights only the drum and its laundry (its own render layer). (ref: WF:12-16, :213-245; TV `glow.idle`,
  `light`, `light_range` 0.45)
- When the machine is broken, then nothing inside washes or tumbles: the laundry lies still and the drum does not turn;
  only after the Final wash may the drum turn (Q1411). (ref: MF:30-33; WF:10-11)

### Its comments (the occasional voice)
- When this player looks at the machine for 4 s from within 8 m and within 12 degrees of its middle (0.5 m up), then it
  asks the Host for a comment once per look (look away and back for another chance); on the Host the stare has a 50 %
  chance. Any player's machine senses its own player's stare. (ref: VT:68-86; VD:42-43; TV `stare_*`; Q1385)
- When a Pair is shelved or a Cabinet is filled (71), then the Host asks for a "progress" comment. (ref: VT:28-36)
- When a thrown thing lands within 1.4 m of the machine (on the floor plane), then the Host asks for a "hit" comment.
  (ref: VT:39-45; TV `hit_radius`)
- When nobody has shelved a Pair for 60 s and a comment could play, then the Host asks for an "idle" comment (checked
  once a second; the quiet spell starts again). (ref: VT:55-65; TV `idle_seconds`)
- When a comment is asked, then the Host gives one only if 120 s have passed since the last comment and no cutscene is
  playing; the line comes from the current Stage's comment set (Stage 1 the stage_1 lines ... Stage 4 the stage_4 lines;
  stage_5 while the Drum is open (D)); one tagged with the trigger or with none, never the line before; when none fits,
  any line of the set but the last. A line given counts as played (the cooldown starts). (ref: VD:27-66; Q1378, Q1379,
  Q1384)
- When the comment is given, then every player's machine plays the same line (the Host decides, Q2545). (ref: VD:1-6;
  `game/core/game.gd`:230-232)
- When the last item goes in (the run's last Pair), then nothing is said (Q1413). (ref: VT:5-6)
- When the run is not staged (the zoo, a debug start), then no comment is asked; inside the Drum the Drum's own rules
  comment (D). (ref: VT:49-56)
- When a comment plays, then it is heard from the machine in 3D (unit size 6 m, gone at 30 m) at +6 dB, muffled behind a
  shut Door by the sound system's rule; its subtitle shows only while this player's camera is within 12 m of the machine
  and within 2 m of its height (the same floor), checked every frame (Q1587); through a shut Door too (Q2552). (ref:
  VP:200-236; TV `earshot`, `level_band`, `comment_db`; Q1586)
- When a comment ends, then it lingers 0.27 s (0.3 of the 0.9 s tail) before the machine is quiet again. (ref: VP:161)
- When the machine is talking and a new line of its own comes, then the new one replaces it (one channel per speaker).
  (ref: VP:85-104)
- The 15 comments, as recorded and corrected (text, length, triggers, mood) (ref: `data/voiceover/stage_*.json`;
  Q1382 "lost socks"; Q1473 "Don't have enough money for a plumber?"):
  - stage_1 A "I don't wanna talk to you!" (1.5 s, stare, angry); B "You feel like you don't have enough to do?" (1.75 s,
    idle, angry); C "Don't you dare to look at me like that!" (1.75 s, stare, angry).
  - stage_2 A "Don't have enough money for a plumber?" (1.75 s, idle, angry); B "Go check out the house, we're not done
    yet." (2.75 s, idle, angry); C "Still don't want to talk to you." (1.75 s, stare, angry).
  - stage_3 A "Oh yeah, purrs like a kitten." (3.5 s, progress, calming); B "Make yourself a coffee or something, man. You
    look worse than I do." (3 s, stare, calming); C "We're getting close, I can feel it!" (1.75 s, progress, calming).
  - stage_4 A "Final stretch. Go check out the attic." (2.75 s, idle, calming); B "Did you know that before electricity,
    people had to wash their clothes with their hands? Like their actual hands? Can you imagine?" (7 s, any, calming);
    C "It's a good thing I was made with the drum in the front. If I had the doors on the top, I'd tell you to throw me
    right away. That's no way to live." (7.5 s, any, calming).
  - stage_5 (D) A "Have you been to the creepy dungeon, I mean cave system full of friendly bats and lost socks yet?"
    (6 s, idle); B "Spinning is one thing, but if I had to walk as much stairs as you, all my buttons would fall off."
    (5 s, any); C "Be careful down there, okay?" (1.5 s, any); all entitled.
  - No line is tagged "hit": a hit plays any line of the set (the fallback above).

### Its cutscenes (the voiced moments)
- When a cutscene plays, then it is the machine's story beat: cutscene_1 when the First wash breaks it (72), cutscene_2 to
  cutscene_5 as each of the four floors' Parts is fitted (71), cutscene_6 after the Final wash's wash (72); the number
  follows the mood (angriest cutscene_1, one calmer per Part). Nothing plays at the run's last Pair (Q1413). (ref:
  VL:144-152; CA:822-827; Q1371)
- Which run each belongs to: cutscene_1 (First wash), _2 filter, _3 motor, _4 drum belt, _6 (Final wash) are batch A's;
  cutscene_5 (the detergent's Fix) leads into the Drum ("...ancient complex cave system...") and the softener's Fix has no
  cutscene of its own (the Drum's spit-out, D). (ref: parts.json; CA:844-848)
- When a cutscene plays, then every player's view cuts to a shared camera on the machine and their input is off; the HUD
  goes; Socks, Pairs, items, Laundry bins and player bodies are not drawn (Q1425, Q1426); it changes nothing in the World
  (Q747). Open menus close; a Guest who joins during it spawns after it at the laundry (Q864). (ref: RI:94-104, :134-172; DG)
- When a cutscene plays, then it opens out of black over 0.5 s and ends with a fade to black over 0.5 s, then everyone
  respawns standing by the machine side by side, every knockdown ended (Q745, Q759, Q817). (ref: RM:163-168, :247-258;
  RI:147-166)
- When a cutscene plays, then its line starts 0.6 s after the shot opens (after the wash part where there is one) and the
  sequence lasts until 0.9 s after the last word, then the fade; flat for everyone at 0 dB, subtitles for all. (ref:
  RM:210-220; TV `lead_in`, `tail`, `cutscene_db`)
- When a cutscene plays, then the music ducks to 0.25 of itself over 0.5 s and back after; comments and other voices do
  not duck it (Q1867, Q2549). (ref: MD:1-30)
- When a cutscene line plays, then the camera holds the wide shot (2.0 m out along the machine's front, 0.95 m up, 0.35 m
  to its right, looking at its middle 0.05 m up, fov 60) for the first subtitle segment, then cuts at each new segment
  between a close shot (0.75 m out from the face, 0.42 m up, 0.06 m to the right, looking at the face 0.57 m up) and the
  wide one (Q1471, Q1472). (ref: RM:351-405; TR; TV `close_shot`, `close_up`)
- When a cutscene has no voice (a missing line, a test), then it holds the wide shot for its fixed length: 5, 5.5, 6.5,
  7.5, 8.5 or 10 s by level. (ref: RM:128-136; TR `seconds`)
- When the Host presses Skip (Space, or the pad's Start), then the cutscene ends for everyone at once; Guests only watch;
  the keycap hint "[Space] Skip" shows at the bottom right on the Host's screen only (Q751, Q862, Q1395). (ref:
  RM:228-244, :482-497)
- When it speaks in a cutscene, then the moods follow the line (Q1383): 1 angry; 2 grudging and angry; 3 surprised,
  turning calm at 3.76 s; 4 surprised, calm at 4.0 s; 5 entitled, surprised at 6.88 s, angry at 9.48 s, entitled at 25.68
  s; 6 surprised, calm at 4 s, entitled at 9 s, surprised at 23 s, entitled at 26 s. (ref: BR:37-45; `data/voiceover/cutscene_*.json`)
- When a cutscene plays, then the sparks and smoke follow its story instead of the mood: their share is 1, 0.8, 0.6,
  0.4, 0.2, 0 for cutscene_1 to _6; on an angry stretch they burst with the voice (0.4 to 1 by its loudness), on any
  other mood they only smoke a little (0.15) (Q1427). (ref: WD:117-157; TB `cutscene_scale`, `cutscene_calm`)
- When a cutscene plays, then the drum light's repair follows the cutscene's level (dim and flickering at cutscene_1,
  healthy at cutscene_6), not the run's mood. (ref: RI:116-125)
- The six cutscene lines, as recorded and corrected (ref: `data/voiceover/cutscene_*.json`; Q1382):
  - cutscene_1 (12 s) "What? What is this? What the? How many socks can one person have? Okay, that's it. I'm done. If
    you ever want to get out of the basement, you first have to learn to take care of me."
  - cutscene_2 (9.25 s) "What? You think a new filter will fix anything? If you ever want to have clean clothes again,
    you gotta find a way to fix me up! So what are we waiting for? Get back to work!"
  - cutscene_3 (22 s) "It's... is that a new engine? Wow! Okay, yeah, that might, that might actually make a difference.
    Pop it in! Okay, the gut pain is gone. Thanks, still though, we've got more work to do go check out the first floor.
    Meanwhile, I'm gonna get used to all this new horsepower."
  - cutscene_4 (15 s) "Whatcha got there friend? Oh, oh wait a minute, is that a new strap? Okay, now we're talking. Put
    that in. I can spin the drum to the speed of light with this thing. Great work, we're getting closer. Just have to
    stay strong and don't give up now."
  - cutscene_5 (29 s) "That's good stuff! Real good stuff! Okay, you can leave that box here with me and I'll take care
    of... Wait... wait... I almost forgot! There's one last thing we're missing. You might not know about it, but this
    house is sitting on an ancient complex cave system. The socks have gone rogue completely and are looking for waste
    out of the house. You can't let that happen! Go check out the dung... eon, uh... cave system, yeah? And see what's
    what, okay?"
  - cutscene_6 (38 s) "You're alive! And you've got the last ingredient! Hey, yeah, awesome! Awesome! Now fill me up and
    stand aside. Oh yeah, baby. That's what I'm talking about. You're a real one, thank you. I'm grateful you willingly
    decided to fix me up rather than return me in that two year warranty time window. What's that? The locked basement
    thing? Let the bargains be bargains. You've accomplished a wonderful thing. I'm proud of you. I'd say we won't have
    to see each other like this again, but knowing how things go, we'll see you in a few months."

### How it talks (the face while a line plays)
- When it is silent, then it keeps its basic pose: neutral brows, no lean, door shut, still; only while it speaks does it
  show the mood pose, the brows' acting and the mouth (Q1436); the share eases in and out over 0.4 s. (ref: WF:55-58, :158)
- When it speaks, then the door opens and shuts with the loudness of the voice (lip sync baked from the recording, Q1372):
  20 ms loudness windows, smoothed, quiet below 8 % of the line's peak keeps it shut, 30 keys a second, shut at the end;
  fully open is 40 degrees on the side hinge. (ref: VO:16-75; MF:53-57)
- When it speaks, then the moods blend over 0.4 s: angry, calming, entitled, surprised; each mood leans the body (on its
  front or back feet) and poses the brows: angry an angry V (tilt 24, down 4 mm), calming flat and lifted, entitled one
  raised smirk (left 12 down 10 mm, right -6 up 52 mm), surprised both raised (Q1374). (ref: BR:24-36; MF:63-78; WF:165-189)
- When it speaks, then the brows act on top of the mood (Q1410): quick flicks on loudness onsets, alternating sides;
  angry furrows deep and lopsided, calming lifts and tilts one brow, entitled raises the right, surprised raises both; a
  line ending with "?" ends raised, a "!" flicks bigger; pauses settle to the mood's pose. (ref: BR:1-20)
- When it speaks, then the body bounces (the `talk` loop) or, when angry, rumbles (the `rumble` loop), only while the
  voice is on: eased in and out over pauses, completely still in pauses and silence (Q1412). (ref: BR:14-15; WF:9; MF:467-484)
- When it speaks, then the light inside the drum comes on in the mood's colour: angry red (1.0, 0.02, 0.005) at 3.0,
  calming orange (1.0, 0.45, 0.12) at 2.0, entitled purple (0.5, 0.06, 1.0) at 2.4 (Q1393), surprised (0.95, 0.8, 0.55) at
  1.2; the colour eases (about a sixth of a second), and the repair dims and flickers it. (ref: WF:213-245; TV `glow`, `light`)
- When it speaks angrily, then a low rumble loops at the machine under the voice, from -36 dB up to -12 dB with the
  anger times the wiggle; it stops when the anger goes. (ref: VP:180-187; TV `rumble_db`; SB `rogue_rumble`, no pick: the
  first synthesised one plays)

### What the face rig carries for others (72)
- When the First wash washes and the Final wash washes, then the drum turns (`spin` loop: the drum a full turn in 30
  frames, the laundry tumbling), 0.8 turns a second in the Final wash, easing to a slow 0.12 during cutscene_6. (ref:
  MF:485-494; RM:334-350; TV `wash_spin`, `after_spin`)
- When the spit starts, then the door swings open over 0.4 s and shuts again over its last 0.6 s. (ref: RM:295-306;
  `data/tuning/first_wash.json` `spit.door_open`, `door_close`)
- When a Laundry bin is loaded, then the laundry pile behind the porthole grows a step (0 hides it, 1 the model's own heap).
  (ref: WF:17-19, :356-400)
- When the First wash washes, then bubbles rise out of the porthole (40, 2.2 s each, small clear spheres) and the
  machine's room light flickers within 4 m once it breaks; the Final wash bubbles too until a second after cutscene_6
  begins. (ref: RM:175-189, :284-289, :500-540)
- When the knockdown wash is played (C or A, see the proposal), then the door is `wash_door`, which takes over the mouth.
  (ref: WF:4-5)

### The knockdown wash (Q2437: waits for the washing machine)
- When a dragger lets go of a knocked-down player's feet within 1.5 m of the door's front, then the body slides in over
  0.35 s and the door shuts; they spin in the drum for 3 s, out of play (no body, nothing to hit, grab or hand to), their
  view spinning in the drum (1.2 turns a second) with the HUD hidden and a sloshing loop; the view fades to black over
  0.4 s at the end. (ref: WS:1-12; TW; SB drum slosh note:449; `game/player/rig_wash.gd`:1-30)
- When the wash ends, then the door bursts open (it stands open 1 s, then swings shut) and they tumble out head first
  (tipped 70 degrees, 2.5 m/s out, 1.5 m/s up, a 0.4 twist), knocked down for 2 s, then get up; the view fades in over
  0.6 s. (ref: WS:1-12; TW)
- When it is washing someone or a cutscene plays, then a body let go at the door just lies there (one at a time, Q758);
  a cutscene's end ends a wash (Q759); a leaver's wash ends too. Not saved. (ref: WS:5-11)
- When an item is put in by the door (a Gift box, the Radio, the Cat), then it spins a load and comes out (C; Gift boxes'
  Secrets are not ported, Q2600). (ref: WS:13-25)

### The voice system as the player meets it (decided Q2545-Q2552)
- When a subtitle shows, then it is the old look: cream text, black outline, bottom centre, now on the Theme, one row per
  speaker talking, with the speaker's icon and no name (Q2550). The old label: font 30, outline 10 at 0.85 black, 160 px
  side margins, on its own layer 26. (ref: VP:248-274)
- When a segment shows, then it is the one begun and not ended, lingering 0.25 s past its end. (ref: VL:82-88)
- When subtitles are off in Options, then no subtitle shows (port: `display/subtitles`, core/58). (ref: VP:171)
- When a voice plays, then it is on the Voice bus with its own volume slider (port: `audio/voice_volume`, Q2549).
- When two speakers would talk at once, then cutscene > washer > Old Tree: the higher cuts the lower, a lower one asked
  meanwhile is dropped, except story beats that wait (Q2548). The Old Tree keeps quiet while the washer talks or a
  cutscene runs (B). (ref: RI:83-85)
- When a line has several takes, then one is picked at random each time it plays (Q2547).

### The old zoo's washer section
- The zoo's Machines tab had "Give a Part" (each Part by name), "Fit my part", "Mood" (From the Fixes, 0 calm .. 5
  angriest) and a "Rogue machine" replay at any level. (ref: `game/debug/zoo/washer_section.gd`:13-29; `game/debug/zoo.gd`:116-117, :1537-1541)

## Dropped or moot (each with its Q)
- The rogue choreography: shake, hop, lunge, spat Socks, alarm, door slam, red pulse and its red glow, the rumble growing
  each floor, the sounds `rogue_slam`, `rogue_alarm` (Q1470; rogue/02 wontfix). The zoo still reached the red glow;
  not ported.
- The sleepy eye at New Game (Q863), moot: the face remodel removed the eye (Q1392).
- The washer as the Upgrade station's model (pipeline/02 note): the Old Tree is the station (Q1508, Q2611).
- Gift box loads and the Rubber Duck Load's squeak (secrets/01): Secrets are not ported (Q2600).
- The "cutscene" Command a line played alone (the old standalone voiced cutscene, `own`): nothing plays a line alone
  since 6_part_1 went (DG "Open"); the port's cutscenes are always a sequence's.

## What was weak in the old washer
- One class did four things: RogueMachine owned the cutscene frame (camera, fades, skip), the First wash's beats, the
  Final wash's beats and the washer's acting, switched by magic levels (`HAPPY = -1`, `FIRST_WASH = -2`) and booleans
  (`intro`, `happy`, `spit_after`, `voiced`). (ref: RM:65-89, :139-190)
- The cutscene line came from a formula on the anger level (`cutscene_for_level`); a reordered run or a new Stage
  silently picks the wrong line or none. (ref: VL:144-152)
- The face was code animation: 30 Hz curves sampled each frame and written to bones, an AnimationTree built in code,
  brows set on the Skeleton after the tree. (ref: WF:21-24, :147-200; VL:20-96)
- Its parts were built in code: the glow light, the bubbles, the sparks, the smoke, the rumble and the overlay. (ref:
  RM:482-540; WD:184-272)
- The comment set was the Stage number spelled in file names (`stage_%d_voice_%s`), probed by `file_exists`; the drum's
  pool by name in tuning; three pickers. (voice-findings 6.1)
- Comments could play before the First wash broke it (the triggers check only that the run is staged), so a stare at the
  machine that looks fine got "I don't wanna talk to you!". (ref: VT:48-52; `game/campaign/laundry.gd`:76-90)
- Voices sat on SFX at +6 dB to make up for quiet clips (peaks near -5.9 dBFS, P109); no slider of their own.
- The cutscene camera's wide shot looked through the decorative Sock heap and a standing player (DG "Open"; the port
  ports the hiding of Socks and bodies, Q1425, Q1426, so it is moot unless a shot is moved).
- The repair state came from two places (the rogue level while a cutscene plays, the mood otherwise). (ref: RI:116-125)
