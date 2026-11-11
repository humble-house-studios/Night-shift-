shader_type spatial;
// Wheat for the ending field: thin tapered blades (night_office.gd builds
// them as one MultiMesh), swaying in slow waves of wind that roll across
// the field. Dark gold at the root, pale and sunlit at the tip, every stalk
// its own shade; fades into the warm haze far away.
render_mode unshaded, cull_disabled;

uniform vec3 root_col : source_color = vec3(0.55, 0.38, 0.12);
uniform vec3 tip_col : source_color = vec3(1.0, 0.88, 0.52);
uniform vec3 haze : source_color = vec3(1.0, 0.86, 0.66);
uniform float wind = 1.0;

varying float tip;
varying float shade;
varying float dist;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void vertex() {
	tip = UV.y;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float id = float(INSTANCE_ID);
	shade = hash(id * 1.37);
	// Gusts roll across the field; each stalk bends with the square of height.
	float gust = sin(wp.x * 0.35 + wp.z * 0.2 - TIME * 1.4) * 0.5 + sin(wp.x * 1.3 - TIME * 2.3 + id) * 0.15;
	float bend = tip * tip * (0.18 + gust * 0.22) * wind;
	VERTEX.x += bend;
	VERTEX.z += bend * 0.4;
	dist = length((VIEW_MATRIX * vec4(wp, 1.0)).xyz);
}

void fragment() {
	vec3 col = mix(root_col, tip_col, smoothstep(0.0, 1.0, tip));
	col *= 0.82 + shade * 0.3;
	// The ear of grain at the top catches the sun.
	col += vec3(0.25, 0.18, 0.06) * smoothstep(0.82, 1.0, tip);
	col = mix(col, haze, smoothstep(12.0, 55.0, dist) * 0.85);
	ALBEDO = col;
}
