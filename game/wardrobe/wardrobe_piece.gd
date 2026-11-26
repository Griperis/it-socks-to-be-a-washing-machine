## One Wardrobe piece (core/128, docs/architecture/wardrobe.md "The pieces as data"): one `.tres` in
## `game/wardrobe/pieces/`, edited in the inspector, its id the file's name. A designer adds a piece by
## dropping its model, making its Looks and one `.tres` (or duplicating one): no code. `Wardrobe` lists them.
class_name WardrobePiece
extends Resource

## The four slots a player wears one piece each of (any may be empty).
enum Slot { HAT, CLOTHES, SOCKS, TRAIL }
## How rare a piece is (the old names).
enum Rarity { COMMON, UNCOMMON, RARE }

## The player's name for it ("Top hat", "Lint puffs").
@export var name := ""
@export var slot := Slot.HAT
## Its Collection's id (a `SockCollection`), empty for the ten basic pieces.
@export var collection: StringName = &""
@export var rarity := Rarity.COMMON
## Its place among its Collection's (or the basic pieces of its slot): the old gifts.json order.
@export var order := 0
## Its Looks: the hat or clothes model, the Socks pair (`sock_l`, `sock_r`) or the Trail's mark scene.
@export var looks: PackedScene
## How many times a waddle its SwishL / SwishR keys swing (Bee wings 4: a small fast buzz).
@export_range(1, 8, 1) var swish_rate := 1
## Every player owns it from a new Profile on (the ten basic pieces, Q2679).
@export var owned_from_start := false
## Off: not in the Wardrobe's rows or counts unless owned (a stand-in).
@export var listed := true

## The file's name ("top_hat"), set by `Wardrobe` as it loads the folder.
var id: StringName = &""
