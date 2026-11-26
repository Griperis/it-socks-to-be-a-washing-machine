## The voice bake (core/84, Q2608, Q2639, Q2640, docs/architecture/voice.md "The bake"): for every speaker
## folder of recordings, its lines JSON is checked and completed (a new wav gets a new line), each take is
## timed and given its acting Animation (VoiceLipsync), and the speaker's VoiceBank and the string table are
## written. It stops on an error in a JSON before writing anything, naming the line. Run by
## `tools/voice_bake.sh` (tools/voice_bake.gd); the folders are options so a test can bake a speaker of its own.
class_name VoiceBaker
extends RefCounted

const TODO := "TODO"
const COMMENT := "--"

## The folders and files it reads and writes (`--assets=` and so on).
var assets := "res://assets/voice"
var lines_dir := "res://game/voice/lines"
var speakers_dir := "res://game/voice/speakers"
var triggers_dir := "res://game/voice/triggers"
var baked_dir := "res://game/voice/baked"
var csv := "res://game/voice/voice_lines.csv"
## The speaker a new folder's speaker is copied from.
var template_speaker := "res://game/voice/speakers/washer.tres"
var transcriber := "res://tools/voice_transcribe.py"
var python := "python3"
## Only this speaker (`--speaker=`), else every folder.
var only := ""
var retranscribe := false
var transcribe := true

## What the bake did and what it found, one line each.
var report: PackedStringArray = PackedStringArray()
var errors: PackedStringArray = PackedStringArray()

var _heard := {}
var _whisper_off := ""
var _kps := 30


## Reads `--assets=`, `--lines=`, `--speakers=`, `--triggers=`, `--baked=`, `--csv=`, `--speaker=`,
## `--python=`, `--retranscribe`, `--no-transcribe`. False on an unknown option (named in `errors`).
func parse_args(args: PackedStringArray) -> bool:
	for arg in args:
		var key := arg.get_slice("=", 0)
		var value := arg.substr(key.length() + 1)
		match key:
			"--assets": assets = value
			"--lines": lines_dir = value
			"--speakers": speakers_dir = value
			"--triggers": triggers_dir = value
			"--baked": baked_dir = value
			"--csv": csv = value
			"--speaker": only = value
			"--python": python = value
			"--retranscribe": retranscribe = true
			"--no-transcribe": transcribe = false
			_:
				errors.append("unknown option %s" % arg)
	return errors.is_empty()


## The bake. 0 when every speaker baked, 1 on an error (nothing written).
func run() -> int:
	var plans: Array[Dictionary] = []
	for id: String in _folders():
		var plan := _plan(id)
		if not plan.is_empty():
			plans.append(plan)
	if not errors.is_empty():
		return 1
	for plan: Dictionary in plans:
		_bake(plan)
		if not errors.is_empty():
			return 1
	_write_csv()
	if not _whisper_off.is_empty():
		report.append("transcription skipped (%s): new lines have the text %s; install faster-whisper (tools/voice_transcribe.py) and run with --retranscribe" % [_whisper_off, TODO])
	return 0 if errors.is_empty() else 1


func _folders() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(assets)
	if dir == null:
		errors.append("no recordings folder %s" % assets)
		return out
	for d in dir.get_directories():
		if only.is_empty() or d == only:
			out.append(d)
	out.sort()
	if out.is_empty():
		errors.append("no speaker folder under %s%s" % [assets, "" if only.is_empty() else " named " + only])
	return out


# --- reading and checking ------------------------------------------------------------------------------

