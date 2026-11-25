> Draft behaviour list for batch B's piece Stage presents, Gifts, Collections unlocking and the encyclopedia
> (core/121), written from the reference on 2026-11-25; for the designer to approve. The proposal built on it:
> `docs/architecture/gifts.md` (its choices are core/121's Open follow-ups G1-G6).

# Batch B piece: Stage presents, Gifts, Collections and the encyclopedia

Draft behaviour list (catalogue B25 Gifts and Stage presents, B52 Gifts and milestones; digest-progression sections 4,
5, 9 and 13). Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short forms:
GI = `game/campaign/gifts.gd`, GV = `game/campaign/gift_view.gd`, GP = `game/campaign/gift_preview.gd`, CA =
`game/campaign/campaign.gd`, CB = `game/campaign/cabinets.gd`, ST = `game/campaign/stages.gd`, PR =
`game/player/profile.gd`, PI = `game/player/profile_installer.gd`, CPO = `game/campaign/cabinet_pools.gd`, EV =
`game/campaign/encyclopedia_view.gd`, BK = `game/campaign/book.gd`, BM = `game/campaign/book_menu.gd`, BV =
`game/campaign/book_view.gd`, FR = `game/campaign/final_record.gd`, ES = `game/ui/ending_screen.gd`, TS =
`game/ui/title_screen.gd`, PRM = `game/ui/prompts.gd`, RC = `game/player/rig_click.gd`, RA = `game/player/rig_aim.gd`,
OTV = `game/audio/old_tree_voice.gd`, JN = `game/net/join.gd`, SI = `game/audio/sound_installer.gd`, T:<name> =
`data/tuning/<name>.json`, CP = `data/cabinet_pools.json`, VO = `data/voiceover/old_tree/`, SND = `data/sounds.json`,
D = `docs/migration/digests/digest-progression.md`. Every number under T: is a placeholder in the old game too.

Marks: "(economy)" a line whose other side is core/120's (Coins, the Old Tree as a thing and its voice), "(wardrobe)"
core/122's (the pieces, what a player owns and wears, the Profile's file and its Lifetime tallies), "(batch C)" a
line of a later batch, listed so nothing is lost. Not ported at all: the Lost Sock Grotto (Q2599: so the Lost Socks
Collection has no Cabinet spot, choice G3), a Gift box loaded into the washer's drum and the Secret boxes (Secrets
are not ported, Q2600; GI:278-288, PRM:42), wash cycles and the data "modes" that stood in for them
("simple_everywhere", Q1464; wash cycles dropped for good, Q2602), Hampers' spots kept clear (Q2599; CA:122-127).
Dropped before v0.1.1 and not ported: the Cabinet gift batches and the whole-Collection big gift with its Coins bonus
(Q1590, Q1602), the boxes beside each player and walk-up pick with E (Q703, Q715), the co-op fifth gift (Q691), the
Collection-complete banner, rosette, confetti, fanfare and star (Q1602; the fanfare files stay, Q1610), choosing
Cabinets by hand (Q1623), the hall Cabinet (Q1438).

## Behaviour list

### When presents come
- When a Stage completes, then every player in the Session at that moment gets one present for each Collection the
  team completed during that Stage (solo: one player), themed by that Collection; none completed, no present: no
  minimum and no extra Stage present. (ref: CA:136-165, CA:522-527, GI:121-140; Q1944, Q1948; choice G6 because the
  first Stage can complete no Collection)
- When a Collection completes during a Stage (its Cabinet has every Drawer unlocked and full, or every Design of it
  in play is shelved), then it is noted for that Stage once, in the order completed, and the list empties when the
  next Stage begins. (ref: CB:61-69, CB:311-316, ST:57-60, ST:157; Q1230)
- When a Collection completes, then there is no banner, no confetti and no Coins bonus; only the completer's pad
  buzzes ("done") and every player's Lifetime "Collections completed" tally counts it (wardrobe). (ref: SI:38-40,
  PI:20; Q1602)
- When a full Cabinet's Rows fill, then it still pays its Coins bonus (economy) and drops no present. (ref: CA:93-104,
  CA:620-624; Q1590, Q1602, Q2619)
