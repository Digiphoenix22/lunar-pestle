shader_type sky;
render_mode use_debanding;

uniform vec4  top_color     : source_color = vec4(0.01, 0.005, 0.05, 1.0);
uniform vec4  mid_color     : source_color = vec4(0.06, 0.03,  0.18, 1.0);
uniform vec4  horizon_color : source_color = vec4(0.18, 0.08,  0.40, 1.0);
uniform vec4  ground_color  : source_color = vec4(0.04, 0.02,  0.10, 1.0);
uniform float horizon_spread     : hint_range(0.0,  1.0)  = 0.25;
uniform float star_density       : hint_range(0.50, 1.0)  = 0.80;
uniform float star_size          : hint_range(0.01, 0.5)  = 0.067;
uniform float twinkle_speed      : hint_range(0.0,  10.0) = 4.78;
uniform float twinkle_amount     : hint_range(0.0,  1.0)  = 0.52;
uniform float horizon_star_fade  : hint_range(-0.2, 0.5)  = 0.38;
uniform float sky_rotation       : hint_range(-3.14159, 3.14159) = 0.0;

float hash3(vec3 p) {
	p = fract(p * vec3(127.1, 311.7, 74.7));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

vec3 rotate_y(vec3 v, float a) {
	float c = cos(a); float s = sin(a);
	return vec3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
}

float star_field(vec3 dir, float scale) {
	vec3 s     = dir * scale;
	vec3 cell  = floor(s);
	vec3 local = fract(s);
	float result = 0.0;
	for (int x = 0; x <= 1; x++) {
		for (int y = 0; y <= 1; y++) {
			for (int z = 0; z <= 1; z++) {
				vec3 c = cell + vec3(float(x), float(y), float(z));
				vec3 star_pos = vec3(
					hash3(c),
					hash3(c + vec3(1.3, 0.0, 0.0)),
					hash3(c + vec3(0.0, 2.7, 0.0))
				);
				vec3  to_star = local - vec3(float(x), float(y), float(z)) - star_pos;
				float dist    = length(to_star);
				float bright  = hash3(c + vec3(5.1, 3.3, 7.7));
				if (bright > star_density) {
					float twinkle = 1.0 + twinkle_amount * sin(TIME * twinkle_speed + bright * 6.28318);
					result += (1.0 - smoothstep(0.0, star_size, dist)) * twinkle
					        * mix(0.5, 1.0, hash3(c + vec3(2.2, 8.4, 1.1)));
				}
			}
		}
	}
	return result;
}

void sky() {
	float elev = EYEDIR.y;

	// Three-band gradient
	vec3 col;
	if (elev >= 0.0) {
		float t_low  = smoothstep(0.0, horizon_spread, elev);
		float t_high = smoothstep(horizon_spread, 1.0,  elev);
		col = mix(horizon_color.rgb, mid_color.rgb, t_low);
		col = mix(col, top_color.rgb, t_high);
	} else {
		col = mix(ground_color.rgb, horizon_color.rgb, smoothstep(-0.35, 0.0, elev));
	}

	float star_fade = smoothstep(-horizon_star_fade, horizon_star_fade + 0.1, elev);
	if (star_fade > 0.0) {
		vec3 rd = rotate_y(EYEDIR, sky_rotation);
		float stars  = star_field(rd, 20.0);
		      stars += star_field(rd * 1.61 + vec3(0.4,  0.7, 0.2), 15.0) * 1.2;
		      stars += star_field(rd * 2.30 + vec3(0.9,  0.3, 0.6), 25.0) * 0.8;
		      stars += star_field(rd * 3.10 + vec3(0.2,  1.1, 0.4), 10.0) * 1.5;
		col += stars * star_fade * vec3(0.9, 0.87, 1.0);
	}

	COLOR = col;
}
