extends Node

const COOLDOWN := 2.5

var _entries: Array = []

func register(lane: int) -> void:
	_entries.append({"lane": lane, "t": Time.get_ticks_msec() / 1000.0})

func _blocked() -> Array:
	var now = Time.get_ticks_msec() / 1000.0
	_entries = _entries.filter(func(e): return now - e.t < COOLDOWN)
	return _entries.map(func(e): return e.lane)

func pick_lane() -> int:
	var blocked = _blocked()
	var free = [0, 1, 2].filter(func(l): return l not in blocked)
	if free.is_empty():
		free = [0, 1, 2]
	return free[randi() % free.size()]