## One speaker read and checked: {id, speaker, json, data, changed, wavs}, or {} with `errors` filled.
func _plan(id: String) -> Dictionary:
	var speaker := _speaker(id)
	if speaker == null:
		return {}
	var json := lines_dir.path_join(id + ".json")
	var data := {}
	var changed := false
	if FileAccess.file_exists(json):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json))
		if not parsed is Dictionary or not (parsed as Dictionary).get("lines") is Array:
			errors.append("%s is not a speaker's lines JSON (an object with \"lines\": [...])" % json)
			return {}
		data = parsed
	else:
		data = {"speaker": id, "lines": []}
		changed = true
		report.append("%s: made %s" % [id, json])
	var folder := assets.path_join(id)
	var wavs := _wavs(folder)
	var lines: Array = data["lines"]
	var named := {}
	for line: Variant in lines:
		if line is Dictionary:
			for r: Variant in (line as Dictionary).get("recordings", []):
				named[str(r)] = true
	for wav in wavs:
		if named.has(wav):
			continue
		lines.append(_new_line(folder.path_join(wav), speaker))
		changed = true
		report.append("%s: a new line %s from %s" % [id, wav.get_basename(), wav])
	if retranscribe:
		for line: Variant in lines:
			if line is Dictionary and _retranscribe(line, folder):
				changed = true
	var known := _trigger_ids()
	var ids := {}
	for line: Variant in lines:
		_check(id, line, known, ids, folder, speaker)
	return {"id": id, "speaker": speaker, "json": json, "data": data, "changed": changed, "folder": folder}


func _speaker(id: String) -> VoiceSpeaker:
	var path := speakers_dir.path_join(id + ".tres")
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var s := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as VoiceSpeaker
		if s == null:
			errors.append("%s is not a VoiceSpeaker" % path)
		return s
	var from := load(template_speaker) as VoiceSpeaker
	if from == null:
		errors.append("no %s and no %s to copy it from" % [path, template_speaker])
		return null
	var copy := from.duplicate() as VoiceSpeaker
	copy.id = StringName(id)
	copy.icon = null
	DirAccess.make_dir_recursive_absolute(speakers_dir)
	ResourceSaver.save(copy, path)
	copy.take_over_path(path)
	report.append("%s: made %s from a copy of %s; set its numbers in the inspector" % [id, path, template_speaker])
	return copy


