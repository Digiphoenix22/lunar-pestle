extends CharacterBody3D

const GRAVITY        := 80.0
const JUMP_FORCE     := 30.0
const LANE_SPEED     := 10.0
const LANES          := [-8.0, 0.0, 8.0]
const NORMAL_SPEED   := 80.0
const SLOW_SPEED     := 30.0
const INVINCIBILITY  := 1.0
const RECOVER_TIME   := 10.0

var current_lane     := 1
var alive            := true
var hit_count        := 0
var invincible_timer := 0.0
var recover_timer    := 0.0

@onready var death_screen    = $"../CanvasLayer/DeathScreen"
@onready var pause_menu      = $"../CanvasLayer/PauseMenu"
@onready var ground_scroller = $"../GroundScroller"
@onready var hit_sound       = $HitSound

const HIT_SOUNDS := [
	"res://sounds/death/terrariahurt.mp3",
	"res://sounds/death/mcdmg.mp3",
	"res://sounds/death/rblxoof.mp3",
	"res://sounds/death/fah.mp3",
	"res://sounds/death/rblxold.mp3",
]

func _ready() -> void:
	pause_menu.visible = false
	pause_menu.get_node("ResumeButton").pressed.connect(_resume)
	pause_menu.get_node("ExitButton").pressed.connect(func(): get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo()):
		return
	if get_tree().paused:
		_resume()
	elif alive:
		get_tree().paused = true
		pause_menu.visible = true

func _resume() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if invincible_timer > 0:
		invincible_timer -= delta
		$MeshInstance3D.visible = int(invincible_timer * 10) % 2 == 0
	else:
		$MeshInstance3D.visible = true

	if recover_timer > 0:
		recover_timer -= delta
		if recover_timer <= 0:
			hit_count = 0
			ground_scroller.target_speed = NORMAL_SPEED

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
	position.z = 0.0
	velocity.z = 0.0

	if invincible_timer <= 0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider().is_in_group("obstacle"):
				take_hit()
				break

func take_hit() -> void:
	if invincible_timer > 0:
		return
	hit_count += 1
	_play_random_hit()
	if hit_count >= 2:
		die()
	else:
		ground_scroller.target_speed = SLOW_SPEED
		invincible_timer = INVINCIBILITY
		recover_timer = RECOVER_TIME

func _play_random_hit() -> void:
	var path = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_sound.stream = load(path)
	hit_sound.play()

func die() -> void:
	alive = false
	ground_scroller.target_speed = 0.0
	# TODO: trigger ragdoll on model when ready
	await get_tree().create_timer(1.5).timeout
	death_screen.visible = true
	death_screen.get_node("RestartButton").pressed.connect(
		func(): get_tree().reload_current_scene()
	)
