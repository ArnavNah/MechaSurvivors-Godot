extends CharacterBody3D
class_name EnemyBase

enum State { CHASE, ATTACK, REPOSITION }

@export var max_hp: float = 50.0
@export var move_speed: float = 5.5
@export var attack_damage: float = 15.0
@export var attack_range: float = 1.8
@export var attack_cooldown_time: float = 1.0
@export var xp_value: int = 10
@export var rotation_speed: float = 12.0
@export var stats: Resource
@export var xp_pickup_scene: PackedScene = preload("res://scenes/pickups/XPPickup.tscn")

var state: State = State.CHASE
var difficulty_multiplier: float = 1.0
var player: Node3D = null

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: Node = $HealthComponent
@onready var hurtbox_component: Area3D = $HurtboxComponent
@onready var death_particles: GPUParticles3D = $DeathParticles
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var visual_root: Node3D = $VisualRoot

var _nav_update_timer: float = 0.0
const NAV_UPDATE_INTERVAL: float = 0.2

func _ready() -> void:
	add_to_group("enemies")
	_find_player()
	
	# Apply resource stats if assigned
	if stats:
		if stats.get("max_hp") != null: max_hp = stats.max_hp
		if stats.get("move_speed") != null: move_speed = stats.move_speed
		if stats.get("damage") != null: attack_damage = stats.damage
		if stats.get("xp_value") != null: xp_value = stats.xp_value

	# Initialize health component
	if health_component:
		health_component.max_hp = max_hp
		health_component.current_hp = max_hp
		if not health_component.died.is_connected(_on_health_component_died):
			health_component.died.connect(_on_health_component_died)
			
	# Connect hurtbox
	if hurtbox_component:
		hurtbox_component.health_component = health_component
		if not hurtbox_component.hurt.is_connected(_on_hurtbox_hurt):
			hurtbox_component.hurt.connect(_on_hurtbox_hurt)
			
	# Attack timer
	if attack_cooldown:
		attack_cooldown.one_shot = true
		attack_cooldown.wait_time = attack_cooldown_time
		if not attack_cooldown.timeout.is_connected(_on_attack_cooldown_timeout):
			attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)

func initialize(diff_mult: float) -> void:
	difficulty_multiplier = diff_mult
	max_hp *= difficulty_multiplier
	attack_damage *= difficulty_multiplier
	if health_component:
		health_component.max_hp = max_hp
		health_component.current_hp = max_hp

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
			
	if health_component and health_component.current_hp <= 0:
		return
		
	var dist_to_player := global_position.distance_to(player.global_position)
	_process_ai_state(delta, dist_to_player)
	_move_and_rotate(delta)

func _process_ai_state(delta: float, dist: float) -> void:
	# Base melee state logic
	if dist <= attack_range:
		state = State.ATTACK
		if attack_cooldown.is_stopped():
			_execute_attack()
	else:
		state = State.CHASE
		_update_navigation_target(delta)

func _update_navigation_target(delta: float) -> void:
	_nav_update_timer -= delta
	if _nav_update_timer <= 0.0 and is_instance_valid(player):
		_nav_update_timer = NAV_UPDATE_INTERVAL
		navigation_agent.target_position = player.global_position

func _move_and_rotate(delta: float) -> void:
	if state == State.CHASE:
		var next_path_pos := navigation_agent.get_next_path_position()
		var move_dir: Vector3
		if global_position.distance_squared_to(next_path_pos) > 0.04:
			move_dir = global_position.direction_to(next_path_pos)
		elif is_instance_valid(player):
			move_dir = global_position.direction_to(player.global_position)
		else:
			move_dir = Vector3.ZERO
			
		move_dir.y = 0.0
		move_dir = move_dir.normalized()
		
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		
		if move_dir.length_squared() > 0.01:
			var target_rot_y := atan2(move_dir.x, move_dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, rotation_speed * delta)
	elif state == State.ATTACK or state == State.REPOSITION:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 10.0 * delta)
		
		var to_player := (player.global_position - global_position).normalized()
		if to_player.length_squared() > 0.01:
			var target_rot_y := atan2(to_player.x, to_player.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, rotation_speed * delta)
			
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()

func _execute_attack() -> void:
	attack_cooldown.start(attack_cooldown_time)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_health_component_died() -> void:
	if death_particles:
		death_particles.emitting = true
		var parent = get_parent()
		if parent:
			var global_t = death_particles.global_transform
			remove_child(death_particles)
			parent.add_child(death_particles)
			death_particles.global_transform = global_t
			death_particles.finished.connect(death_particles.queue_free)
	
	if xp_pickup_scene:
		var xp_pickup = xp_pickup_scene.instantiate()
		get_parent().add_child(xp_pickup)
		xp_pickup.global_position = global_position
		if xp_pickup.has_method("set"):
			xp_pickup.xp_value = xp_value
		
	Events.enemy_killed.emit(global_position, xp_value)
	queue_free()

func _on_hurtbox_hurt(_damage: float) -> void:
	var tween = create_tween()
	for child in visual_root.get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat:
				var new_mat = mat.duplicate()
				child.set_surface_override_material(0, new_mat)
				var original_color = new_mat.albedo_color
				new_mat.albedo_color = Color.WHITE
				tween.tween_property(new_mat, "albedo_color", original_color, 0.1)

func _on_attack_cooldown_timeout() -> void:
	pass
