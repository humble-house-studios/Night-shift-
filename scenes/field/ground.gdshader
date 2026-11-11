shader_type spatial;
// The ground under the wheat: painterly gold and green-gold dabs that melt
// into the haze at the horizon.
render_mode unshaded;
uniform vec3 a : source_color = vec3(0.62, 0.48, 0.18);
uniform vec3 b : source_color = vec3(0.55, 0.52, 0.22);
uniform vec3 haze : source_color = vec3(1.0, 0.86, 0.66);
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 cell = floor(wp.xz * 1.5);
	vec3 col = mix(a, b, hash(cell)) * (0.85 + hash(cell + 2.0) * 0.25);
	float dist = length(wp.xz - CAMERA_POSITION_WORLD.xz);
	col = mix(col, haze, smoothstep(10.0, 70.0, dist));
	ALBEDO = col;
}
