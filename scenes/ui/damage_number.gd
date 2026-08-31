extends Node3D

var amount: float = 0

func setup(dmg: float, pos: Vector3) -> void:
	global_position = pos + Vector3(0, 1.5, 0)
	$Label3D.text = str(int(dmg))
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 1.5, 0.8)
	tween.tween_property($Label3D, "modulate", Color(1, 1, 1, 0), 0.8).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
