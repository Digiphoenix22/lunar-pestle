extends Node3D

@export var spawn_interval := 3.0   # seconds between drops — lower = more frequent
@export var start_delay    := 2.0   # extra wait before first drop
@export var drop_height    := 2.0 # Y to spawn at
@export var land_y         := 1.5   # Y to settle on (floor + half block)
@export var fall_speed     := 18.0  # units/s fall rate

const LANES   := [-8.0, 0.0, 8.0]
const SPAWN_Z := -85.0
const GONE_Z  := 12.0

var templates: Array[Node3D] = []
var _timer := 0.0
var _enemy_scene: PackedScene = load("res://Enemies.glb")

@onready var ground_scroller = $"../GroundScroller"

func _ready() -> void:
	var root = load("res://spawn_blocks.tscn").instantiate()
	for child in root.get_children():
		var t = child.duplicate()
		_apply_danger_material(t)
		templates.append(t)
	root.free()
	_timer = spawn_interval + start_delay

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_spawn()

	var scroll = ground_scroller.scroll_speed
	for block in get_children():
		block.position.z += scroll * delta
		if block.position.y > land_y:
			block.position.y = move_toward(block.position.y, land_y, fall_speed * delta)
		if block.position.z > GONE_Z:
			block.queue_free()

func _spawn() -> void:
	if templates.is_empty():
		return
	var block = templates[randi() % templates.size()].duplicate()
	block.position = Vector3(LANES[randi() % 3], drop_height, SPAWN_Z)
	block.scale = Vector3.ZERO
	_tag_obstacles(block)
	_hide_csg(block)
	var model := _enemy_scene.instantiate() as Node3D
	block.add_child(model)
	add_child(block)
	create_tween().tween_property(block, "scale", Vector3.ONE, 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _hide_csg(node: Node) -> void:
	if node is CSGShape3D:
		(node as GeometryInstance3D).visible = false
	for child in node.get_children():
		_hide_csg(child)

func _apply_danger_material(node: Node) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color               = Color(0.55, 0.0, 0.0, 1.0)
	mat.emission_enabled           = true
	mat.emission                   = Color(0.8, 0.0, 0.0, 1.0)
	mat.emission_energy_multiplier = 20.0
	if node is CSGShape3D:
		node.material = mat
	elif node is GeometryInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_danger_material(child)

func _tag_obstacles(node: Node) -> void:
	if node is StaticBody3D:
		node.add_to_group("obstacle")
	for child in node.get_children():
		_tag_obstacles(child)
