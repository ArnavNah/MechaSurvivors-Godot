extends "res://scenes/enemies/enemy_base.gd"

@export var shooting_range: float = 11.0
@export var retreat_range: float = 5.0

@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var weapon_component: Node3D = $WeaponPivot/WeaponComponent

func _ready() -> void:
	max_hp = 60.0
	move_speed = 4.5
	attack_damage = 12.0
	attack_range = shooting_range
	attack_cooldown_time = 1.2
	xp_value = 20
	super._ready()
	if weapon_component:
		weapon_component.is_player_weapon = false
		weapon_component.base_damage = attack_damage
		weapon_component.base_fire_rate = attack_cooldown_time

func _process_ai_state(delta: float, dist: float) -> void:
	# Aim weapon pivot at player
	if is_instance_valid(player):
		var target_pos := Vector3(player.global_position.x, weapon_pivot.global_position.y, player.global_position.z)
		if weapon_pivot.global_position.distance_squared_to(target_pos) > 0.01:
			weapon_pivot.look_at(target_pos, Vector3.UP)
	
	if dist > shooting_range:
		state = State.CHASE
		_update_navigation_target(delta)
	elif dist < retreat_range:
		state = State.REPOSITION
		# Move backward away from player
		var away_dir := player.global_position.direction_to(global_position)
		away_dir.y = 0.0
		away_dir = away_dir.normalized()
		velocity.x = away_dir.x * (move_speed * 0.8)
		velocity.z = away_dir.z * (move_speed * 0.8)
		if attack_cooldown.is_stopped():
			_execute_attack()
	else:
		state = State.ATTACK
		if attack_cooldown.is_stopped():
			_execute_attack()

func _execute_attack() -> void:
	super._execute_attack()
	if not is_instance_valid(player):
		return
		
	var aim_dir := -weapon_pivot.global_transform.basis.z.normalized()
	if weapon_component and weapon_component.has_method("fire"):
		weapon_component.fire(aim_dir)
	else:
		# Fallback direct projectile spawn
		var proj_scene = load("res://scenes/projectile/Projectile.tscn")
		var proj = proj_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = weapon_pivot.global_position + aim_dir * 0.5
		if proj.has_method("setup"):
			proj.setup(aim_dir, 22.0, attack_damage)
