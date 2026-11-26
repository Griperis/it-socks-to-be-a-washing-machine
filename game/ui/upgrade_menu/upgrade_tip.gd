## The Upgrade menu's tip card (the old keycap card, UM:551-631): beside the hovered or focused button, in
## its section's colours (`UpgradeTipPersonal` / `UpgradeTipHouse`): the title, the description, the
## "now -> next" numbers, "Level n/m" and the price with its currency's icon (or MAX), "Needs: ..." while
## locked and "Coming soon" while unbuilt. The menu fills and places it.
class_name UpgradeTip
extends PanelContainer

const LEVEL := "Level %d/%d"
const NUMBERS := "%s  ->  %s"
const NEEDS := "Needs: %s"
const NEED_LEVEL := "%s level %d"

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _numbers: Label = %Numbers
@onready var _level: Label = %Level
@onready var _currency: TextureRect = %Currency
@onready var _price: Label = %Price
@onready var _needs: Label = %Needs
@onready var _soon: Label = %Soon

## The Upgrade it shows, or null.
var upgrade: Upgrade = null


## Shows `u` for player `by` of `levels`, paid with `currency`.
func fill(u: Upgrade, levels: Upgrades, by: int, currency: Currency) -> void:
	upgrade = u
	theme_type_variation = &"UpgradeTipHouse" if u.is_house() else &"UpgradeTipPersonal"
	var lv := levels.level(u, by)
	var price := u.price_after(lv)
	_title.text = u.full_title()
	_text.text = u.tooltip
	var nums := numbers_of(u, levels, by)
	_numbers.text = nums
	_numbers.visible = nums != ""
	_level.text = LEVEL % [lv, u.top()]
	_currency.texture = currency.icon if currency != null else null
	_currency.visible = price >= 0
	_price.text = UpgradeButton.MAX_TEXT if price < 0 else str(price)
	var needs := needs_of(u, levels, by)
	_needs.text = needs
	_needs.visible = needs != ""
	_soon.text = UpgradeButton.SOON_TEXT
	_soon.visible = u.stat == null
	reset_size()


## Its lines as plain text (a case reads them).
func lines() -> PackedStringArray:
	var out := PackedStringArray()
	for l: Label in [_title, _text, _numbers]:
		if l.visible:
			out.append(l.text)
	out.append("%s   %s" % [_level.text, _price.text])
	for l: Label in [_needs, _soon]:
		if l.visible:
			out.append(l.text)
	return out


## "x1.10  ->  x1.15": the stat's value for `by` now and after one more level (now alone at the top);
## "" for a stat with no format or none.
static func numbers_of(u: Upgrade, levels: Upgrades, by: int) -> String:
	if u.stat == null or u.stat.format == "":
		return ""
	var at := levels.stat_level(u.stat, by)
	if levels.level(u, by) >= u.top():
		return u.stat.text_at(at)
	return NUMBERS % [u.stat.text_at(at), u.stat.text_at(at + 1)]


## "Needs: Sock Smarts" for what `u` still lacks for `by`, or "".
static func needs_of(u: Upgrade, levels: Upgrades, by: int) -> String:
	var lacking := PackedStringArray()
	for need: Upgrade in u.needs:
		var want := int(u.needs[need])
		if levels.level(need, by) < want:
			lacking.append(need.title if want <= 1 else NEED_LEVEL % [need.title, want])
	return "" if lacking.is_empty() else NEEDS % ", ".join(lacking)
