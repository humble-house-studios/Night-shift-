// The trip between scenes: chunky pixels of swirling, posterized plasma
// dissolve in over the view, cover it while the camera moves, then dissolve
// away into the next one. Purely procedural (no screen reads), so it is
// cheap and safe on phones.
shader_type canvas_item;

uniform float amount = 0.0;

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	float px = max(6.0, floor(res.y / 64.0));
	vec2 cell = floor(FRAGCOORD.xy / px);
	vec2 uv = (cell * px) / res.y;
	vec2 c = uv - vec2(0.5 * res.x / res.y, 0.5);
	float r = length(c);
	float a = atan(c.y, c.x) + amount * 3.0 * (1.2 - r) + TIME * 0.6;
	vec2 w = vec2(cos(a), sin(a)) * r;
	float pl = sin(w.x * 14.0 + TIME * 3.0) + sin(w.y * 11.0 - TIME * 2.2) + sin((r * 18.0) - TIME * 4.0);
	vec3 col = 0.5 + 0.5 * cos(6.2831 * (pl * 0.16 + vec3(0.0, 0.33, 0.67) + TIME * 0.25));
	col = floor(col * 5.0 + 0.5) / 5.0;
	// Pixels pop in from the center out, with a ragged random edge.
	float order = clamp(r * 0.9 + h(cell) * 0.35, 0.0, 1.0);
	float on = step(order, amount * 1.45 - 0.1);
	float scan = 0.85 + 0.15 * step(0.5, fract(FRAGCOORD.y / px * 0.5));
	COLOR = vec4(col * scan, on);
}