- When a player joins after a Stage completed, then they are owed nothing from it; a player who leaves keeps their
  presents lying under the tree. (ref: CA:142-145; Q1603)
- When the run ends (the Final screen, Continue, a New Game), then unopened presents are lost; nothing opens by itself.
  (ref: CA:188; Q1601)

### What is inside
- When a present is drawn, then its piece is one of that Collection's Wardrobe pieces (six per Collection: two hats,
  two clothes, a Socks piece, a Trail; wardrobe) that the player neither owns nor has waiting in another box, a rare
  one weighing 0.25 against 1 for the others, so a rare is likelier as fewer are left and certain when only rares
  remain. (ref: GI:79-113, GI:127-140; T:gifts rare_weight, pieces; Q1590, Q1599)
- When the player already owns (or has waiting) every piece of that Collection, then the present holds any piece of
  it at random and opening it pays Coins instead (75). Choice G1 (Q1609 "for now, not final"; Q1834 never answered).
  (ref: GI:132-136, CA:694-702; T:gifts refund; Q635, Q673, Q677)
- When a Collection has no pieces, then it gives no present (every Collection got pieces made: no fallback). (ref:
  GI:116-118; Q1600)
- When the Host draws, then it knows each Session player's owned pieces from their Profile, sent when they join, and
  grows the list as they open presents. (ref: GI:29-33, GI:71-76, JN:37-39; wardrobe)

### The presents under the Old Tree
- When presents are dropped, then they lie in a loose heap at the Old Tree's south foot: the heap's centre is the first
  of the tree's spots whose floor disc (0.4 m, or the heap's own radius if bigger) is clear of walls, furniture and
  Cabinets; the boxes take the free spots of a hex grid 0.42 m apart turned at random, nearest the centre first, at
  least 0.9 x 0.42 m from any box already lying, each nudged up to 5% at random. (ref: CA:118-133, GI:143-226;
  T:gifts tree_pile, tree_spots, apart; Q703, Q705, Q1605)
- When a box appears, then it pops in from 1.4 m above, falling in 0.5 s with a bounce, and bursts 18 specks of its bow
  colour where it lands (size 0.05, speed 1.4, 0.6 s); no sound. (ref: GV:19-20, GV:84-92)
- When a box lies, then it turns on the spot at 1.2 rad/s, bobs up to 4 cm (0.04 x (0.5 + 0.5 sin(2.4 t + id))), starts
  turned (id mod 7) x 0.4 rad, glows on the floor (a soft radial disc 2.6 box sizes across in its bow colour lightened
  35%, alpha 0.75) and sends up sparkles (10 specks of 0.035, 1.2 s, rising at 0.25 m/s2 within 0.8 box sizes). (ref:
  GV:21-24, GV:175, GV:193-219, GV:357-376; Q689, Q705)
- When a box is shown, then it is a wrapped gift 0.3 m across (body 0.82 of that high), a ribbon cross 0.18 wide and a
  lid a little wider (1.06) with the ribbon over it and a bow of two loops and a knot on top; its paper is the
  Collection's paper colour with the Collection's icon as a repeating pattern in its ink colour (2 tiles a face,
  strength 0.85), its ribbon and bow the Collection's bow colour; a Collection without its own wrapping takes its own
  colour (paper lightened 35%, ink darkened 25%). (ref: GV:126-192, GV:133-161; T:wrapping; Q689, Q1591, Q1611; the
  box is built in code today, a model or scene in the port, Q2178)
- When a box lies in co-op, then it carries the name of the player it is for, in their colour, floating 0.28 m over
  it (billboard, font 40, outline 10, pixel 0.004, text the colour lightened 25%, outline darkened 60%), hidden while
  carried; solo boxes have no label. (ref: GV:45, GV:104-111, GV:255-268; Q704)
- When a box lies, then only the player it is for can aim at it (outlined, nearest wins as any aimed thing) and pick
  it up; a Teammate's box is not aimable. (ref: CA:168-182, RA:50-62; Q704)

### Picking up and carrying
- When a player left-clicks their own lying box with empty Hands, then they pick it up: it takes the whole Hands,
  rides in front of them (body frame, 0.95 m up, 0.5 m out), its glow, sparkle and label off; a "pick" cue plays.
  (ref: RC:55-59, CA:663-691, GV:96-113; T:hold gift; Q715)
