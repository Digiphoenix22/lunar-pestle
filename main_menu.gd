extends Control

const HUD_PURPLE := Color(0.55, 0.08, 0.85, 1.0)
const HUD_INDIGO := Color(0.22, 0.08, 0.65, 1.0)

@onready var bg = $Background

func _ready() -> void:
	$PlayButton.pressed.connect(func(): Transition.change_scene("res://main.tscn"))
	$QuitButton.pressed.connect(func(): get_tree().quit())
	_start_bg_tween()
	_play_intro()

func _start_bg_tween() -> void:
	var t = create_tween().set_loops()
	t.tween_property(bg, "color", HUD_PURPLE, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "color", HUD_INDIGO, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _play_intro() -> void:
	var logo       = $LogoRect
	var play_btn   = $PlayButton
	var quit_btn   = $QuitButton

	var logo_y     = logo.position.y
	var play_y     = play_btn.position.y
	var quit_y     = quit_btn.position.y

	logo.position.y     = -320.0
	play_btn.position.y = 820.0
	quit_btn.position.y = 820.0

	logo.modulate.a     = 0.0
	play_btn.modulate.a = 0.0
	quit_btn.modulate.a = 0.0

	var t = create_tween().set_parallel(true)

	t.tween_property(logo, "position:y", logo_y, 0.65)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(logo, "modulate:a", 1.0, 0.45)\
		.set_ease(Tween.EASE_OUT)

	t.tween_property(play_btn, "position:y", play_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.12)
	t.tween_property(play_btn, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_delay(0.12)

	t.tween_property(quit_btn, "position:y", quit_y, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	t.tween_property(quit_btn, "modulate:a", 1.0, 0.4)\
		.set_ease(Tween.EASE_OUT).set_delay(0.2)
