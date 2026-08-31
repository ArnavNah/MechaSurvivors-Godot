class_name HealthComponent
extends Node

signal damaged(amount: float)
signal health_changed(current_hp: float, max_hp: float)
signal died

@export var max_hp: float = 100.0
var current_hp: float
var is_dead: bool = false

func _ready() -> void:
	current_hp = max_hp
	is_dead = false

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		is_dead = true
		died.emit()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func set_max_hp(value: float) -> void:
	var ratio := current_hp / max_hp if max_hp > 0 else 1.0
	max_hp = value
	current_hp = max_hp * ratio
	health_changed.emit(current_hp, max_hp)