- When their Hands are not empty, then the pick is refused with "Hands full". (ref: CA:675-680, CA:690-691; Q715)
- When a player carries a box, then one box at a time; a right click puts it down where the crosshair is (it lands on
  what is under it, turned as held, eased from the hand), "Can't drop there" where it may not, and a "drop" cue; the
  corner hint reads "Drop [RMB]". It is never thrown and never handed to a Teammate. (ref: CA:755-776, PRM:100-101,
  GV:112-113; Q1125)
- When a player carrying a box leaves, then it lies where they were; a save keeps a carried box laid where it would
  lie. (ref: GI:266-270, GI:278-293; Q928)
- When a box lies anywhere (put down elsewhere), then it keeps turning, glowing and labelled, still only its player's.
  (ref: GV:96-113)

### Opening and the reveal
- When a player carrying their box left-clicks again, then it opens: the Host decides the piece is theirs (new) or
  pays the refund (already owned). (ref: RC:55-56, CA:694-707, CA:645-659; Q715, Q677)
- When a box opens, then on every machine but the opener's it shakes where it is (with its carrier): a wobble at 5 Hz
  quickening by 3 Hz over the shake (1.0 s), rocking from 0.04 to 0.3 rad by 70% of it, then a crouch (squash to 0.85),
  a hop 0.45 box sizes high that settles in the air and lands square; then it pops: the lid flies up and tumbles
  (0.3 s), the box shrinks away and 28 specks of its bow colour burst (0.7 s); its glow goes at the pop. A "gift_rattle"
  plays at the box (three synthesised candidates, the first plays; no pick yet). (ref: GV:25-36, GV:271-355, SND:452-456;
  T:gifts shake; Q987)
- When the opener opens, then their own box in the world vanishes (only its rattle plays there) and the reveal shows
  on their screen alone: the same box (1.6 x, yaw 0.5) shakes and pops in a 520 x 520 stage raised 40 px over the
  middle (camera 1.75 m in front, 0.3 up, fov 36), then the piece pops in (0.35 s, overshoot ease) on a turntable at
  1.6 rad/s, fitted to 0.62 m: a hat or clothes as its 3D model, a Socks piece as the leg Socks on bare feet in the
  opener's colour, a Trail as a live sample stepping (turning 0.5 rad/s, tipped -0.6 rad). (ref: GP:1-12, GP:16-36,
  GP:63-117, GP:157-206, GP:228-250; Q716, Q717; wardrobe for the piece's preview)
- When the piece shows, then three lines stand under it: its name (44 px), its Rarity (24 px, "Rare"), and "New in your
  Wardrobe" or "Already yours: +75 Coins" (28 px); white with an outline in its bow colour darkened 60%, 170 px over the
  bottom. (ref: GP:101-114, GP:268-277; Q677, Q716)
- When the reveal shows, then it stays 3.0 s after the pop; any click or pad face button then closes it and does
  nothing else; a click during the shake does nothing and goes no further; the player can walk the whole time; a new
  reveal replaces one still open. (ref: GP:228-266; T:gifts preview; Q718)
- When a box opens, then a "pick" cue plays for the opener (placeholder: "the gift's own sound is a follow-up").
  (ref: CA:656)
- When a new piece is opened, then it is the opener's for good, in their Profile, and the Wardrobe offers it
  (wardrobe); a refund flies into their Coins as a bonus (economy). (ref: PI:27-38, CA:645-659; Q677)
- When a present is opened, then the run's record counts a Gift opened and, for a new piece, the piece won by that
  player; the Final screen shows each player's pieces in their column and "Gifts opened" and "Wardrobe pieces won" in
  the totals. (ref: FR:18-23, FR:43-46, ES:199, ES:232, ES:368-372, ES:421-442; port: run-ends.md "RunRecord", "Totals")
