## The voice bake's entry (core/84): run by `tools/voice_bake.sh`, headless, as a script (it needs none of the
## game's autoloads). The options after `--` go to VoiceBaker (tools/voice_baker.gd); it prints what it did and
## one verdict line, `PASS voice_bake ...` or `FAIL voice_bake ...`, and exits 0 or 1.
extends SceneTree


func _initialize() -> void:
	var baker := VoiceBaker.new()
	var code := 1
	if baker.parse_args(OS.get_cmdline_user_args()):
		code = baker.run()
	for line in baker.report:
		print("voice_bake: " + line)
	for line in baker.errors:
		printerr("voice_bake: " + line)
	if code == 0:
		print("PASS voice_bake (%d steps)" % baker.report.size())
	else:
		print("FAIL voice_bake: %s" % (baker.errors[0] if not baker.errors.is_empty() else "see above"))
	quit(code)
