class_name UpgradeResource
extends Resource

enum ModifierType { FLAT, PERCENT }
enum StatTarget { DAMAGE, FIRE_RATE, PROJECTILE_COUNT, MOVE_SPEED, MAX_HP, XP_RADIUS }

@export var upgrade_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var stat_target: StatTarget = StatTarget.DAMAGE
@export var modifier_type: ModifierType = ModifierType.PERCENT
@export var modifier_value: float = 0.2
