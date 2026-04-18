shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 10.0) = 3.5;

void fragment() {
	vec2 ps = blur_strength / vec2(textureSize(screen_texture, 0));
	vec4 col = vec4(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			col += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * ps);
		}
	}
	COLOR = col / 25.0;
}
