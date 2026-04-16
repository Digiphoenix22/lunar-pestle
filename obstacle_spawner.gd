extends Node3D

@export var obstacle_scene: PackedScene
@export var spawn_z     := -80.0
@export var ground_y    := 1.0
var scroll_speed        := 80.0

const LANES := [-8.0, 0.0, 8.0]

func _ready() -> void:
	$Timer.wait_time = 2.0
	$Timer.timeout.connect(_spawn)
	$Timer.start()

func _spawn() -> void:
	if obstacle_scene == null:
		return
	var obs = obstacle_scene.instantiate()
	obs.position = Vector3(LANES[randi() % 3], ground_y, spawn_z)
	add_child(obs)

func _process(delta: float) -> void:
	for obs in get_children():
		if obs is Timer:
			continue
		obs.position.z += scroll_speed * delta
		if obs.position.z > 10.0:
			obs.queue_free()
