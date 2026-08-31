extends Control

const SETTINGS_PATH := "user://settings.cfg"

@onready var menu_buttons: VBoxContainer = $VBoxContainer
@onready var settings_panel: Control = $SettingsPanel
@onready var fullscreen_toggle: CheckButton = $SettingsPanel/Panel/VBoxContainer/FullscreenToggle
@onready var volume_slider: HSlider = $SettingsPanel/Panel/VBoxContainer/VolumeSlider
@onready var volume_value: Label = $SettingsPanel/Panel/VBoxContainer/VolumeValue
@onready var back_button: Button = $SettingsPanel/Panel/VBoxContainer/BackButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_close_settings)
	$VBoxContainer/QuitButton.visible = not OS.has_feature("mobile")
	_load_settings()

func _on_play_pressed() -> void:
	GameManager.start_game()

func _on_settings_pressed() -> void:
	settings_panel.visible = true
	menu_buttons.visible = false
	back_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()

func _close_settings() -> void:
	settings_panel.visible = false
	menu_buttons.visible = true
	$VBoxContainer/SettingsButton.grab_focus()
	_save_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	if OS.has_feature("mobile"):
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _on_volume_changed(value: float) -> void:
	var linear_volume := value / 100.0
	AudioServer.set_bus_volume_db(0, linear_to_db(linear_volume))
	AudioServer.set_bus_mute(0, is_zero_approx(linear_volume))
	volume_value.text = "%d%%" % int(value)

func _load_settings() -> void:
	var config := ConfigFile.new()
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var volume := 80.0
	if config.load(SETTINGS_PATH) == OK:
		fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
		volume = float(config.get_value("audio", "master_volume", volume))
	fullscreen_toggle.set_pressed_no_signal(fullscreen)
	volume_slider.set_value_no_signal(volume)
	_on_fullscreen_toggled(fullscreen)
	_on_volume_changed(volume)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen_toggle.button_pressed)
	config.set_value("audio", "master_volume", volume_slider.value)
	config.save(SETTINGS_PATH)
