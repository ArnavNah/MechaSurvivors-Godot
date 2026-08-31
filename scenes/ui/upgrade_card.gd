extends PanelContainer

signal selected(upgrade: Resource)

@export var upgrade: Resource  # UpgradeResource

@onready var icon_rect = $VBoxContainer/IconRect
@onready var name_label = $VBoxContainer/NameLabel
@onready var desc_label = $VBoxContainer/DescLabel
@onready var select_button = $VBoxContainer/SelectButton

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)

func setup(upg: Resource) -> void:
	upgrade = upg
	if upgrade:
		icon_rect.texture = upgrade.icon
		name_label.text = upgrade.upgrade_name
		desc_label.text = upgrade.description

func _on_select_pressed() -> void:
	selected.emit(upgrade)
