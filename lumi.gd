extends CharacterBody3D

const GRAVITY             := 80.0
const JUMP_FORCE          := 30.0
const LANE_SPEED          := 10.0
const LANES               := [-8.0, 0.0, 8.0]
const NORMAL_SPEED        := 80.0
const SLOW_SPEED          := 30.0
const SLEEPY_SPEED        := 15.0
const INVINCIBILITY       := 1.0
const RECOVER_TIME        := 5.0
const SLEEPY_DURATION     := 10.0
const MAYA_JUMP_FORCE     := 48.0
const MAYA_FLOAT_DURATION := 1.0
const MAYA_GRAVITY_MULT   := 0.25

const BOOST_DURATION := 5.0
const BOOST_MULT     := 5.0

const STAGE_SCORES := [0, 1000, 2000, 3500, 5000, 7500, 10000]
const STAGE_SPEED  := [80.0, 90.0, 105.0, 120.0, 135.0, 155.0, 275.0]

var current_lane      := 1
var alive             := true
var hit_count         := 0
var invincible_timer  := 0.0
var recover_timer     := 0.0
var boost_timer       := 0.0
var sleepy_timer      := 0.0
var sleepy_stored     := false
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

enum LumiState { RUN, RUN_HURT, JUMP, JUMP_HURT, DEAD }

var _lumi_tex_run       = preload("res://images/Lumi/LumiRun.png")
var _lumi_tex_run_hurt  = preload("res://images/Lumi/LumiRunHurt.png")
var _lumi_tex_jump      = preload("res://images/Lumi/LumiJump.png")
var _lumi_tex_jump_hurt = preload("res://images/Lumi/LumiJumpHurt.png")
var _lumi_tex_dead      = preload("res://images/Lumi/LumiDead.png")
var _lumi_state         := LumiState.RUN

@onready var death_screen    = $"../CanvasLayer/DeathScreen"
@onready var pause_menu      = $"../CanvasLayer/PauseMenu"
@onready var ground_scroller = $"../GroundScroller"
@onready var hit_sound       = $HitSound
@onready var boost_sound     = $BoostSound
@onready var slow_indicator  = $"../CanvasLayer/HUD/SlowIndicator"
@onready var slow_label      = $"../CanvasLayer/HUD/SlowIndicator/SlowLabel"
@onready var slow_anim       = $"../CanvasLayer/HUD/SlowIndicator/AnimationPlayer"
@onready var lumi_rect       = $"../CanvasLayer/HUD/LumiRect"
@onready var bottom_hud      = $"../CanvasLayer/HUD/BottomHud"
@onready var top_hud         = $"../CanvasLayer/HUD/TopHud"
@onready var victory_screen  = $"../CanvasLayer/VictoryScreen"
@onready var stage_label     = $"../CanvasLayer/HUD/StageLabel"
@onready var score_label     = $"../CanvasLayer/HUD/ScoreLabel"
@onready var best_label      = $"../CanvasLayer/HUD/BestLabel"
@onready var time_label      = $"../CanvasLayer/HUD/TimeLabel"
@onready var dist_label      = $"../CanvasLayer/HUD/DistLabel"
@onready var mochi_label     = $"../CanvasLayer/HUD/MochiLabel"
@onready var speed_label     = $"../CanvasLayer/HUD/SpeedLabel"
@onready var jump_buff_rect   = $"../CanvasLayer/HUD/JumpBuff"
@onready var health_buff_rect = $"../CanvasLayer/HUD/HealthBuff"
@onready var shield_buff_rect = $"../CanvasLayer/HUD/ShieldBuff"
@onready var sleepy_buff_rect = $"../CanvasLayer/HUD/SleepyBuff"
@onready var white_flash     = $"../CanvasLayer/HUD/WhiteFlash"
@onready var blur_overlay    = $"../CanvasLayer/BlurOverlay"
@onready var camera          = $"../Camera3D"
@onready var _anim: AnimationPlayer = $LumiModel/AnimationPlayer

const LUMI_RECT_REST_Y  := 515.0
const LUMI_RECT_JUMP_Y  := 462.0
const HUD_PURPLE        := Color(0.75, 0.507, 0.994, 1.0)
const HUD_INDIGO        := Color(0.22, 0.08,  0.65,  1.0)
const HUD_RED           := Color(0.55, 0.07,  0.07,  1.0)
const HUD_RED_DARK      := Color(0.20, 0.03,  0.03,  1.0)
const SKY_DEFAULT := {
	"top_color":     Color(0.01, 0.005, 0.05,  1.0),
	"mid_color":     Color(0.06, 0.03,  0.18,  1.0),
	"horizon_color": Color(0.18, 0.08,  0.40,  1.0),
	"ground_color":  Color(0.04, 0.02,  0.10,  1.0),
}
const SKY_STAGE5 := {
	"top_color":     Color(0.05, 0.004, 0.004, 1.0),
	"mid_color":     Color(0.20, 0.025, 0.025, 1.0),
	"horizon_color": Color(0.40, 0.06,  0.04,  1.0),
	"ground_color":  Color(0.10, 0.015, 0.010, 1.0),
}
const HEART_JADE        := Color(1.0,  1.0,  1.0,  1.0)
const HEART_DEAD        := Color(0.0,  0.0,  0.0,  1.0)
const HEART_X           := 180.0
const HEART_Y           := 598.0
const HEART_SIZE        := 40.0
const HEART_SPACING     := 46.0

var max_health  := 2
var _hearts: Array = []

const HIT_SOUNDS := [
	"res://sounds/death/terrariahurt.mp3",
	"res://sounds/death/mcdmg.mp3",
	"res://sounds/death/rblxoof.mp3",
	"res://sounds/death/fah.mp3",
	"res://sounds/death/rblxold.mp3",
]

const MAYA_GLOW_COLOR   := Color(0.2,  0.65, 1.0,  1.0)
const SHIELD_COLOR      := Color(0.75, 0.42, 0.05, 1.0)
const SHIELD_DURATION   := 30.0

