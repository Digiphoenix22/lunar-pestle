extends Control

const HUD_PURPLE := Color(0.55, 0.08, 0.85, 1.0)
const HUD_INDIGO := Color(0.22, 0.08, 0.65, 1.0)

@onready var bg = $Background

var _options_scene = preload("res://options_menu.tscn")
var _options_instance: Control = null

func _ready() -> void:
	Transition.wire_buttons([$PlayButton, $OptionsButton, $QuitButton])
	$PlayButton.pressed.connect(func(): Transition.change_scene("res://main.tscn"))
	$OptionsButton.pressed.connect(_open_options)
	$QuitButton.pressed.connect(func(): get_tree().quit())
	_start_bg_tween()
	_play_intro()

func _start_bg_tween() -> void:
	var t = create_tween().set_loops()
	t.tween_property(bg, "color", HUD_PURPLE, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "color", HUD_INDIGO, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_intro() -> void:
	var logo        = $LogoRect
	var play_btn    = $PlayButton
	var options_btn = $OptionsButton
	var quit_btn    = $QuitButton

	var logo_y        = logo.position.y
	var play_y        = play_btn.position.y
	var options_y     = options_btn.position.y
	var quit_y        = quit_btn.position.y

	logo.position.y        = -320.0
	play_btn.position.y    = 820.0
	options_btn.position.y = 820.0
	quit_btn.position.y    = 820.0

	logo.modulate.a        = 0.0
	play_btn.modulate.a    = 0.0
	options_btn.modulate.a = 0.0
	quit_btn.modulate.a    = 0.0

	var t = create_tween().set_parallel(true)

	t.tween_property(logo, "position:y", logo_y, 0.65)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(logo, "modulate:a", 1.0, 0.45)\
		.set_ease(Tween.EASE_OUT)

	t.tween_property(play_btn, "position:y", play_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.12)
	t.tween_property(play_btn, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_delay(0.12)

	t.tween_property(options_btn, "position:y", options_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.18)
	t.tween_property(options_btn, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_delay(0.18)

	t.tween_property(quit_btn, "position:y", quit_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.24)
	t.tween_property(quit_btn, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_delay(0.24)

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
	menu.pivot_offset = Vector2(960, 540)
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
