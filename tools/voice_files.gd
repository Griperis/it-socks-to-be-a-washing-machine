## The text the voice bake writes (core/84): a speaker's lines JSON in the designer's order (one field a row,
## lists on one row, whole numbers without a point), a string table row, and a saved resource put in the editor's
## own format (Q2268).
class_name VoiceFiles
extends RefCounted


## Puts a saved text resource in the editor's own format (Q2268), which a headless run's ResourceSaver does
## not write: its own uid in the header (`uid`, else a new one) and each external resource's uid.
static func editor_format(path: String, uid: int) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	if lines.is_empty() or not lines[0].begins_with("[gd_"):
		return
	if not lines[0].contains(" uid="):
		if uid == ResourceUID.INVALID_ID:
			uid = ResourceUID.create_id()
		lines[0] = lines[0].trim_suffix("]") + " uid=\"%s\"]" % ResourceUID.id_to_text(uid)
	if ResourceUID.has_id(uid):
		ResourceUID.set_id(uid, path)
	else:
		ResourceUID.add_id(uid, path)
	var path_re := RegEx.create_from_string("path=\"([^\"]+)\"")
	for i in lines.size():
		if not lines[i].begins_with("[ext_resource ") or lines[i].contains(" uid="):
			continue
		var m := path_re.search(lines[i])
		if m == null:
			continue
		var ext := ResourceLoader.get_resource_uid(m.get_string(1))
		if ext != ResourceUID.INVALID_ID:
			lines[i] = lines[i].replace(" path=", " uid=\"%s\" path=" % ResourceUID.id_to_text(ext))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()


static func csv_row(row: PackedStringArray) -> String:
	var cells := PackedStringArray()
	for c in row:
		if c.contains(",") or c.contains("\"") or c.contains("\n"):
			cells.append("\"%s\"" % c.replace("\"", "\"\""))
		else:
			cells.append(c)
	return ",".join(cells)


## A speaker's lines as the JSON file: one field a row, lists on one row, numbers as written.
static func json_text(data: Dictionary) -> String:
	var out := "{\n"
	var keys := data.keys()
	for k in keys.size():
		var key: Variant = keys[k]
		var comma := "," if k < keys.size() - 1 else ""
		if str(key) == "lines" and data[key] is Array:
			out += "  \"lines\": [\n"
			var lines: Array = data[key]
			for i in lines.size():
				out += _json_object(lines[i], "    ") + ("," if i < lines.size() - 1 else "") + "\n"
			out += "  ]%s\n" % comma
		else:
			out += "  %s: %s%s\n" % [JSON.stringify(str(key)), _json_value(data[key]), comma]
	return out + "}\n"


static func _json_object(d: Variant, pad: String) -> String:
	if not d is Dictionary:
		return pad + _json_value(d)
	var keys := (d as Dictionary).keys()
	var out := pad + "{\n"
	for k in keys.size():
		out += "%s  %s: %s%s\n" % [pad, JSON.stringify(str(keys[k])), _json_value(d[keys[k]]), "," if k < keys.size() - 1 else ""]
	return out + pad + "}"


static func _json_value(v: Variant) -> String:
	if v is Array:
		var parts := PackedStringArray()
		for x: Variant in v:
			parts.append(_json_value(x))
		return "[" + ", ".join(parts) + "]"
	if v is Dictionary:
		var parts := PackedStringArray()
		for k: Variant in v:
			parts.append("%s: %s" % [JSON.stringify(str(k)), _json_value(v[k])])
		return "{" + ", ".join(parts) + "}"
	if v is float:
		var f: float = v
		if f == roundf(f) and absf(f) < 1e9:
			return str(int(f))
		return str(snappedf(f, 0.001))
	if v is int or v is bool or v == null:
		return JSON.stringify(v)
	return JSON.stringify(str(v))
