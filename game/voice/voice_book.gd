## Every spoken line of the game, built at load from the banks under `game/voice/baked/` (core/84), grouped by
## speaker and trigger. Its load checks are what the bake guards: a bank older than its speaker's JSON (the
## bake not run), a trigger file that is missing, a key with no English text in `voice_lines.csv`. Each is
## one entry of `errors` (and pushed as an error, so a test run fails on it).
class_name VoiceBook
extends RefCounted

const BAKED := "res://game/voice/baked"
const LINES := "res://game/voice/lines"
const CSV := "res://game/voice/voice_lines.csv"

## Speaker id -> its bank.
var banks: Dictionary[StringName, VoiceBank] = {}
## What failed the load checks, one line each.
var errors: PackedStringArray = PackedStringArray()


## Loads every bank in `baked` and checks it against the JSON in `lines` and the string table `csv`. A check
## whose file is not there (an exported game has no JSON or CSV) is skipped.
static func load_book(baked := BAKED, lines := LINES, csv := CSV) -> VoiceBook:
	var book := VoiceBook.new()
	book._load(baked, lines, csv)
	return book


## The speakers that have a bank, sorted.
func speakers() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in banks:
		out.append(id)
	out.sort()
	return out


## Every line of one speaker, in its JSON's order.
func lines_of(speaker: StringName) -> Array[VoiceLine]:
	var out: Array[VoiceLine] = []
	var bank: VoiceBank = banks.get(speaker)
	if bank != null:
		out.assign(bank.lines)
	return out


## The lines of one speaker a trigger may give.
func lines_for(speaker: StringName, trigger_id: StringName) -> Array[VoiceLine]:
	var out: Array[VoiceLine] = []
	for line: VoiceLine in lines_of(speaker):
		if line.has_trigger(trigger_id):
			out.append(line)
	return out


## Every line of every speaker with a cutscene trigger, in `order` (the speakers' priority, then their JSON
## order, break a tie).
func cutscene_lines(trigger_id: StringName) -> Array[VoiceLine]:
	var out: Array[VoiceLine] = []
	for id: StringName in speakers():
		out.append_array(lines_for(id, trigger_id))
	var rank := {}
	for i in out.size():
		rank[out[i]] = i
	out.sort_custom(func(a: VoiceLine, b: VoiceLine) -> bool:
		return a.order < b.order if a.order != b.order else int(rank[a]) < int(rank[b]))
	return out


## The line named `id` of a speaker, or null.
func find_line(speaker: StringName, id: StringName) -> VoiceLine:
	for line: VoiceLine in lines_of(speaker):
		if line.id == id:
			return line
	return null


## Whose line it is, or null for a line of no bank here.
func speaker_of(line: VoiceLine) -> VoiceSpeaker:
	for id: StringName in banks:
		if banks[id].lines.has(line):
			return banks[id].speaker
	return null


func _load(baked: String, lines: String, csv: String) -> void:
	var texts := VoiceBook.read_csv_english(csv) if FileAccess.file_exists(csv) else {}
	var check_keys := FileAccess.file_exists(csv)
	for file: String in _bank_files(baked):
		var path := baked.path_join(file)
		var bank := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP) as VoiceBank
		if bank == null or bank.speaker == null:
			_fail("%s is not a voice bank with a speaker" % path)
			continue
		var id := bank.speaker.id
		banks[id] = bank
		var json := lines.path_join(String(id) + ".json")
		if FileAccess.file_exists(json) and FileAccess.get_md5(json) != bank.lines_md5:
			_fail("%s is older than %s: run tools/voice_bake.sh" % [path, json])
		for line: VoiceLine in bank.lines:
			_check_line(id, line, texts, check_keys)


func _check_line(speaker: StringName, line: VoiceLine, texts: Dictionary, check_keys: bool) -> void:
	var name := "%s line %s" % [speaker, line.id]
	for t: VoiceTrigger in line.triggers:
		if t == null or not ResourceLoader.exists(t.resource_path):
			_fail("%s: a trigger file is missing" % name)
	if line.takes.is_empty():
		_fail("%s has no take" % name)
	if check_keys:
		for key: String in line.keys:
			if String(texts.get(key, "")).strip_edges().is_empty():
				_fail("%s: the key %s has no text in the string table" % [name, key])


func _fail(what: String) -> void:
	errors.append(what)
	push_error("VoiceBook: " + what)


static func _bank_files(baked: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(baked)
	if dir == null:
		return out
	for file: String in dir.get_files():
		var f := file.trim_suffix(".remap")
		if f.ends_with(".tres") or f.ends_with(".res"):
			out.append(f)
	out.sort()
	return out


## The `en` column of a string table, key -> text.
static func read_csv_english(csv: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(csv, FileAccess.READ)
	if f == null:
		return out
	var header := f.get_csv_line()
	var en := header.find("en")
	while en >= 0 and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > en and not row[0].is_empty():
			out[row[0]] = row[en]
	return out
