## One kind of effect an Upgrade has (docs/architecture/economy.md "How it is authored"): a number a
## feature reads through `Upgrades.value()`, from `base` at no level, growing by `kind` and `step` with
## the summed levels of every Upgrade that names it. One `.tres` per stat in `game/economy/stats/`; a
## new kind of effect is a new file plus one line in the feature that reads it. Its numbers are the old
## `data/tuning/upgrades.json` ones, each a placeholder in the old game too.
class_name UpgradeStat
extends Resource

## How the levels change the value.
enum Kind {
	## base + level x step
	ADD,
	## base x (1 + level x step)
	SCALE_UP,
	## base x max(least, 1 - level x step)
	SCALE_DOWN,
	## 1 once any level is bought, else 0
	FLAG,
}

## The value with no level bought (the start in a level with an Upgrades Part).
@export var base := 0.0 # placeholder: the old data/tuning/upgrades.json
@export var kind := Kind.ADD
## How much one level adds (ADD) or scales (SCALE_UP, SCALE_DOWN).
@export var step := 0.0 # placeholder: the old data/tuning/upgrades.json
## The least share SCALE_DOWN keeps of `base`.
@export_range(0.0, 1.0, 0.01) var least := 0.0 # placeholder: the old data/tuning/upgrades.json
## The tip card's "now -> next" format ("x%.2f", "%.2fs", "%d"); empty: no numbers shown.
@export var format := ""


## The value at `level` (the summed levels of the Upgrades naming this stat).
func value_at(level: int) -> float:
	return value_from(base, level)


## The value at `level` grown from `start` instead of `base`: a feature whose level sets its own start
## (the zoo's player holds 3, Q2244) keeps it, and the levels change it by `kind` and `step` (core/130).
func value_from(start: float, level: int) -> float:
	match kind:
		Kind.ADD:
			return start + level * step
		Kind.SCALE_UP:
			return start * (1.0 + level * step)
		Kind.SCALE_DOWN:
			return start * maxf(least, 1.0 - level * step)
		Kind.FLAG:
			return 1.0 if level > 0 else 0.0
	return start


## The value at `level` in the tip card's words ("" with no format).
func text_at(level: int) -> String:
	if format == "":
		return ""
	if format.contains("%d"):
		return format % roundi(value_at(level))
	return format % value_at(level)
