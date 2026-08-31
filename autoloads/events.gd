extends Node

# Signals on this autoload are consumed from other scripts, which the per-file
# GDScript analyzer cannot see when it checks this event-bus class in isolation.
@warning_ignore_start("unused_signal")

# Combat
signal enemy_killed(enemy_position: Vector3, xp_value: int)
signal damage_dealt(amount: float, position: Vector3)

# Player
signal player_died
signal player_health_changed(current_hp: float, max_hp: float)

# XP & Leveling
signal xp_collected(amount: int)
signal player_xp_changed(current_xp: float, required_xp: float)
signal player_leveled_up(new_level: int)

# Upgrades
signal upgrade_selected(upgrade: Resource)

# Run stats
signal run_timer_updated(time: float)
signal kill_count_updated(count: int)
