extends CharacterBody3D

const GRAVITY      := 80.0
const JUMP_FORCE   := 30.0
const LANE_SPEED   := 10.0
const LANES        := [-8.0, 0.0, 8.0]

var current_lane   := 1
var alive          := true

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_FORCE

	if Input.is_action_just_pressed("ui_left") and current_lane > 0:
		current_lane -= 1
	if Input.is_action_just_pressed("ui_right") and current_lane < 2:
		current_lane += 1

	position.x = lerp(position.x, LANES[current_lane], LANE_SPEED * delta)

	move_and_slide()

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider().is_in_group("obstacle"):
			die()

func die() -> void:
	alive = false
	print("Lumi hit an obstacle!")
