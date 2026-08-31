extends Node3D

var damage_number_scene = preload("res://scenes/ui/DamageNumber.tscn")

@onready var player = $Player
@onready var camera_rig = $CameraRig
@onready var arena = $DungeonArena
@onready var spawner = $EnemySpawner
@onready var entities = $Entities
@onready var game_over_menu = $GameOverMenu
@onready var level_up_menu = $LevelUpMenu

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Setup Player
	if arena.has_node("PlayerSpawn"):
		player.global_position = arena.get_node("PlayerSpawn").global_position
	player.add_to_group("player")
	
	# Setup Camera Rig tracking via RemoteTransform3D
	if player.has_node("CameraFollowPoint") and camera_rig:
		var follow_pt: RemoteTransform3D = player.get_node("CameraFollowPoint")
		follow_pt.remote_path = camera_rig.get_path()
		camera_rig.global_position = follow_pt.global_position
	
	# Setup Spawner - assign individual scene properties
	spawner.melee_scene = preload("res://scenes/enemies/EnemyMelee.tscn")
	spawner.ranged_scene = preload("res://scenes/enemies/EnemyRanged.tscn")
	spawner.heavy_scene = preload("res://scenes/enemies/EnemyHeavy.tscn")
	
	# Collect spawn points from arena
	if arena.has_node("SpawnPoints"):
		var points: Array[Node3D] = []
		for child in arena.get_node("SpawnPoints").get_children():
			if child is Node3D:
				points.append(child)
		spawner.spawn_points = points
		
	spawner.player = player
	
	# Connect Events
	Events.upgrade_selected.connect(_on_upgrade_selected)
	Events.xp_collected.connect(_on_xp_collected)
	Events.damage_dealt.connect(_on_damage_dealt)
	Events.player_died.connect(_on_player_died)
	Events.player_leveled_up.connect(_on_player_leveled_up)

	# Child scenes are ready now, so publish the real initial values to the HUD.
	Events.player_health_changed.emit(
		player.health_component.current_hp,
		player.health_component.max_hp
	)
	Events.player_xp_changed.emit(
		player.xp_component.current_xp,
		player.xp_component.xp_to_next_level
	)
	
func _on_upgrade_selected(upgrade: Resource) -> void:
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade)

func _on_xp_collected(amount: int) -> void:
	if player.has_node("XPComponent"):
		player.get_node("XPComponent").add_xp(amount)
	elif player.has_method("add_xp"):
		player.add_xp(amount)

func _on_damage_dealt(amount: float, pos: Vector3) -> void:
	var dmg_num = damage_number_scene.instantiate()
	entities.add_child(dmg_num)
	dmg_num.setup(amount, pos)

func _on_player_died() -> void:
	pass # GameOverMenu shows automatically via its own connection

func _on_player_leveled_up(_level: int) -> void:
	pass # LevelUpMenu shows automatically via its own connection
