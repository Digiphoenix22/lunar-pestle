extends CharacterBody3D

const GRAVITY             := 80.0
const JUMP_FORCE          := 30.0
const LANE_SPEED          := 10.0
const LANES               := [-8.0, 0.0, 8.0]
const NORMAL_SPEED        := 80.0
const SLOW_SPEED          := 30.0
const SLEEPY_SPEED        := 15.0
const INVINCIBILITY       := 1.0
const RECOVER_TIME        := 10.0
const SLEEPY_DURATION     := 8.0
const MAYA_JUMP_FORCE     := 48.0
const MAYA_FLOAT_DURATION := 1.0
const MAYA_GRAVITY_MULT   := 0.25

const BOOST_DURATION := 5.0
const BOOST_MULT     := 5.0

const STAGE_SCORES := [0, 1500, 4000, 9000, 18000, 32000]
const STAGE_SPEED  := [80.0, 90.0, 105.0, 120.0, 135.0, 155.0]

var current_lane      := 1
var alive             := true
var hit_count         := 0
var invincible_timer  := 0.0
var recover_timer     := 0.0
var boost_timer       := 0.0
var sleepy_timer      := 0.0
var maya_jump         := false
var _jump_count       := 0
var _maya_float_timer := 0.0
var elapsed_time  := 0.0
var distance      := 0.0
var score         := 0
var mochi_count   := 0
var current_stage := 1
var god_mode      := false
var _won          := false

var _lumi_tex_normal = preload("res://images/buni.png")
var _lumi_tex_hurt   = preload("res://images/bunihurt.png")

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
@onready var victory_screen  = $"../CanvasLayer/VictoryScreen"
@onready var stage_label     = $"../CanvasLayer/HUD/StageLabel"
@onready var score_label     = $"../CanvasLayer/HUD/ScoreLabel"
@onready var time_label      = $"../CanvasLayer/HUD/TimeLabel"
@onready var dist_label      = $"../CanvasLayer/HUD/DistLabel"
@onready var mochi_label     = $"../CanvasLayer/HUD/MochiLabel"
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

var _options_scene    = preload("res://options_menu.tscn")
var _options_instance: Control = null
var _powerup_sound:    AudioStreamPlayer

func _ready() -> void:
	pause_menu.visible = false
	var resume_btn  = pause_menu.get_node("ResumeButton")
	var options_btn = pause_menu.get_node("OptionsButton")
	var exit_btn    = pause_menu.get_node("ExitButton")
	Transition.wire_buttons([resume_btn, options_btn, exit_btn])
	resume_btn.pressed.connect(_resume)
	options_btn.pressed.connect(_open_options)
	exit_btn.pressed.connect(func():
		get_tree().paused = false
		Transition.change_scene("res://main_menu.tscn"))
	hit_sound.bus   = "SFX"
	boost_sound.bus = "SFX"
	_powerup_sound = AudioStreamPlayer.new()
	_powerup_sound.stream = load("res://sounds/sfx/powerup.mp3")
	_powerup_sound.volume_db = -2.5
	_powerup_sound.bus = _ensure_powerup_bus()
	add_child(_powerup_sound)
	_start_bottom_hud_tween()
	_build_slow_anim()
	_setup_blur_overlay()

func _open_options() -> void:
	if _options_instance:
		return
	_options_instance = _options_scene.instantiate()
	get_node("../CanvasLayer").add_child(_options_instance)
	var back_btn = _options_instance.get_node("Panel/VBox/BackButton")
	Transition.wire_buttons([back_btn])
	back_btn.pressed.connect(_close_options)
	_show_menu(_options_instance)

func _close_options() -> void:
	if not _options_instance:
		return
	await _hide_menu(_options_instance)
	_options_instance.queue_free()
	_options_instance = null

