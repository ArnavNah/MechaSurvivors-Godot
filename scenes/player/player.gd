extends CharacterBody3D

@export var move_speed: float = 9.0
@export var max_hp: float = 200.0
@export var stats: Resource
@export var weapon_data: Resource

@onready var health_component: Node = $HealthComponent
@onready var weapon_component: Node3D = $WeaponComponent
@onready var xp_component: Node = $XPComponent
@onready var hurtbox_component: Area3D = $HurtboxComponent
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var visual_root: Node3D = $VisualRoot
@onready var xp_magnet_area: Area3D = $XPMagnetArea

var gravity: float = 9.8
var touch_controls: Node = null

func _ready() -> void:
	add_to_group("player")
	
	# Load default resources if not set in inspector
	if not stats and ResourceLoader.exists("res://resources/data/player_stats.tres"):
		stats = load("res://resources/data/player_stats.tres")
	if not weapon_data and ResourceLoader.exists("res://resources/data/mecha_blaster.tres"):
		weapon_data = load("res://resources/data/mecha_blaster.tres")
	
	# Apply stats resource overrides if available
	if stats:
		var speed_val = stats.get("move_speed")
		if speed_val != null:
			move_speed = speed_val
		var hp_val = stats.get("max_hp")
		if hp_val != null:
			max_hp = hp_val

	# Initialize health component
	if health_component:
		health_component.max_hp = max_hp
		health_component.current_hp = max_hp
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
	
	# Connect hurtbox to health component
	if hurtbox_component and health_component:
		hurtbox_component.health_component = health_component
	
	# Connect XP and magnet
	if xp_component:
		xp_component.leveled_up.connect(_on_leveled_up)
	if xp_magnet_area:
		xp_magnet_area.area_entered.connect(_on_magnet_area_entered)
	
	# Setup weapon component
	if weapon_component and weapon_data:
		weapon_component.weapon_data = weapon_data

func _physics_process(delta: float) -> void:
	# 1. Responsive WASD Movement
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var controls := _get_touch_controls()
	if controls:
		var touch_move: Vector2 = controls.get_move_vector()
		if touch_move.length_squared() > input_vector.length_squared():
			input_vector = touch_move
	var move_dir = Vector3(input_vector.x, 0.0, input_vector.y).normalized()
	
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	
	# 2. Smoothly rotate character visual mesh toward movement direction
	if move_dir.length_squared() > 0.01:
		var target_rot_y = atan2(move_dir.x, move_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, 15.0 * delta)
	
	# 3. Independent mouse aiming in world-space
	var touch_aim := Vector2.ZERO
	if controls:
		touch_aim = controls.get_aim_vector()
	if touch_aim.length_squared() > 0.01:
		_aim_weapon_direction(Vector3(touch_aim.x, 0.0, touch_aim.y))
	else:
		_aim_weapon()
	
	# 4. Shooting
	var touch_firing: bool = controls != null and controls.is_firing()
	if (Input.is_action_pressed("fire") or touch_firing) and weapon_component:
		var aim_dir = -weapon_pivot.global_transform.basis.z.normalized()
		weapon_component.fire(aim_dir)

func _get_touch_controls() -> Node:
	if not is_instance_valid(touch_controls):
		touch_controls = get_tree().get_first_node_in_group("touch_controls")
	return touch_controls

func _aim_weapon_direction(direction: Vector3) -> void:
	if direction.length_squared() <= 0.01:
		return
	var look_pos := weapon_pivot.global_position + direction.normalized()
	look_pos.y = weapon_pivot.global_position.y
	weapon_pivot.look_at(look_pos, Vector3.UP)

func _aim_weapon() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)
	
	var floor_plane = Plane(Vector3.UP, global_position.y)
	var intersect = floor_plane.intersects_ray(ray_origin, ray_normal)
	if intersect != null:
		var look_pos = Vector3(intersect.x, weapon_pivot.global_position.y, intersect.z)
		if weapon_pivot.global_position.distance_squared_to(look_pos) > 0.01:
			weapon_pivot.look_at(look_pos, Vector3.UP)

func _on_health_changed(current: float, max_h: float) -> void:
	Events.player_health_changed.emit(current, max_h)

func _on_died() -> void:
	Events.player_died.emit()
	if GameManager:
		GameManager.game_over()

func _on_leveled_up(_new_level: int) -> void:
	if GameManager:
		GameManager.show_level_up()

func _on_magnet_area_entered(area: Area3D) -> void:
	if area.has_method("start_collection"):
		area.start_collection(self)

func apply_upgrade(upgrade: Resource) -> void:
	if not upgrade:
		return
		
	var stat_target = upgrade.get("stat_target")
	var mod_type = upgrade.get("modifier_type")
	var val = upgrade.get("modifier_value")
	
	match stat_target:
		0: # DAMAGE
			if mod_type == 0: weapon_component.damage_multiplier += val
			else: weapon_component.damage_multiplier *= (1.0 + val)
		1: # FIRE_RATE
			if mod_type == 0: weapon_component.fire_rate_multiplier += val
			else: weapon_component.fire_rate_multiplier *= (1.0 + val)
		2: # PROJECTILE_COUNT
			weapon_component.extra_projectiles += int(val)
		3: # MOVE_SPEED
			if mod_type == 0: move_speed += val
			else: move_speed *= (1.0 + val)
		4: # MAX_HP
			var current_max = health_component.max_hp
			if mod_type == 0: health_component.set_max_hp(current_max + val)
			else: health_component.set_max_hp(current_max * (1.0 + val))
		5: # XP_RADIUS
			var shape = xp_magnet_area.get_node_or_null("CollisionShape3D")
			if shape and shape.shape is SphereShape3D:
				var sphere = shape.shape as SphereShape3D
				if mod_type == 0: sphere.radius += val
				else: sphere.radius *= (1.0 + val)
