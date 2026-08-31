extends CanvasLayer

@export var force_visible_in_editor: bool = false
@export var drag_radius: float = 90.0

var _move_touch: int = -1
var _aim_touch: int = -1
var _move_origin := Vector2.ZERO
var _aim_origin := Vector2.ZERO
var _move_vector := Vector2.ZERO
var _aim_vector := Vector2.ZERO

@onready var controls_root: Control = $ControlsRoot
@onready var pause_button: Button = $ControlsRoot/PauseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("touch_controls")
	controls_root.visible = OS.has_feature("mobile") or force_visible_in_editor
	pause_button.pressed.connect(_on_pause_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not controls_root.visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var left_side := event.position.x < get_viewport().get_visible_rect().size.x * 0.5
	if event.pressed:
		if left_side and _move_touch == -1:
			_move_touch = event.index
			_move_origin = event.position
		elif not left_side and _aim_touch == -1:
			_aim_touch = event.index
			_aim_origin = event.position
	else:
		if event.index == _move_touch:
			_move_touch = -1
			_move_vector = Vector2.ZERO
		elif event.index == _aim_touch:
			_aim_touch = -1
			_aim_vector = Vector2.ZERO

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_touch:
		_move_vector = ((event.position - _move_origin) / drag_radius).limit_length(1.0)
	elif event.index == _aim_touch:
		_aim_vector = ((event.position - _aim_origin) / drag_radius).limit_length(1.0)

func get_move_vector() -> Vector2:
	return _move_vector

func get_aim_vector() -> Vector2:
	return _aim_vector

func is_firing() -> bool:
	return _aim_touch != -1 and _aim_vector.length_squared() > 0.02

func _on_pause_pressed() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	var pause_menu := get_tree().current_scene.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("open_pause"):
		pause_menu.open_pause()
