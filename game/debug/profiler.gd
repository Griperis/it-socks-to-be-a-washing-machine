## The stats overlay: the Profily add-on (addons/profily, MIT, a Godot port of Graphy; autoload
## `Profily`) shown and hidden with F3 (the `toggle_profiler` action), in debug builds only. It
## starts hidden and its own Ctrl+G / Ctrl+H keys are off, so F3 is its one key and no game key
## clashes. A release build switches every module off and frees the node, so the add-on ships
## unseen (kit/docs/TESTING-more.md "Exporting"). Optional: kit/tools/setup.py --profily=no removes all of it.
class_name Profiler

const TEST_KNOBS := ["allowed"]
## Whether F3 may show it: debug builds only. A test sets it false to act as a release build.
static var allowed := OS.is_debug_build()


## Called by ProfilerBoot (the first autoload, before Profily's own _ready reads its project
## settings): hidden at startup, no hotkeys of its own; in a release build every module off and the
## node freed.
static func configure() -> void:
	ProjectSettings.set_setting("profily/general/enabled_on_startup", false)
	ProjectSettings.set_setting("profily/hotkeys/enabled", false)
	if not OS.is_debug_build():
		for module: String in ["fps", "ram", "audio", "advanced", "scene"]:
			ProjectSettings.set_setting("profily/%s/module_state" % module, ProfilyTypes.ModuleState.OFF)
		(func() -> void:
			var tree := Engine.get_main_loop() as SceneTree
			var p := tree.root.get_node_or_null("Profily")
			if p != null:
				p.queue_free()).call_deferred()


## The Profily node; null in a release build or without the autoload.
static func node() -> ProfilyManager:
	return ProfilyManager.instance


## Whether it is showing.
static func shown() -> bool:
	var p := node()
	return p != null and p.is_active


## F3: shows or hides it; false when not allowed (a release build).
static func toggle() -> bool:
	var p := node()
	if not allowed or p == null:
		return false
	p.toggle_active()
	return true


static func show_it() -> void:
	var p := node()
	if allowed and p != null:
		p.enable()


static func hide_it() -> void:
	var p := node()
	if p != null:
		p.disable()
