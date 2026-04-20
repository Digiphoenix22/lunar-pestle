extends Control

func _ready() -> void:
	_style_panel()
	var master_slider = $Panel/VBox/MasterVolumeRow/MasterSlider
	var sfx_slider    = $Panel/VBox/SFXVolumeRow/SFXSlider
	var music_slider  = $Panel/VBox/MusicVolumeRow/MusicSlider

	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	sfx_slider.value    = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	music_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))

	master_slider.value_changed.connect(func(v): _set_bus("Master", v))
	sfx_slider.value_changed.connect(func(v): _set_bus("SFX", v))
	music_slider.value_changed.connect(func(v): _set_bus("Music", v))

func _style_panel() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color                   = Color(0.06, 0.02, 0.20, 0.93)
	style.corner_radius_top_left     = 16
	style.corner_radius_top_right    = 16
	style.corner_radius_bottom_left  = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color  = Color(0.55, 0.18, 0.90, 0.85)
	style.shadow_color  = Color(0.35, 0.08, 0.75, 0.50)
	style.shadow_size   = 12
	style.shadow_offset = Vector2(0, 4)
	$Panel.add_theme_stylebox_override("panel", style)

func _set_bus(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.0 else -80.0)
	AudioServer.set_bus_mute(idx, linear == 0.0)
