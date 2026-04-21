extends Node

@export_range(0.0, 1.0, 0.01) var curvature: float = 0.3

func _process(_delta: float) -> void:
	RenderingServer.global_shader_parameter_set("globe_curvature", curvature * 0.001)
