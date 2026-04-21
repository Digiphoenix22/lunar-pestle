extends Area3D

@export_enum("sleepy", "jade", "maya", "emerald", "shield", "mochi") var orb_type: String = "jade"

const COLORS := {
	"sleepy":   Color(0.5,  0.2,  0.95, 1.0),
	"jade":     Color(0.1,  0.9,  0.35, 1.0),
	"maya":     Color(0.15, 0.6,  1.0,  1.0),
	"mochi":    Color(1.0,  0.65, 0.1,  1.0),
	"emerald":  Color(0.0,  1.0,  0.2,  1.0),
	"shield":   Color(0.75, 0.42, 0.05, 1.0),
}

const MODEL_PATHS := {
	"mochi":   "res://Pestle.glb",
	"sleepy":  "res://BunnyMochii.glb",
	"jade":    "res://BunnyMochii.glb",
	"maya":    "res://BunnyMochii.glb",
	"emerald": "res://BunnyMochii.glb",
	"shield":  "res://BunnyMochii.glb",
}

func _ready() -> void:
	scale = Vector3(1.5, 1.5, 1.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color               = COLORS[orb_type]
	mat.emission_enabled           = true
	mat.emission                   = COLORS[orb_type]
	mat.emission_energy_multiplier = 1.0
	var emit_mat: ShaderMaterial = (load("res://Materials/emmision.tres") as ShaderMaterial).duplicate()
	emit_mat.set_shader_parameter("emission_color", COLORS[orb_type])
	emit_mat.next_pass = mat

	var path: String = MODEL_PATHS.get(orb_type, "")
	if path != "" and ResourceLoader.exists(path):
		$MeshInstance3D.visible = false
		var model: Node3D = (load(path) as PackedScene).instantiate()
		add_child(model)
		_apply_material(model, emit_mat)
	else:
		$MeshInstance3D.material_override = emit_mat

	body_entered.connect(_on_body_entered)
	_start_bob()
	_start_emission_pulse(mat)

func _apply_material(node: Node, emit_mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = emit_mat
	for child in node.get_children():
		_apply_material(child, emit_mat)

func _start_emission_pulse(mat: StandardMaterial3D) -> void:
	var t = create_tween().set_loops()
	t.tween_property(mat, "emission_energy_multiplier", 5.0, 0.9)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(mat, "emission_energy_multiplier", 20.0, 0.9)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _start_bob() -> void:
	var base_y = position.y
	var t = create_tween().set_loops()
	t.tween_property(self, "position:y", base_y + 0.35, 0.85)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "position:y", base_y - 0.35, 0.85)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("collect_orb"):
		body.collect_orb(orb_type, global_position)
		queue_free()
