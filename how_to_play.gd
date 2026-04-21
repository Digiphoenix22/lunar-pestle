extends Control

signal dismissed

const MOCHI_YELLOW := Color(1.0, 0.85, 0.12, 1.0)

const LINES: Array = [
	["← / →  or  A / D", "Switch lanes"],
	["Space / ↑", "Jump"],
	["Press C for slowdown buff / Doouble jump with blue! ", "Buffs!"],
	["Mochi", "Collect for 10 to WIN!", true],
	["Obstacles", "Dodge or jump to survive!"],
]

var _font_bold   = preload("res://fonts/ExodusDisplay-SharpenBold.otf")
var _font_reg    = preload("res://fonts/ExodusDisplay-Sharpen.otf")
var _sfx_stream  = preload("res://sounds/sfx/sfx7.mp3")
var _sfx6_stream = preload("res://sounds/sfx/sfx6.mp3")

var _revealed    := 0
var _busy        := false
var _sfx: AudioStreamPlayer
var _sfx6: AudioStreamPlayer
var _pulse_tween: Tween

@onready var lines_container = $LinesContainer
@onready var click_hint      = $ClickHint
@onready var got_it_btn      = $GotItButton
@onready var lumi_sprite     = $Lumi

func _ready() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = _sfx_stream
	_sfx.bus    = "SFX"
	add_child(_sfx)
	_sfx6 = AudioStreamPlayer.new()
	_sfx6.stream = _sfx6_stream
	_sfx6.bus    = "SFX"
	add_child(_sfx6)
	Transition.wire_buttons([got_it_btn])
	got_it_btn.pressed.connect(_on_got_it)
	_pulse_hint()
	_setup_lumi_sprite()

var _lumi_hopping := false

func _setup_lumi_sprite() -> void:
	lumi_sprite.pivot_offset = lumi_sprite.size * 0.5
	var base_scale: Vector2 = lumi_sprite.scale
	var t = create_tween().set_loops()
	t.tween_property(lumi_sprite, "scale", base_scale * 1.04, 1.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(lumi_sprite, "scale", base_scale, 1.1)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	lumi_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	lumi_sprite.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_hop_lumi(42.0)
			var snd = AudioStreamPlayer.new()
			snd.stream    = load("res://sounds/sfx/lumi2.mp3")
			snd.bus       = "SFX"
			snd.volume_db = -6.0
			add_child(snd)
			snd.play()
			snd.finished.connect(snd.queue_free))

func _hop_lumi(pixels: float) -> void:
	if _lumi_hopping:
		return
	_lumi_hopping = true
	var rest_top: float = lumi_sprite.offset_top
	var rest_bot: float = lumi_sprite.offset_bottom
	var jt = create_tween()
	jt.tween_method(func(v: float):
		lumi_sprite.offset_top    = rest_top + v
		lumi_sprite.offset_bottom = rest_bot + v,
		0.0, -pixels, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	jt.tween_method(func(v: float):
		lumi_sprite.offset_top    = rest_top + v
		lumi_sprite.offset_bottom = rest_bot + v,
		-pixels, 0.0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await jt.finished
	_lumi_hopping = false

func _pulse_hint() -> void:
	var t = create_tween().set_loops()
	t.tween_property(click_hint, "modulate:a", 0.35, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(click_hint, "modulate:a", 1.0,  1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	if got_it_btn.visible:
		return
	var clicked = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var keyed   = event is InputEventKey and event.pressed and not event.is_echo()
	if clicked or keyed:
		get_viewport().set_input_as_handled()
		_sfx.pitch_scale = 0.82 + _revealed * 0.07
		_sfx.play()
		_hop_lumi(14.0)
		if not _busy:
			_reveal_next()

func _reveal_next() -> void:
	if _revealed >= LINES.size():
		return
	_busy = true

	var row = _make_row(LINES[_revealed])
	lines_container.add_child(row)
	row.modulate.a = 0.0
	row.scale      = Vector2(1.0, 0.7)
	var t = create_tween().set_parallel(true)
	t.tween_property(row, "modulate:a", 1.0,       0.3).set_ease(Tween.EASE_OUT)
	t.tween_property(row, "scale:y",    1.0,       0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t.finished

	_revealed += 1
	_busy = false

	if _revealed >= LINES.size():
		_show_got_it()

func _make_row(data: Array) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var mochi_row: bool = data.size() > 2 and data[2]

	var key = Label.new()
	key.text = data[0]
	key.custom_minimum_size = Vector2(270, 0)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key.add_theme_font_override("font", _font_bold)
	key.add_theme_font_size_override("font_size", 28)
	key.add_theme_color_override("font_color", MOCHI_YELLOW if mochi_row else Color(0.78, 0.52, 1.0, 1.0))

	var dash = Label.new()
	dash.text = "—"
	dash.add_theme_font_override("font", _font_reg)
	dash.add_theme_font_size_override("font_size", 28)
	dash.add_theme_color_override("font_color", Color(0.55, 0.35, 0.85, 0.65))

	var desc: Control
	if mochi_row:
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content    = true
		rtl.scroll_active  = false
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.add_theme_font_override("normal_font", _font_reg)
		rtl.add_theme_font_size_override("normal_font_size", 28)
		var y := "[color=#%s]" % MOCHI_YELLOW.to_html(false)
		var w := "[color=#ffffff]"
		rtl.text = w + "Collect for " + "[/color]" + y + "10" + "[/color]" + w + " to WIN!" + "[/color]"
		desc = rtl
	else:
		var lbl = Label.new()
		lbl.text = data[1]
		lbl.add_theme_font_override("font", _font_reg)
		lbl.add_theme_font_size_override("font_size", 28)
		desc = lbl

	row.add_child(key)
	row.add_child(dash)
	row.add_child(desc)
	return row

func _show_got_it() -> void:
	var fade = create_tween()
	fade.tween_property(click_hint, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	await fade.finished
	click_hint.visible = false
	got_it_btn.visible = true
	got_it_btn.modulate.a = 0.0
	got_it_btn.scale = Vector2(0.5, 0.5)
	got_it_btn.pivot_offset = got_it_btn.size * 0.5
	var appear = create_tween().set_parallel(true)
	appear.tween_property(got_it_btn, "modulate:a", 1.0,        0.4).set_ease(Tween.EASE_OUT)
	appear.tween_property(got_it_btn, "scale",      Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await appear.finished
	# Idle pulse once visible
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(got_it_btn, "scale", Vector2(1.06, 1.06), 0.55).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(got_it_btn, "scale", Vector2.ONE,         0.55).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_got_it() -> void:
	SaveData.set_show_tutorial(false)
	got_it_btn.disabled = true
	if _pulse_tween:
		_pulse_tween.kill()

	# sfx6 instant
	_sfx6.play()

	got_it_btn.pivot_offset = got_it_btn.size * 0.5

	# Phase 1 — squish down
	var sq = create_tween().set_parallel(true)
	sq.tween_property(got_it_btn, "scale", Vector2(1.18, 0.38), 0.08)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await sq.finished

	# Phase 2 — rocket upward + fade
	var rk = create_tween().set_parallel(true)
	rk.tween_property(got_it_btn, "scale",      Vector2(0.12, 3.2), 0.24)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	rk.tween_property(got_it_btn, "modulate:a", 0.0,               0.22)\
		.set_ease(Tween.EASE_IN)
	await rk.finished

	# Fade overlay then dismiss — transition handles the rest
	create_tween().tween_property(self, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.25).timeout
	dismissed.emit()
	queue_free()
