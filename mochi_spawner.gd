extends Node3D

const BASE_INTERVAL  := 35.0
const MIN_INTERVAL   := 10.0
const SCORE_SCALE    := 8000.0

const LANES   := [-8.0, 0.0, 8.0]
const SPAWN_Z := -85.0
const GONE_Z  := 12.0
const FLOAT_Y := 2.4

var _orb_scene = preload("res://orb.tscn")
var _timer     := 0.0

@onready var ground_scroller = $"../GroundScroller"
@onready var lumi            = $"../Lumi"

func _ready() -> void:
	_timer = BASE_INTERVAL

func _current_interval() -> float:
	var t = clampf(lumi.score / SCORE_SCALE, 0.0, 1.0)
	return lerpf(BASE_INTERVAL, MIN_INTERVAL, t)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = _current_interval()
		_spawn()

	var scroll = ground_scroller.scroll_speed
	for orb in get_children():
		orb.position.z += scroll * delta
		if orb.position.z > GONE_Z:
			orb.queue_free()

func _spawn() -> void:
	var orb      = _orb_scene.instantiate()
	orb.orb_type = "mochi"
	orb.position = Vector3(LANES[randi() % 3], FLOAT_Y, SPAWN_Z)
	add_child(orb)
	var target_scale = orb.scale
	orb.scale = Vector3.ZERO
	create_tween().tween_property(orb, "scale", target_scale, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
