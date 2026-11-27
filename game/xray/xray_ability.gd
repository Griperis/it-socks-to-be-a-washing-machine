## One X-ray ability (docs/architecture/x-rays.md "The shape"): what differs between the Sock X-ray's
## Show pair and the Cabinet X-ray's Show Cabinet, as data. One `.tres` per X-ray in
## `game/xray/abilities/`: the player's XRays, the HUD's icons and the zoo station's board find every
## file there, so a third X-ray of a kind that exists is a dropped file (plus its Upgrades, stats, input
## action and sounds). A new kind of target is code: one branch of XRay.targets() and a view.
class_name XRayAbility
extends Resource

## What counts as a target while it shows.
enum Shows {
	## the other Sock of each shown loose Sock's Design, wherever it lies, flies or is held
	MATES,
	## the level's Cabinet that takes each shown Sock or Pair
	CABINET,
}

## The input action that uses it (project.godot: key 1, key 2).
@export var action := &"xray_show"
## The Upgrade that unlocks it: the refusal's name and the icon's picture.
@export var upgrade: Upgrade
@export_group("Stats")
## Owning it (FLAG), All-Hands (FLAG), how long it shows and how long it cools down, in seconds.
@export var owned: UpgradeStat
@export var all_hands: UpgradeStat
@export var duration: UpgradeStat
@export var cooldown: UpgradeStat
@export_group("")
@export var shows := Shows.MATES
## Its name ("Show pair"), the Upgrade's short name in "%s not bought" ("X-ray"), and the line when it
## turns on ("Sock X-ray on").
@export var name := ""
@export var short_name := ""
@export var on_text := ""
## Its colour: the glows, the outline, the halo, the arrows, the tint.
@export var colour := Color.WHITE
## The outline its targets wear while it shows (core/183, core/184).
@export var outline: OutlineStyle
## What shows while it is on, instanced under the XRay (core/183, core/184); none: nothing drawn yet.
@export var view: PackedScene
## The key cap under its HUD icon.
@export var key_icon: Texture2D
## The flat sounds when it turns on, when its show ends, and when it is ready again (sound_catalogue.tres).
@export var on_sound := &"xray_on"
@export var off_sound := &"xray_off"
@export var ready_sound := &"xray_ready"
## Its slot in the screen tint (one slot per X-ray).
@export var screen_slot := 0
## Left to right on the HUD and the station's board.
@export var order := 0