var _options_scene    = preload("res://options_menu.tscn")
var _options_instance: Control = null
var _powerup_sound:    AudioStreamPlayer
var _double_jumping      := false
var _dj_anim_triggered   := false
var _air_dash_held       := false
var _last_dash_dir    := 0  # -1 left, 1 right, 0 none
var _maya_glow_mat:        ShaderMaterial
var shield_active         := false
var shield_timer          := 0.0
var _shield_orb:           MeshInstance3D
var _shield_pulse_tween:   Tween
var _shield_buff_float:    Tween
var _shield_buff_show:     Tween
var _shield_buff_rest_y:   float
var _sleepy_buff_float:    Tween
var _sleepy_buff_show:     Tween
var _sleepy_buff_rest_y:   float
var _jump_buff_glow_mat:    ShaderMaterial
var _jump_buff_float_tween: Tween
var _jump_buff_show_tween:  Tween
var _jump_buff_rest_y:      float
var _lumi_breath_tween:    Tween
var _hud_cycle_tween:      Tween
var _stage5_sky_rotating:  bool = false
var _lumi_extra_y     := 0.0
var _bob_amplitude    := 0.0
var _hearts_in_air    := false
var _dash_sound:       AudioStreamPlayer
var _dash_cooldown     := 0.0
var _heart_anim        := false
var _music:            AudioStreamPlayer
var _music_lpf:        AudioEffectLowPassFilter
var _music_phaser:     AudioEffectPhaser

static var _death_restart := false
var _game_started         := false

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
		_clear_lpf()
		Transition.change_scene("res://main_menu.tscn"))
	hit_sound.bus   = "SFX"
	boost_sound.bus = "SFX"
	_powerup_sound = AudioStreamPlayer.new()
	_powerup_sound.stream = load("res://sounds/sfx/powerup.mp3")
	_powerup_sound.volume_db = -2.5
	_powerup_sound.bus = _ensure_powerup_bus()
	add_child(_powerup_sound)
	_dash_sound = AudioStreamPlayer.new()
	_dash_sound.stream = load("res://sounds/sfx/dash.mp3")
	_dash_sound.bus = "SFX"
	add_child(_dash_sound)
	_music = AudioStreamPlayer.new()
	_music.stream    = load("res://sounds/music/Gameplay OST.wav")
	_music.bus       = "Music"
	_music.volume_db = -80.0
	add_child(_music)
	_music_lpf = AudioEffectLowPassFilter.new()
	_music_lpf.cutoff_hz = 20500.0
	var music_idx = AudioServer.get_bus_index("Music")
	AudioServer.add_bus_effect(music_idx, _music_lpf)
	_music.finished.connect(func(): if alive: _music.play())
	var is_restart := _death_restart
	if _death_restart:
		_death_restart = false
		_music.volume_db = 0.0
		_music.pitch_scale = 0.72
		_music.play()
		create_tween().tween_property(_music, "pitch_scale", 1.0, 3.0)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_reset_sky_colors()
	_build_hearts()
	_setup_maya_glow()
	_setup_jump_buff_glow()
	_create_shield_orb()
	_start_bottom_hud_tween()
	_build_slow_anim()
	_setup_blur_overlay()
	_start_lumi_breath()
	if is_restart:
		_begin_game()
	else:
		for n in get_tree().get_nodes_in_group("spawners"):
			n.process_mode = Node.PROCESS_MODE_DISABLED
		_play_hud_intro()
		await _start_countdown()
		_music.volume_db = -80.0
		_music.play()
		create_tween().tween_property(_music, "volume_db", 0.0, 1.5)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_begin_game()

func _build_hearts() -> void:
	for h in _hearts:
		h.queue_free()
	_hearts.clear()
	var tex = load("res://images/heart.png")
	var hud = get_node("../CanvasLayer/HUD")
	for i in max_health:
		var h := TextureRect.new()
		h.texture = tex
		h.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.layout_mode = 0
		h.offset_left   = HEART_X + i * HEART_SPACING
		h.offset_top    = HEART_Y
		h.offset_right  = HEART_X + i * HEART_SPACING + HEART_SIZE
		h.offset_bottom = HEART_Y + HEART_SIZE
		h.pivot_offset  = Vector2(HEART_SIZE * 0.5, HEART_SIZE * 0.5)
		h.modulate = HEART_JADE
		hud.add_child(h)
		_hearts.append(h)

