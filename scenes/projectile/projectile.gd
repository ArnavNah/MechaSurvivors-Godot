extends Area3D

@export var speed: float = 35.0
@export var damage: float = 25.0
@export var is_player_projectile: bool = true

var direction: Vector3 = Vector3.FORWARD
var _has_hit: bool = false

func set_source_faction(from_player: bool) -> void:
	is_player_projectile = from_player
	if from_player:
		collision_layer = 1 << 3 # PlayerProjectiles
		collision_mask = (1 << 0) | (1 << 2) # World + Enemies
	else:
		collision_layer = 1 << 4 # EnemyProjectiles
		collision_mask = (1 << 0) | (1 << 1) # World + Player

func setup(dir: Vector3, spd: float, dmg: float) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area3D) -> void:
	if _has_hit:
		return
	if area.has_method("take_hit"):
		var applied = area.take_hit(damage)
		if applied != false:
			_has_hit = true
			Events.damage_dealt.emit(damage, global_position)
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if _has_hit:
		return
	# If we hit world geometry (StaticBody3D / Layer 1)
	if body is StaticBody3D or (body.collision_layer & 1) != 0:
		_has_hit = true
		queue_free()
	# Fallback if body is hit directly (CharacterBody3D)
	elif body.has_node("HurtboxComponent"):
		var hurtbox = body.get_node("HurtboxComponent")
		if hurtbox.has_method("take_hit"):
			var applied = hurtbox.take_hit(damage)
			if applied != false:
				_has_hit = true
				Events.damage_dealt.emit(damage, global_position)
				queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
