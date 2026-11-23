## SceneChanger: changes the current scene behind the loading screen (the autoload `SceneChanger`;
## the kit's scenes/ template, its loading screen replaced by the game's one, game/level/loading_screen.tscn).
##
##   SceneChanger.change_to(HOUSE, "Loading the house...", func(root: Node) -> void: ...)
##
## The loading screen goes up and is drawn once before any work; the scene loads on a worker thread
## (`ResourceLoader.load_threaded_request`) with the bar following it; `setup` gets the new scene's
## root before it enters the tree (the title hands the level its World this way, never through a
## static); the old scene is taken out of the tree first and freed after. The scene's load fills the
## first `load_share` of the bar. Two frames after the new scene is in, a level that lays its Socks
## behind its own loading screen (the same scene) takes the wait over, the bar where this one left it;
## else this screen fades out from the backdrop's colour (LoadingScreen.finish()), input not held. A path that fails to load does NOT change the scene: `failed` is
## emitted and an error logged.
extends Node

signal progress(ratio: float)
## The new scene is in the tree and current.
signal finished(path: String)
signal failed(path: String, reason: String)

const LOADING := preload("res://game/level/loading_screen.tscn")

var _busy := false
var _screen: LoadingScreen = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_busy() -> bool:
	return _busy


## The loading screen up now, or null.
func screen() -> LoadingScreen:
	return _screen if is_instance_valid(_screen) else null


## Loads `path` behind the loading screen saying `heading` and makes it the current scene; `setup`
## (root: Node) runs on the new root before it enters the tree. Awaitable. A second call while one
## runs fails with "busy".
func change_to(path: String, heading := "", setup := Callable()) -> void:
	if _busy:
		failed.emit(path, "busy")
		return
	_busy = true
	if not ResourceLoader.exists(path):
		_fail(path, "no scene at that path")
		return
	await _show_screen(heading)
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		_fail(path, "could not start loading (%s)" % error_string(err))
		return
	var ratio: Array = []
	while true:
		var status := ResourceLoader.load_threaded_get_status(path, ratio)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_report(float(ratio[0]) if not ratio.is_empty() else 0.0)
			await get_tree().process_frame
			continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		_fail(path, "the load failed (status %d)" % status)
		return
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	if packed == null:
		_fail(path, "the file is not a scene")
		return
	_report(1.0)
	var root := packed.instantiate()
	if setup.is_valid():
		setup.call(root)
	_swap(root)
	await get_tree().process_frame
	await get_tree().process_frame
	if screen() != null:
		var runtime := LevelRuntime.of(root) if is_instance_valid(root) else null
		var theirs := runtime.loading if runtime != null and runtime.has_node(^"LoadingScreen") else null
		if theirs != null and theirs.is_showing():
			theirs.set_progress(_screen.shown_progress())
			_screen.queue_free()
		else:
			_screen.finish()
	_screen = null
	_busy = false
	finished.emit(path)


## Puts the new scene in the tree and current, then frees the old one.
func _swap(new_scene: Node) -> void:
	var tree := get_tree()
	var old := tree.current_scene
	if old != null:
		tree.root.remove_child(old)
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	if old != null:
		old.queue_free()


func _fail(path: String, reason: String) -> void:
	Log.error("scenes", "cannot change to '%s': %s" % [path, reason])
	if screen() != null:
		_screen.queue_free()
	_screen = null
	_busy = false
	failed.emit(path, reason)


func _report(ratio: float) -> void:
	progress.emit(ratio)
	if screen() != null:
		_screen.set_progress(ratio * _screen.tuning.load_share)


## The loading screen up, DRAWN once before the heavy work starts (headless: one frame).
func _show_screen(heading: String) -> void:
	_screen = LOADING.instantiate() as LoadingScreen
	_screen.free_when_faded = true
	if heading != "":
		_screen.set_heading(heading)
	get_tree().root.add_child(_screen)
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
