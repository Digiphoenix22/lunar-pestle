extends Area3D

@export_enum("sleepy", "jade", "maya") var orb_type: String = "jade"

const COLORS := {
	"sleepy": Color(0.5,  0.2,  0.95, 1.0),
	"jade":   Color(0.1,  0.9,  0.35, 1.0),
	"maya":   Color(0.15, 0.6,  1.0,  1.0),
	"mochi":  Color(1.0,  0.65, 0.1,  1.0),
}

const MODEL_PATHS := {
	"sleepy": "",
	"jade":   "",
	"maya":   "",
	"mochi":  "",
}

func _ready() -> void:
	scale = Vector3(1.5, 1.5, 1.5)
	var path = MODEL_PATHS.get(orb_type, "")
	if path != "" and ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		if scene:
			var model = scene.instantiate()
			$MeshInstance3D.replace_by(model)
	var mat = StandardMaterial3D.new()
	mat.albedo_color               = COLORS[orb_type]
	mat.emission_enabled           = true
	mat.emission                   = COLORS[orb_type]
	mat.emission_energy_multiplier = 1.0
	$MeshInstance3D.material_override = mat
	body_entered.connect(_on_body_entered)
	_start_bob()
	_start_emission_pulse(mat)

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
		body.collect_orb(orb_type)
		queue_free()
