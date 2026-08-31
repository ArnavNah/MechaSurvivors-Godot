extends "res://scenes/enemies/enemy_base.gd"

@onready var hitbox: Area3D = $HitboxComponent

func _ready() -> void:
	max_hp = 180.0
	move_speed = 3.2
	attack_damage = 30.0
	attack_range = 2.2
	attack_cooldown_time = 1.5
	xp_value = 35
	super._ready()
	if hitbox:
		hitbox.damage = attack_damage

func _execute_attack() -> void:
	super._execute_attack()
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range + 0.6:
		if player.has_node("HurtboxComponent"):
			var hurtbox = player.get_node("HurtboxComponent")
			if hurtbox.has_method("take_hit"):
				var applied = hurtbox.take_hit(attack_damage)
				if applied != false:
					Events.damage_dealt.emit(attack_damage, player.global_position)
