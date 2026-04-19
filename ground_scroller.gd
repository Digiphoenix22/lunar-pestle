extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT  := 10
const STAGE_OBSTACLE_CHANCE := [0.4, 0.55, 0.65, 0.75, 0.85, 0.90]
var obstacle_chance := 0.4
var scroll_speed    := 0.0
var target_speed      := 80.0
const SPEED_EASE      := 0.5

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

	# First chunk always plain so player never spawns on an obstacle
	var first = plain_template.duplicate()
	first.position.z = 0.0
	add_child(first)
	for i in range(1, CHUNK_COUNT):
		_place_chunk(-i * CHUNK_LENGTH, false)

func set_stage(stage: int) -> void:
	var idx = clampi(stage - 1, 0, STAGE_OBSTACLE_CHANCE.size() - 1)
	obstacle_chance = STAGE_OBSTACLE_CHANCE[idx]

func _make_chunk() -> Node3D:
	var template: Node3D
	if obstacle_templates.is_empty() or randf() > obstacle_chance:
		template = plain_template
	else:
		template = obstacle_templates[randi() % obstacle_templates.size()]
	var chunk = template.duplicate()
	chunk.position = Vector3.ZERO
	return chunk

func _place_chunk(z: float, fade: bool = true) -> void:
	var chunk = _make_chunk()
	chunk.position.z = z
	add_child(chunk)
	if fade:
		chunk.scale = Vector3.ZERO
		create_tween().tween_property(chunk, "scale", Vector3.ONE, 0.6)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _process(delta: float) -> void:
	scroll_speed = lerp(scroll_speed, target_speed, SPEED_EASE * delta)
	for child in get_children():
		child.position.z += scroll_speed * delta
		if child.position.z > CHUNK_LENGTH:
			var old_z = child.position.z
			child.queue_free()
			_place_chunk(old_z - CHUNK_LENGTH * CHUNK_COUNT)
