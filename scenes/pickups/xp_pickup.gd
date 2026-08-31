extends Area3D

@export var xp_value: int = 10
var is_being_collected: bool = false
var collect_target: Node3D = null
var collect_speed: float = 15.0

func _physics_process(delta: float) -> void:
	if is_being_collected and is_instance_valid(collect_target):
		var dir = global_position.direction_to(collect_target.global_position)
		global_position += dir * collect_speed * delta
		if global_position.distance_to(collect_target.global_position) < 0.5:
			Events.xp_collected.emit(xp_value)
			queue_free()
	else:
		var time = Time.get_ticks_msec() / 1000.0
		visual_offset(time)

func visual_offset(time: float) -> void:
	var visual = $MeshInstance3D
	if visual:
		visual.position.y = sin(time * 3.0) * 0.1
		visual.rotation.y = time * 2.0

func start_collection(target: Node3D) -> void:
	is_being_collected = true
	collect_target = target
	if has_node("CollectionParticles"):
		$CollectionParticles.emitting = true
