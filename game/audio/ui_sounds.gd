## The menus' sounds (the old game/audio/ui_sounds.gd, Q336; the autoload `UiSounds`): every button
## in every menu is hooked as it enters the tree: a soft click (`ui_click`) when it is pressed, a very
## quiet tick (`ui_hover`) when the mouse comes over an enabled one; both are SoundEvents of the
## catalogue on the UI bus. A button with the metadata `no_ui_sound` stays silent.
## It also feeds the selection ring (`FocusRingStyle`) the window's input (core/75).
extends Node

const CLICK := &"ui_click"
const HOVER := &"ui_hover"
const SILENT := &"no_ui_sound"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	# core/75: the selection ring shows after a key or pad press and hides after a mouse click.
	get_tree().root.window_input.connect(FocusRingStyle.on_input)


func _on_node_added(node: Node) -> void:
	var b := node as BaseButton
	if b == null or b.has_meta(SILENT) or b.pressed.is_connected(_click):
		return
	b.pressed.connect(_click)
	b.mouse_entered.connect(_hover.bind(b))


## The hover tick on its own: a key that ticks and does not click (the Lobby's Ready) plays it when pressed.
func hover() -> void:
	Sounds.play(HOVER)


func _click() -> void:
	Sounds.play(CLICK)


func _hover(b: BaseButton) -> void:
	if is_instance_valid(b) and not b.disabled:
		Sounds.play(HOVER)