func _wavs(folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(folder)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.get_extension().to_lower() == "wav":
			out.append(f)
	out.sort()
	return out


func _trigger_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(triggers_dir)
	if dir != null:
		for f in dir.get_files():
			f = f.trim_suffix(".remap")
			if f.ends_with(".tres"):
				out.append(f.get_basename())
	out.sort()
	return out


func _new_line(wav: String, speaker: VoiceSpeaker) -> Dictionary:
	var segs := _transcription(wav)
	var text: Array = []
	if segs.is_empty():
		text = [TODO]
	else:
		for s: Dictionary in segs:
			text.append(str(s["text"]))
	return {
		"id": wav.get_file().get_basename(),
		"triggers": [],
		"sets": [],
		"text": text,
		"recordings": [wav.get_file()],
		"moods": [[0.0, String(speaker.default_mood)]] if speaker.acting != null else [],
		"order": 0,
		"waits": false,
		"placeholder": false,
		"note": "",
	}


func _retranscribe(line: Dictionary, folder: String) -> bool:
	var recs: Array = line.get("recordings", [])
	if recs.is_empty():
		return false
	var segs := _transcription(folder.path_join(str(recs[0])))
	if segs.is_empty():
		return false
	var text: Array = []
	for s: Dictionary in segs:
		text.append(str(s["text"]))
	line["text"] = text
	line.erase("timing")
	report.append("line %s: text transcribed again" % line.get("id", "?"))
	return true


func _check(speaker: String, line: Variant, known: PackedStringArray, ids: Dictionary, folder: String,
		s: VoiceSpeaker) -> void:
	if not line is Dictionary:
		errors.append("%s: a line that is not an object" % speaker)
		return
	var d: Dictionary = line
	var id := str(d.get("id", ""))
	var name := "%s line %s" % [speaker, id if not id.is_empty() else "(no id)"]
	var ok_id := RegEx.create_from_string("^[A-Za-z0-9_]+$")
	if ok_id.search(id) == null:
		errors.append("%s: the id must be letters, digits and _" % name)
	elif ids.has(id):
		errors.append("%s: a second line with this id" % name)
	ids[id] = true
	for t: Variant in d.get("triggers", []):
		if not str(t) in known:
			errors.append("%s: unknown trigger \"%s\"; the known ones (game/voice/triggers/): %s" % [name, t, ", ".join(known)])
	var text: Variant = d.get("text", [])
	if not text is Array or (text as Array).is_empty():
		errors.append("%s: \"text\" must be a list of one string a segment" % name)
	var recs: Variant = d.get("recordings", [])
	if not recs is Array or (recs as Array).is_empty():
		errors.append("%s: no recording" % name)
	else:
		for r: Variant in recs:
			if not FileAccess.file_exists(folder.path_join(str(r))):
				errors.append("%s: the recording %s is not in %s" % [name, r, folder])
	var moods: Variant = d.get("moods", [])
	if not moods is Array:
		errors.append("%s: \"moods\" must be a list of [seconds, mood]" % name)
		return
	for m: Variant in moods:
		if not m is Array or (m as Array).size() != 2:
			errors.append("%s: a mood key must be [seconds, mood]" % name)
		elif s.acting == null:
			errors.append("%s: a mood key, but %s has no acting (no moods)" % [name, speaker])
		elif s.acting.mood(StringName(str(m[1]))) == null:
			errors.append("%s: unknown mood \"%s\"; %s's moods: %s" % [name, m[1], speaker, ", ".join(s.acting.mood_ids())])
	for t: Variant in d.get("sets", []):
		if not (t is float or t is int):
			errors.append("%s: a set must be a number" % name)


# --- baking ---------------------------------------------------------------------------------------------

func _bake(plan: Dictionary) -> void:
	var id: String = plan["id"]
	var speaker: VoiceSpeaker = plan["speaker"]
	var data: Dictionary = plan["data"]
	if plan["changed"]:
		DirAccess.make_dir_recursive_absolute(lines_dir)
		var f := FileAccess.open(plan["json"], FileAccess.WRITE)
		f.store_string(VoiceFiles.json_text(data))
		f.close()
	var bank_path := baked_dir.path_join(id + ".tres")
	var old := _old_takes(bank_path)
	var acting_dir := baked_dir.path_join(id)
	if speaker.acting != null:
		DirAccess.make_dir_recursive_absolute(acting_dir)
	var bank := VoiceBank.new()
	bank.speaker = speaker
	var written := {}
	for d: Dictionary in data["lines"]:
		var line := _bake_line(d, speaker, plan["folder"], acting_dir, old, written)
		if line == null:
			return
		bank.lines.append(line)
	bank.lines_md5 = FileAccess.get_md5(plan["json"])
	_save(bank, bank_path)
	var dir := DirAccess.open(acting_dir)
	for f in dir.get_files() if dir != null else PackedStringArray():
		if f.ends_with(".anim.tres") and not written.has(f):
			DirAccess.remove_absolute(acting_dir.path_join(f))
			report.append("%s: removed %s (its recording is gone)" % [id, f])
	report.append("%s: %d lines baked into %s" % [id, bank.lines.size(), bank_path])


func _bake_line(d: Dictionary, speaker: VoiceSpeaker, folder: String, acting_dir: String, old: Dictionary,
		written: Dictionary) -> VoiceLine:
	# A speaker with no acting (the Old Tree's, until its rework, Q2670) gets no acting files: the default
	# profile's loudness window still finds the voiced span a guessed timing needs.
	var acting: VoiceActing = speaker.acting if speaker.acting != null else VoiceActing.new()
	_kps = acting.keys_per_second
	var line := VoiceLine.new()
	line.id = StringName(str(d["id"]))
	line.resource_scene_unique_id = "line_%s" % line.id
	for t: Variant in d.get("triggers", []):
		line.triggers.append(load(triggers_dir.path_join(str(t) + ".tres")) as VoiceTrigger)
	var sets := PackedInt32Array()
	for s: Variant in d.get("sets", []):
		sets.append(int(s))
	line.sets = sets
	var text: Array = d["text"]
	for n in text.size():
		line.keys.append("VO_%s_%d" % [String(line.id).to_upper(), n + 1])
	line.order = int(d.get("order", 0))
	line.waits = bool(d.get("waits", false))
	line.placeholder = bool(d.get("placeholder", false))
	if TODO in text:
		line.marks.append("text TODO")
	var moods: Array = d.get("moods", [])
	if moods.is_empty() and speaker.acting != null:
		moods = [[0.0, String(speaker.default_mood)]]
	moods = moods.duplicate()
	moods.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var timing: Dictionary = d.get("timing", {}) if d.get("timing", {}) is Dictionary else {}
	var recs: Array = d["recordings"]
	for r in recs.size():
		var file := str(recs[r])
		var path := folder.path_join(file)
		var wav := VoiceLipsync.read_wav(path)
		if wav.has("error"):
			errors.append("%s line %s: %s" % [speaker.id, line.id, wav["error"]])
			return null
		var take := VoiceTake.new()
		take.resource_scene_unique_id = "take_%s_%d" % [line.id, r]
		take.stream = _stream(path)
		if take.stream == null:
			errors.append("%s line %s: %s does not load as audio (tools/voice_bake.sh imports it first)" % [speaker.id, line.id, path])
			return null
		take.source_md5 = FileAccess.get_md5(path)
		take.duration = snappedf(float(wav["duration"]), 0.001)
		var door := VoiceLipsync.door_keys(VoiceLipsync.envelope(wav, acting.window), take.duration, acting)
		var times := _times(line, file, path, text, take, door, timing.get(file), old.get(file))
		var segs: Array = []
		for n in text.size():
			var seg := VoiceSegment.new()
			seg.resource_scene_unique_id = "seg_%s_%d_%d" % [line.id, r, n]
			seg.start = times[n].x
			seg.end = times[n].y
			seg.key = StringName(line.keys[n])
			take.segments.append(seg)
			segs.append({"start": seg.start, "end": seg.end, "text": str(text[n])})
		if speaker.acting != null:
			var anim := VoiceLipsync.animation(door, take.duration, segs, moods, speaker.acting)
			var anim_file := file.get_basename() + ".anim.tres"
			_save(anim, acting_dir.path_join(anim_file))
			written[anim_file] = true
			take.acting = anim
		line.takes.append(take)
	return line


## Each segment's (start, end): the JSON's `timing` for this recording, the bank's when the wav is the same,
## the transcription's matched by order, else the voiced span shared by the texts' lengths.
func _times(line: VoiceLine, file: String, path: String, text: Array, take: VoiceTake,
		door: PackedFloat32Array, timing: Variant, old: Variant) -> Array[Vector2]:
	var n := text.size()
	var out: Array[Vector2] = []
	var name := "line %s (%s)" % [line.id, file]
	if timing is Array:
		if (timing as Array).size() == n:
			for t: Variant in timing:
				out.append(Vector2(float(t[0]), float(t[1])))
			return out
		report.append("%s: its timing has %d segments for %d texts; timed again" % [name, (timing as Array).size(), n])
		_mark(line, "keys differ")
	var prev := old as VoiceTake
	if prev != null and prev.source_md5 == take.source_md5 and prev.segments.size() == n and not retranscribe:
		for s: VoiceSegment in prev.segments:
			out.append(Vector2(s.start, s.end))
		return out
	var segs := _transcription(path)
	if segs.size() == n:
		for s: Dictionary in segs:
			out.append(Vector2(float(s["start"]), float(s["end"])))
		return out
	if not segs.is_empty():
		report.append("%s: the transcription has %d segments for %d texts; the timing is guessed" % [name, segs.size(), n])
		_mark(line, "keys differ")
	var span := VoiceLipsync.voiced_span(door, take.duration, _kps)
	var total := 0
	for t: Variant in text:
		total += maxi(1, str(t).length())
	var at := span.x
	for t: Variant in text:
		var len := (span.y - span.x) * float(maxi(1, str(t).length())) / float(total)
		out.append(Vector2(snappedf(at, 0.01), snappedf(at + len, 0.01)))
		at += len
	if n > 1:
		_mark(line, "timing guessed")
	return out


func _mark(line: VoiceLine, what: String) -> void:
	if not what in line.marks:
		line.marks.append(what)


func _stream(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path) as AudioStream if ResourceLoader.exists(path) else null
	return AudioStreamWAV.load_from_file(path)


## The takes of the bank there now, by recording file name.
func _old_takes(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	var bank := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as VoiceBank
	if bank == null:
		return out
	for line: VoiceLine in bank.lines:
		for take: VoiceTake in line.takes:
			if take != null and take.stream != null:
				out[take.stream.resource_path.get_file()] = take
	return out


## The segments of a wav's transcription ([{start, end, text}]), [] without one.
func _transcription(wav: String) -> Array:
	if _heard.has(wav):
		return _heard[wav]
	var segs: Array = []
	if transcribe and _whisper_off.is_empty():
		var out: Array = []
		var code := OS.execute(python, [ProjectSettings.globalize_path(transcriber), ProjectSettings.globalize_path(wav)], out, true)
		var text := "".join(out)
		var parsed: Variant = null
		for row in text.split("\n"):
			if code == 0 and row.begins_with("{\"segments\""):
				parsed = JSON.parse_string(row)
		if parsed is Dictionary and (parsed as Dictionary).get("segments") is Array:
			segs = parsed["segments"]
		else:
			_whisper_off = text.strip_edges().get_slice("\n", 0).left(200) if code != 0 else "no transcription read"
			if _whisper_off.is_empty():
				_whisper_off = "%s exited %d" % [python, code]
	elif not transcribe:
		_whisper_off = "--no-transcribe"
	_heard[wav] = segs
	return segs


## Saves a resource, keeping the uid the file had (the editor's own format, Q2268).
func _save(res: Resource, path: String) -> void:
	var uid := ResourceLoader.get_resource_uid(path) if FileAccess.file_exists(path) else ResourceUID.INVALID_ID
	res.take_over_path(path)
	var err := ResourceSaver.save(res, path)
	if err != OK:
		errors.append("could not write %s (error %d)" % [path, err])
		return
	VoiceFiles.editor_format(path, uid)


# --- the string table -----------------------------------------------------------------------------------

## `keys,en,...`: the English column from every speaker's JSON text, other columns kept for keys that stay.
func _write_csv() -> void:
	var header := PackedStringArray(["keys", "en"])
	var kept := {}
	var f := FileAccess.open(csv, FileAccess.READ) if FileAccess.file_exists(csv) else null
	if f != null:
		var h := f.get_csv_line()
		if h.size() >= 2 and h[0] == "keys":
			header = h
			if not "en" in header:
				header.append("en")
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() > 0 and not row[0].is_empty():
				kept[row[0]] = row
		f.close()
	var en := header.find("en")
	var rows: Array[PackedStringArray] = []
	var dir := DirAccess.open(lines_dir)
	var files := dir.get_files() if dir != null else PackedStringArray()
	files.sort()
	for file in files:
		if file.get_extension() != "json":
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(lines_dir.path_join(file)))
		if not data is Dictionary:
			continue
		for d: Variant in (data as Dictionary).get("lines", []):
			if not d is Dictionary:
				continue
			var text: Array = (d as Dictionary).get("text", [])
			for n in text.size():
				var key := "VO_%s_%d" % [str(d.get("id", "")).to_upper(), n + 1]
				var row := PackedStringArray()
				row.resize(header.size())
				if kept.has(key):
					var old: PackedStringArray = kept[key]
					for c in mini(old.size(), header.size()):
						row[c] = old[c]
				row[0] = key
				row[en] = str(text[n])
				rows.append(row)
	var out := FileAccess.open(csv, FileAccess.WRITE)
	if out == null:
		errors.append("could not write %s" % csv)
		return
	out.store_string(VoiceFiles.csv_row(header) + "\n")
	for row in rows:
		out.store_string(VoiceFiles.csv_row(row) + "\n")
	out.close()
	report.append("%d subtitle keys written to %s" % [rows.size(), csv])
