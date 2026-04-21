extends Control

const SPACE_DARK  := Color(0.017, 0.004, 0.111, 1.0)
const SPACE_MID   := Color(0.069, 0.021, 0.249, 1.0)

const PARALLAX := {
	"StarRect1": 0.005,
	"StarRect2": 0.006,
	"MoonRect":  0.015,
	"EarthRect": 0.010,
}

@onready var bg = $Background

var _options_scene    = preload("res://options_menu.tscn")
var _options_instance: Control = null
var _music:           AudioStreamPlayer
var _parallax_bases:  Dictionary = {}  # node_name -> {ol, or, ot, ob}
var _intro_offsets:   Dictionary = {}  # node_name -> float (extra y offset during intro)
var _intro_done       := false
var _intro_tween:     Tween = null
var _intro_skipped    := false
var _intro_start_ms   := 0
var _logo_rest_y      := 0.0
var _play_rest_y      := 0.0
var _options_rest_y   := 0.0
var _quit_rest_y      := 0.0

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.stream    = load("res://sounds/music/Menu OST.wav")
	_music.bus       = "Music"
	_music.volume_db = -80.0
	_music.autoplay  = false
	add_child(_music)
	_music.finished.connect(func(): _music.play())
	_music.play()
	create_tween().tween_property(_music, "volume_db", 0.0, 1.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	Transition.wire_buttons([$PlayButton, $OptionsButton, $QuitButton])
	$PlayButton.pressed.connect(_play_game)
	$OptionsButton.pressed.connect(_open_options)
	$QuitButton.pressed.connect(func(): get_tree().quit())
	_start_bg_tween()
	await get_tree().process_frame
	for node_name in PARALLAX:
		var n = get_node(node_name)
		_parallax_bases[node_name] = {
			"ol": n.offset_left,  "or": n.offset_right,
			"ot": n.offset_top,   "ob": n.offset_bottom
		}
	_play_intro()

func _input(event: InputEvent) -> void:
	if _intro_done or _intro_skipped:
		return
	if Time.get_ticks_msec() - _intro_start_ms > 1000:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip_intro()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		_skip_intro()

func _skip_intro() -> void:
	_intro_skipped = true
	if _intro_tween:
		_intro_tween.kill()
	# Zero intro offsets so _process snaps nodes to resting positions
	for node_name in _intro_offsets:
		_intro_offsets[node_name] = 0.0
	for node_name in PARALLAX:
		get_node(node_name).modulate.a = 1.0
	$StarRect2.modulate.a = 0.7
	# Drop logo and buttons in quickly
	var logo        = $LogoRect
	var play_btn    = $PlayButton
	var options_btn = $OptionsButton
	var quit_btn    = $QuitButton
	logo.position.y        = -320.0
	play_btn.position.y    = 820.0
	options_btn.position.y = 820.0
	quit_btn.position.y    = 820.0
	logo.modulate.a        = 0.0
	play_btn.modulate.a    = 0.0
	options_btn.modulate.a = 0.0
	quit_btn.modulate.a    = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(logo, "position:y", _logo_rest_y, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(logo, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	t.tween_property(play_btn, "position:y", _play_rest_y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.08)
	t.tween_property(play_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_delay(0.08)
	t.tween_property(options_btn, "position:y", _options_rest_y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.14)
	t.tween_property(options_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_delay(0.14)
	t.tween_property(quit_btn, "position:y", _quit_rest_y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.20)
	t.tween_property(quit_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_delay(0.20)
	await t.finished
	_intro_done = true

func _process(_delta: float) -> void:
	if _parallax_bases.is_empty():
		return
	var center = get_viewport_rect().size * 0.5
	var mo = get_viewport().get_mouse_position() - center
	for node_name in PARALLAX:
		var n = get_node(node_name)
		var b = _parallax_bases[node_name]
		var f = PARALLAX[node_name]
		var iy = _intro_offsets.get(node_name, 0.0)
		n.offset_left   = b.ol - mo.x * f
		n.offset_right  = b.or - mo.x * f
		n.offset_top    = b.ot - mo.y * f + iy
		n.offset_bottom = b.ob - mo.y * f + iy

var _htp_scene = preload("res://how_to_play.tscn")

func _play_game() -> void:
	if SaveData.get_show_tutorial():
		var htp = _htp_scene.instantiate()
		add_child(htp)
		_animate_menu_in(htp)
		await htp.dismissed
	create_tween().tween_property(_music, "volume_db", -80.0, 0.8).set_ease(Tween.EASE_IN)
	Transition.change_scene("res://main.tscn")

func _start_bg_tween() -> void:
	var t = create_tween().set_loops()
	t.tween_property(bg, "color", SPACE_MID,  5.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "color", SPACE_DARK, 5.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_intro() -> void:
	var stars1      = $StarRect1
	var stars2      = $StarRect2
	var moon        = $MoonRect
	var earth       = $EarthRect
	var logo        = $LogoRect
	var play_btn    = $PlayButton
	var options_btn = $OptionsButton
	var quit_btn    = $QuitButton

	_logo_rest_y    = logo.position.y
	_play_rest_y    = play_btn.position.y
	_options_rest_y = options_btn.position.y
	_quit_rest_y    = quit_btn.position.y
	var logo_y     = _logo_rest_y
	var play_y     = _play_rest_y
	var options_y  = _options_rest_y
	var quit_y     = _quit_rest_y

	# Store resting offsets for parallax nodes
	var s1b = _parallax_bases["StarRect1"]
	var s2b = _parallax_bases["StarRect2"]
	var mb  = _parallax_bases["MoonRect"]
	var eb  = _parallax_bases["EarthRect"]

	# Hide everything
	stars1.modulate.a      = 0.0
	stars2.modulate.a      = 0.0
	moon.modulate.a        = 0.0
	earth.modulate.a       = 0.0
	logo.modulate.a        = 0.0
	play_btn.modulate.a    = 0.0
	options_btn.modulate.a = 0.0
	quit_btn.modulate.a    = 0.0

	# Set starting intro offsets (tween these to 0 — _process folds them in)
	_intro_offsets["StarRect1"] = -180.0
	_intro_offsets["StarRect2"] = -120.0
	_intro_offsets["MoonRect"]  =  220.0
	_intro_offsets["EarthRect"] =  160.0

	# Logo/buttons start off-screen
	logo.position.y        = -320.0
	play_btn.position.y    = 820.0
	options_btn.position.y = 820.0
	quit_btn.position.y    = 820.0

	_intro_start_ms = Time.get_ticks_msec()
	_intro_tween = create_tween().set_parallel(true)
	var t = _intro_tween

	# Stars fall from top (tween intro offset to 0)
	t.tween_method(func(v: float): _intro_offsets["StarRect1"] = v, -180.0, 0.0, 1.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_method(func(v: float): _intro_offsets["StarRect2"] = v, -120.0, 0.0, 2.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(stars1, "modulate:a", 1.0, 1.4).set_ease(Tween.EASE_OUT)
	t.tween_property(stars2, "modulate:a", 0.7, 1.7).set_ease(Tween.EASE_OUT)

	# Moon rises from bottom
	t.tween_method(func(v: float): _intro_offsets["MoonRect"] = v, 220.0, 0.0, 1.7)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(moon, "modulate:a", 1.0, 1.3).set_ease(Tween.EASE_OUT)

	# Earth follows
	t.tween_method(func(v: float): _intro_offsets["EarthRect"] = v, 160.0, 0.0, 1.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.25)
	t.tween_property(earth, "modulate:a", 1.0, 1.2).set_ease(Tween.EASE_OUT).set_delay(0.25)

	# Logo and buttons at 1.8 seconds
	t.tween_property(logo, "position:y", logo_y, 0.75)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(1.8)
	t.tween_property(logo, "modulate:a", 1.0, 0.55).set_ease(Tween.EASE_OUT).set_delay(1.8)

	t.tween_property(play_btn, "position:y", play_y, 0.65)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(2.0)
	t.tween_property(play_btn, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_delay(2.0)

	t.tween_property(options_btn, "position:y", options_y, 0.65)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(2.1)
	t.tween_property(options_btn, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_delay(2.1)

	t.tween_property(quit_btn, "position:y", quit_y, 0.65)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(2.2)
	t.tween_property(quit_btn, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_delay(2.2)

	await t.finished
	_intro_done = true

func _open_options() -> void:
	if _options_instance:
		return
	_options_instance = _options_scene.instantiate()
	add_child(_options_instance)
	var back_btn = _options_instance.get_node("Panel/VBox/BackButton")
	Transition.wire_buttons([back_btn])
	back_btn.pressed.connect(_close_options)
	_animate_menu_in(_options_instance)

func _close_options() -> void:
	if not _options_instance:
		return
	await _animate_menu_out(_options_instance)
	_options_instance.queue_free()
	_options_instance = null

func _animate_menu_in(menu: Control) -> void:
	menu.pivot_offset = Vector2(576, 324)
	menu.scale = Vector2(0.92, 0.92)
	menu.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(menu, "scale", Vector2.ONE, 0.22)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(menu, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)

func _animate_menu_out(menu: Control) -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(menu, "scale", Vector2(0.92, 0.92), 0.14)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(menu, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	await t.finished
