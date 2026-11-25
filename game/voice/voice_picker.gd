## Which line a speaker says, and which take of it (core/85, V3, Q2637): one picker for every speaker, rules
## only. The lines that fit the trigger (and the comment set) come first; a trigger no line has falls back
## to any comment line of the set (the old washer's fallback, so a "hit" plays any line). Never the line said last
## (unless it is the only one: the old game's answer), and each fitting line once before any repeats. A
## picker holds the memory of one speaker; it is not saved (a load starts quiet).
class_name VoicePicker
extends RefCounted

## The dice; a test seeds it.
var rng := RandomNumberGenerator.new()

var _last: VoiceLine = null
## The lines said since the last time every one of the pool had been said.
var _said: Dictionary[VoiceLine, bool] = {}


## {"line": VoiceLine, "take": int} from `lines` (one speaker's) for `trigger` in comment set `comment_set`
## (0: any set), or {} when there is no line to say.
func pick(lines: Array[VoiceLine], trigger: StringName, comment_set := 0) -> Dictionary:
	var of_set: Array[VoiceLine] = []
	var fit: Array[VoiceLine] = []
	for line in lines:
		if not line.has_comment_trigger():
			continue  # a cutscene's line, or one no game moment gives
		if comment_set != 0 and not line.sets.is_empty() and not line.sets.has(comment_set):
			continue
		of_set.append(line)
		if line.has_trigger(trigger):
			fit.append(line)
	var pool := fit if not fit.is_empty() else of_set
	if pool.is_empty():
		return {}
	var choice := _choose(pool)
	_last = choice
	_said[choice] = true
	return {"line": choice, "take": take_of(choice)}


## A take of `line`, at random (Q2547).
func take_of(line: VoiceLine) -> int:
	return rng.randi() % maxi(line.takes.size(), 1)


## Forgets what was said (a new run).
func forget() -> void:
	_last = null
	_said.clear()


func _choose(pool: Array[VoiceLine]) -> VoiceLine:
	var open: Array[VoiceLine] = []
	for line in pool:
		if line != _last:
			open.append(line)
	if open.is_empty():
		return pool[0]  # the only line there is
	var fresh: Array[VoiceLine] = []
	for line in open:
		if not _said.has(line):
			fresh.append(line)
	if fresh.is_empty():
		# Every line of the pool was said: a new round (the last one still stays out).
		for line in pool:
			_said.erase(line)
		fresh = open
	return fresh[rng.randi() % fresh.size()]