func add_heart() -> void:
	max_health += 1
	_build_hearts()
	_hearts[-1].modulate = HEART_DEAD
	_hearts[-1].scale = Vector2.ZERO
	var t = create_tween().set_parallel(true)
	t.tween_property(_hearts[-1], "modulate", HEART_JADE, 0.4).set_ease(Tween.EASE_OUT)
	t.tween_property(_hearts[-1], "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t.finished
	create_tween().tween_property(_hearts[-1], "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

func _open_options() -> void:
	if _options_instance:
		return
	_options_instance = _options_scene.instantiate()
	get_node("../CanvasLayer").add_child(_options_instance)
	var back_btn = _options_instance.get_node("Panel/VBox/BackButton")
	Transition.wire_buttons([back_btn])
	back_btn.pressed.connect(_close_options)
	_show_panel(_options_instance)

func _close_options() -> void:
	if not _options_instance:
		return
	await _hide_panel(_options_instance)
	_options_instance.queue_free()
	_options_instance = null

func _show_panel(menu: Control) -> void:
	menu.pivot_offset = Vector2(960, 540)
	menu.scale = Vector2(0.92, 0.92)
	menu.modulate.a = 0.0
	menu.visible = true
	var t = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(menu, "scale", Vector2.ONE, 0.22)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(menu, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)

func _hide_panel(menu: Control) -> void:
	var t = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(menu, "scale", Vector2(0.92, 0.92), 0.14)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(menu, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await t.finished
	menu.visible = false

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

func _hide_menu(menu: Control, hide_blur: bool = true) -> void:
	var t = create_tween().set_parallel(true)
	if hide_blur:
		t.tween_property(blur_overlay, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN)
	t.tween_property(menu, "scale", Vector2(0.92, 0.92), 0.14)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(menu, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await t.finished
	menu.visible = false
	if hide_blur:
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

func _play_hud_intro() -> void:
	var top_nodes: Array = [top_hud, stage_label, score_label, best_label, mochi_label]
	var bot_nodes: Array = [bottom_hud, lumi_rect, time_label, dist_label, speed_label, slow_indicator] + _hearts
	var top_rests: Array = []
	var bot_rests: Array = []
	for n: Control in top_nodes:
		top_rests.append(n.position.y)
		n.position.y -= 220.0
	for n: Control in bot_nodes:
		bot_rests.append(n.position.y)
		n.position.y += 220.0
	var t = create_tween().set_parallel(true)
	for i in top_nodes.size():
		t.tween_property(top_nodes[i], "position:y", top_rests[i], 0.7)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.1)
	for i in bot_nodes.size():
		t.tween_property(bot_nodes[i], "position:y", bot_rests[i], 0.7)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.1)

func _begin_game() -> void:
	_game_started = true
	ground_scroller.target_speed = _base_speed()
	for n in get_tree().get_nodes_in_group("spawners"):
		n.process_mode = Node.PROCESS_MODE_INHERIT

func _play_countdown_sfx(path: String) -> void:
	var snd = AudioStreamPlayer.new()
	snd.stream    = load(path)
	snd.bus       = "SFX"
	snd.volume_db = linear_to_db(0.7)
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)

func _start_countdown() -> void:
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var reverb  = AudioEffectReverb.new()
	reverb.room_size = 0.5
	reverb.damping   = 0.5
	reverb.wet       = 0.22
	reverb.dry       = 1.0
	AudioServer.add_bus_effect(sfx_idx, reverb)

	var hud  = get_node("../CanvasLayer/HUD")
	var font = load("res://fonts/ExodusDisplay-SharpenBold.otf")
	var lbl  = Label.new()
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 128)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.size     = Vector2(300, 160)
	lbl.position = Vector2(-150, -80)
	hud.add_child(lbl)

	for n in [3, 2, 1]:
		_play_countdown_sfx("res://sounds/sfx/countdownstart.mp3")
		lbl.text = str(n)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lbl.modulate.a = 0.0
		lbl.scale      = Vector2(1.4, 1.4)
		lbl.pivot_offset = lbl.size * 0.5
		var t_in = create_tween().set_parallel(true)
		t_in.tween_property(lbl, "modulate:a", 1.0,      0.18).set_ease(Tween.EASE_OUT)
		t_in.tween_property(lbl, "scale",      Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await t_in.finished
		await get_tree().create_timer(0.62).timeout
		var t_out = create_tween()
		t_out.tween_property(lbl, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
		await t_out.finished

	_play_countdown_sfx("res://sounds/sfx/countdownfinish.mp3")
	lbl.text = "GO!"
	lbl.add_theme_color_override("font_color", HUD_PURPLE)
	lbl.modulate.a   = 0.0
	lbl.scale        = Vector2(0.75, 0.75)
	lbl.pivot_offset = lbl.size * 0.5
	var go_in = create_tween().set_parallel(true)
	go_in.tween_property(lbl, "modulate:a", 1.0,        0.15).set_ease(Tween.EASE_OUT)
	go_in.tween_property(lbl, "scale",      Vector2(1.1, 1.1), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await go_in.finished
	await get_tree().create_timer(0.45).timeout
	create_tween().tween_property(lbl, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.3).timeout
	lbl.queue_free()

	for i in AudioServer.get_bus_effect_count(sfx_idx):
		if AudioServer.get_bus_effect(sfx_idx, i) is AudioEffectReverb:
			AudioServer.remove_bus_effect(sfx_idx, i)
			break

func _start_lumi_breath() -> void:
	lumi_rect.pivot_offset = Vector2(lumi_rect.size.x * 0.5, lumi_rect.size.y * 0.5)
	lumi_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	lumi_rect.gui_input.connect(_on_lumi_rect_click)
	_restart_breath_tween()

func _restart_breath_tween() -> void:
	if _lumi_breath_tween:
		_lumi_breath_tween.kill()
	_lumi_breath_tween = create_tween().set_loops()
	_lumi_breath_tween.tween_property(lumi_rect, "scale", Vector2(1.035, 1.035), 1.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_lumi_breath_tween.tween_property(lumi_rect, "scale", Vector2.ONE, 1.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_lumi_rect_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		lumi_rect.pivot_offset = Vector2(lumi_rect.size.x * 0.5, lumi_rect.size.y * 0.5)
		var t = create_tween()
		t.tween_property(lumi_rect, "position:y", lumi_rect.position.y - 18.0, 0.12)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(lumi_rect, "position:y", lumi_rect.position.y, 0.2)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		var snd = AudioStreamPlayer.new()
		snd.stream    = load("res://sounds/sfx/lumi2.mp3")
		snd.bus       = "SFX"
		snd.volume_db = -6.0
		add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)

func _transition_to_stage5_colors() -> void:
	if _hud_cycle_tween:
		_hud_cycle_tween.kill()
	_hud_cycle_tween = create_tween().set_loops()
	_hud_cycle_tween.tween_property(bottom_hud, "modulate", HUD_RED_DARK, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.parallel().tween_property(top_hud, "modulate", HUD_RED_DARK, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.tween_property(bottom_hud, "modulate", HUD_RED, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.parallel().tween_property(top_hud, "modulate", HUD_RED, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var sky_mat = _get_sky_mat()
	if sky_mat:
		for param in SKY_STAGE5:
			var from_col: Color = sky_mat.get_shader_parameter(param)
			var to_col: Color   = SKY_STAGE5[param]
			create_tween().tween_method(
				func(v: Color): sky_mat.set_shader_parameter(param, v),
				from_col, to_col, 3.0
			).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_stage5_sky_rotating = true

func _reset_sky_colors() -> void:
	var sky_mat = _get_sky_mat()
	if not sky_mat:
		return
	for param in SKY_DEFAULT:
		sky_mat.set_shader_parameter(param, SKY_DEFAULT[param])
	sky_mat.set_shader_parameter("sky_rotation", 0.0)

func _start_bottom_hud_tween() -> void:
	var start_color := Color(0.220, 0.078, 0.647, 1.0)
	bottom_hud.modulate = start_color
	top_hud.modulate    = start_color
	_hud_cycle_tween = create_tween().set_loops()
	_hud_cycle_tween.tween_property(bottom_hud, "modulate", HUD_INDIGO, 3.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.parallel().tween_property(top_hud, "modulate", HUD_INDIGO, 3.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.tween_property(bottom_hud, "modulate", HUD_PURPLE, 3.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_hud_cycle_tween.parallel().tween_property(top_hud, "modulate", HUD_PURPLE, 3.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	if event.is_action("ui_cancel"):
		if get_tree().paused:
			_resume()
		elif alive:
			get_tree().paused = true
			_show_menu(pause_menu)
			_tween_lpf(400.0, 0.45)
	elif event.keycode == KEY_C and sleepy_stored and alive and _game_started:
		_activate_sleepy()
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
	_tween_lpf(20500.0, 1.4)

func _tween_lpf(target_hz: float, duration: float) -> void:
	var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(func(hz: float): _music_lpf.cutoff_hz = hz,
		_music_lpf.cutoff_hz, target_hz, duration)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _clear_lpf() -> void:
	var idx = AudioServer.get_bus_index("Music")
	for i in range(AudioServer.get_bus_effect_count(idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(idx, i)

func _base_speed() -> float:
	var stage_spd: float = STAGE_SPEED[current_stage - 1] if current_stage <= STAGE_SPEED.size() else STAGE_SPEED[-1]
	if sleepy_timer > 0:
		return stage_spd * 0.7
	if recover_timer > 0:
		return SLOW_SPEED
	return stage_spd

func _check_stage() -> void:
	var new_stage = 1
	for i in range(1, STAGE_SCORES.size()):
		if score >= STAGE_SCORES[i]:
			new_stage = i + 1
	if new_stage > current_stage:
		current_stage = new_stage
		_on_stage_up()

func _get_sky_mat() -> ShaderMaterial:
	var env = get_node("../WorldEnvironment").environment
	if env and env.sky:
		return env.sky.sky_material as ShaderMaterial
	return null

func _on_stage_up() -> void:
	ground_scroller.set_stage(current_stage)
	if boost_timer <= 0:
		ground_scroller.target_speed = _base_speed()
	_do_flash(Color(0.863, 0.714, 0.937, 0.45), 0.4)
	if current_stage == 5:
		_transition_to_stage5_colors()
	var sky_mat = _get_sky_mat()
	if sky_mat:
		var from = float(sky_mat.get_shader_parameter("sky_rotation"))
		var to   = from + 0.35
		create_tween().tween_method(
			func(v: float): sky_mat.set_shader_parameter("sky_rotation", v),
			from, to, 4.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var snd = AudioStreamPlayer.new()
	snd.stream = load("res://sounds/sfx/sfx6.mp3")
	snd.bus = "SFX"
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)
	var notif = Label.new()
	notif.text = "STAGE %d" % current_stage
	notif.add_theme_font_override("font", load("res://fonts/ExodusDisplay-SharpenBold.otf"))
	notif.add_theme_font_size_override("font_size", 72)
	notif.add_theme_color_override("font_color", Color(0.863, 0.714, 0.937, 1.0))
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	notif.set_anchors_preset(Control.PRESET_CENTER)
	notif.size     = Vector2(420, 90)
	notif.position = Vector2(-210, -45)
	notif.modulate.a = 0.0
	get_node("../CanvasLayer/HUD").add_child(notif)
	var t = create_tween()
	t.tween_property(notif, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.2)
	t.tween_property(notif, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	t.tween_callback(notif.queue_free)

func _physics_process(delta: float) -> void:
	if _stage5_sky_rotating:
		var sky_mat = _get_sky_mat()
		if sky_mat:
			var rot: float = sky_mat.get_shader_parameter("sky_rotation")
			sky_mat.set_shader_parameter("sky_rotation", rot + 0.04 * delta)
	if not alive or get_tree().paused:
		return
	if not _game_started:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		velocity.x = 0.0
		move_and_slide()
		position.z = 0.0
		velocity.z = 0.0
		_update_hud()
		return

	if invincible_timer > 0:
		invincible_timer -= delta
		$LumiModel.visible = int(invincible_timer * 10) % 2 == 0
	else:
		$LumiModel.visible = true

	if recover_timer > 0:
		recover_timer -= delta
		if recover_timer <= 0 and boost_timer <= 0:
			ground_scroller.target_speed = _base_speed()

	if sleepy_timer > 0:
		sleepy_timer -= delta
		if sleepy_timer <= 0:
			_remove_music_phaser()
			if boost_timer <= 0:
				ground_scroller.target_speed = _base_speed()

	if boost_timer > 0:
		boost_timer -= delta
		if boost_timer <= 0:
			ground_scroller.target_speed = _base_speed()

	if _maya_float_timer > 0:
		_maya_float_timer -= delta

	if shield_timer > 0:
		shield_timer -= delta
		if shield_timer <= 0 and shield_active:
			shield_active = false
			_deactivate_shield()

	elapsed_time += delta
	distance     += ground_scroller.scroll_speed * delta
	score         = int(distance * 0.5 + elapsed_time * 10.0)
	_check_stage()


	_update_hud()

	if is_on_floor():
		_air_dash_held = false
		if _double_jumping:
			_double_jumping = false
			_dj_anim_triggered = false
			_set_maya_glow(0.0, 0.35)
			create_tween().tween_property(self, "_bob_amplitude", 0.0, 0.3)\
				.set_ease(Tween.EASE_OUT)
		if _hearts_in_air:
			_hearts_in_air = false
			_float_hearts(false)
		_jump_count = 0
	elif not _hearts_in_air:
		_hearts_in_air = true
		_float_hearts(true)

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
			_double_jumping = true
			_dj_anim_triggered = false
			_set_maya_glow(1.5, 0.2)
			_lumi_extra_y = -38.0
			create_tween().tween_property(self, "_lumi_extra_y", 0.0, 0.5)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			create_tween().tween_property(self, "_bob_amplitude", 7.0, 0.25)\
				.set_ease(Tween.EASE_OUT)
			_consume_jump_buff_icon()
			var snd = AudioStreamPlayer.new()
			snd.stream = load("res://sounds/sfx/sfx5.mp3")
			snd.bus = "SFX"
			add_child(snd)
			snd.play()
			snd.finished.connect(snd.queue_free)

	if _dash_cooldown > 0:
		_dash_cooldown -= delta
	if Input.is_action_just_pressed("ui_left") and current_lane > 0:
		current_lane -= 1
		_last_dash_dir = -1
		_play_dash()
	if Input.is_action_just_pressed("ui_right") and current_lane < 2:
		current_lane += 1
		_last_dash_dir = 1
		_play_dash()

	position.x = lerp(position.x, LANES[current_lane], LANE_SPEED * delta)

	move_and_slide()
	position.z = 0.0
	velocity.z = 0.0
	_update_anim()

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
			slow_label.text = "Slowed!  %ds" % ceili(maxf(sleepy_timer, recover_timer))
		elif sleepy_timer > 0:
			slow_label.text = "World Slowed!  %ds" % ceili(sleepy_timer)
		else:
			slow_label.text = "Slowed!  %ds" % ceili(recover_timer)
	else:
		if slow_anim.is_playing():
			slow_anim.stop()
			slow_indicator.scale = Vector2.ONE
			slow_indicator.modulate = Color(1, 1, 1, 1)
		slow_label.text = "Slowed!"
	if not _heart_anim:
		for i in _hearts.size():
			_hearts[i].modulate = HEART_JADE if i < (max_health - hit_count) else HEART_DEAD
	var bob = sin(Time.get_ticks_msec() * 0.006) * _bob_amplitude
	lumi_rect.position.y = clampf(remap(position.y, 2.2, 8.0, LUMI_RECT_REST_Y, LUMI_RECT_JUMP_Y), LUMI_RECT_JUMP_Y, LUMI_RECT_REST_Y) + _lumi_extra_y + bob
	_update_lumi_sprite()
	score_label.text  = "%d" % score
	best_label.text   = "Best: %d" % SaveData.get_high_score()
	stage_label.text  = "Stage %d" % current_stage
	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	time_label.text  = "%d:%02d" % [mins, secs]
	dist_label.text  = "%dm" % int(distance)
	mochi_label.text = "Mochi  x%d" % mochi_count
	speed_label.text = "%du/s" % int(ground_scroller.scroll_speed)

func _toggle_boost() -> void:
	if boost_timer > 0:
		boost_timer = 0.0
		ground_scroller.target_speed = _base_speed()
	else:
		boost_timer = BOOST_DURATION
		ground_scroller.target_speed = _base_speed() * BOOST_MULT
		boost_sound.stream = load("res://sounds/death/speed.mp3")
		boost_sound.play()

func _setup_maya_glow() -> void:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(0.2, 0.65, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 0.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 tinted = mix(tex.rgb, glow_color.rgb, intensity * 0.55);
	COLOR = vec4(tinted * (1.0 + intensity * 0.9), tex.a);
}
"""
	_maya_glow_mat = ShaderMaterial.new()
	_maya_glow_mat.shader = shader
	_maya_glow_mat.set_shader_parameter("glow_color", MAYA_GLOW_COLOR)
	_maya_glow_mat.set_shader_parameter("intensity", 0.0)
	lumi_rect.material = _maya_glow_mat

func _setup_jump_buff_glow() -> void:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(0.2, 0.65, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.2;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 tinted = mix(tex.rgb, glow_color.rgb, intensity * 0.55);
	COLOR = vec4(tinted * (1.0 + intensity * 0.9), tex.a);
}
"""
	_jump_buff_glow_mat = ShaderMaterial.new()
	_jump_buff_glow_mat.shader = shader
	_jump_buff_glow_mat.set_shader_parameter("glow_color", MAYA_GLOW_COLOR)
	_jump_buff_glow_mat.set_shader_parameter("intensity", 1.2)
	jump_buff_rect.material = _jump_buff_glow_mat
	_jump_buff_rest_y = jump_buff_rect.position.y

func _create_shield_orb() -> void:
	_shield_orb = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.6
	sphere.height = 3.2
	sphere.radial_segments = 24
	sphere.rings = 12
	_shield_orb.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color              = Color(0.85, 0.52, 0.08, 0.18)
	mat.emission_enabled          = true
	mat.emission                  = Color(0.9, 0.55, 0.05, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.cull_mode                 = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shield_orb.material_override = mat
	_shield_orb.visible           = false
	_shield_buff_rest_y  = shield_buff_rect.position.y
	_sleepy_buff_rest_y  = sleepy_buff_rect.position.y
	add_child(_shield_orb)

func _activate_shield() -> void:
	_shield_orb.scale    = Vector3.ZERO
	_shield_orb.visible  = true
	create_tween().tween_property(_shield_orb, "scale", Vector3.ONE, 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if _shield_pulse_tween:
		_shield_pulse_tween.kill()
	var mat = _shield_orb.material_override as StandardMaterial3D
	_shield_pulse_tween = create_tween().set_loops()
	_shield_pulse_tween.tween_method(func(v: float): mat.emission_energy_multiplier = v,
		2.0, 5.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shield_pulse_tween.tween_method(func(v: float): mat.emission_energy_multiplier = v,
		5.0, 2.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_show_shield_buff_icon()

func _deactivate_shield() -> void:
	if _shield_pulse_tween:
		_shield_pulse_tween.kill()
	var shrink = create_tween().set_parallel(true)
	shrink.tween_property(_shield_orb, "scale", Vector3.ZERO, 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	shrink.tween_method(func(v: float):
		(_shield_orb.material_override as StandardMaterial3D).albedo_color.a = v,
		0.18, 0.0, 0.3).set_ease(Tween.EASE_IN)
	await shrink.finished
	_shield_orb.visible = false
	(_shield_orb.material_override as StandardMaterial3D).albedo_color.a = 0.18
	_consume_shield_buff_icon()

func _show_shield_buff_icon() -> void:
	if _shield_buff_show:
		_shield_buff_show.kill()
	if _shield_buff_float:
		_shield_buff_float.kill()
	shield_buff_rect.position.y = _shield_buff_rest_y
	shield_buff_rect.modulate.a = 0.0
	shield_buff_rect.scale      = Vector2(0.12, 0.12)
	shield_buff_rect.visible    = true
	_shield_buff_show = create_tween().set_parallel(true)
	_shield_buff_show.tween_property(shield_buff_rect, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	_shield_buff_show.tween_property(shield_buff_rect, "scale", Vector2(0.184, 0.184), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await _shield_buff_show.finished
	_shield_buff_float = create_tween().set_loops()
	_shield_buff_float.tween_property(shield_buff_rect, "position:y", _shield_buff_rest_y - 5.0, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shield_buff_float.tween_property(shield_buff_rect, "position:y", _shield_buff_rest_y, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _consume_shield_buff_icon() -> void:
	if _shield_buff_show:
		_shield_buff_show.kill()
	if _shield_buff_float:
		_shield_buff_float.kill()
	var from_y: float = shield_buff_rect.position.y
	var d = create_tween().set_parallel(true)
	d.tween_property(shield_buff_rect, "position:y", from_y - 48.0, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	d.tween_property(shield_buff_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_ease(Tween.EASE_IN)
	await d.finished
	shield_buff_rect.visible    = false
	shield_buff_rect.position.y = _shield_buff_rest_y

func _show_sleepy_buff_icon() -> void:
	if _sleepy_buff_show:
		_sleepy_buff_show.kill()
	if _sleepy_buff_float:
		_sleepy_buff_float.kill()
	sleepy_buff_rect.position.y = _sleepy_buff_rest_y
	sleepy_buff_rect.modulate.a = 0.0
	sleepy_buff_rect.scale      = Vector2(0.12, 0.12)
	sleepy_buff_rect.visible    = true
	_sleepy_buff_show = create_tween().set_parallel(true)
	_sleepy_buff_show.tween_property(sleepy_buff_rect, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	_sleepy_buff_show.tween_property(sleepy_buff_rect, "scale", Vector2(0.184, 0.184), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await _sleepy_buff_show.finished
	_sleepy_buff_float = create_tween().set_loops()
	_sleepy_buff_float.tween_property(sleepy_buff_rect, "position:y", _sleepy_buff_rest_y - 5.0, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_sleepy_buff_float.tween_property(sleepy_buff_rect, "position:y", _sleepy_buff_rest_y, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _consume_sleepy_buff_icon() -> void:
	if _sleepy_buff_show:
		_sleepy_buff_show.kill()
	if _sleepy_buff_float:
		_sleepy_buff_float.kill()
	var from_y: float = sleepy_buff_rect.position.y
	var d = create_tween().set_parallel(true)
	d.tween_property(sleepy_buff_rect, "position:y", from_y - 48.0, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	d.tween_property(sleepy_buff_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_ease(Tween.EASE_IN)
	await d.finished
	sleepy_buff_rect.visible    = false
	sleepy_buff_rect.position.y = _sleepy_buff_rest_y

func _activate_sleepy() -> void:
	sleepy_stored = false
	sleepy_timer  = SLEEPY_DURATION
	var stage_spd: float = STAGE_SPEED[current_stage - 1] if current_stage <= STAGE_SPEED.size() else STAGE_SPEED[-1]
	ground_scroller.target_speed = stage_spd * 0.7
	_do_flash(Color(0.5, 0.2, 1.0, 0.5), 0.35)
	_add_music_phaser()
	_consume_sleepy_buff_icon()

func _add_music_phaser() -> void:
	_remove_music_phaser()
	_music_phaser = AudioEffectPhaser.new()
	_music_phaser.rate_hz  = 0.1
	_music_phaser.depth    = 1.0
	_music_phaser.feedback = 0.7
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), _music_phaser)

func _remove_music_phaser() -> void:
	if _music_phaser == null:
		return
	var idx := AudioServer.get_bus_index("Music")
	for i in range(AudioServer.get_bus_effect_count(idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectPhaser:
			AudioServer.remove_bus_effect(idx, i)
	_music_phaser = null

func _show_health_buff_icon() -> void:
	health_buff_rect.modulate.a = 0.0
	health_buff_rect.scale      = Vector2(0.12, 0.12)
	health_buff_rect.visible    = true
	var rest_y: float = health_buff_rect.position.y
	var t = create_tween().set_parallel(true)
	t.tween_property(health_buff_rect, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.tween_property(health_buff_rect, "scale", Vector2(0.184, 0.184), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t.finished
	var ft = create_tween().set_loops()
	ft.tween_property(health_buff_rect, "position:y", rest_y - 5.0, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	ft.tween_property(health_buff_rect, "position:y", rest_y, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.6).timeout
	ft.kill()
	var cur_y: float = health_buff_rect.position.y
	var d = create_tween().set_parallel(true)
	d.tween_property(health_buff_rect, "position:y", cur_y - 48.0, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	d.tween_property(health_buff_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_ease(Tween.EASE_IN)
	await d.finished
	health_buff_rect.visible    = false
	health_buff_rect.position.y = rest_y

func _show_jump_buff_icon() -> void:
	if _jump_buff_show_tween:
		_jump_buff_show_tween.kill()
	if _jump_buff_float_tween:
		_jump_buff_float_tween.kill()
	jump_buff_rect.position.y = _jump_buff_rest_y
	jump_buff_rect.modulate.a = 0.0
	jump_buff_rect.scale      = Vector2(0.12, 0.12)
	jump_buff_rect.visible    = true
	_jump_buff_show_tween = create_tween().set_parallel(true)
	_jump_buff_show_tween.tween_property(jump_buff_rect, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	_jump_buff_show_tween.tween_property(jump_buff_rect, "scale", Vector2(0.184, 0.184), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await _jump_buff_show_tween.finished
	if not maya_jump:
		return
	_jump_buff_float_tween = create_tween().set_loops()
	_jump_buff_float_tween.tween_property(jump_buff_rect, "position:y", _jump_buff_rest_y - 5.0, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_jump_buff_float_tween.tween_property(jump_buff_rect, "position:y", _jump_buff_rest_y, 0.95)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _consume_jump_buff_icon() -> void:
	if _jump_buff_show_tween:
		_jump_buff_show_tween.kill()
	if _jump_buff_float_tween:
		_jump_buff_float_tween.kill()
	var from_y: float = jump_buff_rect.position.y
	var t = create_tween().set_parallel(true)
	t.tween_property(jump_buff_rect, "position:y", from_y - 48.0, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(jump_buff_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4).set_ease(Tween.EASE_IN)
	await t.finished
	jump_buff_rect.visible    = false
	jump_buff_rect.position.y = _jump_buff_rest_y

func _set_maya_glow(target: float, duration: float) -> void:
	var from = _maya_glow_mat.get_shader_parameter("intensity")
	create_tween().tween_method(
		func(v: float): _maya_glow_mat.set_shader_parameter("intensity", v),
		from, target, duration).set_ease(Tween.EASE_OUT)

func _update_lumi_sprite() -> void:
	var low_hp := (max_health - hit_count) <= 1
	var in_air := not is_on_floor()
	var new_state: LumiState
	if not alive:
		new_state = LumiState.DEAD
	elif in_air:
		new_state = LumiState.JUMP_HURT if low_hp else LumiState.JUMP
	else:
		new_state = LumiState.RUN_HURT if low_hp else LumiState.RUN
	if new_state == _lumi_state:
		return
	_lumi_state = new_state
	var target_scale := Vector2(1.4, 1.0) if new_state == LumiState.DEAD else Vector2.ONE
	if _lumi_breath_tween:
		_lumi_breath_tween.kill()
	var t = create_tween().set_parallel(true)
	t.tween_property(lumi_rect, "scale", Vector2(0.0, 0.0), 0.07).set_ease(Tween.EASE_IN)
	await t.finished
	match new_state:
		LumiState.RUN:       lumi_rect.texture = _lumi_tex_run
		LumiState.RUN_HURT:  lumi_rect.texture = _lumi_tex_run_hurt
		LumiState.JUMP:      lumi_rect.texture = _lumi_tex_jump
		LumiState.JUMP_HURT: lumi_rect.texture = _lumi_tex_jump_hurt
		LumiState.DEAD:      lumi_rect.texture = _lumi_tex_dead
	var scale_tween = create_tween()
	scale_tween.tween_property(lumi_rect, "scale", target_scale, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await scale_tween.finished
	if new_state != LumiState.DEAD:
		_restart_breath_tween()

func _do_flash(color: Color, duration: float) -> void:
	white_flash.color = color
	white_flash.modulate.a = 1.0
	create_tween().tween_property(white_flash, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func collect_orb(orb_type: String) -> void:
	if orb_type == "mochi":
		_powerup_sound.pitch_scale = minf(1.0 + mochi_count * 0.06, 1.5)
		_powerup_sound.volume_db   = -5.6
	else:
		_powerup_sound.pitch_scale = 1.0
		_powerup_sound.volume_db   = -2.5
	_powerup_sound.play()
	match orb_type:
		"sleepy":
			sleepy_stored = true
			_do_flash(Color(0.5, 0.2, 1.0, 0.4), 0.25)
			_show_sleepy_buff_icon()
		"jade":
			var was_hit     = hit_count > 0
			var old_hits    := hit_count
			hit_count        = 0
			recover_timer    = 0.0
			sleepy_timer     = 0.0
			invincible_timer = 0.0
			_do_flash(Color(0.1, 1.0, 0.4, 0.5), 0.3)
			_show_health_buff_icon()
			if was_hit:
				_animate_heart_heal(old_hits)
			if boost_timer <= 0:
				ground_scroller.target_speed = NORMAL_SPEED
		"maya":
			maya_jump = true
			_do_flash(Color(0.2, 0.6, 1.0, 0.4), 0.25)
			_show_jump_buff_icon()
		"emerald":
			add_heart()
			_do_flash(Color(0.0, 1.0, 0.2, 0.5), 0.35)
			_show_health_buff_icon()
		"shield":
			shield_active = true
			shield_timer  = SHIELD_DURATION
			_do_flash(SHIELD_COLOR, 0.3)
			_activate_shield()
		"mochi":
			mochi_count += 1
			_do_flash(Color(1.0, 0.75, 0.1, 0.45), 0.3)
			if mochi_count >= 10 and not _won:
				_trigger_win()

func take_hit() -> void:
	if god_mode or invincible_timer > 0:
		return
	if shield_active:
		shield_active = false
		shield_timer  = 0.0
		_deactivate_shield()
		_do_flash(SHIELD_COLOR, 0.3)
		_play_random_hit()
		invincible_timer = INVINCIBILITY
		return
	hit_count += 1
	_play_random_hit()
	if hit_count >= max_health:
		die()
	else:
		_do_flash(Color(1, 0.15, 0.15, 0.45), 0.2)
		if boost_timer <= 0:
			ground_scroller.target_speed = SLOW_SPEED
		invincible_timer = INVINCIBILITY
		recover_timer    = RECOVER_TIME

func _animate_heart_heal(old_hits: int) -> void:
	_heart_anim = true
	# Floating +heart feedback at the healed heart's position
	var healed_idx := max_health - old_hits
	var ghost_x    := HEART_X + healed_idx * HEART_SPACING
	var hud = get_node("../CanvasLayer/HUD")
	var ghost := TextureRect.new()
	ghost.texture = load("res://images/heart.png")
	ghost.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.layout_mode = 0
	ghost.offset_left   = ghost_x
	ghost.offset_top    = HEART_Y
	ghost.offset_right  = ghost_x + HEART_SIZE
	ghost.offset_bottom = HEART_Y + HEART_SIZE
	ghost.pivot_offset  = Vector2(HEART_SIZE * 0.5, HEART_SIZE * 0.5)
	ghost.modulate      = Color(1.0, 1.0, 1.0, 0.0)
	ghost.scale         = Vector2(0.5, 0.5)
	hud.add_child(ghost)
	var gt = create_tween().set_parallel(true)
	gt.tween_property(ghost, "scale",      Vector2(1.4, 1.4), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	gt.tween_property(ghost, "modulate:a", 1.0,               0.15).set_ease(Tween.EASE_OUT)
	await gt.finished
	var gt2 = create_tween().set_parallel(true)
	gt2.tween_property(ghost, "offset_top",    HEART_Y - 55.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	gt2.tween_property(ghost, "offset_bottom", HEART_Y + HEART_SIZE - 55.0, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	gt2.tween_property(ghost, "modulate:a",    0.0,            0.45).set_ease(Tween.EASE_IN).set_delay(0.1)
	await gt2.finished
	ghost.queue_free()
	# Pulse hearts green
	var t = create_tween().set_parallel(true)
	for h in _hearts:
		t.tween_property(h, "modulate", HEART_JADE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(h, "scale", Vector2(1.4, 1.4), 0.15).set_ease(Tween.EASE_OUT)
	await t.finished
	var t2 = create_tween().set_parallel(true)
	for h in _hearts:
		t2.tween_property(h, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	await t2.finished
	_heart_anim = false

func _float_hearts(up: bool) -> void:
	for i in _hearts.size():
		var target_y = HEART_Y - 6.0 if up else HEART_Y
		var dur      = 0.28 if up else 0.32
		var trans    = Tween.TRANS_BACK if up else Tween.TRANS_CUBIC
		create_tween().tween_property(_hearts[i], "position:y", target_y, dur)\
			.set_ease(Tween.EASE_OUT).set_trans(trans).set_delay(i * 0.055)

func _animate_hearts_die() -> void:
	_heart_anim = true
	var t = create_tween().set_parallel(true)
	for h in _hearts:
		t.tween_property(h, "modulate", HEART_DEAD, 0.3).set_ease(Tween.EASE_IN)

func _update_anim() -> void:
	if not alive:
		return
	var next: String
	if _dash_cooldown > 0.05 and is_on_floor():
		next = "LUMI_Animsss/LumiDashLBake" if _last_dash_dir < 0 else "LUMI_Animsss/LumiDashRBake"
	elif _air_dash_held or (_dash_cooldown > 0.05 and not is_on_floor()):
		return
	elif not is_on_floor():
		if _double_jumping and velocity.y > 0:
			if not _dj_anim_triggered:
				_dj_anim_triggered = true
				_anim.play("LUMI_Animsss/LumiDoubleJumpBake")
				_anim.animation_finished.connect(
					func(_n: String) -> void: _anim.pause(), CONNECT_ONE_SHOT)
			return
		elif velocity.y > 0:
			next = "LUMI_Animsss/LumiJumpBake"
		else:
			next = "LUMI_Animsss/LumiFallBake"
	else:
		next = "LUMI_Animsss/LumiRunBake"
	if _anim.current_animation != next:
		_anim.play(next)

func _play_dash() -> void:
	if _dash_cooldown > 0:
		return
	_dash_sound.pitch_scale = randf_range(0.88, 1.12)
	_dash_sound.volume_db   = randf_range(-4.0, 0.0)
	_dash_sound.play()
	_dash_cooldown = 0.12
	_air_dash_held = false
	if not is_on_floor():
		var an := "LUMI_Animsss/LumiDashLBake" if _last_dash_dir < 0 else "LUMI_Animsss/LumiDashRBake"
		_anim.play(an)
		_anim.animation_finished.connect(func(_n: String) -> void:
			if not is_on_floor():
				_air_dash_held = true
				_anim.pause()
		, CONNECT_ONE_SHOT)
	const BASE := Vector3(0.2, 0.2, 0.2)
	var squeeze_x := 0.12 if _last_dash_dir < 0 else 0.28
	$LumiModel.scale = Vector3(squeeze_x, 0.27, 0.2)
	create_tween().tween_property($LumiModel, "scale", BASE, 0.22)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _play_random_hit() -> void:
	var path = HIT_SOUNDS[randi() % HIT_SOUNDS.size()]
	hit_sound.stream = load(path)
	hit_sound.play()

func _trigger_win() -> void:
	_won = true
	var snd = AudioStreamPlayer.new()
	snd.stream = load("res://sounds/sfx/sfx6.mp3")
	snd.bus = "SFX"
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)
	var slow_tween = create_tween()
	slow_tween.tween_method(func(v: float): Engine.time_scale = v, 1.0, 0.05, 0.8)
	await get_tree().create_timer(1.2, true, false, true).timeout
	slow_tween.kill()
	Engine.time_scale = 1.0
	get_tree().paused = true
	await Transition.wipe_in()
	var is_best = SaveData.submit_score(score)
	var score_txt = "Score: %d" % score
	if is_best:
		score_txt += "  —  NEW BEST!"
	victory_screen.get_node("ScoreText").text = score_txt
	victory_screen.visible = true
	var cont_btn = victory_screen.get_node("ContinueButton")
	var quit_btn  = victory_screen.get_node("QuitButton")
	Transition.wire_buttons([cont_btn, quit_btn])
	cont_btn.pressed.connect(func():
		await Transition.wipe_in()
		victory_screen.visible = false
		get_tree().paused = false
		await Transition.wipe_out()
	, CONNECT_ONE_SHOT)
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		_clear_lpf()
		Transition.change_scene("res://main_menu.tscn")
	, CONNECT_ONE_SHOT)
	await Transition.wipe_out()

func die() -> void:
	Engine.time_scale = 1.0
	_remove_music_phaser()
	alive = false
	_lumi_state = LumiState.RUN  # force re-evaluation next frame
	_update_lumi_sprite()
	_animate_hearts_die()
	var mt = create_tween().set_parallel(true)
	mt.tween_property(_music, "pitch_scale", 0.72, 1.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	mt.tween_property(_music, "volume_db", -9.0, 1.8).set_ease(Tween.EASE_IN)
	ground_scroller.target_speed = 0.0
	camera.death_zoom()
	_do_flash(Color(1, 1, 1, 1), 0.35)
	# TODO: trigger ragdoll on model when ready
	SaveData.submit_score(score)
	await get_tree().create_timer(1.5).timeout
	var death_text = death_screen.get_node("DeathText")
	death_text.text = "Score: %d   Best: %d" % [score, SaveData.get_high_score()]
	_show_menu(death_screen)
	var restart_btn = death_screen.get_node("RestartButton")
	var quit_btn    = death_screen.get_node("QuitButton")
	Transition.wire_buttons([restart_btn, quit_btn])
	restart_btn.pressed.connect(func():
		_death_restart = true
		Transition.reload_scene(), CONNECT_ONE_SHOT)
	quit_btn.pressed.connect(func():
		_clear_lpf()
		create_tween().tween_property(_music, "volume_db", -80.0, 0.6).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.6).timeout
		Transition.change_scene("res://main_menu.tscn"), CONNECT_ONE_SHOT)
