extends CanvasLayer

@onready var root: Control = $Root
@onready var resume_btn: Button = $Root/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Root/VBoxContainer/RestartButton
@onready var menu_btn: Button = $Root/VBoxContainer/MainMenuButton
@onready var quit_btn: Button = $Root/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			open_pause()
			get_viewport().set_input_as_handled()
		elif GameManager.current_state == GameManager.GameState.PAUSED and root.visible:
			close_pause()
			get_viewport().set_input_as_handled()

func open_pause() -> void:
	root.visible = true
	GameManager.pause_game()

func close_pause() -> void:
	root.visible = false
	GameManager.resume_game()

func _on_resume_pressed() -> void:
	close_pause()

func _on_restart_pressed() -> void:
	root.visible = false
	GameManager.restart()

func _on_menu_pressed() -> void:
	root.visible = false
	GameManager.go_to_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()
