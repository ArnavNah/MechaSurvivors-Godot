extends CanvasLayer

@onready var hp_bar = $HUDRoot/TopLeft/HPBar
@onready var xp_bar = $HUDRoot/TopLeft/XPBar
@onready var level_label = $HUDRoot/TopLeft/LevelLabel
@onready var timer_label = $HUDRoot/TopRight/TimerLabel
@onready var kill_label = $HUDRoot/TopRight/KillLabel

func _ready() -> void:
	Events.player_health_changed.connect(_on_health_changed)
	Events.player_xp_changed.connect(_on_xp_changed)
	Events.player_leveled_up.connect(_on_leveled_up)
	Events.run_timer_updated.connect(_on_timer_updated)
	Events.kill_count_updated.connect(_on_kill_count_updated)

func _on_health_changed(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current

func _on_xp_changed(current: float, required: float) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Level %d" % new_level

func _on_timer_updated(time_seconds: float) -> void:
	var mins: int = int(time_seconds / 60.0)
	var secs: int = int(fmod(time_seconds, 60.0))
	timer_label.text = "%02d:%02d" % [mins, secs]

func _on_kill_count_updated(count: int) -> void:
	kill_label.text = "Kills: %d" % count
