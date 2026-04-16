# camera.gd
extends Camera3D

@export var target: NodePath
@export var lag_speed := 12.0
@export var offset    := Vector3(0, 5, 8)

var _target_node: Node3D

func _ready() -> void:
	_target_node = get_node(target)

func _process(delta: float) -> void:
	var goal = _target_node.global_position + offset
	global_position = lerp(global_position, goal, lag_speed * delta)
