extends CanvasLayer

@onready var root = $Root
@onready var card_container = $Root/VBoxContainer/CardContainer

var upgrade_card_scene = preload("res://scenes/ui/UpgradeCard.tscn")
var all_upgrades: Array[Resource] = []

func _ready() -> void:
	root.visible = false
	Events.player_leveled_up.connect(_on_player_leveled_up)
	_load_upgrades()

func _load_upgrades() -> void:
	var paths = [
		"res://resources/data/upgrades/damage_up.tres",
		"res://resources/data/upgrades/fire_rate_up.tres",
		"res://resources/data/upgrades/projectile_up.tres",
		"res://resources/data/upgrades/speed_up.tres",
		"res://resources/data/upgrades/hp_up.tres",
		"res://resources/data/upgrades/xp_radius_up.tres"
	]
	for path in paths:
		if ResourceLoader.exists(path):
			var res = load(path) as Resource
			if res:
				all_upgrades.append(res)

func _on_player_leveled_up(_level: int) -> void:
	show_upgrades()

func show_upgrades() -> void:
	GameManager.show_level_up()
	root.visible = true
	
	for child in card_container.get_children():
		child.queue_free()
	
	var available = all_upgrades.duplicate()
	available.shuffle()
	
	for i in range(min(3, available.size())):
		var card = upgrade_card_scene.instantiate()
		card_container.add_child(card)
		card.setup(available[i])
		card.selected.connect(_on_card_selected)

func _on_card_selected(upgrade: Resource) -> void:
	Events.upgrade_selected.emit(upgrade)
	root.visible = false
	GameManager.finish_level_up()
