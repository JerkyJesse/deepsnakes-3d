shader_type canvas_item;

uniform float blink = 0.0;
uniform float jaw = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float v = smoothstep(0.35, 1.15, r);
	v = max(v, blink * 0.92);
	float lids = 0.0;
	lids += smoothstep(0.55 - jaw * 0.15, 0.82, UV.y);
	lids += smoothstep(0.45 + jaw * 0.12, 0.18, UV.y);
	v = max(v, lids * 0.75);
	COLOR = vec4(0.02, 0.03, 0.02, v * 0.55);
}
