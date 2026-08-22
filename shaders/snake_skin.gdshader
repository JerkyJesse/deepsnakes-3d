shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform vec3 dorsal_color : source_color = vec3(0.42, 0.28, 0.14);
uniform vec3 ventral_color : source_color = vec3(0.78, 0.68, 0.48);
uniform vec3 pattern_color : source_color = vec3(0.12, 0.08, 0.04);
uniform float pattern_scale = 14.0;
uniform float scale_scale = 36.0;
uniform int pattern_type = 0;
uniform float wetness = 0.3;
uniform float sss_strength = 0.22;
uniform sampler2D photo_albedo : source_color;
uniform sampler2D photo_normal : hint_normal;
uniform float use_photo = 0.0;

varying vec3 world_pos;
varying vec3 world_n;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash2(i).x;
	float b = hash2(i + vec2(1.0, 0.0)).x;
	float c = hash2(i + vec2(0.0, 1.0)).x;
	float d = hash2(i + vec2(1.0, 1.0)).x;
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float hex_scale(vec2 uv) {
	vec2 r = vec2(1.0, 1.73205);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	float d = length(gv);
	return 1.0 - smoothstep(0.28, 0.46, d);
}

float blotch(vec2 uv) {
	float n = noise(uv * 3.4) * 0.55 + noise(uv * 8.0) * 0.45;
	return smoothstep(0.42, 0.62, n);
}

float chevron(vec2 uv) {
	float v = abs(fract(uv.x * 2.2 + abs(uv.y - 0.5) * 1.8) - 0.5);
	return 1.0 - smoothstep(0.12, 0.28, v);
}

float bands(vec2 uv) {
	float v = abs(fract(uv.x * 7.0) - 0.5);
	return 1.0 - smoothstep(0.18, 0.32, v);
}

float diamonds(vec2 uv) {
	vec2 p = vec2(uv.x * 6.0, (uv.y - 0.5) * 8.0);
	float d = abs(p.x - floor(p.x + 0.5)) + abs(p.y);
	return 1.0 - smoothstep(0.35, 0.7, d);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float around = UV.y;
	float along = UV.x;
	float belly = pow(0.5 + 0.5 * cos(around * TAU), 1.6);

	vec2 suv = vec2(along * scale_scale, around * scale_scale * 0.55);
	float scales = hex_scale(suv);
	float groove = 1.0 - scales;

	vec2 puv = vec2(along * pattern_scale, around);
	float pat = 0.0;
	if (pattern_type == 0) {
		pat = blotch(puv);
	} else if (pattern_type == 1) {
		pat = chevron(vec2(along, around));
	} else if (pattern_type == 2) {
		pat = bands(vec2(along, around));
	} else {
		pat = diamonds(vec2(along, around));
	}

	vec3 base_col = mix(dorsal_color, ventral_color, belly);
	base_col = mix(base_col, pattern_color, pat * (1.0 - belly) * 0.85);
	base_col *= mix(0.72, 1.08, scales);
	base_col += vec3(0.04, 0.03, 0.02) * groove;

	if (use_photo > 0.5) {
		vec3 photo = texture(photo_albedo, vec2(along * 4.0, around)).rgb;
		base_col = mix(base_col, photo * base_col / max(dot(base_col, vec3(0.33)), 0.05), 0.65);
	}

	ALBEDO = base_col;
	float wet = clamp(wetness + belly * 0.15, 0.0, 1.0);
	ROUGHNESS = mix(0.62, 0.18, wet) * mix(1.0, 0.7, scales);
	METALLIC = 0.0;
	SPECULAR = mix(0.4, 0.85, wet);
	EMISSION = base_col * (0.012 + sss_strength * 0.04);

	vec2 e = vec2(0.02, 0.0);
	float hx = hex_scale(suv + e) - hex_scale(suv - e);
	float hy = hex_scale(suv + e.yx) - hex_scale(suv - e.yx);
	NORMAL = normalize(NORMAL + vec3(-hx, -hy, 0.0) * 0.65);
}
