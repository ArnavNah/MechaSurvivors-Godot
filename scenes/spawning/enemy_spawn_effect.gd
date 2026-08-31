extends Node3D

signal spawn_ready

@export var telegraph_duration: float = 0.45
@export var fade_duration: float = 0.45

@onready var ring: MeshInstance3D = $SpawnRing
@onready var particles: GPUParticles3D = $SpawnParticles
@onready var flash_light: OmniLight3D = $FlashLight

func _ready() -> void:
	ring.scale = Vector3(0.2, 0.2, 0.2)
	ring.transparency = 0.15
	flash_light.light_energy = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector3(1.35, 1.35, 1.35), telegraph_duration)
	tween.parallel().tween_property(flash_light, "light_energy", 2.2, telegraph_duration)
	tween.tween_callback(_trigger_spawn)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(ring, "scale", Vector3(1.8, 1.8, 1.8), fade_duration)
	tween.parallel().tween_property(ring, "transparency", 1.0, fade_duration)
	tween.parallel().tween_property(flash_light, "light_energy", 0.0, fade_duration)
	tween.tween_callback(queue_free)

func _trigger_spawn() -> void:
	particles.restart()
	particles.emitting = true
	spawn_ready.emit()
