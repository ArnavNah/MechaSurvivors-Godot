class_name WeaponComponent
extends Node3D

signal fired

@export var weapon_data: Resource
@export var base_damage: float = 25.0
@export var base_fire_rate: float = 0.25
@export var base_projectile_speed: float = 35.0
@export var base_projectile_count: int = 1
@export var base_spread_angle: float = 10.0
@export var muzzle_path: NodePath
@export var projectile_container_path: NodePath
@export var is_player_weapon: bool = true

var can_fire: bool = true
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var extra_projectiles: int = 0

@onready var cooldown_timer: Timer = Timer.new()
var muzzle: Marker3D = null

func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)
	if muzzle_path:
		muzzle = get_node_or_null(muzzle_path)

func fire(direction: Vector3) -> void:
	if not can_fire:
		return
	
	var container := _get_container()
	if container == null:
		return
	
	# Determine stats from weapon_data resource or fallback exported values
	var dmg: float = base_damage
	var f_rate: float = base_fire_rate
	var spd: float = base_projectile_speed
	var p_count: int = base_projectile_count
	var s_angle: float = base_spread_angle
	var p_scene: PackedScene = null
	
	if weapon_data:
		if weapon_data.get("damage") != null: dmg = weapon_data.damage
		if weapon_data.get("fire_rate") != null: f_rate = weapon_data.fire_rate
		if weapon_data.get("projectile_speed") != null: spd = weapon_data.projectile_speed
		if weapon_data.get("projectile_count") != null: p_count = weapon_data.projectile_count
		if weapon_data.get("spread_angle") != null: s_angle = weapon_data.spread_angle
		if weapon_data.get("projectile_scene") != null: p_scene = weapon_data.projectile_scene
	
	if p_scene == null:
		p_scene = load("res://scenes/projectile/Projectile.tscn")
	
	var total_projectiles := p_count + extra_projectiles
	var effective_damage := dmg * damage_multiplier
	var spawn_pos := muzzle.global_position if muzzle else global_position
	
	for i in total_projectiles:
		var proj = p_scene.instantiate()
		container.add_child(proj)
		proj.global_position = spawn_pos
		if proj.has_method("set_source_faction"):
			proj.set_source_faction(is_player_weapon)
		
		var dir := direction.normalized()
		if total_projectiles > 1:
			var spread_deg: float = s_angle if s_angle > 0.0 else 10.0
			var angle_offset: float = lerpf(-spread_deg / 2.0, spread_deg / 2.0, float(i) / float(total_projectiles - 1))
			dir = dir.rotated(Vector3.UP, deg_to_rad(angle_offset))
		
		if proj.has_method("setup"):
			proj.setup(dir, spd, effective_damage)
	
	can_fire = false
	var actual_fire_rate := f_rate / fire_rate_multiplier
	cooldown_timer.wait_time = maxf(actual_fire_rate, 0.05)
	cooldown_timer.start()
	fired.emit()

func _get_container() -> Node:
	if projectile_container_path:
		var node = get_node_or_null(projectile_container_path)
		if node:
			return node
	var entities = get_tree().current_scene.get_node_or_null("Entities")
	if entities:
		return entities
	return get_tree().current_scene

func _on_cooldown_timeout() -> void:
	can_fire = true
