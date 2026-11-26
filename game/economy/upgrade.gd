## One Upgrade of the Old Tree's grid (docs/architecture/economy.md "How it is authored", Q2613): its
## words, icon, section and cell, a price per level, what it needs, and the stat its levels add to. Its
## id is its file's stem. A designer adds one by dropping a `.tres` into `game/economy/upgrades/`: the
## menu, the zoo's board and the `buy` verb find it there (Upgrades.listed()); one with no `stat` shows
## greyed "Coming soon", seen and not buyable (Q1272, Q2669).
class_name Upgrade
extends Resource

## Which money buys it and whose it is.
enum Section {
	## bought with the buyer's own Coins, theirs alone
	PERSONAL,
	## bought with the team's Drawers, for every player
	HOUSE,
}

## Its name in the menu and the tip card ("Footwork").
@export var title := ""
## The tip card's description.
@export_multiline var tooltip := ""
## The button's picture.
@export var icon: Texture2D
@export var section := Section.PERSONAL
## Its place on its section's grid: x the row, y the column (rows nobody stands in close up).
@export var cell := Vector2i.ZERO
## One price per level (so the level count). Coins for a Personal one, Drawers for a House one.
@export var prices := PackedInt32Array() # placeholder: the old data/upgrades.json prices (House ones re-scaled, Q1405)
## What must be bought first: {Upgrade: the level it must have}. Keyed by Resource, not Upgrade: a
## collection typed with its own class holds this script and it is never freed (reported at quit).
@export var needs: Dictionary[Resource, int] = {}
## The stat its levels add to; empty: its feature is not built and it says "Coming soon".
@export var stat: UpgradeStat
## Hidden and not for sale in single player (Q1357; hosting counts as co-op, Q1399).
@export var coop_only := false
## The key its title names in brackets ("hold Shift", "key 1"); empty: none.
@export var key_hint := ""


## Its id: its file's stem ("sock_smarts").
func id() -> StringName:
	return StringName(resource_path.get_file().get_basename())


## How many levels it has.
func top() -> int:
	return prices.size()


## Its title with the key it names: "Sprint (hold Shift)".
func full_title() -> String:
	return "%s (%s)" % [title, key_hint] if key_hint != "" else title


## Whether it is bought with the team's Drawers.
func is_house() -> bool:
	return section == Section.HOUSE


## The price of level `level` + 1, or -1 at its top.
func price_after(level: int) -> int:
	return prices[level] if level >= 0 and level < prices.size() else -1
