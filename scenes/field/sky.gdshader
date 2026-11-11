shader_type spatial;
// The sky over the wheat at the end: an impressionist summer sky, painted
// not rendered. Deep cerulean up top fading to a warm haze at the horizon,
// big soft cumulus built from short brush dabs (each dab one flat colour from
// a small palette, laid along a stroke direction), the whole thing drifting.
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec3 zenith : source_color = vec3(0.16, 0.36, 0.78);
uniform vec3 mid : source_color = vec3(0.42, 0.62, 0.92);
uniform vec3 horizon : source_color = vec3(1.0, 0.86, 0.66);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.97, 0.9);
uniform vec3 cloud_shade : source_color = vec3(0.7, 0.72, 0.9);
uniform vec3 sun_dir = vec3(0.3, 0.25, -1.0);
uniform float dab = 46.0;

varying vec3 dir;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += noise(p) * a; p = p * 2.03 + 7.1; a *= 0.5; }
	return v;
}

void vertex() {
	dir = normalize((MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz);
}

void fragment() {
	vec3 d = normalize(dir);
	float h = clamp(d.y, -0.2, 1.0);
	// Sky plane coordinates (clouds flatten toward the horizon).
	vec2 sp = d.xz / max(d.y + 0.12, 0.05);
	// Brush dabs: snap to a cell grid, jitter, and stretch along a stroke.
	vec2 cell = floor(sp * dab / 8.0);
	vec2 jit = vec2(hash(cell), hash(cell + 3.7)) - 0.5;
	float ang = noise(cell * 0.11) * 3.14;
	vec2 c = (cell + 0.5 + jit * 0.6) / (dab / 8.0);
	vec2 drift = vec2(TIME * 0.008, TIME * 0.003);
	float cl = fbm(c * 0.55 + drift);
	cl = smoothstep(0.5, 0.72, cl) * smoothstep(-0.05, 0.25, d.y);
	// Lit from the sun side, violet in the shade, a warm rim.
	float lit = clamp(fbm(c * 0.55 + drift + vec2(0.06, 0.04)) - fbm(c * 0.55 + drift) + 0.55, 0.0, 1.0);
	vec3 sky = mix(horizon, mid, smoothstep(0.0, 0.25, h));
	sky = mix(sky, zenith, smoothstep(0.25, 0.85, h));
	// Each dab picks a slightly different shade, like oil laid wet on wet.
	float tone = hash(cell + 11.0);
	sky *= 0.94 + tone * 0.1;
	vec3 cloud = mix(cloud_shade, cloud_lit, lit);
	cloud = mix(cloud, horizon, 0.25 * (1.0 - smoothstep(0.0, 0.3, d.y)));
	cloud *= 0.95 + tone * 0.08;
	vec3 col = mix(sky, cloud, cl);
	// The sun: a warm bloom, no hard disc.
	float sd = max(dot(d, normalize(sun_dir)), 0.0);
	col += vec3(1.0, 0.85, 0.6) * pow(sd, 18.0) * 0.6 + vec3(1.0, 0.9, 0.7) * pow(sd, 260.0) * 1.2;
	// Visible canvas: a faint weave.
	col *= 0.97 + 0.03 * sin(FRAGCOORD.x * 1.7) * sin(FRAGCOORD.y * 1.9);
	ALBEDO = col;
}
