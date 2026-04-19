extends Node

@export var curvature: float = 0.00015

func _ready() -> void:
	RenderingServer.global_shader_parameter_add("globe_curvature", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, curvature)

func _process(_delta: float) -> void:
	RenderingServer.global_shader_parameter_set("globe_curvature", curvature)
