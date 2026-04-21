shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled, ambient_light_disabled;

uniform vec4 emission_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1, 0.001) = 0.02;

void vertex() {
	vec3 normal = normalize(NORMAL);
	VERTEX += normal * outline_width;
}

void fragment() {
	ALBEDO = emission_color.rgb;
	EMISSION = emission_color.rgb;
}
