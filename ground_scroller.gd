extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT  := 3
var scroll_speed   := 80

func _process(delta: float) -> void:
	for chunk in get_children():
		chunk.position.z += scroll_speed * delta
		if chunk.position.z > CHUNK_LENGTH:
			chunk.position.z -= CHUNK_LENGTH * CHUNK_COUNT
