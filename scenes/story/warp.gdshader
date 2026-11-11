// The trip between scenes: the world swirls, ripples, pixelates and floods
// with a posterized plasma, peaks, then folds back into the new view.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	float asp = res.x / res.y;
	vec2 c = SCREEN_UV - 0.5;
	c.x *= asp;
	float r = length(c);
	float a = atan(c.y, c.x);
	a += amount * (2.2 - r * 2.5) * sin(TIME * 1.3 + 0.7);
	r *= 1.0 + amount * 0.15 * sin(r * 24.0 - TIME * 6.0);
	vec2 w = vec2(cos(a), sin(a)) * r;
	w.x /= asp;
	w += 0.5;
	float px = mix(1.0, 28.0, amount * amount);
	vec2 cell = px * SCREEN_PIXEL_SIZE;
	w = (floor(w / cell) + 0.5) * cell;
	vec3 col = texture(screen_tex, w).rgb;
	float pl = sin(w.x * 18.0 + TIME * 3.0) + sin(w.y * 14.0 - TIME * 2.0) + sin((w.x + w.y) * 12.0 + TIME * 4.0);
	vec3 tint = 0.5 + 0.5 * cos(6.2831 * (pl * 0.15 + vec3(0.0, 0.33, 0.67) + TIME * 0.2));
	col = mix(col, col * 0.4 + tint * 0.9, amount * 0.75);
	float lv = mix(32.0, 4.0, amount);
	col = floor(col * lv + 0.5) / lv;
	col = mix(col, vec3(1.0, 0.95, 1.0) * tint, smoothstep(0.85, 1.0, amount) * 0.6);
	COLOR = vec4(col, 1.0);
}
