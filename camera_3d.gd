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

func death_zoom() -> void:
	var t = create_tween()
	t.tween_property(self, "fov", 45.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "fov", 88.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
