extends Node

const SAVE_PATH := "user://save.json"

var _data := {"high_score": 0}

func _ready() -> void:
	_ensure_music_bus()
	_load()

func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		return
	AudioServer.add_bus()
	var idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, "Music")
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, linear_to_db(0.40))

func get_high_score() -> int:
	return int(_data.get("high_score", 0))

func submit_score(score: int) -> bool:
	if score > get_high_score():
		_data["high_score"] = score
		_save()
		return true
	return false

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_data))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var result = JSON.parse_string(f.get_as_text())
		if result is Dictionary:
			_data = result