func _ensure_powerup_bus() -> String:
	const BUS := "PowerupSFX"
	if AudioServer.get_bus_index(BUS) == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_send(idx, "SFX")
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.35
		reverb.damping   = 0.65
		reverb.wet       = 0.28
		reverb.dry       = 1.0
		AudioServer.add_bus_effect(idx, reverb)
	return BUS

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
	elif event.keycode == KEY_BRACKETRIGHT:
		if current_stage < STAGE_SCORES.size():
			current_stage += 1
			_on_stage_up()
	elif event.keycode == KEY_G:
		var types := ["sleepy", "jade", "maya"]
		collect_orb(types[randi() % types.size()])
	elif event.keycode == KEY_H:
		collect_orb("mochi")
	elif event.keycode == KEY_T:
		god_mode = !god_mode
		_do_flash(Color(0.3, 1.0, 1.0, 0.5) if god_mode else Color(0.5, 0.5, 0.5, 0.4), 0.3)

func _resume() -> void:
	get_tree().paused = false
	_hide_menu(pause_menu)

func _base_speed() -> float:
	if sleepy_timer > 0 or recover_timer > 0:
		return SLEEPY_SPEED if sleepy_timer > 0 else SLOW_SPEED
	return STAGE_SPEED[current_stage - 1]

func _check_stage() -> void:
	var new_stage = 1
	for i in range(1, STAGE_SCORES.size()):
		if score >= STAGE_SCORES[i]:
			new_stage = i + 1
	if new_stage > current_stage:
		current_stage = new_stage
		_on_stage_up()

