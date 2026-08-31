extends CanvasLayer

@onready var root = $Root
@onready var time_label = $Root/VBoxContainer/StatsContainer/TimeLabel
@onready var kills_label = $Root/VBoxContainer/StatsContainer/KillsLabel
@onready var level_label = $Root/VBoxContainer/StatsContainer/LevelLabel
@onready var restart_btn = $Root/VBoxContainer/RestartButton
@onready var menu_btn = $Root/VBoxContainer/MenuButton

func _ready() -> void:
	root.visible = false
	Events.player_died.connect(_on_player_died)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_player_died() -> void:
	root.visible = true
	var time_seconds = GameManager.run_time
	var mins: int = int(time_seconds / 60.0)
	var secs: int = int(fmod(time_seconds, 60.0))
	time_label.text = "Run Time: %02d:%02d" % [mins, secs]
	kills_label.text = "Enemies Destroyed: %d" % GameManager.kill_count
	level_label.text = "Level Reached: %d" % GameManager.current_level

func _on_restart_pressed() -> void:
	GameManager.restart()

func _on_menu_pressed() -> void:
	GameManager.go_to_menu()
