// Glitch in the matrix: colorful static blocks, torn rows and scanlines over
// a face while its head swaps between the puppet and the real scan.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float amount = 0.0;
uniform float seed = 0.0;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
vec3 hue(float x) { return clamp(abs(fract(x + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0); }

void vertex() {
	// Billboard that keeps the head's scale (Chad on his TV is tiny).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float st = floor(TIME * 30.0);
	float row = floor(UV.y * 28.0);
	float tear = (h(vec2(row, st)) - 0.5) * 0.45 * step(0.6, h(vec2(row * 3.0, st)));
	vec2 uv = UV + vec2(tear, 0.0);
	vec2 b = floor(uv * vec2(10.0, 14.0));
	float r = h(b + st);
	vec3 c = hue(r + TIME * 0.5);
	c = mix(c, vec3(h(b * 1.7 + st)), step(0.75, r));
	float scan = 0.65 + 0.35 * step(0.5, fract(UV.y * 40.0 + TIME * 8.0));
	float oval = 1.0 - smoothstep(0.36, 0.5, length((UV - 0.5) * vec2(1.0, 0.85)));
	ALBEDO = c * scan;
	ALPHA = clamp(amount * step(0.3, h(b * 2.3 + st * 1.3)) * oval * scan, 0.0, 1.0);
}
