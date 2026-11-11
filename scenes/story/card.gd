extends Control
## One collectible card, drawn in code: a dark rounded card with a coloured
## header, a big flat icon on a soft glow, the name, a flavour line and the
## floor it came from. Goal cards have a gold edge; relics a silver one.
## A shine sweeps across now and then. `locked` = a silhouette (COLLECTION).

const Icons := preload("res://scenes/story/icons.gd")
const PIXEL := preload("res://addons/hh_minigames/_shared/fonts/press_start_2p.ttf")
const BODY := preload("res://addons/hh_minigames/_shared/fonts/pixelify_sans.ttf")

var info: Array = ["", "", "", 1, Color.WHITE]   # name, flavour, icon, act, colour
var kind := "card"   # "card" (goal) or "relic"
var locked := false
var shine := -1.0
var _t := 0.0


func setup(entry: Array, k: String, is_locked := false) -> void:
	info = entry
	kind = k
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not locked and is_visible_in_tree():
		shine = fmod(_t * 0.5, 2.4) - 0.4
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var w := size.x
	var col: Color = info[4] if not locked else Color(0.35, 0.35, 0.4)
	var edge := Color(1.0, 0.82, 0.4) if kind == "card" else Color(0.82, 0.86, 0.95)
	if locked:
		edge = Color(0.3, 0.3, 0.35)
	var body := StyleBoxFlat.new()
	body.bg_color = Color(0.07, 0.06, 0.1)
	body.border_color = edge
	body.set_border_width_all(maxi(2, int(w * 0.022)))
	body.set_corner_radius_all(int(w * 0.07))
	body.shadow_color = Color(col.r, col.g, col.b, 0.35 if not locked else 0.0)
	body.shadow_size = int(w * 0.06)
	draw_style_box(body, r)
	# Header band in the card's colour.
	var head := StyleBoxFlat.new()
	head.bg_color = col.darkened(0.15)
	head.corner_radius_top_left = int(w * 0.06)
	head.corner_radius_top_right = int(w * 0.06)
	var pad := w * 0.035
	draw_style_box(head, Rect2(pad, pad, w - pad * 2, size.y * 0.13))
	var fs_tag := maxi(8, int(w * 0.042))
	var tag := ("GOAL CARD" if kind == "card" else "RELIC") if not locked else "???"
	draw_string(PIXEL, Vector2(pad * 2.2, pad + size.y * 0.085), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_tag, Color(0.06, 0.04, 0.08))
	draw_string(PIXEL, Vector2(0, pad + size.y * 0.085), "F%d" % info[3], HORIZONTAL_ALIGNMENT_RIGHT, w - pad * 2.2, fs_tag, Color(0.06, 0.04, 0.08))
	# The icon on a soft glow.
	var ic := Rect2(w * 0.2, size.y * 0.2, w * 0.6, w * 0.6)
	for i in 6:
		draw_circle(ic.get_center(), ic.size.x * (0.62 - i * 0.07), Color(col.r, col.g, col.b, 0.05 + i * 0.012))
	if locked:
		draw_string(PIXEL, ic.get_center() + Vector2(-w * 0.08, w * 0.08), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * 0.22), Color(0.4, 0.4, 0.45))
	else:
		Icons.draw(self, info[2], ic, col)
	# Name and flavour.
	var name_y := size.y * 0.2 + w * 0.6 + w * 0.08
	var fs_name := maxi(9, int(w * 0.052))
	draw_multiline_string(PIXEL, Vector2(pad * 2, name_y), info[0] if not locked else "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, w - pad * 4, fs_name, 2, Color(1, 0.97, 0.9) if not locked else Color(0.5, 0.5, 0.55))
	if not locked:
		var fs_body := maxi(10, int(w * 0.058))
		draw_multiline_string(BODY, Vector2(pad * 2.5, name_y + fs_name * 2.6), info[1], HORIZONTAL_ALIGNMENT_CENTER, w - pad * 5, fs_body, 4, Color(0.85, 0.83, 0.9))
	# The shine: a soft diagonal band sweeping across.
	if shine > -0.3 and shine < 1.3:
		var x := shine * w * 1.4 - w * 0.2
		var band := PackedVector2Array([Vector2(x, 0), Vector2(x + w * 0.16, 0), Vector2(x - w * 0.24, size.y), Vector2(x - w * 0.4, size.y)])
		var clip := PackedVector2Array()
		for p in band:
			clip.append(Vector2(clampf(p.x, pad, w - pad), p.y))
		draw_colored_polygon(clip, Color(1, 1, 1, 0.07))
