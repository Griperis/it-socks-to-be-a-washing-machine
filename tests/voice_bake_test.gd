## The voice lines' data and the bake (core/84, docs/architecture/voice.md "The bake"). Nothing plays yet
## (core/85), so the real path is the designer's: a wav dropped into a speaker folder and the bake command run
## (VoiceBaker with the command's own options, as `tools/voice_bake.sh` runs it, on a test speaker of its own
## under user://), then the line edited in its JSON and the bake run again. The washer's 21 lines are checked
## as the game loads them (VoiceBook).
extends TestSuite

const FIXTURE := "res://tests/fixtures/voice/tone_pattern.wav"
const ROOT := "user://voice_bake_test"
const SPEAKER := "tester"
const LINE := &"tone_pattern"
## The fixture's tones (tests/fixtures/voice/make_tone_pattern.py): 0.25-0.6 s and 0.85-1.3 s of 1.6 s.
const LOUD: Array[float] = [0.4, 0.5, 1.0, 1.15]
## The silences, late in the gap: the mouth closes with the old release smoothing, not at once.
const QUIET: Array[float] = [0.1, 0.82]
const DURATION := 1.6
## The washer's lines: 15 comments and 6 cutscenes, as the old game recorded them.
const WASHER_LINES := 21
const CUTSCENES := {
	&"cutscene_first_wash": &"cutscene_1", &"cutscene_fix_1": &"cutscene_2", &"cutscene_fix_2": &"cutscene_3",
	&"cutscene_fix_3": &"cutscene_4", &"cutscene_fix_4": &"cutscene_5", &"cutscene_final_wash": &"cutscene_6",
}


func cases() -> Array[Dictionary]:
	return [
		{"name": "drop_and_bake", "method": "case_drop_and_bake", "world": false,
				"title": "real path: a wav dropped into a speaker folder and the bake run gives a new JSON entry and a bank line the VoiceBook lists, its acting opening the mouth on the loud parts and shut at the end"},
		{"name": "edit_survives", "method": "case_edit_survives", "world": false,
				"title": "real path: a hand edit of a line's triggers and text survives a second bake and reaches the bank and the string table"},
		{"name": "unknown_trigger", "method": "case_unknown_trigger", "world": false,
				"title": "an unknown trigger in a line stops the bake, naming the line and the known triggers, and writes nothing"},
		{"name": "stale_bank", "method": "case_stale_bank", "world": false,
				"title": "a JSON edited after its bake is a VoiceBook load error (the bake not run)"},
		{"name": "washer_lines", "method": "case_washer_lines", "world": false,
				"title": "the washer's 21 lines load with no VoiceBook error, every key has text, every take its stream, timing and acting, no take carries a gain"},
		{"name": "washer_triggers", "method": "case_washer_triggers", "world": false,
				"title": "the washer's comments keep the old triggers, sets and moods; each cutscene trigger gives its one old cutscene line"},
	]


func _before_case() -> void:
	_wipe(ROOT)


