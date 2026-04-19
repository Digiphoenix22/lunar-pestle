shader_type spatial;

global uniform float globe_curvature;

void vertex() {
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec2 flat_offset = world_pos.xz - CAMERA_POSITION_WORLD.xz;
	float dist_sq = dot(flat_offset, flat_offset);
	VERTEX.y -= dist_sq * globe_curvature;
}

void fragment() {
	ALBEDO = vec3(1.0);
}
