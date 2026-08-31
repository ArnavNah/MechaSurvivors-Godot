extends Node

enum GameState { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER }

var current_state: GameState = GameState.MENU
var run_time: float = 0.0
var kill_count: int = 0
var current_level: int = 1
var is_run_active: bool = false

func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.player_leveled_up.connect(_on_player_leveled_up)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING and is_run_active:
		run_time += delta
		Events.run_timer_updated.emit(run_time)

func start_game() -> void:
	run_time = 0.0
	kill_count = 0
	current_level = 1
	is_run_active = true
	current_state = GameState.PLAYING
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func pause_game() -> void:
	current_state = GameState.PAUSED
	get_tree().paused = true

func resume_game() -> void:
	current_state = GameState.PLAYING
	get_tree().paused = false

func show_level_up() -> void:
	current_state = GameState.LEVEL_UP
	get_tree().paused = true

func finish_level_up() -> void:
	current_state = GameState.PLAYING
	get_tree().paused = false

func game_over() -> void:
	current_state = GameState.GAME_OVER
	is_run_active = false
	get_tree().paused = true

func restart() -> void:
	get_tree().paused = false
	start_game()

func go_to_menu() -> void:
	current_state = GameState.MENU
	is_run_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_enemy_killed(_pos: Vector3, _xp: int) -> void:
	kill_count += 1
	Events.kill_count_updated.emit(kill_count)

func _on_player_leveled_up(level: int) -> void:
	current_level = level
