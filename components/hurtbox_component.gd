class_name HurtboxComponent
extends Area3D

signal hurt(damage: float)

@export var health_component: Node
@export var invincibility_duration: float = 0.15

var is_invincible: bool = false
@onready var invincibility_timer: Timer = Timer.new()

func _ready() -> void:
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)

func take_hit(damage: float) -> bool:
	if is_invincible or damage <= 0.0:
		return false
	hurt.emit(damage)
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(damage)
	else:
		return false
	start_invincibility(invincibility_duration)
	return true

func start_invincibility(duration: float = 0.15) -> void:
	is_invincible = true
	invincibility_timer.wait_time = maxf(duration, 0.01)
	invincibility_timer.start()

func _on_invincibility_timeout() -> void:
	is_invincible = false
