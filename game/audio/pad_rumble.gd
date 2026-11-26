## Pad rumble: one cue at a time asked of every connected pad, unless the "pad/rumble" setting (default
## on, the Options menu's later) is off. The cues are the old game's (pad.json), one RumbleCue
## Resource each beside this file. Only the machine that decided the moment asks for it (core/17's rule).
class_name PadRumble
extends RefCounted

## The setting's key and default.
const SETTING := "pad/rumble"
const THROW := preload("res://game/audio/rumble_throw.tres")
const PAIR := preload("res://game/audio/rumble_pair.tres")
## A knockdown, and being grabbed to be dragged (coop/10): the knocked or dragged player's pad only.
const KNOCK := preload("res://game/audio/rumble_knock.tres")
## A Cabinet drawer this player filled (the old "done" cue, Q1556; core/124).
const DONE := preload("res://game/audio/rumble_done.tres")

## The cue last asked for, for a test (a headless run has no pad to shake).
static var last: RumbleCue = null
## How many were asked for since the last reset.
static var asked := 0


## Rumbles every connected pad with `cue`; nothing when the setting is off.
static func play(cue: RumbleCue) -> void:
	if not Settings.get_bool(SETTING):
		return
	last = cue
	asked += 1
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, cue.weak, cue.strong, cue.seconds)


## Forgets what was asked (a test between cases).
static func reset() -> void:
	last = null
	asked = 0
