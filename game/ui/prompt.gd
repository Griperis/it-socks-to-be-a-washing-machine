## One line the screen prompts (core/15, the old Prompt): what the player sees and presses, as data.
## The Hud draws it as KEY, ICON, Name: the keycaps that do it, an icon between them and the title,
## then the title. No keys and no icon is a plain read-out. `text()` is the same line as plain text,
## for tests (A13).
class_name Prompt
extends Resource

## The words shown ("Open the Door", "Drop / hold: Throw").
@export var title := ""
## The UiIcons key drawn between the keys and the title, or "".
@export var icon := ""
## The keycaps that do it, as UiIcons keys ("key_e", "key_lmb", "pad_a"); empty for a read-out.
@export var keys: Array[String] = []


static func of(title_text: String, key_names: Array[String] = [], icon_key := "") -> Prompt:
	var p := Prompt.new()
	p.title = title_text
	p.icon = icon_key
	p.keys = key_names.duplicate()
	return p


## The line as plain text: "[E] Open the Door", "[LMB] [L]", or the bare title.
func text() -> String:
	if keys.is_empty():
		return title
	var caps := ""
	for k in keys:
		caps += Prompt.cap_text(k)
	return "%s %s" % [caps, title]


## Every field in one string, to see whether a list of Prompts changed (A08).
func signature() -> String:
	return "%s|%s|%s" % [",".join(keys), icon, title]


## A keycap as plain text: "key_lmb" reads "[LMB]", "pad_a" "[PAD_A]".
static func cap_text(key: String) -> String:
	return "[%s]" % key.trim_prefix("key_").to_upper()


## The lines of `prompts` as one plain text, joined by `sep`.
static func joined(prompts: Array[Prompt], sep: String) -> String:
	var parts := PackedStringArray()
	for p in prompts:
		parts.append(p.text())
	return sep.join(parts)


## The lines of `prompts` as one string that changes whenever any of them does.
static func signature_of(prompts: Array[Prompt]) -> String:
	var parts := PackedStringArray()
	for p in prompts:
		parts.append(p.signature())
	return "\n".join(parts)
