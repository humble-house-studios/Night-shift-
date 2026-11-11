extends RefCounted
## Little flat icons for the cards and relics, drawn in code on any
## CanvasItem: clean shapes, one accent colour, a dark ink outline.
## draw(ci, id, rect, accent)

const INK := Color(0.08, 0.06, 0.1)
const PAPER := Color(0.97, 0.95, 0.88)


static func _r(rect: Rect2, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(rect.position + rect.size * Vector2(x, y), rect.size * Vector2(w, h))


static func _p(rect: Rect2, x: float, y: float) -> Vector2:
	return rect.position + rect.size * Vector2(x, y)


static func _box(ci: CanvasItem, r: Rect2, fill: Color, line := 0.0) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, INK, false, line if line > 0.0 else maxf(2.0, r.size.x * 0.03))


static func _lines(ci: CanvasItem, rect: Rect2, x0: float, x1: float, ys: Array, w := 2.0) -> void:
	for y in ys:
		ci.draw_line(_p(rect, x0, y), _p(rect, x1, y), INK, w)


static func draw(ci: CanvasItem, id: String, rect: Rect2, accent: Color) -> void:
	var s := rect.size.x
	var lw := maxf(2.0, s * 0.035)
	match id:
		"timecard":
			_box(ci, _r(rect, 0.22, 0.12, 0.56, 0.76), PAPER, lw)
			ci.draw_rect(_r(rect, 0.22, 0.12, 0.56, 0.14), accent)
			_lines(ci, rect, 0.3, 0.7, [0.36, 0.46, 0.56, 0.66, 0.76], lw * 0.6)
			ci.draw_rect(_r(rect, 0.52, 0.42, 0.18, 0.08), Color(0.85, 0.2, 0.2))
		"badge":
			ci.draw_line(_p(rect, 0.5, 0.0), _p(rect, 0.5, 0.2), accent, lw * 2.0)
			_box(ci, _r(rect, 0.25, 0.18, 0.5, 0.68), PAPER, lw)
			ci.draw_circle(_p(rect, 0.5, 0.4), s * 0.1, accent)
			ci.draw_rect(_r(rect, 0.32, 0.58, 0.36, 0.06), INK)
			ci.draw_rect(_r(rect, 0.36, 0.7, 0.28, 0.04), INK)
		"code":
			_box(ci, _r(rect, 0.12, 0.28, 0.76, 0.44), Color(0.05, 0.12, 0.06), lw)
			for i in 4:
				var x := 0.2 + i * 0.16
				ci.draw_rect(_r(rect, x, 0.38, 0.11, 0.24), accent, false, lw)
			ci.draw_rect(_r(rect, 0.2, 0.47, 0.11, 0.06), accent)
		"keycard":
			_box(ci, _r(rect, 0.14, 0.26, 0.72, 0.48), accent, lw)
			ci.draw_rect(_r(rect, 0.14, 0.34, 0.72, 0.08), INK)
			ci.draw_rect(_r(rect, 0.22, 0.52, 0.14, 0.12), Color(1.0, 0.9, 0.5))
			_lines(ci, rect, 0.44, 0.78, [0.56, 0.64], lw * 0.6)
		"signoff":
			_box(ci, _r(rect, 0.18, 0.16, 0.64, 0.68), PAPER, lw)
			var pts := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				pts.append(_p(rect, 0.26 + t * 0.48, 0.58 + sin(t * 11.0) * 0.06 - t * 0.06))
			ci.draw_polyline(pts, accent.darkened(0.3), lw)
			ci.draw_line(_p(rect, 0.26, 0.7), _p(rect, 0.74, 0.7), INK, lw * 0.5)
		"form":
			_box(ci, _r(rect, 0.2, 0.12, 0.6, 0.76), PAPER, lw)
			_lines(ci, rect, 0.28, 0.72, [0.24, 0.32, 0.4], lw * 0.5)
			ci.draw_circle(_p(rect, 0.56, 0.64), s * 0.14, Color(0.85, 0.15, 0.25, 0.85))
			ci.draw_circle(_p(rect, 0.56, 0.64), s * 0.09, PAPER)
			ci.draw_circle(_p(rect, 0.56, 0.64), s * 0.05, Color(0.85, 0.15, 0.25, 0.85))
		"board":
			ci.draw_rect(_r(rect, 0.08, 0.62, 0.84, 0.08), Color(0.35, 0.2, 0.12))
			for i in 4:
				var x := 0.18 + i * 0.21
				ci.draw_circle(_p(rect, x, 0.38), s * 0.07, Color(0.85, 0.75, 0.65))
				ci.draw_rect(_r(rect, x - 0.08, 0.46, 0.16, 0.16), accent.darkened(0.5 + i * 0.05))
				ci.draw_arc(_p(rect, x, 0.38), s * 0.07, 0.0, TAU, 24, INK, lw * 0.6)
		"suit":
			var pts := PackedVector2Array([_p(rect, 0.22, 0.88), _p(rect, 0.26, 0.3), _p(rect, 0.4, 0.2), _p(rect, 0.6, 0.2), _p(rect, 0.74, 0.3), _p(rect, 0.78, 0.88)])
			ci.draw_colored_polygon(pts, Color(0.12, 0.12, 0.16))
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.4, 0.2), _p(rect, 0.5, 0.42), _p(rect, 0.6, 0.2)]), PAPER)
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.47, 0.3), _p(rect, 0.53, 0.3), _p(rect, 0.55, 0.6), _p(rect, 0.5, 0.66), _p(rect, 0.45, 0.6)]), Color(0.6, 0.1, 0.15))
			ci.draw_line(_p(rect, 0.5, 0.06), _p(rect, 0.5, 0.2), INK, lw)
			ci.draw_arc(_p(rect, 0.5, 0.06), s * 0.06, PI, TAU, 8, INK, lw)
			ci.draw_rect(_r(rect, 0.6, 0.36, 0.08, 0.08), Color(0.72, 0.5, 0.95))
		"pen":
			ci.draw_line(_p(rect, 0.2, 0.8), _p(rect, 0.78, 0.22), INK, s * 0.14)
			ci.draw_line(_p(rect, 0.22, 0.78), _p(rect, 0.76, 0.24), accent, s * 0.1)
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.14, 0.86), _p(rect, 0.18, 0.72), _p(rect, 0.28, 0.82)]), INK)
			ci.draw_line(_p(rect, 0.64, 0.3), _p(rect, 0.72, 0.42), Color(0.9, 0.85, 0.7), lw)
		"rules":
			_box(ci, _r(rect, 0.2, 0.14, 0.6, 0.72), Color(0.92, 0.97, 0.94), lw)
			for i in 5:
				var y := 0.24 + i * 0.12
				ci.draw_circle(_p(rect, 0.3, y + 0.02), s * 0.025, accent.darkened(0.3))
				ci.draw_line(_p(rect, 0.36, y + 0.02), _p(rect, 0.7, y + 0.02), INK, lw * 0.5)
			ci.draw_rect(_r(rect, 0.18, 0.12, 0.64, 0.76), Color(1, 1, 1, 0.25), false, lw * 1.5)
		"mint":
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.08, 0.36), _p(rect, 0.26, 0.5), _p(rect, 0.08, 0.64)]), PAPER)
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.92, 0.36), _p(rect, 0.74, 0.5), _p(rect, 0.92, 0.64)]), PAPER)
			ci.draw_circle(_p(rect, 0.5, 0.5), s * 0.26, PAPER)
			ci.draw_arc(_p(rect, 0.5, 0.5), s * 0.26, 0.0, TAU, 24, INK, lw)
			for i in 6:
				var a := TAU * i / 6.0
				ci.draw_line(_p(rect, 0.5, 0.5), _p(rect, 0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.24, accent.darkened(0.2), lw * 1.2)
		"mug":
			_box(ci, _r(rect, 0.22, 0.3, 0.44, 0.52), Color(0.95, 0.95, 0.92), lw)
			ci.draw_arc(_p(rect, 0.68, 0.52), s * 0.12, -PI * 0.5, PI * 0.5, 10, INK, lw)
			ci.draw_rect(_r(rect, 0.24, 0.32, 0.4, 0.06), Color(0.35, 0.2, 0.1))
			for i in 3:
				var x := 0.32 + i * 0.1
				ci.draw_arc(_p(rect, x, 0.2), s * 0.04, PI * 0.5, PI * 1.5, 6, accent, lw * 0.7)
		"lanyard":
			ci.draw_polyline(PackedVector2Array([_p(rect, 0.2, 0.05), _p(rect, 0.5, 0.48), _p(rect, 0.8, 0.05)]), accent, lw * 2.0)
			_box(ci, _r(rect, 0.32, 0.46, 0.36, 0.44), PAPER, lw)
			ci.draw_rect(_r(rect, 0.38, 0.54, 0.24, 0.14), Color(0.95, 0.72, 0.2))
			ci.draw_line(_p(rect, 0.38, 0.78), _p(rect, 0.62, 0.78), INK, lw * 0.6)
		"page":
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.22, 0.1), _p(rect, 0.66, 0.1), _p(rect, 0.8, 0.24), _p(rect, 0.8, 0.9), _p(rect, 0.22, 0.9)]), PAPER)
			ci.draw_polyline(PackedVector2Array([_p(rect, 0.22, 0.1), _p(rect, 0.66, 0.1), _p(rect, 0.8, 0.24), _p(rect, 0.8, 0.9), _p(rect, 0.22, 0.9), _p(rect, 0.22, 0.1)]), INK, lw)
			_lines(ci, rect, 0.3, 0.7, [0.34, 0.44, 0.54], lw * 0.5)
			_lines(ci, rect, 0.3, 0.6, [0.66], lw * 0.5)
			ci.draw_line(_p(rect, 0.3, 0.78), _p(rect, 0.72, 0.78), accent.darkened(0.3), lw)
		"pedometer":
			ci.draw_rect(_r(rect, 0.26, 0.18, 0.48, 0.66), accent.darkened(0.2))
			ci.draw_rect(_r(rect, 0.26, 0.18, 0.48, 0.66), INK, false, lw)
			ci.draw_rect(_r(rect, 0.34, 0.3, 0.32, 0.22), Color(0.75, 0.85, 0.7))
			_lines(ci, rect, 0.38, 0.62, [0.41], lw * 0.8)
			ci.draw_circle(_p(rect, 0.5, 0.68), s * 0.07, PAPER)
		"boat":
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.14, 0.62), _p(rect, 0.86, 0.62), _p(rect, 0.72, 0.78), _p(rect, 0.28, 0.78)]), PAPER)
			ci.draw_polyline(PackedVector2Array([_p(rect, 0.14, 0.62), _p(rect, 0.86, 0.62), _p(rect, 0.72, 0.78), _p(rect, 0.28, 0.78), _p(rect, 0.14, 0.62)]), INK, lw)
			ci.draw_line(_p(rect, 0.5, 0.14), _p(rect, 0.5, 0.62), INK, lw)
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.52, 0.16), _p(rect, 0.8, 0.56), _p(rect, 0.52, 0.56)]), accent)
			ci.draw_arc(_p(rect, 0.5, 0.88), s * 0.36, PI * 1.15, PI * 1.85, 12, accent.darkened(0.2), lw)
		"kitten":
			ci.draw_circle(_p(rect, 0.5, 0.54), s * 0.26, Color(0.95, 0.75, 0.45))
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.28, 0.4), _p(rect, 0.3, 0.14), _p(rect, 0.44, 0.32)]), Color(0.95, 0.75, 0.45))
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.72, 0.4), _p(rect, 0.7, 0.14), _p(rect, 0.56, 0.32)]), Color(0.95, 0.75, 0.45))
			ci.draw_circle(_p(rect, 0.42, 0.52), s * 0.035, INK)
			ci.draw_circle(_p(rect, 0.58, 0.52), s * 0.035, INK)
			ci.draw_arc(_p(rect, 0.5, 0.62), s * 0.06, 0.2, PI - 0.2, 6, INK, lw * 0.6)
			ci.draw_arc(_p(rect, 0.5, 0.54), s * 0.26, 0.0, TAU, 24, INK, lw)
		"nameplate":
			ci.draw_colored_polygon(PackedVector2Array([_p(rect, 0.1, 0.72), _p(rect, 0.9, 0.72), _p(rect, 0.82, 0.38), _p(rect, 0.18, 0.38)]), Color(0.8, 0.62, 0.28))
			ci.draw_polyline(PackedVector2Array([_p(rect, 0.1, 0.72), _p(rect, 0.9, 0.72), _p(rect, 0.82, 0.38), _p(rect, 0.18, 0.38), _p(rect, 0.1, 0.72)]), INK, lw)
			_lines(ci, rect, 0.3, 0.7, [0.54], lw * 1.4)
		_:
			ci.draw_circle(rect.get_center(), s * 0.3, accent)