func _on_stage_up() -> void:
	ground_scroller.set_stage(current_stage)
	if boost_timer <= 0:
		ground_scroller.target_speed = _base_speed()
	_do_flash(Color(1.0, 0.85, 0.2, 0.45), 0.4)
	var notif = Label.new()
	notif.text = "STAGE %d" % current_stage
	notif.add_theme_font_override("font", load("res://fonts/ExodusDisplay-SharpenBold.otf"))
	notif.add_theme_font_size_override("font_size", 72)
	notif.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.set_anchors_preset(Control.PRESET_CENTER)
	notif.position = Vector2(-200, -80)
	notif.modulate.a = 0.0
	get_node("../CanvasLayer/HUD").add_child(notif)
	var t = create_tween()
	t.tween_property(notif, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.2)
	t.tween_property(notif, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	t.tween_callback(notif.queue_free)

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
				ground_scroller.target_speed = _base_speed()

	if sleepy_timer > 0:
		sleepy_timer -= delta
		if sleepy_timer <= 0 and boost_timer <= 0:
			ground_scroller.target_speed = _base_speed()

	if boost_timer > 0:
		boost_timer -= delta
		if boost_timer <= 0:
			ground_scroller.target_speed = _base_speed()

	if _maya_float_timer > 0:
		_maya_float_timer -= delta

	elapsed_time += delta
	distance     += ground_scroller.scroll_speed * delta
	score         = int(distance * 0.5 + elapsed_time * 10.0)
	_check_stage()


	_update_hud()

	if is_on_floor():
		_jump_count = 0

	if not is_on_floor():
		var grav_mult = MAYA_GRAVITY_MULT if _maya_float_timer > 0 else 1.0
		velocity.y -= GRAVITY * grav_mult * delta

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_FORCE
			_jump_count = 1
		elif maya_jump and _jump_count < 2:
			velocity.y = MAYA_JUMP_FORCE
			_jump_count = 2
			maya_jump = false
			_maya_float_timer = MAYA_FLOAT_DURATION

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
	var debuffed = recover_timer > 0 or sleepy_timer > 0
	slow_indicator.visible = debuffed
	if debuffed:
		if not slow_anim.is_playing():
			slow_anim.play("pulse")
		if sleepy_timer > 0 and recover_timer > 0:
			slow_label.text = "Sleepy+Slow!  %ds" % ceili(maxf(sleepy_timer, recover_timer))
		elif sleepy_timer > 0:
			slow_label.text = "Sleepy!  %ds" % ceili(sleepy_timer)
		else:
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
	lumi_rect.texture = _lumi_tex_hurt if hit_count > 0 else _lumi_tex_normal
	score_label.text  = "%d" % score
	stage_label.text  = "Stage %d" % current_stage
	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	time_label.text  = "%d:%02d" % [mins, secs]
	dist_label.text  = "%dm" % int(distance)
	mochi_label.text = "Mochi  x%d" % mochi_count

func _toggle_boost() -> void:
	if boost_timer > 0:
		boost_timer = 0.0
		ground_scroller.target_speed = _base_speed()
	else:
		boost_timer = BOOST_DURATION
		ground_scroller.target_speed = _base_speed() * BOOST_MULT
		boost_sound.stream = load("res://sounds/death/speed.mp3")
		boost_sound.play()

func _do_flash(color: Color, duration: float) -> void:
	white_flash.color = color
	white_flash.modulate.a = 1.0
	create_tween().tween_property(white_flash, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func collect_orb(orb_type: String) -> void:
	_powerup_sound.play()
	match orb_type:
		"sleepy":
			sleepy_timer = SLEEPY_DURATION
			_do_flash(Color(0.5, 0.2, 1.0, 0.4), 0.25)
			if boost_timer <= 0:
				ground_scroller.target_speed = SLEEPY_SPEED
		"jade":
			hit_count    = 0
			recover_timer  = 0.0
			sleepy_timer   = 0.0
			invincible_timer = 0.0
			_do_flash(Color(0.1, 1.0, 0.4, 0.5), 0.3)
			if boost_timer <= 0:
				ground_scroller.target_speed = NORMAL_SPEED
		"maya":
			maya_jump = true
			_do_flash(Color(0.2, 0.6, 1.0, 0.4), 0.25)
		"mochi":
			mochi_count += 1
			_do_flash(Color(1.0, 0.75, 0.1, 0.45), 0.3)
			if mochi_count >= 10 and not _won:
				_trigger_win()

func take_hit() -> void:
	if god_mode or invincible_timer > 0:
		return
	hit_count += 1
	_play_random_hit()
	if hit_count >= 2:
		die()
	else:
		_do_flash(Color(1, 0.15, 0.15, 0.45), 0.2)
		if boost_timer <= 0:
			ground_scroller.target_speed = SLOW_SPEED
		invincible_timer = INVINCIBILITY
		recover_timer    = RECOVER_TIME

func _play_random_hit() -> void:
	var path = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_sound.stream = load(path)
	hit_sound.play()

func _trigger_win() -> void:
	_won = true
	var slow_tween = create_tween()
	slow_tween.tween_method(func(v: float): Engine.time_scale = v, 1.0, 0.05, 1.5)
	await get_tree().create_timer(2.2, true, false, true).timeout
	slow_tween.kill()
	Engine.time_scale = 1.0
	get_tree().paused = true
	victory_screen.get_node("ScoreText").text = "Score: %d" % score
	_show_menu(victory_screen)
	var cont_btn = victory_screen.get_node("ContinueButton")
	var quit_btn = victory_screen.get_node("QuitButton")
	Transition.wire_buttons([cont_btn, quit_btn])
	cont_btn.pressed.connect(func():
		get_tree().paused = false
		_hide_menu(victory_screen)
	, CONNECT_ONE_SHOT)
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		Engine.time_scale = 1.0
		Transition.change_scene("res://main_menu.tscn")
	, CONNECT_ONE_SHOT)

func die() -> void:
	Engine.time_scale = 1.0
	alive = false
	ground_scroller.target_speed = 0.0
	camera.death_zoom()
	_do_flash(Color(1, 1, 1, 1), 0.35)
	# TODO: trigger ragdoll on model when ready
	await get_tree().create_timer(1.5).timeout
	_show_menu(death_screen)
	var restart_btn = death_screen.get_node("RestartButton")
	var quit_btn    = death_screen.get_node("QuitButton")
	Transition.wire_buttons([restart_btn, quit_btn])
	restart_btn.pressed.connect(func(): Transition.reload_scene(), CONNECT_ONE_SHOT)
	quit_btn.pressed.connect(func(): Transition.change_scene("res://main_menu.tscn"), CONNECT_ONE_SHOT)
