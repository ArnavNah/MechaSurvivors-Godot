extends Node3D
class_name EnemySpawner

@export var melee_scene: PackedScene = preload("res://scenes/enemies/EnemyMelee.tscn")
@export var ranged_scene: PackedScene = preload("res://scenes/enemies/EnemyRanged.tscn")
@export var heavy_scene: PackedScene = preload("res://scenes/enemies/EnemyHeavy.tscn")
@export var spawn_effect_scene: PackedScene = preload("res://scenes/spawning/EnemySpawnEffect.tscn")
@export var spawn_points: Array[Node3D] = []
@export var initial_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.4
@export var max_enemies: int = 60
@export var difficulty_increase_rate: float = 0.015

var difficulty: float = 1.0
var elapsed_time: float = 0.0
var player: Node3D = null
var pending_spawn_count: int = 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var enemy_container: Node3D = $EnemyContainer
@onready var spawn_effect_container: Node3D = $SpawnEffects

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_timer.wait_time = initial_spawn_interval
	spawn_timer.autostart = true
	
	_find_player()
	
	# Initial quick spawn wave so action begins immediately.
	get_tree().create_timer(0.5, false).timeout.connect(_spawn_initial_wave)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta: float) -> void:
	elapsed_time += delta
	difficulty = 1.0 + (elapsed_time * difficulty_increase_rate)
	
	# Scale spawn timer interval
	var target_interval = maxf(min_spawn_interval, initial_spawn_interval - (elapsed_time * 0.012))
	if absf(spawn_timer.wait_time - target_interval) > 0.05:
		spawn_timer.wait_time = target_interval

func _spawn_initial_wave() -> void:
	for i in range(3):
		spawn_single_enemy()

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player):
		_find_player()
		
	# Scale batch size with difficulty (1 at start, up to 4 in later waves)
	var spawn_count: int = 1 + int(minf(difficulty - 1.0, 3.0))
	for i in range(spawn_count):
		if get_reserved_enemy_count() >= max_enemies:
			break
		spawn_single_enemy()

func spawn_single_enemy() -> void:
	if get_reserved_enemy_count() >= max_enemies:
		return
		
	var enemy_scene: PackedScene = _pick_enemy_scene()
	if not enemy_scene:
		enemy_scene = melee_scene
		
	var spawn_pos: Vector3 = _get_spawn_position()
	var difficulty_snapshot := difficulty

	if spawn_effect_scene:
		var effect = spawn_effect_scene.instantiate()
		pending_spawn_count += 1
		effect.spawn_ready.connect(
			_spawn_enemy.bind(enemy_scene, spawn_pos, difficulty_snapshot),
			CONNECT_ONE_SHOT
		)
		spawn_effect_container.add_child(effect)
		effect.global_position = spawn_pos
	else:
		_spawn_enemy(enemy_scene, spawn_pos, difficulty_snapshot)

func _spawn_enemy(enemy_scene: PackedScene, spawn_pos: Vector3, spawn_difficulty: float) -> void:
	if pending_spawn_count > 0:
		pending_spawn_count -= 1
	if not is_inside_tree() or get_active_enemy_count() >= max_enemies:
		return

	var enemy: Node3D = enemy_scene.instantiate()
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.scale = Vector3.ONE * 0.15

	if enemy.has_method("initialize"):
		enemy.initialize(spawn_difficulty)

	var arrival_tween := enemy.create_tween()
	arrival_tween.set_trans(Tween.TRANS_BACK)
	arrival_tween.set_ease(Tween.EASE_OUT)
	arrival_tween.tween_property(enemy, "scale", Vector3.ONE, 0.24)

func _pick_enemy_scene() -> PackedScene:
	var r: float = randf()
	if difficulty < 1.4:
		# Early run: mostly melee
		return melee_scene if r < 0.85 else ranged_scene
	elif difficulty < 2.2:
		# Mid run: balanced mix with occasional heavies
		if r < 0.55:
			return melee_scene
		elif r < 0.85:
			return ranged_scene
		else:
			return heavy_scene
	else:
		# Late run: dangerous hordes
		if r < 0.40:
			return melee_scene
		elif r < 0.75:
			return ranged_scene
		else:
			return heavy_scene

func _get_spawn_position() -> Vector3:
	# Prefer defined spawn points if available
	if not spawn_points.is_empty():
		var pt: Node3D = spawn_points.pick_random()
		if is_instance_valid(pt):
			return pt.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			
	# Dynamic ring around player
	if is_instance_valid(player):
		var angle: float = randf() * TAU
		var radius: float = randf_range(16.0, 24.0)
		return player.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		
	# Fallback arena bounds
	return Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))

func get_active_enemy_count() -> int:
	return enemy_container.get_child_count()

func get_reserved_enemy_count() -> int:
	return get_active_enemy_count() + pending_spawn_count
