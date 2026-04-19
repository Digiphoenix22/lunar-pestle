shader_type spatial;
render_mode ambient_light_disabled;

group_uniforms Base;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;

group_uniforms Shadow;
uniform vec4 shadow_color : source_color = vec4(0.5, 0.4, 0.8, 1.0);
uniform bool use_ramp = false;
uniform sampler2D ramp_texture : hint_default_white;
uniform int shadow_bands : hint_range(2, 8, 1) = 2;
uniform float shadow_fill_strength : hint_range(0.0, 1.0) = 0.12;

group_uniforms Rim;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_size : hint_range(0.0, 1.0) = 0.4;
uniform float rim_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms Specular;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glossiness : hint_range(1.0, 256.0) = 32.0;
uniform float specular_strength : hint_range(0.0, 2.0) = 1.0;

group_uniforms Ambient;
uniform vec4 ambient_color : source_color = vec4(0.1, 0.1, 0.15, 1.0);
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 albedo = texture(albedo_texture, UV) * albedo_color;
	ALBEDO = albedo.rgb;
	EMISSION = albedo.rgb * (ambient_color.rgb * ambient_strength + shadow_color.rgb * shadow_fill_strength);
	ROUGHNESS = 0.0;
}

void light() {
	vec4 albedo = vec4(ALBEDO, 1.0);
	float NdotL = dot(NORMAL, LIGHT);
	float light_att = ATTENUATION;

	// Shadow
	float diffuse_band;
	if (use_ramp) {
		float ramp_uv = NdotL * 0.5 + 0.5;
		diffuse_band = texture(ramp_texture, vec2(ramp_uv, 0.5)).r;
	} else {
		float NdotL_01 = clamp(NdotL * 0.5 + 0.5, 0.0, 1.0);
		float bands = float(shadow_bands);
		diffuse_band = clamp(floor(NdotL_01 * bands) / (bands - 1.0), 0.0, 1.0);
	}
	float diffuse = diffuse_band * light_att;

	vec3 shadow = mix(shadow_color.rgb, vec3(1.0), diffuse_band);
	vec3 lit = albedo.rgb * shadow * LIGHT_COLOR * light_att;

	// Specular — glossiness controls both size and sharpness
	vec3 H = normalize(LIGHT + VIEW);
	float NdotH = dot(NORMAL, H);
	float spec = pow(max(NdotH, 0.0), glossiness);
	vec3 specular_contrib = specular_color.rgb * step(0.5, spec) * specular_strength * LIGHT_COLOR * diffuse;

	// Rim — rim_size 0=none, 1=large
	float rim = 1.0 - dot(NORMAL, VIEW);
	float rim_step = smoothstep(1.0 - rim_size - 0.05, 1.0 - rim_size + 0.05, rim);
	vec3 rim_contrib = rim_color.rgb * rim_step * rim_strength * LIGHT_COLOR * diffuse;

	DIFFUSE_LIGHT += lit + specular_contrib + rim_contrib;
}



