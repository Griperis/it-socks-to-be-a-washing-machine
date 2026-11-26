## The Achievements' numbers (core/145): the toast's slide and stay, the HUD line of a reward, the shared
## placeholder icon. One `.tres` beside it, edited in the inspector.
class_name AchievementTuning # placeholder: the old design's numbers (Q1695: about 4 s) until the designer sets them
extends Resource

@export_group("Toast")
## How long the card stays in full view between its slide in and its slide out (Q1695: about 4 s).
@export_range(0.5, 20.0, 0.1, "suffix:s") var toast_seconds := 4.0
## How long each slide (in, then out) takes; its clip is played at the speed that makes it this long.
@export_range(0.05, 3.0, 0.05, "suffix:s") var slide_seconds := 0.35
## The picture of an Achievement with no icon of its own (Q1698).
@export var placeholder_icon: Texture2D

@export_group("Reward")
## How long the HUD says "Wardrobe: <name> unlocked" (the old message line's 2 s, old hud.gd:676).
@export_range(0.5, 10.0, 0.1, "suffix:s") var message_seconds := 2.0