- When a present is taken while the player stands near the Old Tree, then the tree may say a "present_taken" line;
  when new presents lie for a player, the first time they come near it says a "presents_ready" line, and after 240 s
  near with one still waiting a "presents" line; positional, near only, no house-wide call and no HUD hint (economy:
  the tree's voice). Lines: "I got some presents for you." and two variants; four "presents"; four "present_taken".
  (ref: OTV:148-150, OTV:272-284, OTV:295-300; T:old_tree presents_nag_seconds; VO tree_presents*,
  tree_present_taken*; Q1592, Q1593, Q1666, Q1667)
- When a Machine Part pops out in front of a Cabinet, then its spot moves to the nearest free hex spot clear of any box
  lying there (0.42 m apart). (ref: CA:439-479; batch A carried item, core/79)

### Collections unlocking
- When a first game is played, then nine Collections are unlocked: Simple, Sport, Lost Socks, Patterns, Animals,
  Superhero, Winter, Nature, Food. (ref: CP start; PR:41-45; Q1439)
- When a game is finished (the Final wash), then every player in it unlocks the next Collection in their own Profile,
  one a game, in the fixed order Space, Fruit, Machinery, Drinks, Tech, Vegetables, Transport, Math; none once all are
  unlocked. (ref: CP unlock, CPO:129-143, PI:63-79; Q1440, Q1465)
- When a Collection unlocks, then the Final screen shows a strip: "New Collection unlocked" (plural for more) with the
  Collection's icon (96 px) and name under it, each popping in after the totals (0.6 s delay, 0.5 s pop with an
  overshoot, 0.25 s apart, a sparkle and a "pop" cue each); a skip shows them at once. (ref: ES:655-731; Q1466)
