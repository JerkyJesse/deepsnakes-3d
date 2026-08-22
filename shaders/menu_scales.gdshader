shader_type canvas_item;

uniform vec3 col_a : source_color = vec3(0.05, 0.08, 0.05);
uniform vec3 col_b : source_color = vec3(0.18, 0.14, 0.07);

float hex(vec2 uv) {
	vec2 r = vec2(1.0, 1.73205);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = length(a) < length(b) ? a : b;
	return 1.0 - smoothstep(0.3, 0.48, length(gv));
}

void fragment() {
	vec2 uv = UV * vec2(18.0, 12.0);
	uv.x += TIME * 0.08;
	float s = hex(uv);
	vec3 c = mix(col_a, col_b, s);
	COLOR = vec4(c, 1.0);
}
