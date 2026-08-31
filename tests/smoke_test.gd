extends Node

var failures: Array[String] = []

func _ready() -> void:
	_test_projectile_factions()
	_test_damage_invincibility()
	_test_release_scenes()
	await _test_spawn_effect()

	if failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _test_projectile_factions() -> void:
	var projectile = load("res://scenes/projectile/Projectile.tscn").instantiate()
	add_child(projectile)
	projectile.set_source_faction(false)
	_check(projectile.collision_layer == 16, "Enemy projectile must use EnemyProjectiles layer.")
	_check(projectile.collision_mask == 3, "Enemy projectile must collide with World and Player.")
	projectile.set_source_faction(true)
	_check(projectile.collision_layer == 8, "Player projectile must use PlayerProjectiles layer.")
	_check(projectile.collision_mask == 5, "Player projectile must collide with World and Enemies.")
	projectile.queue_free()

func _test_damage_invincibility() -> void:
	var player = load("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	var health = player.get_node("HealthComponent")
	var hurtbox = player.get_node("HurtboxComponent")
	var initial_hp: float = health.current_hp
	_check(hurtbox.take_hit(10.0), "First valid hit should apply damage.")
	_check(not hurtbox.take_hit(10.0), "Invincibility window should reject an immediate second hit.")
	_check(is_equal_approx(health.current_hp, initial_hp - 10.0), "Rejected hits must not reduce health.")
	player.free()

func _test_release_scenes() -> void:
	var required_scenes := [
		"res://scenes/ui/MainMenu.tscn",
		"res://scenes/game/Game.tscn",
		"res://scenes/ui/TouchControls.tscn",
		"res://scenes/ui/PauseMenu.tscn",
		"res://scenes/ui/LevelUpMenu.tscn",
		"res://scenes/ui/GameOverMenu.tscn",
		"res://scenes/spawning/EnemySpawnEffect.tscn"
	]
	for path in required_scenes:
		_check(ResourceLoader.exists(path), "Missing release scene: %s" % path)
		var scene = load(path)
		_check(scene is PackedScene, "Release scene failed to load: %s" % path)

func _test_spawn_effect() -> void:
	var effect = load("res://scenes/spawning/EnemySpawnEffect.tscn").instantiate()
	effect.telegraph_duration = 0.02
	effect.fade_duration = 0.02
	add_child(effect)
	await effect.spawn_ready
	_check(is_instance_valid(effect), "Spawn effect should emit before it is cleaned up.")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
