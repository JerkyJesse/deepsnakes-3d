shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

uniform vec3 grass_color : source_color = vec3(0.22, 0.38, 0.12);
uniform float wind = 0.12;

void vertex() {
	float t = TIME * 1.4 + VERTEX.x * 2.0 + VERTEX.z * 1.3;
	VERTEX.x += sin(t) * wind * COLOR.r;
	VERTEX.z += cos(t * 0.9) * wind * 0.6 * COLOR.r;
}

void fragment() {
	ALBEDO = grass_color * mix(0.55, 1.15, COLOR.g);
	ROUGHNESS = 0.8;
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
}
