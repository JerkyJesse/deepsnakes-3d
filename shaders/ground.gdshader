shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform vec3 col_a : source_color = vec3(0.18, 0.14, 0.08);
uniform vec3 col_b : source_color = vec3(0.28, 0.32, 0.14);
uniform float noise_scale = 0.12;
uniform float pebble = 0.35;
uniform sampler2D photo_albedo : source_color;
uniform sampler2D photo_normal : hint_normal;
uniform sampler2D photo_rough : hint_default_white;
uniform float use_photo = 0.0;

varying vec3 wpos;
varying vec3 wn;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = wpos.xz * noise_scale;
	float n = fbm(uv);
	float peb = fbm(uv * 7.0);
	vec3 col = mix(col_a, col_b, n);
	col = mix(col, col * 0.7, step(0.62, peb) * pebble);

	if (use_photo > 0.5) {
		vec2 tuv = wpos.xz * 0.08;
		vec3 p = texture(photo_albedo, tuv).rgb;
		col = mix(col, p, 0.85);
		vec3 pn = texture(photo_normal, tuv).rgb * 2.0 - 1.0;
		NORMAL = normalize(NORMAL + pn * 0.45);
		ROUGHNESS = texture(photo_rough, tuv).r;
	} else {
		ROUGHNESS = mix(0.85, 0.55, peb);
		vec2 e = vec2(0.04, 0.0);
		float ddx = fbm(uv + e) - fbm(uv - e);
		float ddy = fbm(uv + e.yx) - fbm(uv - e.yx);
		NORMAL = normalize(NORMAL + vec3(-ddx, -ddy, 0.0) * 1.8);
	}

	ALBEDO = col;
	METALLIC = 0.0;
	SPECULAR = 0.25;
}
