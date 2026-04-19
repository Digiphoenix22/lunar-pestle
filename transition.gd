extends CanvasLayer

const DURATION_IN  := 0.38
const DURATION_OUT := 0.48
const COLOR        := Color(0.18, 0.05, 0.55, 1.0)

const SELECT_SOUNDS := [
	"res://sounds/sfx/select1.mp3",
	"res://sounds/sfx/select2.mp3",
]
const HOVER_SOUND := "res://sounds/sfx/hover.mp3"

var _block: ColorRect
var _busy  := false
var _sfx:   AudioStreamPlayer
var _hover: AudioStreamPlayer

func _ready() -> void:
	layer = 100
	_block = ColorRect.new()
	_block.color = COLOR
	_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_block)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)
	_hover = AudioStreamPlayer.new()
	_hover.bus = "SFX"
	_hover.volume_db = -6.0
	_hover.stream = load(HOVER_SOUND)
	add_child(_hover)
	await get_tree().process_frame
	var s = get_viewport().get_visible_rect().size
	_block.size = Vector2(s.x + 4, s.y)
	_block.position = Vector2(-s.x - 4, 0)

func play_select() -> void:
	_sfx.stream = load(SELECT_SOUNDS[randi() % SELECT_SOUNDS.size()])
	_sfx.play()

func play_hover() -> void:
	_hover.stop()
	_hover.play()

func wire_buttons(buttons: Array) -> void:
	for btn in buttons:
		btn.pressed.connect(play_select)
		btn.mouse_entered.connect(play_hover)

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	var w = get_viewport().get_visible_rect().size.x
	_block.position.x = -w
	var t_in = create_tween()
	t_in.tween_property(_block, "position:x", 0.0, DURATION_IN)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await t_in.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t_out = create_tween()
	t_out.tween_property(_block, "position:x", w, DURATION_OUT)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await t_out.finished
	_busy = false

func reload_scene() -> void:
	change_scene(get_tree().current_scene.scene_file_path)
