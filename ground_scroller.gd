extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT  := 10
const STAGE_OBSTACLE_CHANCE := [0.4, 0.55, 0.65, 0.75, 0.85, 0.90, 0.95]
const CHUNK_WEIGHTS := [
	[85, 10,  0,  0,  0,  0,  5],  # player stage 1
	[15, 70, 15,  0,  0,  0,  0],  # player stage 2
	[ 0, 20, 60, 20,  0,  0,  0],  # player stage 3
	[ 0,  0, 20, 60, 20,  0,  0],  # player stage 4
	[ 0,  0,  0, 20, 60, 20,  0],  # player stage 5
	[ 0,  0,  0,  0, 20, 60, 20],  # player stage 6
	[ 0,  0,  0,  0,  0, 30, 70],  # player stage 7
]
# Min/max plain breathing-room chunks forced between obstacles per player stage
const MIN_PLAINS := [1, 1, 1, 0, 0, 1, 2]
const MAX_PLAINS := [4, 3, 2, 1, 1, 5, 8]

var obstacle_chance  := 0.4
var scroll_speed     := 0.0
var target_speed     := 0.0
const SPEED_EASE     := 0.5

var plain_template: Node3D = null
var _stage_templates: Dictionary = {}
var _current_stage: int = 1
var _plains_remaining: int = 2  # start with some breathing room

func _ready() -> void:
	var chunks_root = load("res://chunks.tscn").instantiate()
	for child in chunks_root.get_children():
		if child.name == "Base":
			plain_template = child.duplicate()
		elif child.name.begins_with("Stage"):
			var stage_num: int = child.name.substr(5).to_int()
			var templates: Array[Node3D] = []
			for chunk in child.get_children():
				templates.append(chunk.duplicate())
			_stage_templates[stage_num] = templates
	chunks_root.free()

	var first = plain_template.duplicate()
	first.position.z = 0.0
	_tag_chunk(first, plain_template)
	add_child(first)
	for i in range(1, CHUNK_COUNT):
		_place_chunk(-i * CHUNK_LENGTH, false)

# Set true to measure chunk length from Start/End Marker3D nodes instead of CHUNK_LENGTH.
const USE_MARKER_LENGTH := false

func _template_length(template: Node3D) -> float:
	if USE_MARKER_LENGTH:
		var start_node = template.get_node_or_null("Start")
		var end_node   = template.get_node_or_null("End")
		if end_node:
			var start_z: float = start_node.position.z if start_node else 0.0
			return maxf(absf(end_node.position.z - start_z), CHUNK_LENGTH)
	return CHUNK_LENGTH

func _tag_chunk(chunk: Node3D, template: Node3D) -> void:
	chunk.set_meta("chunk_length", _template_length(template))

func set_stage(stage: int) -> void:
	_current_stage = stage
	var idx := clampi(stage - 1, 0, STAGE_OBSTACLE_CHANCE.size() - 1)
	obstacle_chance = STAGE_OBSTACLE_CHANCE[idx]

func _pick_chunk_stage() -> int:
	var weights: Array = CHUNK_WEIGHTS[clampi(_current_stage - 1, 0, CHUNK_WEIGHTS.size() - 1)]
	var total := 0
	for w in weights:
		total += w
	var roll := randi() % total
	var acc := 0
	for i in weights.size():
		acc += weights[i]
		if roll < acc:
			return i + 1
	return _current_stage

func _make_chunk() -> Node3D:
	var template: Node3D

	if _stage_templates.is_empty():
		template = plain_template
	elif _plains_remaining > 0:
		_plains_remaining -= 1
		template = plain_template
	elif randf() > obstacle_chance:
		template = plain_template
	else:
		var stage_pick := _pick_chunk_stage()
		var pool: Array = _stage_templates.get(stage_pick, [])
		if pool.is_empty():
			pool = _stage_templates.get(1, [])
		if pool.is_empty():
			template = plain_template
		else:
			template = pool[randi() % pool.size()]
			var si := clampi(_current_stage - 1, 0, MIN_PLAINS.size() - 1)
			_plains_remaining = randi_range(MIN_PLAINS[si], MAX_PLAINS[si])

	var chunk = template.duplicate()
	chunk.position = Vector3.ZERO
	_tag_chunk(chunk, template)
	return chunk

func _place_chunk(z: float, fade: bool = true) -> void:
	var chunk = _make_chunk()
	chunk.position.z = z
	add_child(chunk)
	if fade:
		if _current_stage >= 6:
			chunk.scale = Vector3.ZERO
			create_tween().tween_property(chunk, "scale", Vector3.ONE, 0.6)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			_fade_in_chunk(chunk, 0.18)

func _fade_in_chunk(chunk: Node3D, duration: float) -> void:
	var meshes: Array = []
	_collect_meshes(chunk, meshes)
	for m in meshes:
		(m as MeshInstance3D).transparency = 1.0
	var t = create_tween()
	for m in meshes:
		t.parallel().tween_property(m, "transparency", 0.0, duration)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)

func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)

func _process(delta: float) -> void:
	scroll_speed = lerp(scroll_speed, target_speed, SPEED_EASE * delta)
	for child in get_children():
		child.position.z += scroll_speed * delta
		var cl: float = maxf(child.get_meta("chunk_length", CHUNK_LENGTH), CHUNK_LENGTH)
		if child.position.z > cl:
			var old_z: float = child.position.z
			child.queue_free()
			_place_chunk(old_z - cl * CHUNK_COUNT)
