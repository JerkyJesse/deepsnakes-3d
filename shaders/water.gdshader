shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 water_color : source_color = vec3(0.08, 0.16, 0.12);
uniform float murk = 0.65;

varying vec3 wpos;

void vertex() {
	VERTEX.y += sin(TIME * 0.7 + VERTEX.x * 0.4) * 0.02;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = sin(wpos.x * 2.5 + TIME * 0.8) * 0.5 + sin(wpos.z * 1.8 - TIME * 0.6) * 0.5;
	ALBEDO = water_color * (0.85 + n * 0.08);
	ROUGHNESS = 0.08;
	METALLIC = 0.05;
	ALPHA = mix(0.55, 0.8, murk);
	SPECULAR = 0.9;
	EMISSION = water_color * 0.04;
}