- When a New Game starts, then each Cabinet spot draws its Collection at random from its pool, only from the Host's
  unlocked Collections, never the same Collection twice, solving the shared pools so every spot is filled (laundry
  Simple; garage Machinery, Transport, Sport, Tech; kitchen Fruit, Vegetables, Drinks, Food; living room Patterns;
  kids' room two of Animals, Nature, Superhero, Space, Math; attic two of Winter, Space, Nature, Tech); the draw is
  kept in the World. (ref: CP modes.normal.pools, CPO:193-262; Q1437, Q1440; port: Q2618 kept the placed ones for
  batch A)
- When the pools cannot be filled (too few unlocked Collections), then it is an error that names why. (ref:
  CPO:164-192; Q1437)
- When a Cabinet spot is drawn, then only the run's Collections exist in it: their Cabinets, Rows, Stage bars and
  Stage Socks; an undrawn Collection has no Socks. (ref: Q1228; port: Stages spawns only unlocked Cabinets' Designs)
- When a Cabinet should stay hidden past its floor (the garage's, until Stage 1 completes), then it does by the
  spot's setting. (ref: CP modes.normal.hidden_until; Q1463, Q1467; port: `Cabinet.unlock_stage`, built)
- When the zoo is used, then any Collection's unlock can be switched. (ref: Q1441)

### The encyclopedia
- When a Pair is shelved in a Cabinet by anyone in a game a player is in, then its Design enters that player's
  encyclopedia, once, for good, counted on their own machine; a World loaded adds its shelved Designs; a Guest who
  joins mid-game records only what is shelved after they join. (ref: PR:38-40, PR:111-121, PI:16-19, PI:51-60;
  Q1153, Q1197)
- When the encyclopedia shows, then it is one page per unlocked Collection in catalogue order (a locked one is hidden
  entirely), Lost Socks included, the Dirty Collection never; a Collection over 50 Designs takes several pages. (ref:
  EV:1-7, EV:80-90; Q1161, Q1163, Q1441)
- When a page shows, then its Collection's icon (48 px) and name stand at the top ("Simple (1/3)" on a Collection of
  several pages), the count "37 / 130" beside it, "<" and ">" arrows (80 px wide) at the sides that wrap round; the
  Designs in a 10 x 5 grid of 150 x 124 px cells, small first, then medium, then large, catalogue order inside a Size;
  a collected Design drawn as its Sock (fitted to 0.34 m, 400 px a metre) with its name (14 px), an uncollected one a
  dark-brown silhouette named "???"; every cell has its Size badge (S/M/L, 17 px) in its corner; shared names carry
  their colour ("Big acorn (navy)"). (ref: EV:10-25, EV:91-128, EV:179-228; Q1161, Q1196, Q1198, Q1199)
- When the title's Home page shows, then a 72 x 72 icon key ("menu_encyclopedia", tooltip "Sock encyclopedia") stands
  in the bottom-right corner left of the Licence's and opens the encyclopedia page. (ref: TS:3, TS:86-87, TS:207-212;
  Q1158, Q1195; port: Q2562 "the encyclopedia key comes later")
- When a game is played, then one shared book lies on the workshop's workbench at a New Game; a player left-clicks it
  into empty Hands (the crosshair row "Sock Encyclopedia [LMB]"), where it fills one Hands slot; E ("Read") opens its
  pages, the reader's own Profile, on their own machine; the player is frozen and the mouse free while it is open,
  the world runs; the arrows, A / D or Left / Right turn pages; E or Esc closes it, and it closes by itself when the
  book leaves the Hands. A right click puts it down ("Drop"), into a Teammate's empty Hands when aimed at one; it is
  never thrown, even with Throw bought. One book, saved where it lies, in the join snapshot. Choice G4 (when).
  (ref: BK:1-9, BK:22, BM:1-7, BV:1-52, PRM:11-12, PRM:59-61, PRM:91-94, RC:78-79, RC:124-126; Q1162, Q1195, Q1267,
  Q1268, Q1274-Q1276; the book's model: `assets/encyclopedia_book/`; it rides the Elevator: batch C)

### Saves and co-op
- When a World is saved, then the presents lying (each one's player, piece, Collection, where it lies and its turn;
  a carried one laid where it would lie), the Collections completed this Stage, each Cabinet spot's drawn Collection,
  the book's place and the run's record of Gifts and pieces are in its file and the join snapshot. (ref: GI:278-306,
  ST:206-230, FR:1-6, BK:1-9)
- When a player's Profile is saved, then it holds their encyclopedia (the Design ids) and their unlocked Collections,
  beside their pieces (wardrobe); it travels with them into any game. (ref: PR:31-45, PR:88-100)
- When anything of the presents changes, then the Host decides and every machine shows the same, except the reveal,
  which only the opener sees. (ref: GI:10-11, GV:6-12)

### Words
- The old placeholder wording: "Already yours: +%d Coins", "New in your Wardrobe", "Hands full", "Can't drop there",
  "Drop", "Sock Encyclopedia", "Read", "Sock encyclopedia" (the key's tooltip), "???", "%s (%d/%d)", "%d / %d", "New
  Collection unlocked", "New Collections unlocked", "Gifts opened", "Wardrobe pieces won". (ref: GP:113, CA:690, PRM:12,
  PRM:92, PRM:101, TS:209, EV:112-122, ES:232, ES:660, ES:677)

## What was weak in the old piece
- The boxes were built in code (cubes, a code gradient, code particles; GV:126-252) and tweened by hand each frame
  (GV:293-376): nothing to open in the editor (Q2178: models or scenes).
- The heap's spot was searched in code from 13 offsets round the tree, clear of colliders, Cabinets and the Hampers'
  spots (CA:118-133, T:gifts tree_spots): a hand-placed spot would do.
- Gifts were plain shared World data on one `Gifts` object with their own save rows, picked and put down by their
  own verbs (CA:663-776), beside the generic carried things.
- The Host took each Guest's owned pieces from their join, unchecked (JN:37-39).
- A duplicate pays Coins "for now, not final" since Q1609; the better answer (Q1834) was never given.
- No hint says a left click opens a carried box (only "Drop [RMB]", PRM:100-101; ticket 27's keycaps were never
  answered); the open plays the generic "pick" (CA:656) and the rattle was never picked (SND:452-456).
- The first Stage can complete no Collection (its only Cabinet, Simple, needs six Drawers), so the first presents come
  after Stage 2: Q1948's premise ("players must complete Collections to proceed") holds only from Stage 2 on.
- The Lost Socks' pieces came only from its Grotto Cabinet; without the Grotto (Q2599) they cannot be had.
- The wrapping colours sat in their own tuning file apart from the Collection's data (T:wrapping); a Collection's
  colour, name, icon and Cabinet name were spread over `designs.json`, the icons and the wrapping.
- The pools, start set and unlock order were a JSON file with modes nobody used once wash cycles went.
- The encyclopedia was drawn by code into one SubViewport (EV:150-228), and the book's menu built its panel in code.
- Each machine counts its own encyclopedia, so two players' records of one game can differ (by design, Q1153).
