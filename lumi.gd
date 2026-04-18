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
var boost_timer      := 0.0

const BOOST_DURATION := 5.0
const BOOST_MULT     := 5.0

@onready var death_screen    = $"../CanvasLayer/DeathScreen"
@onready var pause_menu      = $"../CanvasLayer/PauseMenu"
@onready var ground_scroller = $"../GroundScroller"
@onready var hit_sound       = $HitSound
@onready var boost_sound     = $BoostSound
@onready var pip1            = $"../CanvasLayer/HUD/Pip1"
@onready var pip2            = $"../CanvasLayer/HUD/Pip2"
@onready var slow_indicator  = $"../CanvasLayer/HUD/SlowIndicator"
@onready var slow_label      = $"../CanvasLayer/HUD/SlowIndicator/SlowLabel"
@onready var slow_anim       = $"../CanvasLayer/HUD/SlowIndicator/AnimationPlayer"
@onready var lumi_rect       = $"../CanvasLayer/HUD/LumiRect"
@onready var bottom_hud      = $"../CanvasLayer/HUD/BottomHud"
@onready var white_flash     = $"../CanvasLayer/HUD/WhiteFlash"
@onready var blur_overlay    = $"../CanvasLayer/BlurOverlay"
@onready var camera          = $"../Camera3D"

const LUMI_RECT_REST_Y := 515.0
const LUMI_RECT_JUMP_Y := 462.0
const HUD_PURPLE       := Color(0.75, 0.507, 0.994, 1.0)
const HUD_INDIGO       := Color(0.22, 0.08, 0.65, 1.0)

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
	pause_menu.get_node("ExitButton").pressed.connect(func():
		get_tree().paused = false
		Transition.change_scene("res://main_menu.tscn"))
	_start_bottom_hud_tween()
	_build_slow_anim()
	_setup_blur_overlay()

func _setup_blur_overlay() -> void:
	var shader = load("res://blur.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	blur_overlay.material = mat

func _show_menu(menu: Control) -> void:
	blur_overlay.visible = true
	blur_overlay.modulate.a = 0.0
	menu.pivot_offset = Vector2(960, 540)
	menu.scale = Vector2(0.92, 0.92)
	menu.modulate.a = 0.0
	menu.visible = true
	var t = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(blur_overlay, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(menu, "scale", Vector2.ONE, 0.22)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(menu, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)

func _hide_menu(menu: Control) -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(blur_overlay, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN)
	t.tween_property(menu, "scale", Vector2(0.92, 0.92), 0.14)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(menu, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await t.finished
	menu.visible = false
	blur_overlay.visible = false

func _build_slow_anim() -> void:
	var anim = Animation.new()
	anim.length = 0.7
	anim.loop_mode = Animation.LOOP_LINEAR

	var st = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(st, ".:scale")
	anim.track_insert_key(st, 0.0,  Vector2(1.0,  1.0))
	anim.track_insert_key(st, 0.35, Vector2(1.06, 1.06))
	anim.track_insert_key(st, 0.7,  Vector2(1.0,  1.0))
	anim.track_set_interpolation_type(st, Animation.INTERPOLATION_CUBIC)

	var mt = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(mt, ".:modulate")
	anim.track_insert_key(mt, 0.0,  Color(1, 1, 1, 1.0))
	anim.track_insert_key(mt, 0.35, Color(1, 1, 1, 0.65))
	anim.track_insert_key(mt, 0.7,  Color(1, 1, 1, 1.0))
	anim.track_set_interpolation_type(mt, Animation.INTERPOLATION_CUBIC)

	var lib = AnimationLibrary.new()
	lib.add_animation("pulse", anim)
	slow_anim.add_animation_library("", lib)

func _start_bottom_hud_tween() -> void:
	var t = create_tween().set_loops()
	t.tween_property(bottom_hud, "modulate", HUD_INDIGO, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bottom_hud, "modulate", HUD_PURPLE, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	if event.is_action("ui_cancel"):
		if get_tree().paused:
			_resume()
		elif alive:
			get_tree().paused = true
			_show_menu(pause_menu)
	elif event.keycode == KEY_B:
		_toggle_boost()
	elif event.keycode == KEY_PERIOD and alive:
		die()

func _resume() -> void:
	get_tree().paused = false
	_hide_menu(pause_menu)

func _physics_process(delta: float) -> void:
	if not alive or get_tree().paused:
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
			if boost_timer <= 0:
				ground_scroller.target_speed = NORMAL_SPEED

	if boost_timer > 0:
		boost_timer -= delta
		if boost_timer <= 0:
			ground_scroller.target_speed = SLOW_SPEED if recover_timer > 0 else NORMAL_SPEED

	_update_hud()

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

func _update_hud() -> void:
	var slowed = recover_timer > 0
	slow_indicator.visible = slowed
	if slowed:
		if not slow_anim.is_playing():
			slow_anim.play("pulse")
		slow_label.text = "Slowed!  %ds" % ceili(recover_timer)
	else:
		if slow_anim.is_playing():
			slow_anim.stop()
			slow_indicator.scale = Vector2.ONE
			slow_indicator.modulate = Color(1, 1, 1, 1)
		slow_label.text = "Slowed!"
	pip1.color = Color(0.2, 1.0, 0.3, 1.0) if hit_count == 0 else Color(0.3, 0.3, 0.3, 1.0)
	pip2.color = Color(0.2, 1.0, 0.3, 1.0) if hit_count == 0 else Color(1.0, 0.3, 0.1, 1.0)
	lumi_rect.position.y = clampf(remap(position.y, 2.2, 8.0, LUMI_RECT_REST_Y, LUMI_RECT_JUMP_Y), LUMI_RECT_JUMP_Y, LUMI_RECT_REST_Y)

func _toggle_boost() -> void:
	if boost_timer > 0:
		boost_timer = 0.0
		ground_scroller.target_speed = SLOW_SPEED if recover_timer > 0 else NORMAL_SPEED
	else:
		boost_timer = BOOST_DURATION
		var base = SLOW_SPEED if recover_timer > 0 else NORMAL_SPEED
		ground_scroller.target_speed = base * BOOST_MULT
		boost_sound.stream = load("res://sounds/death/speed.mp3")
		boost_sound.play()

func _do_flash(color: Color, duration: float) -> void:
	white_flash.color = color
	white_flash.modulate.a = 1.0
	create_tween().tween_property(white_flash, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func take_hit() -> void:
	if invincible_timer > 0:
		return
	hit_count += 1
	_play_random_hit()
	if hit_count >= 2:
		die()
	else:
		_do_flash(Color(1, 0.15, 0.15, 0.45), 0.2)
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
	camera.death_zoom()
	_do_flash(Color(1, 1, 1, 1), 0.35)
	# TODO: trigger ragdoll on model when ready
	await get_tree().create_timer(1.5).timeout
	_show_menu(death_screen)
	death_screen.get_node("RestartButton").pressed.connect(
		func(): Transition.reload_scene()
	)