func _wipe(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_wipe(dir.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


func _args() -> PackedStringArray:
	return PackedStringArray(["--assets=%s/assets" % ROOT, "--lines=%s/lines" % ROOT,
			"--speakers=%s/speakers" % ROOT, "--baked=%s/baked" % ROOT, "--csv=%s/voice_lines.csv" % ROOT,
			"--no-transcribe"])


## The designer drops the wav into the speaker's folder.
func _drop() -> void:
	DirAccess.make_dir_recursive_absolute("%s/assets/%s" % [ROOT, SPEAKER])
	var f := FileAccess.open("%s/assets/%s/%s.wav" % [ROOT, SPEAKER, LINE], FileAccess.WRITE)
	f.store_buffer(FileAccess.get_file_as_bytes(FIXTURE))
	f.close()


## The bake command, with its own options; returns the baker for its report and errors.
func _bake() -> VoiceBaker:
	var baker := VoiceBaker.new()
	_check(baker.parse_args(_args()), "the bake takes its options (%s)" % ", ".join(baker.errors))
	baker.run()
	return baker


func _json() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/lines/%s.json" % [ROOT, SPEAKER]))
	return data if data is Dictionary else {}


func _entry(data: Dictionary) -> Dictionary:
	for line: Dictionary in data.get("lines", []):
		if line.get("id") == String(LINE):
			return line
	return {}


func _book() -> VoiceBook:
	return VoiceBook.load_book(ROOT + "/baked", ROOT + "/lines", ROOT + "/voice_lines.csv")


## The mouth's opening (degrees) at t in a take's acting.
func _mouth(anim: Animation, t: float) -> float:
	var idx := anim.find_track(NodePath("face_rig:door_hinge"), Animation.TYPE_ROTATION_3D)
	if idx < 0:
		return -1.0
	var rest := VoiceActing.new().mouth_rest.basis.get_rotation_quaternion()
	var q := anim.rotation_track_interpolate(idx, t) * rest.inverse()
	return rad_to_deg(q.get_angle())


func case_drop_and_bake() -> void:
	_drop()
	var baker := _bake()
	_check(baker.errors.is_empty(), "the bake ran clean (%s)" % ", ".join(baker.errors))
	_check(FileAccess.file_exists("%s/speakers/%s.tres" % [ROOT, SPEAKER]),
			"a new folder's speaker is made from a copy of the washer's")
	var entry := _entry(_json())
	_check(not entry.is_empty(), "the JSON has a new entry for the dropped wav")
	_same(entry.get("recordings"), [String(LINE) + ".wav"], "the entry names its recording")
	_same(entry.get("triggers"), [], "a new line has no trigger yet")
	_same(entry.get("text"), [VoiceBaker.TODO], "without a transcription its text is TODO")
	var book := _book()
	_check(book.errors.is_empty(), "the VoiceBook loads it clean (%s)" % ", ".join(book.errors))
	var line := book.find_line(&"tester", LINE)
	_check(line != null, "the VoiceBook lists the new line at the next load")
	if line == null:
		return
	_check("text TODO" in line.marks, "the line is marked text TODO for the station")
	_check(line.takes.size() == 1, "one take for its one recording, found %d" % line.takes.size())
	var take := line.takes[0]
	_near(take.duration, DURATION, 0.01, "the take is as long as the wav")
	_check(take.stream != null, "the take has its stream")
	_check(take.segments.size() == 1 and take.segments[0].key == &"VO_TONE_PATTERN_1",
			"one segment keyed VO_TONE_PATTERN_1")
	var seg := take.segments[0]
	_check(seg.start > 0.2 and seg.start < 0.3 and seg.end > 1.25 and seg.end < 1.5,
			"the segment spans the voiced part (%.2f-%.2f s)" % [seg.start, seg.end])
	var anim := take.acting
	_check(anim != null and FileAccess.file_exists(anim.resource_path), "the acting is its own file")
	if anim == null:
		return
	_near(anim.length, DURATION, 0.01, "the acting is as long as the take")
	for t in LOUD:
		_check(_mouth(anim, t) > 20.0, "the mouth is open on the loud part at %.2f s (%.1f deg)" % [t, _mouth(anim, t)])
	for t in QUIET:
		_check(_mouth(anim, t) < 2.0, "the mouth is shut in the silence at %.2f s (%.1f deg)" % [t, _mouth(anim, t)])
	_check(_mouth(anim, DURATION) < 0.01, "the mouth is shut at the end")
	var wig := anim.find_track(NodePath(".:wiggle"), Animation.TYPE_VALUE)
	_check(wig >= 0 and float(anim.value_track_interpolate(wig, 0.5)) > 0.5
			and float(anim.value_track_interpolate(wig, 0.05)) < 0.01, "the body wiggles only while the voice is on")


func case_edit_survives() -> void:
	_drop()
	_bake()
	var data := _json()
	var entry := _entry(data)
	entry["triggers"] = ["washer_idle"]
	entry["text"] = ["Beep boop."]
	var f := FileAccess.open("%s/lines/%s.json" % [ROOT, SPEAKER], FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ", false))
	f.close()
	var baker := _bake()
	_check(baker.errors.is_empty(), "the second bake ran clean (%s)" % ", ".join(baker.errors))
	entry = _entry(_json())
	_same(entry.get("triggers"), ["washer_idle"], "the edited triggers survive the second bake")
	_same(entry.get("text"), ["Beep boop."], "the edited text survives the second bake")
	var book := _book()
	_check(book.errors.is_empty(), "the VoiceBook loads it clean (%s)" % ", ".join(book.errors))
	var line := book.find_line(&"tester", LINE)
	_check(line != null and line.has_trigger(&"washer_idle"), "the bank line has the edited trigger")
	_check(line != null and line.marks.is_empty(), "the text is no longer marked TODO")
	_check(book.lines_for(&"tester", &"washer_idle").size() == 1, "the VoiceBook groups it under its trigger")
	var texts := VoiceBook.read_csv_english(ROOT + "/voice_lines.csv")
	_same(texts.get("VO_TONE_PATTERN_1"), "Beep boop.", "the string table has the edited text")


func case_unknown_trigger() -> void:
	_drop()
	_bake()
	var bank := ROOT + "/baked/tester.tres"
	var before := FileAccess.get_md5(bank)
	var data := _json()
	_entry(data)["triggers"] = ["washer_idle", "no_such_trigger"]
	var f := FileAccess.open("%s/lines/%s.json" % [ROOT, SPEAKER], FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ", false))
	f.close()
	var baker := VoiceBaker.new()
	baker.parse_args(_args())
	_check(baker.run() == 1, "the bake stops")
	var said := "\n".join(baker.errors)
	_check(said.contains("tone_pattern") and said.contains("no_such_trigger") and said.contains("washer_stare"),
			"the error names the line, the trigger and the known ones: %s" % said)
	_same(FileAccess.get_md5(bank), before, "the bank is not rewritten")


func case_stale_bank() -> void:
	_drop()
	_bake()
	var data := _json()
	_entry(data)["text"] = ["Edited, not baked."]
	var f := FileAccess.open("%s/lines/%s.json" % [ROOT, SPEAKER], FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ", false))
	f.close()
	_expect_error("run tools/voice_bake.sh")
	var book := _book()
	_check(book.errors.size() == 1 and book.errors[0].contains("older than"), "one load error: %s" % ", ".join(book.errors))


func case_washer_lines() -> void:
	var book := VoiceBook.load_book()
	_check(book.errors.is_empty(), "no VoiceBook error (%s)" % ", ".join(book.errors))
	var lines := book.lines_of(&"washer")
	_check(lines.size() == WASHER_LINES, "the washer has %d lines, found %d" % [WASHER_LINES, lines.size()])
	var texts := VoiceBook.read_csv_english(VoiceBook.CSV)
	for prop: Dictionary in VoiceTake.new().get_property_list():
		var name := String(prop["name"]).to_lower()
		_check(not name.contains("gain") and not name.contains("db") and not name.contains("volume"),
				"a take has no level field (%s)" % name)
	for line in lines:
		_check(not line.keys.is_empty(), "%s has subtitle keys" % line.id)
		for key in line.keys:
			_check(not String(texts.get(key, "")).is_empty(), "%s has text in the string table" % key)
		for take in line.takes:
			_check(take.stream != null and take.acting != null, "%s's take has its stream and acting" % line.id)
			_check(take.segments.size() == line.keys.size(), "%s's take has a segment per key" % line.id)
			_near(take.acting.length if take.acting != null else 0.0, take.duration, 0.001,
					"%s's acting is as long as its take" % line.id)


func case_washer_triggers() -> void:
	var book := VoiceBook.load_book()
	var stage_1_a := book.find_line(&"washer", &"stage_1_voice_A")
	_check(stage_1_a != null and stage_1_a.has_trigger(&"washer_stare") and stage_1_a.sets == PackedInt32Array([1]),
			"stage_1 A is a stare comment of set 1")
	_same(VoiceBook.read_csv_english(VoiceBook.CSV).get("VO_STAGE_2_VOICE_A_1"), "Don't have enough money for a plumber?",
			"the corrected text (Q1473)")
	var any := book.find_line(&"washer", &"stage_4_voice_B")
	for t: StringName in [&"washer_stare", &"washer_progress", &"washer_hit", &"washer_idle"]:
		_check(any != null and any.has_trigger(t), "the old untagged stage_4 B fits %s" % t)
	for trigger: StringName in CUTSCENES:
		var got := book.cutscene_lines(trigger)
		_check(got.size() == 1 and got[0].id == CUTSCENES[trigger], "%s gives %s" % [trigger, CUTSCENES[trigger]])
	var c5 := book.find_line(&"washer", &"cutscene_5")
	_check(c5 != null and c5.takes.size() == 1 and c5.takes[0].segments.size() == 8, "cutscene_5 is whole, its eight segments")
	var angry := c5.takes[0].acting.find_track(NodePath(".:angry"), Animation.TYPE_VALUE) if c5 != null else -1
	_check(angry >= 0 and float(c5.takes[0].acting.value_track_interpolate(angry, 1.0)) < 0.01
			and float(c5.takes[0].acting.value_track_interpolate(angry, 15.0)) > 0.99,
			"cutscene_5's acting is entitled, then angry from 9.48 s (Q1383)")
