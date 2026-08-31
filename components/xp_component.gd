class_name XPComponent
extends Node

signal xp_changed(current_xp: float, required_xp: float)
signal leveled_up(new_level: int)

@export var base_xp_requirement: float = 50.0
@export var xp_growth_rate: float = 0.5

var current_xp: float = 0.0
var current_level: int = 1
var xp_to_next_level: float

func _ready() -> void:
	xp_to_next_level = _calculate_xp_requirement(current_level)

func add_xp(amount: float) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level = _calculate_xp_requirement(current_level)
		leveled_up.emit(current_level)
		Events.player_leveled_up.emit(current_level)
	xp_changed.emit(current_xp, xp_to_next_level)
	Events.player_xp_changed.emit(current_xp, xp_to_next_level)

func _calculate_xp_requirement(level: int) -> float:
	return base_xp_requirement * (1.0 + xp_growth_rate * (level - 1))
