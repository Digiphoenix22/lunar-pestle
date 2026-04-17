extends Node3D

const CHUNK_LENGTH    := 40.0
const CHUNK_COUNT     := 5
const OBSTACLE_CHANCE := 0.4
var scroll_speed      := 80.0
var target_speed      := 80.0
const SPEED_EASE      := 3.0

var plain_template: Node3D = null
var obstacle_templates: Array[Node3D] = []

func _ready() -> void:
	var chunks_root = load("res://chunks.tscn").instantiate()
	for child in chunks_root.get_children():
		if child.name == "Base":
			plain_template = child.duplicate()
		elif child.name.is_valid_int():
			obstacle_templates.append(child.duplicate())
	chunks_root.free()

	for i in CHUNK_COUNT:
		_place_chunk(-i * CHUNK_LENGTH)

func _make_chunk() -> Node3D:
	var template: Node3D
	if obstacle_templates.is_empty() or randf() > OBSTACLE_CHANCE:
		template = plain_template
	else:
		template = obstacle_templates[randi() % obstacle_templates.size()]
	var chunk = template.duplicate()
	chunk.position = Vector3.ZERO
	return chunk

func _place_chunk(z: float) -> void:
	var chunk = _make_chunk()
	chunk.position.z = z
	add_child(chunk)

func _process(delta: float) -> void:
	scroll_speed = lerp(scroll_speed, target_speed, SPEED_EASE * delta)
	for child in get_children():
		child.position.z += scroll_speed * delta
		if child.position.z > CHUNK_LENGTH:
			var old_z = child.position.z
			child.queue_free()
			_place_chunk(old_z - CHUNK_LENGTH * CHUNK_COUNT)
