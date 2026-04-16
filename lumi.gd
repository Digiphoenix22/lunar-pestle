extends CharacterBody3D

const GRAVITY      := 80.0
const JUMP_FORCE   := 30.0
const LANE_SPEED   := 10.0
const LANES        := [-8.0, 0.0, 8.0]

var current_lane   := 1  # 0 = left, 1 = center, 2 = right

func _physics_process(delta: float) -> void:
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
