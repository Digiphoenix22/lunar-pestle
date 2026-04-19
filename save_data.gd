extends Node

const SAVE_PATH := "user://save.json"

var _data := {"high_score": 0}

func _ready() -> void:
	_load()

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
