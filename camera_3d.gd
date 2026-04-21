# camera.gd
extends Camera3D

@export var target: NodePath
@export var lag_speed := 12.0
@export var offset    := Vector3(0, 5, 8)

var _target_node: Node3D
var _shake_trauma := 0.0

func _ready() -> void:
	_target_node = get_node(target)

func shake(trauma: float) -> void:
	_shake_trauma = minf(_shake_trauma + trauma, 1.0)

func _process(delta: float) -> void:
	var goal = _target_node.global_position + offset
	global_position = lerp(global_position, goal, lag_speed * delta)
	if _shake_trauma > 0.0:
		var s := _shake_trauma * _shake_trauma
		global_position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * s * 0.55
		_shake_trauma = move_toward(_shake_trauma, 0.0, delta * 2.8)

func death_zoom() -> void:
	var t = create_tween()
	t.tween_property(self, "fov", 45.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "fov", 88.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
