## The bake's acting math (core/84), ported from the old game's `tools/voiceover/voiceover.py` (the door
## curve: loudness windows, smoothed, gated, keyed, ending shut) and `tools/voiceover/brows.py` (the moods'
## lean and brows blended, the brows' flicks on loudness onsets, "?" and "!", the body's wiggle), with the
## numbers on the speaker's VoiceActing. Rules only: the wav's bytes in, an Animation out.
class_name VoiceLipsync
extends RefCounted


## A 16-bit (or 8, 24, 32-bit) PCM wav: {rate, channels, frames, duration, bits, data (the sample bytes)},
## or {error}.
static func read_wav(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 12 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF" \
			or bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return {"error": "%s is not a RIFF wav" % path}
	var at := 12
	var fmt := {}
	var data := PackedByteArray()
	while at + 8 <= bytes.size():
		var id := bytes.slice(at, at + 4).get_string_from_ascii()
		var size := bytes.decode_u32(at + 4)
		var body := at + 8
		if id == "fmt ":
			fmt = {"format": bytes.decode_u16(body), "channels": bytes.decode_u16(body + 2),
					"rate": bytes.decode_u32(body + 4), "bits": bytes.decode_u16(body + 14)}
		elif id == "data":
			data = bytes.slice(body, mini(body + size, bytes.size()))
		at = body + size + (size & 1)
	if fmt.is_empty() or data.is_empty():
		return {"error": "%s has no fmt or data chunk" % path}
	if int(fmt["format"]) != 1 and int(fmt["format"]) != 0xFFFE:
		return {"error": "%s is not PCM (format %d): save it as 16-bit PCM" % [path, int(fmt["format"])]}
	var bits := int(fmt["bits"])
	if not bits in [8, 16, 24, 32]:
		return {"error": "%s has %d-bit samples" % [path, bits]}
	var channels := maxi(1, int(fmt["channels"]))
	var frames := data.size() / (channels * (bits / 8))
	return {"rate": int(fmt["rate"]), "channels": channels, "bits": bits, "frames": frames,
			"duration": float(frames) / float(fmt["rate"]), "data": data}


## The RMS loudness of each `window` s of the wav's mono mix (voiceover.py door_curve).
static func envelope(wav: Dictionary, window: float) -> PackedFloat32Array:
	var data: PackedByteArray = wav["data"]
	var channels: int = wav["channels"]
	var bits: int = wav["bits"]
	var width := bits / 8
	var frames: int = wav["frames"]
	var win := maxi(1, int(int(wav["rate"]) * window))
	var out := PackedFloat32Array()
	var scale := 1.0 / (float(channels) * pow(2.0, bits - 1))
	var frame := 0
	while frame < frames:
		var stop := mini(frame + win, frames)
		var sum := 0.0
		for f in range(frame, stop):
			var mono := 0.0
			var at := f * channels * width
			for c in channels:
				mono += _sample(data, at + c * width, bits)
			mono *= scale
			sum += mono * mono
		out.append(sqrt(sum / float(stop - frame)))
		frame = stop
	return out


static func _sample(data: PackedByteArray, at: int, bits: int) -> float:
	match bits:
		16:
			return data.decode_s16(at)
		8:
			return data[at] - 128.0
		24:
			var v := data[at] | (data[at + 1] << 8) | (data[at + 2] << 16)
			return v - 16777216 if v >= 8388608 else v
		_:
			return data.decode_s32(at)


## The door curve: one key 0-1 a 1/kps s from the smoothed, gated, normalised envelope, plus a last key 0
## (it ends shut). voiceover.py door_curve.
static func door_keys(env: PackedFloat32Array, duration: float, acting: VoiceActing) -> PackedFloat32Array:
	var smooth := PackedFloat32Array()
	var s := 0.0
	for e in env:
		s += (acting.attack if e > s else acting.release) * (e - s)
		smooth.append(s)
	var peak := 0.0
	for v in smooth:
		peak = maxf(peak, v)
	var kps := acting.keys_per_second
	var n := int(ceil(duration * kps)) + 1
	var keys := PackedFloat32Array()
	keys.resize(n + 1)
	keys.fill(0.0)
	if peak <= 1e-6 or smooth.is_empty():
		return keys
	for k in n:
		var idx := mini(smooth.size() - 1, int(float(k) / kps / acting.window))
		var v := smooth[idx] / peak
		v = 0.0 if v < acting.gate else (v - acting.gate) / (1.0 - acting.gate)
		keys[k] = snappedf(minf(1.0, v), 0.001)
	return keys


## The span from the first to the last open key (seconds), or the whole take when it never opens.
static func voiced_span(door: PackedFloat32Array, duration: float, kps: int) -> Vector2:
	var first := -1
	var last := -1
	for i in door.size():
		if door[i] > 0.0:
			if first < 0:
				first = i
			last = i
	if first < 0:
		return Vector2(0.0, duration)
	return Vector2(float(first) / kps, minf(duration, float(last + 1) / kps))


## The take's typical loud level (brows.py loud): one shout can normalise a quiet file low.
static func loud(door: PackedFloat32Array, acting: VoiceActing) -> float:
	var voiced := PackedFloat32Array()
	for v in door:
		if v > acting.voiced:
			voiced.append(v)
	if voiced.is_empty():
		voiced.append(1.0)
	voiced.sort()
	var i := int(voiced.size() * acting.loud_percentile) - 1 if voiced.size() > 1 else 0
	return maxf(acting.loud_floor, voiced[clampi(i, 0, voiced.size() - 1)])


## The times of loudness peaks that rise sharply from a lower level: the stressed syllables (brows.py onsets).
static func onsets(door: PackedFloat32Array, acting: VoiceActing) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var ref := loud(door, acting)
	var kps := float(acting.keys_per_second)
	var back := maxi(1, int(round(acting.onset_lookback * kps)))
	for i in range(back, door.size() - 1):
		var v := door[i]
		var low := v
		for j in range(i - back, i):
			low = minf(low, door[j])
		if v >= acting.onset_level * ref and v > door[i - 1] and v >= door[i + 1] and v - low > acting.onset_rise * ref:
			if out.is_empty() or i / kps - out[out.size() - 1] > acting.onset_gap:
				out.append(i / kps)
	return out


## 0-1 a key: 1 while the voice is on (short gaps bridged), eased in and out (brows.py wiggle, Q1412).
static func wiggle(door: PackedFloat32Array, acting: VoiceActing) -> PackedFloat32Array:
	var kps := float(acting.keys_per_second)
	var n := door.size()
	var h := int(round(acting.wiggle_hold * kps))
	var on: Array[bool] = []
	for v in door:
		on.append(v > acting.voiced)
	var gate := on.duplicate()
	for i in n:
		if on[i]:
			continue
		var before := false
		for j in range(maxi(0, i - h), i):
			before = before or on[j]
		var after := false
		for j in range(i + 1, mini(n, i + 1 + h)):
			after = after or on[j]
		gate[i] = before and after
	var out := PackedFloat32Array()
	var w := 0.0
	var up := 1.0 / (acting.wiggle_ease_in * kps)
	var down := 1.0 / (acting.wiggle_ease_out * kps)
	for g: bool in gate:
		w = minf(1.0, w + up) if g else maxf(0.0, w - down)
		out.append(snappedf(w * w * (3.0 - 2.0 * w), 0.001))
	return out


## [from mood, to mood, weight] at t: each mood key blends in over `mood_blend` s (brows.py _mood_at).
static func mood_at(moods: Array, t: float, blend: float) -> Array:
	var cur := 0
	for k in moods.size():
		if t >= float(moods[k][0]):
			cur = k
	var m: StringName = moods[cur][1]
	if cur == 0:
		return [m, m, 1.0]
	return [StringName(moods[cur - 1][1]), m, minf(1.0, (t - float(moods[cur][0])) / maxf(blend, 0.001))]


## The take's acting Animation: mouth, brows, lean on the rig's bones; wiggle, angry, glow on the Looks.
## `segments`: [{start, end, text}]; `moods`: [[seconds, mood id]] sorted.
static func animation(door: PackedFloat32Array, duration: float, segments: Array, moods: Array,
		acting: VoiceActing) -> Animation:
	var kps := acting.keys_per_second
	var times := PackedFloat32Array()
	var k := 0
	while float(k) / kps < duration - 0.0001:
		times.append(float(k) / kps)
		k += 1
	times.append(duration)
	var peaks := onsets(door, acting)
	var ref := loud(door, acting)
	var wig := wiggle(door, acting)
	var mouth: Array = []
	var brow_l_rot: Array = []
	var brow_l_pos: Array = []
	var brow_r_rot: Array = []
	var brow_r_pos: Array = []
	var lean_rot: Array = []
	var lean_pos: Array = []
	var wiggles: Array = []
	var angry: Array = []
	var glow_c: Array = []
	var glow_e: Array = []
	var glow := Color.BLACK
	var energy := 0.0
	var ease := clampf(acting.glow_ease / kps, 0.0, 1.0)
	var mouth_q := acting.mouth_rest.basis.get_rotation_quaternion()
	for i in times.size():
		var t := times[i]
		var last := i == times.size() - 1
		var di := clampi(int(round(t * kps)), 0, door.size() - 1)
		var open := 0.0 if last else door[di]
		mouth.append(Quaternion(acting.mouth_axis.normalized(), deg_to_rad(acting.mouth_open * open)) * mouth_q)
		var blend := mood_at(moods, t, acting.mood_blend)
		var a := acting.mood(blend[0])
		var b := acting.mood(blend[1])
		var w: float = blend[2]
		var acting_mood := b if w > 0.5 else a
		var d := _brow_acting(t, acting_mood, door, peaks, segments, ref, acting)
		var tilt_l := clampf(lerpf(a.brow_left.x, b.brow_left.x, w) + d[0], acting.tilt_range.x, acting.tilt_range.y)
		var raise_l := clampf(lerpf(a.brow_left.y, b.brow_left.y, w) + d[1], acting.raise_range.x, acting.raise_range.y)
		var tilt_r := clampf(lerpf(a.brow_right.x, b.brow_right.x, w) + d[2], acting.tilt_range.x, acting.tilt_range.y)
		var raise_r := clampf(lerpf(a.brow_right.y, b.brow_right.y, w) + d[3], acting.raise_range.x, acting.raise_range.y)
		var axis := acting.brow_tilt_axis.normalized()
		brow_l_rot.append(Quaternion(axis, deg_to_rad(tilt_l)) * acting.brow_left_rest.basis.get_rotation_quaternion())
		brow_l_pos.append(acting.brow_left_rest.origin + acting.brow_raise_axis * raise_l)
		brow_r_rot.append(Quaternion(axis, deg_to_rad(-tilt_r)) * acting.brow_right_rest.basis.get_rotation_quaternion())
		brow_r_pos.append(acting.brow_right_rest.origin + acting.brow_raise_axis * raise_r)
		var lean := lerpf(a.lean, b.lean, w)
		var turn := Quaternion(acting.lean_axis.normalized(), deg_to_rad(lean))
		var pivot := acting.front_feet if lean >= 0.0 else acting.back_feet
		lean_rot.append(turn * acting.lean_rest.basis.get_rotation_quaternion())
		lean_pos.append(acting.lean_rest.origin + pivot - turn * pivot)
		wiggles.append(0.0 if last else wig[di])
		var share := 0.0
		if a.id == acting.angry_mood:
			share += 1.0 - w
		if b.id == acting.angry_mood:
			share += w
		angry.append(snappedf(share, 0.001))
		var target := a.glow_colour.lerp(b.glow_colour, w)
		var target_e := lerpf(a.glow_energy, b.glow_energy, w)
		glow = target if i == 0 else glow.lerp(target, ease)
		energy = target_e if i == 0 else lerpf(energy, target_e, ease)
		glow_c.append(glow)
		glow_e.append(snappedf(energy, 0.001))
	var anim := Animation.new()
	anim.length = duration
	var rig := String(acting.rig)
	if not acting.mouth_bone.is_empty():
		_track(anim, Animation.TYPE_ROTATION_3D, "%s:%s" % [rig, acting.mouth_bone], times, mouth)
	if not acting.brow_left_bone.is_empty():
		_track(anim, Animation.TYPE_ROTATION_3D, "%s:%s" % [rig, acting.brow_left_bone], times, brow_l_rot)
		_track(anim, Animation.TYPE_POSITION_3D, "%s:%s" % [rig, acting.brow_left_bone], times, brow_l_pos)
	if not acting.brow_right_bone.is_empty():
		_track(anim, Animation.TYPE_ROTATION_3D, "%s:%s" % [rig, acting.brow_right_bone], times, brow_r_rot)
		_track(anim, Animation.TYPE_POSITION_3D, "%s:%s" % [rig, acting.brow_right_bone], times, brow_r_pos)
	if not acting.lean_bone.is_empty():
		_track(anim, Animation.TYPE_ROTATION_3D, "%s:%s" % [rig, acting.lean_bone], times, lean_rot)
		_track(anim, Animation.TYPE_POSITION_3D, "%s:%s" % [rig, acting.lean_bone], times, lean_pos)
	for pair: Array in [[acting.wiggle_property, wiggles], [acting.angry_property, angry],
			[acting.glow_colour_property, glow_c], [acting.glow_energy_property, glow_e]]:
		if not StringName(pair[0]).is_empty():
			_track(anim, Animation.TYPE_VALUE, ".:%s" % pair[0], times, pair[1])
	return anim


## [left tilt, left raise, right tilt, right raise] added by the acting at t (brows.py _acting, Q1410).
static func _brow_acting(t: float, mood: VoiceMood, door: PackedFloat32Array, peaks: PackedFloat32Array,
		segments: Array, ref: float, acting: VoiceActing) -> PackedFloat32Array:
	var kps := acting.keys_per_second
	var i := int(round(t * kps))
	var v := minf(1.0, (door[i] if i >= 0 and i < door.size() else 0.0) / ref)
	var imp := 0.0
	var side := 0
	for p in peaks.size():
		var dt := t - peaks[p]
		if dt >= -acting.flick_attack and dt < acting.flick_length:
			var e := (dt + acting.flick_attack) / acting.flick_attack if dt < 0.0 else exp(-dt / acting.flick_decay)
			if e > imp:
				imp = e
				side = p % 2
	var seg := {}
	for s: Dictionary in segments:
		if float(s["start"]) <= t and t < float(s["end"]) + acting.segment_linger:
			seg = s
			break
	var text := String(seg.get("text", ""))
	var bang := acting.exclaim_flick if "!" in text else 1.0
	var out := PackedFloat32Array([
		mood.brow_left_tilt.x * v + mood.brow_left_tilt.y * imp + mood.brow_left_tilt.z * imp * bang,
		mood.brow_left_raise.x * v + mood.brow_left_raise.y * imp + mood.brow_left_raise.z * imp * bang,
		mood.brow_right_tilt.x * v + mood.brow_right_tilt.y * imp + mood.brow_right_tilt.z * imp * bang,
		mood.brow_right_raise.x * v + mood.brow_right_raise.y * imp + mood.brow_right_raise.z * imp * bang,
	])
	var beat := 0 if side == 0 else 2
	out[beat] += mood.beat_tilt.x * v + mood.beat_tilt.y * imp + mood.beat_tilt.z * imp * bang
	out[beat + 1] += mood.beat_raise.x * v + mood.beat_raise.y * imp + mood.beat_raise.z * imp * bang
	if "?" in text:
		var q := clampf((t - (float(seg["end"]) - acting.question_start)) / acting.question_ramp, 0.0, 1.0)
		for s: int in [0, 2]:
			out[s] += acting.question_tilt * q
			out[s + 1] += acting.question_raise * q
	return out


## One track, a key wherever the value is not part of a flat run.
static func _track(anim: Animation, type: Animation.TrackType, path: String, times: PackedFloat32Array,
		values: Array) -> void:
	var idx := anim.add_track(type)
	anim.track_set_path(idx, NodePath(path))
	anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_LINEAR)
	if type == Animation.TYPE_VALUE:
		anim.value_track_set_update_mode(idx, Animation.UPDATE_CONTINUOUS)
	var n := values.size()
	for i in n:
		if i > 0 and i < n - 1 and values[i] == values[i - 1] and values[i] == values[i + 1]:
			continue
		match type:
			Animation.TYPE_ROTATION_3D:
				anim.rotation_track_insert_key(idx, times[i], values[i])
			Animation.TYPE_POSITION_3D:
				anim.position_track_insert_key(idx, times[i], values[i])
			_:
				anim.track_insert_key(idx, times[i], values[i])
