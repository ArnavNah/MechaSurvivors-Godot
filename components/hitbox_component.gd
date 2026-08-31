class_name HitboxComponent
extends Area3D

@export var damage: float = 10.0

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_hit"):
		var applied = area.take_hit(damage)
		if applied != false:
			Events.damage_dealt.emit(damage, global_position)
