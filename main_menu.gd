extends Control

const HUD_PURPLE := Color(0.55, 0.08, 0.85, 1.0)
const HUD_INDIGO := Color(0.22, 0.08, 0.65, 1.0)

@onready var bg = $Background

func _ready() -> void:
	$PlayButton.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	$QuitButton.pressed.connect(func(): get_tree().quit())
	_start_bg_tween()

func _start_bg_tween() -> void:
	var t = create_tween().set_loops()
	t.tween_property(bg, "color", HUD_PURPLE, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg, "color", HUD_INDIGO, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
