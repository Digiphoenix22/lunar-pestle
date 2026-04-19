extends Control

func _ready() -> void:
	var master_slider = $Panel/VBox/MasterVolumeRow/MasterSlider
	var sfx_slider    = $Panel/VBox/SFXVolumeRow/SFXSlider
	var music_slider  = $Panel/VBox/MusicVolumeRow/MusicSlider

	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	sfx_slider.value    = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	music_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))

	master_slider.value_changed.connect(func(v): _set_bus("Master", v))
	sfx_slider.value_changed.connect(func(v): _set_bus("SFX", v))
	music_slider.value_changed.connect(func(v): _set_bus("Music", v))

func _set_bus(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.0 else -80.0)
	AudioServer.set_bus_mute(idx, linear == 0.0)
