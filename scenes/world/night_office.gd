extends Node
## The Look Busy office after hours, rebuilt for Night Shift: the same room,
## hand-made pieces and PS1 paint (ps1.gdshader at after_hours = 1), with the
## night's people in it. Builds into a Node3D you give it; story/main.gd
## drives the lights, the screens and the people.
## The helpers (_mat, _box, _cyl, _lump, _chair, _crt...) are Look Busy's
## (scenes/office/office.gd), kept the same so the two games look like one.

const Handmade := preload("res://addons/hh_minigames/_shared/handmade.gd")
const Puppet := preload("res://scenes/world/puppet.gd")
const SUNSET := preload("res://scenes/world/sunset.gdshader")
const LAYER_WORLD := 1

const DESK_SCREEN := Vector3(0.0, 1.17, -2.38)
const PHONE_SPOT := Vector3(0.5, 0.76, -2.3)
const DALE_SPOT := Vector3(-3.05, 0.0, -0.6)
const KIP_SPOT := Vector3(3.05, 0.0, -0.9)
const PRINTY_SPOT := Vector3(3.12, 0.0, 1.15)
const WENDY_SPOT := Vector3(-0.75, 0.0, 2.45)
const COFFEE_SPOT := Vector3(-2.55, 0.0, 3.72)
const PUNCH_SPOT := Vector3(0.35, 1.3, 3.99)

const LOOKS := {
	"dale": {"skin": Color(0.93, 0.72, 0.58), "shirt": Color(0.7, 0.8, 0.88), "sleeves": "short", "pants": Color(0.22, 0.24, 0.3), "hair": Color(0.36, 0.24, 0.15), "hair_style": "horseshoe", "glasses": true, "moustache": true, "tie": Color(0.62, 0.12, 0.42), "wide": 1.3, "belly": true},
	"wendy": {"skin": Color(0.4, 0.26, 0.19), "shirt": Color(0.34, 0.42, 0.45), "pants": Color(0.22, 0.25, 0.28), "hair": Color(0.74, 0.74, 0.76), "hair_style": "curls", "lanyard": true, "brows": 0.15, "collar": true},
	"kip": {"skin": Color(0.96, 0.8, 0.66), "shirt": Color(0.95, 0.72, 0.2), "pants": Color(0.62, 0.54, 0.38), "hair": Color(0.45, 0.3, 0.18), "hair_style": "cap_back", "cap": Color(0.2, 0.35, 0.82), "lanyard": true, "wide": 0.86, "brows": -0.25},
}

var root: Node3D
## Where each floor is built (main.gd moves you between them): 1 = the night
## shift, 2 = middle management, 3 = the top, 4 = the field past the roof.
const ORIGIN := {1: Vector3.ZERO, 2: Vector3(40, 0, 0), 3: Vector3(80, 0, 0), 4: Vector3(400, 0, 0)}
var _room := ""
var _rooms := {}
var _r: Node3D
var floor_nodes := {}
## Floor two: Marge's route, Chad's TV, the ceiling tubes (they die at 3:33).
const ROUTE := [Vector3(-3.6, 0, -2.6), Vector3(3.6, 0, -2.6), Vector3(3.6, 0, 2.6), Vector3(-3.6, 0, 2.6)]
var chad_caption: Label3D
var chad_scene: Node3D
var chad_blue: MeshInstance3D
var tubes: Array = []
var desk_screens: Array = []
var ceo_chair: Node3D
var dale3: Node3D
var field_people: Node3D
var wheat_mat: ShaderMaterial
var _ps1 := preload("res://scenes/world/ps1.gdshader")
var _exact := false
var _shadow_mat: StandardMaterial3D
var _shadow_quad: QuadMesh
var _night := 1.0
var _lights := 1.0
var _slot_pos := PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
var _slot_col := PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
var _all_mats: Array[ShaderMaterial] = []
var _sunset_mats: Array[ShaderMaterial] = []
var _night_glow: Array = []
var _clock_hands: Array[Node3D] = []
var _dale_root: Node3D
var _dale_desk_body: Node3D
var _last_frame: MeshInstance3D
var _pages: Array = []

## Built pieces the story drives.
var people := {}
var screens := {}
var phone: Node3D
var paper_at := Vector3.ZERO
var doors: Array = []
var floor_label: Label3D
var punch_label: Label3D
var coffee_dot: ShaderMaterial
## "Golden Hour", the painting the title sequence opens on.
const PICTURE := Vector3(-1.45, 1.62, 3.975)
var picture_mat: ShaderMaterial


func _mat(albedo: Color, pattern := 0, albedo2 := Color.BLACK, texel := 24.0, emission := Color.BLACK) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _ps1
	if _room != "":
		# Floors two and three and the field bring their own lights.
		_rooms[_room].mats.append(m)
		m.set_shader_parameter("office_lights", 0.0)
		_apply_room(m, _rooms[_room])
	else:
		_all_mats.append(m)
		m.set_shader_parameter("after_hours", _night * _night * (3.0 - 2.0 * _night))
		m.set_shader_parameter("office_lights", _lights)
		_room_uniforms(m)
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("albedo2", albedo2)
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("texel", texel)
	m.set_shader_parameter("emission", emission)
	return m


## A box at pos (its centre), optionally solid to walk into. Hand-made
## (bevelled, never quite square: Handmade.box) unless it's a wall, floor or
## ceiling (`_exact`, so they still meet without gaps) or too thin to bevel
## (screens, stickers, glowing panels).
func _box(size: Vector3, pos: Vector3, mat: Material, solid := false, rot := Vector3.ZERO, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var longest := maxf(size.x, maxf(size.y, size.z))
	var wall := solid and size.y >= 1.85 and minf(size.x, size.z) <= 0.11
	if _exact or wall or longest >= 3.3 or Handmade.is_thin(size):
		var mesh := BoxMesh.new()
		mesh.size = size
		# Subdivide big faces so the per-vertex light has something to work with.
		mesh.subdivide_width = clampi(int(size.x / 0.3), 0, 24)
		mesh.subdivide_height = clampi(int(size.y / 0.3), 0, 24)
		mesh.subdivide_depth = clampi(int(size.z / 0.3), 0, 24)
		mi.mesh = mesh
	else:
		mi.mesh = Handmade.box(size, Handmade.variant_at(pos + size))
	mi.material_override = mat
	mi.layers = LAYER_WORLD
	mi.position = pos
	mi.rotation = rot
	(parent if parent else root).add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		mi.add_child(body)
		if not (_exact or wall or longest >= 3.3):
			_ground(mi, size)
	return mi


## A turned shape (mug, leg, bin): Handmade.tube, rims bevelled, never quite round.
func _cyl(radius: float, height: float, pos: Vector3, mat: Material, rot := Vector3.ZERO, sides := 8, top := -1.0, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Handmade.tube(radius, height, sides, top, Handmade.variant_at(pos))
	mi.material_override = mat
	mi.layers = LAYER_WORLD
	mi.position = pos
	mi.rotation = rot
	(parent if parent else root).add_child(mi)
	return mi


## A soft painted shadow on the floor under a solid piece of furniture: dark
## under things that stand on the carpet, fainter under table tops.
func _ground(mi: MeshInstance3D, size: Vector3) -> void:
	if not mi.is_inside_tree():
		return
	var at := mi.global_position
	var bottom := at.y - size.y * 0.5
	if bottom < -0.02 or bottom > 0.9 or absf(mi.global_transform.basis.y.y) < 0.95:
		return
	# Under the piece's own parent, so it hides (and moves) with it.
	_shadow(Vector3(at.x, 0.0, at.z), Vector2(size.x, size.z), lerpf(0.55, 0.16, bottom / 0.9), mi.global_rotation.y, mi.get_parent())


## A blob of shadow painted on the floor at `at` (world), `size` across.
func _shadow(at: Vector3, size: Vector2, strength := 0.5, yaw := 0.0, parent: Node = null) -> MeshInstance3D:
	if _shadow_mat == null:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		grad.colors = PackedColorArray([Color(0.07, 0.05, 0.07, 1.0), Color(0.07, 0.05, 0.07, 0.7), Color(0.07, 0.05, 0.07, 0.0)])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 32
		tex.height = 32
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.albedo_texture = tex
		_shadow_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_shadow_mat.vertex_color_use_as_albedo = true
		_shadow_quad = QuadMesh.new()
		_shadow_quad.size = Vector2.ONE
		_shadow_quad.orientation = PlaneMesh.FACE_Y
	var mi := MeshInstance3D.new()
	mi.mesh = _shadow_quad
	mi.material_override = _shadow_mat
	mi.layers = LAYER_WORLD
	mi.transparency = 1.0 - clampf(strength, 0.0, 1.0)
	mi.scale = Vector3(size.x * 1.3 + 0.1, 1.0, size.y * 1.3 + 0.1)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else root).add_child(mi)
	mi.global_position = Vector3(at.x, at.y + 0.006, at.z)
	mi.global_rotation = Vector3(0.0, yaw, 0.0)
	return mi


func _label(text: String, pos: Vector3, size: int, color: Color, rot := Vector3.ZERO, width := 0.0, parent: Node = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://addons/hh_minigames/_shared/fonts/press_start_2p.ttf")
	l.font_size = size
	l.pixel_size = 0.002
	l.modulate = color
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.position = pos
	l.rotation = rot
	l.layers = LAYER_WORLD
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.width = width
	(parent if parent else root).add_child(l)
	return l


## A chunky beige 90s CRT, its 4:3 glass centred on pos and facing +z in
## parent space: bezel with a fat chin, dark rim, tapered tube with vents on
## top, a badge, a power LED and a swivel foot down to desk_y.
func _crt(parent: Node, pos: Vector3, glass: Vector2, shell: Material, badge: String, led: Color, desk_y := 0.76) -> void:
	var rim := _mat(Color(0.14, 0.13, 0.12))
	var vent := _mat(Color(0.45, 0.42, 0.36))
	var bw := glass.x + 0.13
	var bh := glass.y + 0.16
	var by := pos.y - 0.015
	_box(Vector3(bw, bh, 0.09), Vector3(pos.x, by, pos.z - 0.05), shell, false, Vector3.ZERO, parent)
	_box(Vector3(glass.x + 0.035, glass.y + 0.035, 0.004), Vector3(pos.x, pos.y, pos.z - 0.0045), rim, false, Vector3.ZERO, parent)
	_box(Vector3(bw * 0.86, bh * 0.84, 0.2), Vector3(pos.x, by + 0.005, pos.z - 0.19), shell, false, Vector3.ZERO, parent)
	_box(Vector3(bw * 0.58, bh * 0.58, 0.12), Vector3(pos.x, by + 0.01, pos.z - 0.34), shell, false, Vector3.ZERO, parent)
	var top := by + 0.005 + bh * 0.42
	for i in 5:
		_box(Vector3(bw * 0.5, 0.004, 0.012), Vector3(pos.x, top + 0.002, pos.z - 0.13 - i * 0.03), vent, false, Vector3.ZERO, parent)
	# Chin: badge on the left, two knobs and the power LED on the right.
	var chin := pos.y - glass.y * 0.5 - 0.048
	_label(badge, Vector3(pos.x - bw * 0.5 + 0.03 + badge.length() * 0.0075, chin, pos.z - 0.004), 7, Color(0.38, 0.35, 0.3), Vector3.ZERO, 0.0, parent)
	for k in 2:
		_box(Vector3(0.022, 0.022, 0.01), Vector3(pos.x + bw * 0.5 - 0.15 + k * 0.035, chin, pos.z - 0.004), vent, false, Vector3.ZERO, parent)
	_box(Vector3(0.026, 0.012, 0.01), Vector3(pos.x + bw * 0.5 - 0.05, chin, pos.z - 0.004), _mat(Color.BLACK, 0, Color.BLACK, 24.0, led), false, Vector3.ZERO, parent)
	# Swivel foot.
	var bottom := by - bh * 0.5
	if bottom - desk_y > 0.01:
		_box(Vector3(bw * 0.42, bottom - desk_y, 0.2), Vector3(pos.x, (bottom + desk_y) * 0.5, pos.z - 0.14), shell, false, Vector3.ZERO, parent)
	_box(Vector3(bw * 0.55, 0.02, 0.3), Vector3(pos.x, desk_y + 0.01, pos.z - 0.14), shell, false, Vector3.ZERO, parent)


## A beige tower PC on the floor, front facing +z: floppy slot, CD tray, LED.
func _tower(parent: Node, pos: Vector3, shell: Material) -> void:
	var dark := _mat(Color(0.2, 0.19, 0.17))
	_box(Vector3(0.2, 0.44, 0.44), pos + Vector3(0, 0.22, 0), shell, false, Vector3.ZERO, parent)
	_box(Vector3(0.15, 0.03, 0.005), pos + Vector3(0, 0.37, 0.221), dark, false, Vector3.ZERO, parent)
	_box(Vector3(0.12, 0.008, 0.005), pos + Vector3(0, 0.31, 0.221), dark, false, Vector3.ZERO, parent)
	_box(Vector3(0.02, 0.01, 0.005), pos + Vector3(0.05, 0.25, 0.221), _mat(Color.BLACK, 0, Color.BLACK, 24.0, Color(0.3, 1.0, 0.4)), false, Vector3.ZERO, parent)
	for i in 4:
		_box(Vector3(0.12, 0.004, 0.005), pos + Vector3(0, 0.06 + i * 0.02, 0.221), dark, false, Vector3.ZERO, parent)


## Shared shell colours: classic beige, and a slightly greyer putty.
func _beige() -> ShaderMaterial:
	return _mat(Color(0.86, 0.82, 0.7), 6, Color.BLACK, 40.0)


## The sunset (sunset.gdshader) on a quad facing +z of `rot`, `size` across.
## Every one follows the after-hours fade (_apply_night).
func _sunset_quad(size: Vector2, pos: Vector3, rot: Vector3, params: Dictionary, parent: Node = null) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = SUNSET
	m.set_shader_parameter("aspect", size.x / size.y)
	for k in params:
		m.set_shader_parameter(k, params[k])
	m.set_shader_parameter("night", _night * _night * (3.0 - 2.0 * _night))
	_sunset_mats.append(m)
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.layers = LAYER_WORLD
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.rotation = rot
	(parent if parent else root).add_child(mi)
	return mi


## A swivel chair facing local +z: a soft cushion and back, a gas lift and a
## five-star base on casters. `solid` = you bump into the seat.
## `dark` / `steel` = the frame's materials (the other floors pass their own,
## lit by their own lights).
func _chair(parent: Node3D, fabric: Material, solid := false, back := 0.56, dark: Material = null, steel: Material = null) -> void:
	if dark == null:
		dark = _mat(Color(0.1, 0.1, 0.11))
	if steel == null:
		steel = _mat(Color(0.55, 0.56, 0.58))
	_box(Vector3(0.42, 0.05, 0.4), Vector3(0, 0.36, 0), dark, solid, Vector3.ZERO, parent)
	_lump(Vector3(0.52, 0.11, 0.5), Vector3(0, 0.41, 0.0), fabric, parent, 0.6)
	_lump(Vector3(0.48, back, 0.12), Vector3(0, 0.52 + back * 0.5, -0.28), fabric, parent, 0.6, Vector3(0.12, 0, 0))
	_box(Vector3(0.06, 0.3, 0.03), Vector3(0, 0.48, -0.28), dark, false, Vector3(0.12, 0, 0), parent)
	for side in [-1.0, 1.0]:
		_box(Vector3(0.03, 0.2, 0.03), Vector3(side * 0.27, 0.5, -0.04), dark, false, Vector3.ZERO, parent)
		_lump(Vector3(0.06, 0.04, 0.26), Vector3(side * 0.27, 0.61, -0.02), dark, parent, 0.7)
	_cyl(0.028, 0.26, Vector3(0, 0.22, 0), steel, Vector3.ZERO, 6, -1.0, parent)
	_lump(Vector3(0.1, 0.07, 0.1), Vector3(0, 0.1, 0), dark, parent)
	for i in 5:
		var a := TAU * i / 5.0
		_box(Vector3(0.045, 0.03, 0.28), Vector3(sin(a) * 0.14, 0.085, cos(a) * 0.14), dark, false, Vector3(0.12, a, 0), parent)
		_lump(Vector3(0.05, 0.05, 0.05), Vector3(sin(a) * 0.27, 0.03, cos(a) * 0.27), dark, parent)
	if parent.is_inside_tree():
		_shadow(parent.global_position, Vector2(0.5, 0.5), 0.45, 0.0, parent)


## Four bits of yellowed tape holding a poster `size` across to the wall at
## pos (facing +z in parent space), none of them straight.
func _tape(pos: Vector3, size: Vector2, parent: Node = null) -> void:
	var tape := _mat(Color(0.9, 0.84, 0.62))
	var i := 0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			i += 1
			_box(Vector3(0.09, 0.03, 0.004), pos + Vector3(sx * (size.x * 0.5 - 0.01), sy * (size.y * 0.5 - 0.01), 0.004), tape, false,
				Vector3(0, 0, sx * sy * -0.75 + sin(i * 7.3 + pos.x * 3.0) * 0.25), parent)


## A mug with a handle (turned toward +x) and something in it.
func _mug(pos: Vector3, mat: Material, parent: Node = null, drink := Color(0.33, 0.19, 0.1), turn := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = turn
	(parent if parent else root).add_child(n)
	_cyl(0.04, 0.1, Vector3(0, 0.05, 0), mat, Vector3.ZERO, 8, 0.046, n)
	_cyl(0.037, 0.006, Vector3(0, 0.099, 0), _mat(drink), Vector3.ZERO, 8, -1.0, n)
	_box(Vector3(0.034, 0.014, 0.014), Vector3(0.056, 0.075, 0), mat, false, Vector3.ZERO, n)
	_box(Vector3(0.034, 0.014, 0.014), Vector3(0.056, 0.03, 0), mat, false, Vector3.ZERO, n)
	_box(Vector3(0.014, 0.058, 0.014), Vector3(0.07, 0.0525, 0), mat, false, Vector3.ZERO, n)
	return n


## A low-poly sphere (faceted, like the rest of the room).
## A lump of clay (Handmade.blob): a ball, squashed by `squash`; soft < 1
## flattens it toward a pillow with rounded corners (heads, cushions).
func _ball(radius: float, pos: Vector3, mat: Material, parent: Node3D, squash := Vector3.ONE, soft := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Handmade.blob(Vector3.ONE * radius * 2.0 * squash, soft, 10, Handmade.variant_at(pos))
	mi.material_override = mat
	mi.layers = LAYER_WORLD
	mi.position = pos
	parent.add_child(mi)
	return mi


## A lump of clay `dims` across (Handmade.blob), optionally turned.
func _lump(dims: Vector3, pos: Vector3, mat: Material, parent: Node, soft := 1.0, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Handmade.blob(dims, soft, 10, Handmade.variant_at(pos + dims))
	mi.material_override = mat
	mi.layers = LAYER_WORLD
	mi.position = pos
	mi.rotation = rot
	(parent if parent else root).add_child(mi)
	return mi

# ---------------------------------------------------------------- the night

## Every office material follows these: after hours (1 = night, 0 = golden
## hour, which is also what dawn looks like), the office lights (blackout),
## and six extra room lights (Wendy's lantern, the EXIT sign, the coffee
## maker, red screens).
func set_night(e: float) -> void:
	_night = clampf(e, 0.0, 1.0)
	var s := _night * _night * (3.0 - 2.0 * _night)
	for m in _all_mats:
		m.set_shader_parameter("after_hours", s)
	for g in _night_glow:
		g[0].set_shader_parameter("emission", (g[1] as Color).lerp(g[2], s))
	for m in _sunset_mats:
		m.set_shader_parameter("night", s)


func set_lights(k: float) -> void:
	_lights = k
	for m in _all_mats:
		m.set_shader_parameter("office_lights", k)


func set_slot(i: int, pos: Vector3, col: Color) -> void:
	_slot_pos[i] = pos
	_slot_col[i] = Vector3(col.r, col.g, col.b)
	for m in _all_mats:
		_room_uniforms(m)


func _room_uniforms(m: ShaderMaterial) -> void:
	m.set_shader_parameter("room_range", 3.0)
	m.set_shader_parameter("room_pos", _slot_pos)
	m.set_shader_parameter("room_col", _slot_col)


## A glowing panel (screens, lamps, signs), not in the after-hours fade.
func _glow(c: Color) -> ShaderMaterial:
	return _mat(Color.BLACK, 0, Color.BLACK, 24.0, c)


## A lit screen: a glowing pane and its words, facing +z in parent space.
func _screen(id: String, parent: Node3D, pos: Vector3, size: Vector2, text: String, col: Color, font := 22) -> void:
	var m := _glow(col.darkened(0.82))
	_box(Vector3(size.x, size.y, 0.002), pos + Vector3(0, 0, -0.002), m, false, Vector3.ZERO, parent)
	var l := _label(text, pos + Vector3(0, 0, 0.001), font, col, Vector3.ZERO, size.x / 0.002 * 0.92, parent)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screens[id] = {"mat": m, "label": l, "text": text, "col": col, "font": font}


## Show something on a screen ("" = its usual words); off = dark glass.
func screen(id: String, text := "", col := Color(), off := false) -> void:
	var s: Dictionary = screens[id]
	var c: Color = s.col if col == Color() else col
	s.label.text = s.text if text == "" else text
	s.label.modulate = c
	s.label.visible = not off
	s.mat.set_shader_parameter("emission", Color(0.03, 0.03, 0.035) if off else c.darkened(0.82))


func screen_ids() -> Array:
	return screens.keys()


# ---------------------------------------------------------------- build

func build(parent: Node3D) -> void:
	root = parent
	set_slot(0, Vector3(-1.2, 1.5, 2.6), Color(0.75, 0.5, 0.22))
	set_slot(1, Vector3(1.8, 2.4, 3.85), Color(0.5, 0.06, 0.05))
	set_slot(2, Vector3(-2.55, 1.15, 3.55), Color(0.22, 0.04, 0.03))
	_build_room()
	_build_your_desk()
	_build_dale()
	_build_kip()
	_build_printy()
	_build_wendy()
	_build_board()
	_build_coffee()
	_build_exit()
	_build_props()
	_build_picture()
	_build_floor2()
	_build_floor3()
	_build_field()
	set_night(_night)


func _build_room() -> void:
	# Room: x -3.5..3.5, z -3..4, 2.6 tall, the elevator in the front wall.
	# Look Busy's golden-hour office; at night (after_hours) the CRTs, Dale's
	# lamp and the moon in the window light it (ps1.gdshader).
	var wall := _mat(Color(0.88, 0.82, 0.68), 6, Color.BLACK, 20.0)
	var carpet := _mat(Color(0.5, 0.6, 0.56), 1, Color(0.43, 0.52, 0.49), 28.0)
	var ceiling := _mat(Color(0.93, 0.92, 0.87), 2, Color(0.64, 0.62, 0.58), 30.0)
	var trim := _mat(Color(0.58, 0.4, 0.25))
	_exact = true
	_box(Vector3(7.4, 0.1, 7.4), Vector3(0, -0.05, 0.5), carpet, true)
	_box(Vector3(7.4, 0.1, 7.4), Vector3(0, 2.65, 0.5), ceiling, true)
	_box(Vector3(7.4, 2.6, 0.1), Vector3(0, 1.3, -3.05), wall, true)
	# South wall, with a gap (x 0.85..2.75, 2.5 tall) for the elevator up the
	# ladder (ladder.gd builds it: scenes/office/lift.gd).
	_box(Vector3(4.55, 2.6, 0.1), Vector3(-1.425, 1.3, 4.05), wall, true)
	_box(Vector3(0.95, 2.6, 0.1), Vector3(3.225, 1.3, 4.05), wall, true)
	_box(Vector3(1.9, 0.1, 0.1), Vector3(1.8, 2.55, 4.05), wall, true)
	# The left wall, built round the window opening (z -1.4..0.4, y 0.95..2.05)
	# so you can see out of it.
	_box(Vector3(0.1, 0.95, 7.2), Vector3(-3.55, 0.475, 0.5), wall, true)
	_box(Vector3(0.1, 0.55, 7.2), Vector3(-3.55, 2.325, 0.5), wall, true)
	_box(Vector3(0.1, 1.1, 1.7), Vector3(-3.55, 1.5, -2.25), wall, true)
	_box(Vector3(0.1, 1.1, 3.7), Vector3(-3.55, 1.5, 2.25), wall, true)
	_box(Vector3(0.1, 2.6, 7.2), Vector3(3.55, 1.3, 0.5), wall, true)
	for b in [[Vector3(7.0, 0.1, 0.02), Vector3(0, 0.05, -2.99)], [Vector3(4.35, 0.1, 0.02), Vector3(-1.325, 0.05, 3.99)],
			[Vector3(0.75, 0.1, 0.02), Vector3(3.125, 0.05, 3.99)],
			[Vector3(0.02, 0.1, 7.0), Vector3(-3.49, 0.05, 0.5)], [Vector3(0.02, 0.1, 7.0), Vector3(3.49, 0.05, 0.5)]]:
		_box(b[0], b[1], trim)
	_exact = false

	# Ceiling panels, dimmed: the sun does the lighting.
	var panel := _mat(Color(0.2, 0.2, 0.2), 0, Color.BLACK, 24.0, Color(0.62, 0.55, 0.45))
	_night_glow.append([panel, Color(0.62, 0.55, 0.45), Color(0.04, 0.05, 0.07)])
	_box(Vector3(0.6, 0.03, 1.2), Vector3(0, 2.59, -1.6), panel)
	_box(Vector3(0.6, 0.03, 1.2), Vector3(0, 2.59, 2.2), panel)

	# Window on the left wall: the real sunset over the bay outside
	# (sunset.gdshader, a big painted backdrop out past the wall), the blinds
	# pulled half way up, and the long low sunbeam across the carpet.
	_sunset_quad(Vector2(10.0, 5.5), Vector3(-6.5, 1.3, -0.5), Vector3(0, PI / 2, 0),
		{"grid": 420.0, "horizon": 0.5, "sun_x": 0.53, "window_view": 1.0})
	_box(Vector3(0.08, 1.2, 0.06), Vector3(-3.47, 1.5, 0.43), trim)
	_box(Vector3(0.08, 1.2, 0.06), Vector3(-3.47, 1.5, -1.43), trim)
	_box(Vector3(0.12, 0.05, 1.9), Vector3(-3.45, 0.93, -0.5), trim)
	_box(Vector3(0.1, 0.06, 1.9), Vector3(-3.46, 2.07, -0.5), trim)
	_box(Vector3(0.04, 0.04, 1.8), Vector3(-3.56, 1.5, -0.5), trim)
	var slat := _mat(Color(0.78, 0.66, 0.5), 0, Color.BLACK, 24.0, Color(0.1, 0.05, 0.01))
	_night_glow.append([slat, Color(0.1, 0.05, 0.01), Color(0.0, 0.0, 0.0)])
	var y := 2.0
	while y > 1.42:
		_box(Vector3(0.05, 0.012, 1.78), Vector3(-3.46, y, -0.5), slat, false, Vector3(0, 0, -0.55))
		y -= 0.05
	_box(Vector3(0.06, 0.025, 1.8), Vector3(-3.46, 1.4, -0.5), slat)
	_cyl(0.004, 0.5, Vector3(-3.43, 1.58, 0.3), _mat(Color(0.92, 0.88, 0.8)), Vector3.ZERO, 4)
	_lump(Vector3(0.02, 0.035, 0.02), Vector3(-3.43, 1.32, 0.3), _mat(Color(0.92, 0.88, 0.8)), null)
	var beam := _mat(Color(0.58, 0.66, 0.56), 1, Color(0.5, 0.58, 0.5), 28.0, Color(0.42, 0.2, 0.04))
	_night_glow.append([beam, Color(0.42, 0.2, 0.04), Color(0.02, 0.04, 0.1)])
	_box(Vector3(4.2, 0.004, 1.3), Vector3(-1.3, 0.003, -0.35), beam, false, Vector3(0, 0.18, 0))



func _build_props() -> void:
	var metal := _mat(Color(0.62, 0.64, 0.62))
	var dark := _mat(Color(0.1, 0.1, 0.11))
	# Filing cabinet.
	_box(Vector3(0.5, 1.3, 0.6), Vector3(-3.15, 0.65, -2.6), metal, true)
	for y in [0.3, 0.62, 0.94]:
		_box(Vector3(0.44, 0.015, 0.01), Vector3(-3.15, y + 0.12, -2.29), dark)
		_box(Vector3(0.12, 0.03, 0.02), Vector3(-3.15, y, -2.29), dark)

	# Plant in the corner: a terracotta pot, soil, and leaves that all lean
	# their own way.
	var pot := _mat(Color(0.62, 0.34, 0.22), 6, Color.BLACK, 40.0)
	_cyl(0.16, 0.34, Vector3(3.1, 0.17, -2.6), pot, Vector3.ZERO, 8, 0.21)
	_cyl(0.225, 0.05, Vector3(3.1, 0.345, -2.6), pot, Vector3.ZERO, 8)
	_cyl(0.19, 0.02, Vector3(3.1, 0.365, -2.6), _mat(Color(0.24, 0.16, 0.1)), Vector3.ZERO, 8)
	_shadow(Vector3(3.1, 0, -2.6), Vector2(0.4, 0.4), 0.55)
	var leaf := _mat(Color(0.3, 0.6, 0.3), 6, Color.BLACK, 30.0)
	var leaf2 := _mat(Color(0.4, 0.7, 0.32), 6, Color.BLACK, 30.0)
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var out := 0.5 if i % 2 == 0 else 0.26
		var tall := 0.5 if i % 2 == 0 else 0.66
		_lump(Vector3(0.13, tall, 0.035), Vector3(3.1 + sin(a) * (0.05 + out * 0.22), 0.36 + tall * 0.46, -2.6 + cos(a) * (0.05 + out * 0.22)),
			leaf if i % 3 else leaf2, null, 1.0, Vector3(cos(a) * out, a, -sin(a) * out))

	# Coat rack by the back wall: a jacket somebody forgot, and a hat.
	var rack := _mat(Color(0.42, 0.28, 0.17), 3, Color(0.35, 0.23, 0.14), 60.0)
	var rack_at := Vector3(2.4, 0, -2.72)
	_cyl(0.17, 0.04, rack_at + Vector3(0, 0.02, 0), rack, Vector3.ZERO, 8, 0.12)
	_cyl(0.025, 1.7, rack_at + Vector3(0, 0.87, 0), rack, Vector3.ZERO, 6, 0.02)
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		_cyl(0.012, 0.16, rack_at + Vector3(sin(a) * 0.06, 1.62, cos(a) * 0.06), rack, Vector3(cos(a) * 0.9, 0, -sin(a) * 0.9), 5)
	_lump(Vector3(0.3, 0.62, 0.16), rack_at + Vector3(-0.1, 1.25, -0.05), _mat(Color(0.34, 0.4, 0.3), 6, Color.BLACK, 40.0), null, 0.75, Vector3(0, 0.5, 0.05))
	_lump(Vector3(0.24, 0.09, 0.24), rack_at + Vector3(0.02, 1.76, 0.02), _mat(Color(0.5, 0.36, 0.22), 6, Color.BLACK, 40.0), null, 0.8, Vector3(0.15, 0, 0.1))
	_lump(Vector3(0.36, 0.025, 0.36), rack_at + Vector3(0.02, 1.725, 0.02), _mat(Color(0.5, 0.36, 0.22), 6, Color.BLACK, 40.0), null, 0.9, Vector3(0.15, 0, 0.1))
	_shadow(rack_at, Vector2(0.4, 0.4), 0.45)

	# A stack of moving boxes nobody ever unpacked, by the filing cabinet.
	var card := _mat(Color(0.72, 0.56, 0.38), 6, Color.BLACK, 40.0)
	var tape := _mat(Color(0.86, 0.76, 0.56))
	for spec in [[Vector3(0.46, 0.34, 0.4), Vector3(-2.55, 0.17, -2.68), 0.12], [Vector3(0.38, 0.28, 0.34), Vector3(-2.58, 0.48, -2.7), -0.2]]:
		_box(spec[0], spec[1], card, true, Vector3(0, spec[2], 0))
		_box(Vector3(spec[0].x + 0.006, 0.006, 0.06), spec[1] + Vector3(0, spec[0].y * 0.5, 0), tape, false, Vector3(0, spec[2], 0))
	_label("DESK\nSTUFF", Vector3(-2.55, 0.2, -2.475), 7, Color(0.25, 0.18, 0.12), Vector3(0, 0.12, 0.05))

	# Trash can.
	_cyl(0.13, 0.34, Vector3(-1.05, 0.17, -2.55), _mat(Color(0.3, 0.32, 0.3), 6, Color.BLACK, 40.0), Vector3.ZERO, 8, 0.17)
	var scrap := _mat(Color(0.95, 0.94, 0.88))
	for at in [Vector3(-1.07, 0.33, -2.57), Vector3(-1.0, 0.34, -2.5), Vector3(-0.82, 0.04, -2.3), Vector3(-1.2, 0.035, -2.25)]:
		_lump(Vector3(0.08, 0.07, 0.08), at, scrap, null, 1.0, Vector3(at.x * 7.0, at.z * 5.0, 0))
	_shadow(Vector3(-1.05, 0, -2.55), Vector2(0.3, 0.3), 0.5)

	# Poster above the desk: the game's own flyer.
	_box(Vector3(0.7, 0.9, 0.01), Vector3(-1.5, 1.6, -2.99), _mat(Color(0.08, 0.05, 0.1)))
	_tape(Vector3(-1.5, 1.6, -2.98), Vector2(0.7, 0.9))
	_label("KILLIN'\nIN", Vector3(-1.5, 1.88, -2.98), 22, Color(1.0, 0.35, 0.7))
	_label("COMEDY", Vector3(-1.5, 1.68, -2.98), 22, Color(0.35, 0.85, 1.0))
	_label("OPEN MIC\nTONITE\n8PM", Vector3(-1.5, 1.38, -2.98), 12, Color(1.0, 0.85, 0.3))
	# Motivational poster.
	_box(Vector3(0.6, 0.45, 0.01), Vector3(1.6, 1.65, -2.99), _mat(Color(0.05, 0.05, 0.05)))
	_tape(Vector3(1.6, 1.65, -2.98), Vector2(0.6, 0.45))
	_box(Vector3(0.5, 0.28, 0.005), Vector3(1.6, 1.7, -2.985), _mat(Color(0.35, 0.5, 0.7), 4, Color(0.3, 0.42, 0.62)))
	_label("PERSEVERANCE", Vector3(1.6, 1.5, -2.98), 9, Color(0.9, 0.9, 0.85))

	# Wall clock on the right wall, showing the real time.
	var clock := Node3D.new()
	clock.position = Vector3(3.48, 2.0, 2.3)
	clock.rotation.y = -PI / 2
	root.add_child(clock)
	_cyl(0.2, 0.035, Vector3(0, 0, -0.005), _mat(Color(0.2, 0.2, 0.22)), Vector3(PI / 2, 0, 0), 12, -1.0, clock)
	_cyl(0.175, 0.04, Vector3.ZERO, _mat(Color(0.94, 0.93, 0.87)), Vector3(PI / 2, 0, 0), 12, -1.0, clock)
	for i in 12:
		var a := TAU * i / 12.0
		_box(Vector3(0.012, 0.03 if i % 3 == 0 else 0.016, 0.004), Vector3(sin(a) * 0.145, cos(a) * 0.145, 0.022), dark, false, Vector3(0, 0, -a), clock)
	for spec in [[0.09, 0.016], [0.14, 0.01]]:
		var pivot := Node3D.new()
		pivot.position.z = 0.025
		clock.add_child(pivot)
		_box(Vector3(spec[1], spec[0], 0.005), Vector3(0, spec[0] * 0.45, 0), dark, false, Vector3.ZERO, pivot)
		_clock_hands.append(pivot)


func _build_your_desk() -> void:
	var wood := _mat(Color(0.7, 0.52, 0.34), 3, Color(0.62, 0.45, 0.28), 60.0)
	var metal := _mat(Color(0.55, 0.56, 0.56))
	var beige := _beige()
	var dark := _mat(Color(0.2, 0.2, 0.2))
	_box(Vector3(1.8, 0.05, 0.8), Vector3(0, 0.735, -2.55), wood, true)
	_box(Vector3(0.05, 0.71, 0.75), Vector3(-0.86, 0.355, -2.55), metal, true)
	_box(Vector3(0.05, 0.71, 0.75), Vector3(0.86, 0.355, -2.55), metal, true)
	_box(Vector3(1.7, 0.4, 0.03), Vector3(0, 0.5, -2.9), metal)
	_box(Vector3(0.45, 0.6, 0.7), Vector3(0.6, 0.41, -2.55), metal, true)
	_tower(root, Vector3(-0.55, 0, -2.6), beige)
	_crt(root, DESK_SCREEN, Vector2(0.72, 0.54), beige, "HUMBLE", Color(0.3, 1.0, 0.4))
	_screen("desk", root, DESK_SCREEN, Vector2(0.68, 0.5), "SHIFT EXTENDED.\n\nTHANK YOU FOR\nYOUR DEDICATION.", Color(0.55, 0.85, 1.0), 26)
	# Keyboard (where your cheek was), mouse, a sticky note.
	_box(Vector3(0.46, 0.03, 0.16), Vector3(-0.02, 0.775, -2.2), beige, false, Vector3(0, 0.04, 0))
	_box(Vector3(0.42, 0.006, 0.12), Vector3(-0.02, 0.792, -2.2), _mat(Color(0.7, 0.68, 0.6), 7, Color(0.5, 0.48, 0.42), 30.0), false, Vector3(0, 0.04, 0))
	_lump(Vector3(0.06, 0.035, 0.1), Vector3(0.33, 0.78, -2.2), beige, null)
	_box(Vector3(0.07, 0.07, 0.004), Vector3(0.3, 0.95, -2.33), _mat(Color(1.0, 0.9, 0.35)), false, Vector3(-0.2, 0, 0.08))
	_label("DAY 1!\n:)", Vector3(0.3, 0.95, -2.327), 5, Color(0.3, 0.25, 0.2), Vector3(-0.2, 0, 0.08))
	_mug(Vector3(-0.62, 0.76, -2.3), _mat(Color(0.25, 0.45, 0.7)), null, Color(0.12, 0.08, 0.05), 0.4)
	# The phone, its speaker light still on.
	phone = Node3D.new()
	phone.position = PHONE_SPOT
	phone.rotation.y = -0.35
	root.add_child(phone)
	var grey := _mat(Color(0.82, 0.8, 0.72), 6, Color.BLACK, 40.0)
	_box(Vector3(0.22, 0.06, 0.2), Vector3(0, 0.03, 0), grey, false, Vector3(-0.12, 0, 0), phone)
	_lump(Vector3(0.22, 0.05, 0.06), Vector3(0, 0.085, -0.04), grey, phone, 0.8)
	for i in 9:
		_box(Vector3(0.022, 0.006, 0.018), Vector3(-0.03 + (i % 3) * 0.03, 0.065, 0.02 + (i / 3) * 0.025), _mat(Color(0.55, 0.53, 0.48)), false, Vector3(-0.12, 0, 0), phone)
	var led := _glow(Color(1.0, 0.25, 0.2))
	_box(Vector3(0.014, 0.008, 0.008), Vector3(0.08, 0.07, 0.07), led, false, Vector3.ZERO, phone)
	_cyl(0.004, 0.3, Vector3(-0.12, 0.02, -0.18), _mat(Color(0.75, 0.73, 0.66)), Vector3(PI / 2, 0, 0.4), 4, -1.0, phone)
	# Your chair, pushed back where you got up.
	var chair := Node3D.new()
	chair.position = Vector3(0.1, 0, -1.75)
	chair.rotation.y = PI + 0.25
	root.add_child(chair)
	_chair(chair, _mat(Color(0.3, 0.45, 0.66), 1, Color(0.25, 0.38, 0.58), 50.0), true)


## Dale's corner under the window, his lamp the only warm light all night.
func _build_dale() -> void:
	var dale_node: Node3D
	dale_node = Node3D.new()
	dale_node.position = DALE_SPOT
	dale_node.rotation.y = PI / 2
	root.add_child(dale_node)
	var r := dale_node
	var wood := _mat(Color(0.7, 0.52, 0.34), 3, Color(0.62, 0.45, 0.28), 60.0)
	var metal := _mat(Color(0.55, 0.56, 0.56))
	var dark := _mat(Color(0.1, 0.1, 0.11))

	# Chair behind him.
	var fabric := _mat(Color(0.6, 0.36, 0.28), 1, Color(0.52, 0.3, 0.24), 50.0)
	_chair(r, fabric, false, 0.66)

	# Desk in front of him (top at 0.76), with a modesty panel facing the room.
	var dz := 0.62
	_box(Vector3(1.3, 0.05, 0.62), Vector3(0, 0.735, dz), wood, true, Vector3.ZERO, r)
	_box(Vector3(1.26, 0.6, 0.03), Vector3(0, 0.42, dz + 0.29), wood, true, Vector3.ZERO, r)
	_box(Vector3(0.05, 0.71, 0.58), Vector3(-0.62, 0.355, dz), metal, true, Vector3.ZERO, r)
	_box(Vector3(0.38, 0.6, 0.5), Vector3(0.42, 0.41, dz), metal, true, Vector3.ZERO, r)
	for y in [0.58, 0.36]:
		_box(Vector3(0.12, 0.02, 0.01), Vector3(0.42, y, dz - 0.25), dark, false, Vector3.ZERO, r)
	# Nameplate, facing you.
	_box(Vector3(0.34, 0.07, 0.03), Vector3(0.0, 0.795, dz + 0.24), _mat(Color(0.75, 0.6, 0.28)), false, Vector3(-0.3, 0, 0), r)
	_label("DALE P.\nACCTS RECEIVABLE", Vector3(0.0, 0.797, dz + 0.258), 7, Color(0.15, 0.1, 0.05), Vector3(-0.3, 0, 0), 0.0, r)
	# His old monitor, turned away to the side so you can see him.
	var beige := _beige()
	var old_pc := Node3D.new()
	old_pc.position = Vector3(-0.5, 0.76, dz - 0.12)
	old_pc.rotation.y = PI - 0.9
	r.add_child(old_pc)
	_box(Vector3(0.36, 0.3, 0.07), Vector3(0, 0.2, 0.12), beige, false, Vector3.ZERO, old_pc)
	_box(Vector3(0.3, 0.25, 0.14), Vector3(0, 0.2, 0.02), beige, false, Vector3.ZERO, old_pc)
	_box(Vector3(0.2, 0.17, 0.12), Vector3(0, 0.2, -0.1), beige, false, Vector3.ZERO, old_pc)
	_box(Vector3(0.28, 0.2, 0.004), Vector3(0, 0.215, 0.157), _mat(Color(0.05, 0.06, 0.05), 0, Color.BLACK, 24.0, Color(0.05, 0.16, 0.08)), false, Vector3.ZERO, old_pc)
	_box(Vector3(0.12, 0.04, 0.12), Vector3(0, 0.035, 0.02), beige, false, Vector3.ZERO, old_pc)
	_box(Vector3(0.22, 0.02, 0.2), Vector3(0, 0.01, 0.02), beige, false, Vector3.ZERO, old_pc)
	# A purple sticky note on its side. Hmm.
	_box(Vector3(0.07, 0.07, 0.004), Vector3(0.03, 0.21, -0.163), _mat(Color(0.72, 0.5, 0.95)), false, Vector3(0, PI, 0.1), old_pc)
	# His desk lamp (it lights the corner after hours: ps1.gdshader N_POS3).
	var brass := _mat(Color(0.7, 0.56, 0.26))
	var lamp := Vector3(-0.56, 0.76, dz + 0.2)
	_cyl(0.07, 0.02, lamp + Vector3(0, 0.01, 0), brass, Vector3.ZERO, 8, 0.06, r)
	_cyl(0.01, 0.3, lamp + Vector3(-0.03, 0.16, 0), brass, Vector3(0, 0, 0.2), 5, -1.0, r)
	_cyl(0.01, 0.16, lamp + Vector3(0.05, 0.33, 0.0), brass, Vector3(0, 0, -0.9), 5, -1.0, r)
	_cyl(0.085, 0.09, lamp + Vector3(0.14, 0.34, 0.0), _mat(Color(0.2, 0.42, 0.3), 6, Color.BLACK, 40.0), Vector3(0, 0, -0.5), 8, 0.04, r)
	var bulb := _mat(Color(0.3, 0.26, 0.16), 0, Color.BLACK, 24.0, Color(0.5, 0.4, 0.2))
	_night_glow.append([bulb, Color(0.5, 0.4, 0.2), Color(1.0, 0.85, 0.5)])
	_lump(Vector3(0.07, 0.05, 0.07), lamp + Vector3(0.125, 0.315, 0.0), bulb, r)
	# Mug, invoices, a purple pen.
	_mug(Vector3(0.42, 0.76, dz + 0.08), _mat(Color(0.95, 0.95, 0.92)), r, Color(0.33, 0.19, 0.1), -0.9)
	_label("#1\nDAD", Vector3(0.42, 0.815, dz + 0.127), 5, Color(0.2, 0.3, 0.7), Vector3.ZERO, 0.0, r)
	_box(Vector3(0.24, 0.05, 0.3), Vector3(0.18, 0.785, dz - 0.02), _mat(Color(0.92, 0.92, 0.86)), false, Vector3(0, 0.15, 0), r)
	_box(Vector3(0.012, 0.012, 0.14), Vector3(0.05, 0.768, dz + 0.12), _mat(Color(0.55, 0.25, 0.85)), false, Vector3(0, 0.7, 0), r)

	var body := Node3D.new()
	r.add_child(body)
	_dale_root = r
	_dale_desk_body = body
	_person("dale", body, LOOKS.dale, "desk", r, PI / 2)


## Dale stands up beside his desk (when he decides to go home).
func dale_stand() -> void:
	var p: Dictionary = people.dale
	for c in _dale_desk_body.get_children():
		c.queue_free()
	var stand := Node3D.new()
	stand.position = Vector3(0.75, 0, 0.1)
	_dale_root.add_child(stand)
	_person("dale", stand, LOOKS.dale, "stand", _dale_root, PI / 2)


## DEMO: real 3D head scans with photo textures (art/scan, see CREDITS.txt):
## the Lee Perry-Smith scan (CC BY 3.0) for Dale, and the same scan reshaped
## with an AI-generated face baked on for each coworker. PS1 warp, their own
## blinking eyes and talking mouth, glasses and moustache on top.
const SCAN_DEMO := true
const SCAN_HEADS := {"dale": "dale", "dale3": "dale", "wendy": "wendy", "kip": "kip", "marge": "marge", "chad": "chad", "brenda": "brenda"}
var _scan_cache := {}


func _scan(name: String) -> Array:
	if not _scan_cache.has(name):
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/scan/%s_head.json" % name))
		var v := PackedVector3Array(); var n := PackedVector3Array(); var uv := PackedVector2Array()
		var fv: Array = d.v; var fn: Array = d.n; var fu: Array = d.uv
		for i in range(0, fv.size(), 3):
			v.append(Vector3(fv[i], fv[i + 1], fv[i + 2]))
			n.append(Vector3(fn[i], fn[i + 1], fn[i + 2]))
		for i in range(0, fu.size(), 2):
			uv.append(Vector2(fu[i], fu[i + 1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(d.i)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var tex := ImageTexture.create_from_image(Image.load_from_file("res://art/scan/%s_face.png" % name))
		_scan_cache[name] = [mesh, tex, d.marks]
	return _scan_cache[name]


func _scan_head(id: String, parts: Dictionary, look: Dictionary) -> void:
	if not SCAN_DEMO or not SCAN_HEADS.has(id):
		return
	var sc := _scan(SCAN_HEADS[id])
	var mk: Dictionary = sc[2]
	var head: Node3D = parts.head
	for c in head.get_children():
		c.visible = false
	var m := _mat(Color.WHITE)
	m.set_shader_parameter("photo", sc[1])
	m.set_shader_parameter("use_photo", 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = sc[0]
	mi.material_override = m
	head.add_child(mi)
	var el := Vector3(mk.eyeL[0], mk.eyeL[1], mk.eyeL[2])
	var er := Vector3(mk.eyeR[0], mk.eyeR[1], mk.eyeR[2])
	var br := Vector3(mk.bridge[0], mk.bridge[1], mk.bridge[2])
	var st := Vector3(mk.stache[0], mk.stache[1], mk.stache[2])
	var mo := Vector3(mk.mouth[0], mk.mouth[1], mk.mouth[2])
	var half := (er.x - el.x) * 0.5
	var eyes: Array = parts.eyes
	for k in eyes.size():
		eyes[k].visible = true
		eyes[k].position = (el if k == 0 else er) + Vector3(0, 0, 0.003)
		eyes[k].scale = Vector3.ONE * clampf(half / 0.06, 0.7, 1.05)
	var mouth: Node3D = parts.mouth
	mouth.visible = true
	mouth.position = mo + Vector3(0, 0, 0.006)
	var dark := _mat(Color(0.06, 0.06, 0.08))
	var g := Puppet.Shape.new()
	var any := false
	if look.get("glasses", false):
		any = true
		var gz := br.z + 0.008
		var w := half * 1.1
		for side in [-1.0, 1.0]:
			var cx: float = side * half
			for bar in [[Vector3(w, 0.011, 0.011), Vector3(0, 0.026, 0)], [Vector3(w, 0.011, 0.011), Vector3(0, -0.026, 0)],
					[Vector3(0.011, 0.058, 0.011), Vector3(w * 0.5, 0, 0)], [Vector3(0.011, 0.058, 0.011), Vector3(-w * 0.5, 0, 0)]]:
				g.box(bar[0], Vector3(cx, el.y + 0.002, gz) + bar[1], dark)
			g.box(Vector3(0.011, 0.011, 0.15), Vector3(side * (half + w * 0.5 + 0.004), el.y + 0.01, gz - 0.075), dark, Vector3(0, side * 0.12, 0))
		g.box(Vector3(maxf(0.02, half * 2.0 - w), 0.011, 0.011), Vector3(0, el.y + 0.008, gz + 0.004), dark)
	if look.get("moustache", false):
		any = true
		var hair := _mat(look.hair)
		for side in [-1.0, 1.0]:
			g.lump(Vector3(0.07, 0.03, 0.03), Vector3(st.x + side * 0.032, st.y + 0.005, maxf(st.z, mo.z) + 0.014), hair, 0.9, Vector3(0, 0, -side * 0.28))
	if any:
		g.commit(self, head)


func _person(id: String, body: Node3D, look: Dictionary, pose: String, holder: Node3D, yaw: float) -> void:
	var parts: Dictionary = Puppet.build(self, body, look, Callable(self, "_mat"), pose)
	_scan_head(id, parts, look)
	people[id] = {"holder": holder, "body": body, "head": parts.head, "mouth": parts.mouth, "eyes": parts.eyes, "yaw": yaw}


## Kip at a desk by the right wall, facing into the room, his monitor turned
## so you can see the welcome video too.
func _build_kip() -> void:
	var r := Node3D.new()
	r.position = KIP_SPOT
	r.rotation.y = -PI / 2
	root.add_child(r)
	var wood := _mat(Color(0.62, 0.5, 0.36), 3, Color(0.55, 0.43, 0.3), 60.0)
	var metal := _mat(Color(0.55, 0.56, 0.56))
	_chair(r, _mat(Color(0.25, 0.5, 0.42), 1, Color(0.2, 0.42, 0.36), 50.0), false, 0.56)
	var dz := 0.62
	_box(Vector3(1.3, 0.05, 0.62), Vector3(0, 0.735, dz), wood, true, Vector3.ZERO, r)
	_box(Vector3(1.26, 0.6, 0.03), Vector3(0, 0.42, dz + 0.29), wood, true, Vector3.ZERO, r)
	_box(Vector3(0.05, 0.71, 0.58), Vector3(0.62, 0.355, dz), metal, true, Vector3.ZERO, r)
	_box(Vector3(0.05, 0.71, 0.58), Vector3(-0.62, 0.355, dz), metal, true, Vector3.ZERO, r)
	var mon := Node3D.new()
	mon.position = Vector3(0.42, 0, dz - 0.05)
	mon.rotation.y = PI - 1.05
	r.add_child(mon)
	var beige := _beige()
	_crt(mon, Vector3(0, 1.0, 0.12), Vector2(0.4, 0.3), beige, "HUMBLE", Color(0.3, 1.0, 0.4))
	_screen("kip", mon, Vector3(0, 1.0, 0.12), Vector2(0.38, 0.28), "WELCOME TO\nHUMBLE HOUSE!\n\nMODULE 4 OF 4\nQUESTION 4", Color(0.6, 1.0, 0.7), 14)
	# Cold coffee with a skin on it, a stack of onboarding binders, a stress ball.
	_mug(Vector3(-0.15, 0.76, dz + 0.12), _mat(Color(0.95, 0.95, 0.92)), r, Color(0.45, 0.35, 0.25), 0.6)
	for i in 4:
		_box(Vector3(0.24, 0.045, 0.3), Vector3(-0.45, 0.785 + i * 0.047, dz - 0.05), _mat([Color(0.2, 0.35, 0.75), Color(0.85, 0.2, 0.2), Color(0.95, 0.75, 0.2), Color(0.2, 0.6, 0.35)][i]), false, Vector3(0, i * 0.17 - 0.2, 0), r)
	_label("ONBOARDING\nVOL. 1-4", Vector3(-0.45, 0.97, dz + 0.11), 5, Color(0.95, 0.95, 0.9), Vector3(-0.3, 0, 0), 0.0, r)
	_ball(0.035, Vector3(-0.42, 0.795, dz + 0.2), _mat(Color(1.0, 0.45, 0.6)), r)
	var body := Node3D.new()
	r.add_child(body)
	_person("kip", body, LOOKS.kip, "desk", r, -PI / 2)


## PRINTY-9000: a big beige copier by the right wall with a little face on
## its control panel.
func _build_printy() -> void:
	var r := Node3D.new()
	r.position = PRINTY_SPOT
	r.rotation.y = -PI / 2
	root.add_child(r)
	var shell := _mat(Color(0.84, 0.82, 0.74), 6, Color.BLACK, 40.0)
	var grey := _mat(Color(0.5, 0.5, 0.5), 6, Color.BLACK, 40.0)
	var dark := _mat(Color(0.14, 0.14, 0.15))
	_box(Vector3(0.8, 0.62, 0.62), Vector3(0, 0.31, 0), shell, true, Vector3.ZERO, r)
	_box(Vector3(0.76, 0.03, 0.02), Vector3(0, 0.2, 0.31), dark, false, Vector3.ZERO, r)
	_box(Vector3(0.76, 0.03, 0.02), Vector3(0, 0.4, 0.31), dark, false, Vector3.ZERO, r)
	_box(Vector3(0.8, 0.26, 0.6), Vector3(0, 0.75, -0.01), shell, true, Vector3.ZERO, r)
	_box(Vector3(0.78, 0.05, 0.58), Vector3(0, 0.905, -0.02), grey, false, Vector3(-0.03, 0, 0), r)
	# Output tray sticking out the side, a page waiting.
	_box(Vector3(0.3, 0.02, 0.32), Vector3(0.53, 0.66, 0.02), grey, false, Vector3(0, 0, -0.12), r)
	_box(Vector3(0.21, 0.004, 0.28), Vector3(0.53, 0.675, 0.02), _mat(Color(0.95, 0.94, 0.88)), false, Vector3(0, 0.05, -0.12), r)
	paper_at = r.to_global(Vector3(0.53, 0.7, 0.02)) if r.is_inside_tree() else PRINTY_SPOT + Vector3(-0.02, 0.7, -0.53)
	# Control panel with its little face, angled up at you.
	var panel := Node3D.new()
	panel.position = Vector3(0.18, 0.86, 0.3)
	panel.rotation.x = -0.6
	r.add_child(panel)
	_box(Vector3(0.36, 0.16, 0.05), Vector3(0, 0, -0.02), grey, false, Vector3.ZERO, panel)
	_screen("printy", panel, Vector3(-0.03, 0.0, 0.006), Vector2(0.2, 0.11), "o_o", Color(0.65, 1.0, 0.4), 28)
	_box(Vector3(0.04, 0.04, 0.02), Vector3(0.13, 0.03, 0.005), _mat(Color(0.2, 0.75, 0.3)), false, Vector3.ZERO, panel)
	_box(Vector3(0.04, 0.04, 0.02), Vector3(0.13, -0.03, 0.005), _mat(Color(0.85, 0.2, 0.2)), false, Vector3.ZERO, panel)
	_label("PRINTY-9000", Vector3(-0.2, 0.55, 0.315), 9, Color(0.3, 0.3, 0.32), Vector3.ZERO, 0.0, r)
	# The recycling bin: four hundred thousand last lines.
	var bin := _mat(Color(0.2, 0.42, 0.75), 6, Color.BLACK, 40.0)
	_box(Vector3(0.36, 0.5, 0.32), Vector3(-0.7, 0.25, 0.05), bin, true, Vector3.ZERO, r)
	_label("RECYCLE", Vector3(-0.7, 0.36, 0.215), 6, Color(0.92, 0.95, 1.0), Vector3.ZERO, 0.0, r)
	for i in 7:
		_lump(Vector3(0.09, 0.08, 0.09), Vector3(-0.78 + (i % 3) * 0.08, 0.53 + (i / 3) * 0.05, 0.0 + (i % 2) * 0.08), _mat(Color(0.95, 0.94, 0.88)), r, 1.0, Vector3(i, i * 2.0, 0))
	for at in [Vector3(-0.4, 0.04, 0.45), Vector3(-0.95, 0.035, 0.38), Vector3(0.2, 0.035, 0.55)]:
		_lump(Vector3(0.08, 0.07, 0.08), at, _mat(Color(0.95, 0.94, 0.88)), r, 1.0, Vector3(at.x * 7.0, at.z * 5.0, 0))


## Drop a fresh printed page on the floor by the copier.
func print_page() -> void:
	var page := _box(Vector3(0.21, 0.004, 0.28), paper_at + Vector3(randf_range(-0.6, -0.2), -0.68, randf_range(-0.4, 0.4)), _mat(Color(0.96, 0.95, 0.9)), false, Vector3(0, randf() * TAU, 0))
	_pages.append(page)


## Wendy in her perfect wet square, her cart and lantern beside her.
func _build_wendy() -> void:
	var r := Node3D.new()
	r.position = WENDY_SPOT
	r.rotation.y = PI - 0.25
	root.add_child(r)
	var wet := _mat(Color(0.36, 0.44, 0.44), 1, Color(0.3, 0.38, 0.4), 40.0, Color(0.02, 0.03, 0.04))
	_box(Vector3(1.3, 0.003, 1.3), Vector3(0, 0.003, 0.1), wet, false, Vector3.ZERO, r)
	var body := Node3D.new()
	r.add_child(body)
	_person("wendy", body, LOOKS.wendy, "stand", r, PI - 0.25)
	# Her mop, held at her right side.
	var wood := _mat(Color(0.6, 0.45, 0.28))
	_cyl(0.014, 1.35, Vector3(-0.26, 0.72, 0.16), wood, Vector3(0.12, 0, -0.06), 5, -1.0, r)
	_lump(Vector3(0.24, 0.1, 0.18), Vector3(-0.3, 0.05, 0.25), _mat(Color(0.82, 0.8, 0.7), 6, Color.BLACK, 40.0), r, 0.8)
	# The cart: grey frame, bins, a yellow bucket, a lantern on top.
	var cart := Node3D.new()
	cart.position = Vector3(-0.85, 0, -0.35)
	cart.rotation.y = 0.4
	r.add_child(cart)
	var grey := _mat(Color(0.32, 0.34, 0.36), 6, Color.BLACK, 40.0)
	_box(Vector3(0.5, 0.06, 0.8), Vector3(0, 0.18, 0), grey, true, Vector3.ZERO, cart)
	_box(Vector3(0.5, 0.06, 0.8), Vector3(0, 0.82, 0), grey, false, Vector3.ZERO, cart)
	for sx in [-0.23, 0.23]:
		for sz in [-0.37, 0.37]:
			_cyl(0.015, 0.7, Vector3(sx, 0.5, sz), grey, Vector3.ZERO, 5, -1.0, cart)
			_lump(Vector3(0.06, 0.06, 0.06), Vector3(sx, 0.04, sz), _mat(Color(0.1, 0.1, 0.1)), cart)
	_cyl(0.16, 0.28, Vector3(0, 0.35, 0.18), _mat(Color(0.95, 0.8, 0.1), 6, Color.BLACK, 40.0), Vector3.ZERO, 8, 0.18, cart)
	_box(Vector3(0.36, 0.3, 0.3), Vector3(0, 0.38, -0.22), _mat(Color(0.25, 0.45, 0.7), 6, Color.BLACK, 40.0), false, Vector3.ZERO, cart)
	for i in 3:
		_cyl(0.035, 0.18, Vector3(-0.12 + i * 0.12, 0.94, -0.2), _mat([Color(0.3, 0.75, 0.9), Color(0.9, 0.4, 0.6), Color(0.95, 0.95, 0.9)][i]), Vector3.ZERO, 6, 0.025, cart)
	var lamp := _glow(Color(1.0, 0.72, 0.35))
	_lump(Vector3(0.1, 0.14, 0.1), Vector3(0.12, 0.93, 0.2), lamp, cart)
	_box(Vector3(0.12, 0.02, 0.12), Vector3(0.12, 1.01, 0.2), grey, false, Vector3.ZERO, cart)
	_box(Vector3(0.24, 0.16, 0.004), Vector3(0, 0.62, 0.401), _mat(Color(0.95, 0.85, 0.2)), false, Vector3.ZERO, cart)
	_label("CAUTION\nWET", Vector3(0, 0.62, 0.404), 7, Color(0.1, 0.1, 0.1), Vector3.ZERO, 0.0, cart)


## Employee of the Month: twelve frames on the left wall over an empty desk,
## all the same man getting greyer, and an empty one with your name on it.
func _build_board() -> void:
	var r := Node3D.new()
	r.position = Vector3(-3.47, 0, 2.0)
	r.rotation.y = PI / 2
	root.add_child(r)
	var cork := _mat(Color(0.62, 0.45, 0.3), 6, Color.BLACK, 60.0)
	_box(Vector3(1.4, 0.95, 0.02), Vector3(0, 1.72, 0.01), cork, false, Vector3.ZERO, r)
	_label("EMPLOYEE OF THE MONTH", Vector3(0, 2.13, 0.024), 9, Color(0.98, 0.9, 0.6), Vector3.ZERO, 0.0, r)
	var frame := _mat(Color(0.12, 0.1, 0.08))
	var bg := _mat(Color(0.45, 0.55, 0.7))
	for i in 12:
		var cx := -0.53 + (i % 4) * 0.355
		var cy := 1.95 - (i / 4) * 0.27
		_box(Vector3(0.22, 0.2, 0.015), Vector3(cx, cy, 0.025), frame, false, Vector3.ZERO, r)
		if i == 11:
			_last_frame = _box(Vector3(0.18, 0.16, 0.004), Vector3(cx, cy, 0.034), _mat(Color(0.08, 0.07, 0.06)), false, Vector3.ZERO, r)
			_box(Vector3(0.12, 0.025, 0.004), Vector3(cx, cy - 0.115, 0.03), _mat(Color(0.78, 0.64, 0.3)), false, Vector3.ZERO, r)
			_label("YOU", Vector3(cx, cy - 0.115, 0.033), 5, Color(0.2, 0.12, 0.05), Vector3.ZERO, 0.0, r)
			continue
		var k := i / 11.0
		_box(Vector3(0.18, 0.16, 0.004), Vector3(cx, cy, 0.034), bg, false, Vector3.ZERO, r)
		var skin := Color(0.92, 0.72, 0.58).lerp(Color(0.72, 0.68, 0.66), k)
		_lump(Vector3(0.07, 0.085, 0.01), Vector3(cx, cy + 0.01, 0.04), _mat(skin), r, 0.6)
		_lump(Vector3(0.12, 0.04, 0.01), Vector3(cx, cy - 0.06, 0.04), _mat(Color(0.3, 0.3, 0.4)), r, 0.6)
		_lump(Vector3(0.075, 0.025, 0.01), Vector3(cx, cy + 0.05, 0.042), _mat(Color(0.3, 0.2, 0.12).lerp(Color(0.8, 0.8, 0.8), k)), r, 0.6)
	_tape(Vector3(0, 1.72, 0.02), Vector2(1.4, 0.95), r)
	# The empty desk under it, its screen still on.
	var wood := _mat(Color(0.62, 0.5, 0.36), 3, Color(0.55, 0.43, 0.3), 60.0)
	_box(Vector3(1.2, 0.05, 0.6), Vector3(0, 0.735, 0.4), wood, true, Vector3.ZERO, r)
	_box(Vector3(1.16, 0.6, 0.03), Vector3(0, 0.42, 0.12), wood, true, Vector3.ZERO, r)
	_crt(r, Vector3(0.25, 1.0, 0.42), Vector2(0.36, 0.27), _beige(), "HUMBLE", Color(0.3, 1.0, 0.4))
	_screen("board", r, Vector3(0.25, 1.0, 0.42), Vector2(0.34, 0.25), "NOMINATE\nYOURSELF\nTONIGHT!", Color(1.0, 0.85, 0.45), 13)


## The empty frame gets a photo: you, asleep on your keyboard.
func board_photo() -> void:
	if _last_frame:
		_last_frame.material_override = _mat(Color(0.3, 0.42, 0.62), 0, Color.BLACK, 24.0, Color(0.15, 0.2, 0.32))


## The complimentary coffee, on a cabinet by the front wall. Its red power
## light watches you.
func _build_coffee() -> void:
	var r := Node3D.new()
	r.position = COFFEE_SPOT
	r.rotation.y = PI
	root.add_child(r)
	var wood := _mat(Color(0.5, 0.36, 0.24), 3, Color(0.44, 0.3, 0.2), 60.0)
	_box(Vector3(0.9, 0.86, 0.46), Vector3(0, 0.43, 0), wood, true, Vector3.ZERO, r)
	_box(Vector3(0.94, 0.04, 0.5), Vector3(0, 0.88, 0), _mat(Color(0.86, 0.84, 0.78)), false, Vector3.ZERO, r)
	var black := _mat(Color(0.12, 0.12, 0.13), 6, Color.BLACK, 40.0)
	_box(Vector3(0.24, 0.36, 0.24), Vector3(0, 1.08, -0.06), black, false, Vector3.ZERO, r)
	_box(Vector3(0.24, 0.06, 0.32), Vector3(0, 1.29, -0.02), black, false, Vector3.ZERO, r)
	_box(Vector3(0.22, 0.02, 0.18), Vector3(0, 0.91, 0.06), black, false, Vector3.ZERO, r)
	_cyl(0.075, 0.15, Vector3(0, 0.99, 0.07), _mat(Color(0.1, 0.06, 0.04), 0, Color.BLACK, 24.0, Color(0.03, 0.01, 0.0)), Vector3.ZERO, 8, 0.06, r)
	_box(Vector3(0.025, 0.07, 0.025), Vector3(0.09, 1.02, 0.15), black, false, Vector3.ZERO, r)
	coffee_dot = _glow(Color(1.0, 0.15, 0.1))
	_box(Vector3(0.025, 0.025, 0.01), Vector3(0.07, 1.18, 0.065), coffee_dot, false, Vector3.ZERO, r)
	for i in 3:
		_mug(Vector3(-0.3 + i * 0.09, 0.9, 0.1 + (i % 2) * 0.06), _mat([Color(0.9, 0.9, 0.86), Color(0.7, 0.3, 0.25), Color(0.3, 0.5, 0.4)][i]), r, Color(0.2, 0.12, 0.07), i * 1.1)
	_box(Vector3(0.3, 0.22, 0.004), Vector3(0.0, 1.52, 0.235 - 0.46), _mat(Color(0.97, 0.96, 0.9)), false, Vector3.ZERO, r)
	_label("COMPLIMENTARY\nCOFFEE\n(BE NICE)", Vector3(0.0, 1.52, 0.237 - 0.46), 6, Color(0.3, 0.2, 0.15), Vector3.ZERO, 0.0, r)


## The way out: the punch clock on the front wall, the elevator in its gap,
## and a red EXIT sign over it all.
func _build_exit() -> void:
	var steel := _mat(Color(0.6, 0.62, 0.64), 6, Color.BLACK, 40.0)
	var dark := _mat(Color(0.08, 0.08, 0.09))
	var face := Vector3(0, PI, 0)
	# Elevator: the car behind, lit, and two doors in the gap (x 0.85..2.75).
	_exact = true
	_box(Vector3(1.9, 2.5, 0.1), Vector3(1.8, 1.25, 5.3), _glow(Color(0.85, 0.75, 0.55)), false)
	_box(Vector3(0.1, 2.5, 1.2), Vector3(0.85, 1.25, 4.7), _glow(Color(0.7, 0.62, 0.45)), false)
	_box(Vector3(0.1, 2.5, 1.2), Vector3(2.75, 1.25, 4.7), _glow(Color(0.7, 0.62, 0.45)), false)
	_box(Vector3(1.9, 0.05, 1.2), Vector3(1.8, 0.0, 4.7), _glow(Color(0.4, 0.33, 0.25)), false)
	for side in [-1.0, 1.0]:
		var d := _box(Vector3(0.95, 2.48, 0.06), Vector3(1.8 + side * 0.475, 1.24, 4.04), steel, true)
		doors.append(d)
	_exact = false
	_box(Vector3(0.06, 2.5, 0.08), Vector3(0.82, 1.25, 4.0), steel)
	_box(Vector3(0.06, 2.5, 0.08), Vector3(2.78, 1.25, 4.0), steel)
	_box(Vector3(2.0, 0.08, 0.08), Vector3(1.8, 2.5, 4.0), steel)
	_box(Vector3(0.22, 0.1, 0.02), Vector3(1.8, 2.36, 3.98), dark, false, face)
	floor_label = _label("1", Vector3(1.8, 2.36, 3.968), 18, Color(1.0, 0.35, 0.25), face)
	_box(Vector3(0.08, 0.14, 0.02), Vector3(3.0, 1.15, 3.985), steel, false, face)
	var call := _glow(Color(0.3, 1.0, 0.45))
	_box(Vector3(0.035, 0.035, 0.012), Vector3(3.0, 1.15, 3.97), call, false, face)
	set_slot(3, Vector3(3.0, 1.15, 3.7), Color(0.05, 0.25, 0.08))
	# EXIT sign.
	_box(Vector3(0.4, 0.16, 0.06), Vector3(1.8, 2.4, 3.97) + Vector3(0, 0.0, 0.0) - Vector3(0, -0.12, 0.0), _glow(Color(0.9, 0.08, 0.06)), false, face)
	_label("EXIT", Vector3(1.8, 2.52, 3.938), 22, Color(1.0, 0.85, 0.8), face)
	# Punch clock: a grey box with a slot, a keypad, a rack of cards.
	var clock := Node3D.new()
	clock.position = PUNCH_SPOT
	clock.rotation.y = PI
	root.add_child(clock)
	var grey := _mat(Color(0.55, 0.56, 0.54), 6, Color.BLACK, 40.0)
	_box(Vector3(0.3, 0.4, 0.14), Vector3(0, 0, 0.07), grey, false, Vector3.ZERO, clock)
	_box(Vector3(0.2, 0.012, 0.01), Vector3(0, 0.12, 0.145), dark, false, Vector3.ZERO, clock)
	_cyl(0.07, 0.01, Vector3(0, 0.0, 0.142), _mat(Color(0.94, 0.93, 0.87)), Vector3(PI / 2, 0, 0), 12, -1.0, clock)
	punch_label = _label("--:--", Vector3(0, -0.13, 0.146), 12, Color(0.3, 1.0, 0.4), Vector3.ZERO, 0.0, clock)
	_box(Vector3(0.11, 0.08, 0.012), Vector3(0, -0.13, 0.142), _glow(Color(0.02, 0.06, 0.03)), false, Vector3.ZERO, clock)
	for i in 6:
		_box(Vector3(0.02, 0.016, 0.01), Vector3(-0.1 + (i % 3) * 0.02, -0.21 - (i / 3) * 0.022, 0.145), dark, false, Vector3.ZERO, clock)
	_box(Vector3(0.2, 0.36, 0.05), Vector3(-0.32, -0.02, 0.025), grey, false, Vector3.ZERO, clock)
	for i in 5:
		_box(Vector3(0.08, 0.1, 0.004), Vector3(-0.32 + (i % 2) * 0.06 - 0.03, 0.08 - i * 0.05, 0.053), _mat(Color(0.93, 0.9, 0.78)), false, Vector3(0, 0, (i % 3 - 1) * 0.06), clock)


## "Golden Hour" (Look Busy's print by Pong): the sunset over the bay, framed
## on the front wall. The title sequence opens close on it as the sun goes.
func _build_picture() -> void:
	var at := PICTURE
	var wood := _mat(Color(0.36, 0.22, 0.13), 3, Color(0.3, 0.18, 0.1), 60.0)
	var matte := _mat(Color(0.93, 0.9, 0.82))
	var face := Vector3(0, PI, 0)
	_box(Vector3(0.94, 0.68, 0.012), at + Vector3(0, 0, 0.012), matte, false, face)
	var q := _sunset_quad(Vector2(0.8, 0.54), at + Vector3(0, 0, -0.002), face, {"grid": 240.0, "level": 0.92, "horizon": 0.34, "sun_x": 0.42})
	picture_mat = q.material_override
	for bar in [[Vector3(1.04, 0.06, 0.05), Vector3(0, 0.37, 0)], [Vector3(1.04, 0.06, 0.05), Vector3(0, -0.37, 0)],
			[Vector3(0.06, 0.8, 0.05), Vector3(0.49, 0, 0)], [Vector3(0.06, 0.8, 0.05), Vector3(-0.49, 0, 0)]]:
		_box(bar[0], at + bar[1], wood, false, face)
	_box(Vector3(0.22, 0.05, 0.012), at + Vector3(0, -0.44, 0.005), _mat(Color(0.78, 0.64, 0.3)), false, face)
	_label("GOLDEN HOUR", at + Vector3(0, -0.44, -0.004), 6, Color(0.22, 0.14, 0.06), face)


## Open the elevator (dawn).
func open_doors(t: float) -> void:
	for i in doors.size():
		var side := -1.0 if i == 0 else 1.0
		doors[i].position.x = 1.8 + side * (0.475 + 0.9 * t)


## The wall clock's hands follow the story's clock (minutes after midnight).
func set_time(minutes: float) -> void:
	var h := fmod(minutes / 60.0, 12.0)
	if _clock_hands.size() >= 2:
		_clock_hands[0].rotation.z = -h / 12.0 * TAU
		_clock_hands[1].rotation.z = -fmod(minutes, 60.0) / 60.0 * TAU
	if punch_label:
		var m := int(minutes) % 1440
		punch_label.text = "%02d:%02d" % [m / 60, m % 60]


# ================================================================ other floors
# Floors two and three and the field are built far off along x, each in its
# own lighting (ps1.gdshader room_* uniforms: six lights, ambient, haze).

func _begin_room(id: String, floor: int, ambient: Color, fog: Color, reach := 4.5) -> void:
	_room = id
	_r = Node3D.new()
	_r.position = ORIGIN[floor]
	root.add_child(_r)
	floor_nodes[floor] = _r
	var pos := PackedVector3Array()
	var col := PackedVector3Array()
	for i in 6:
		pos.append(Vector3(0, -50, 0))
		col.append(Vector3.ZERO)
	_rooms[id] = {"mats": [], "pos": pos, "col": col, "range": reach, "ambient": ambient, "fog": fog, "origin": ORIGIN[floor]}


func _end_room() -> void:
	_room = ""


func _apply_room(m: ShaderMaterial, r: Dictionary) -> void:
	m.set_shader_parameter("room_range", r.range)
	m.set_shader_parameter("room_pos", r.pos)
	m.set_shader_parameter("room_col", r.col)
	m.set_shader_parameter("room_ambient", Vector3(r.ambient.r, r.ambient.g, r.ambient.b))
	m.set_shader_parameter("room_fog", Vector3(r.fog.r, r.fog.g, r.fog.b))


## Set one of a room's six lights (pos in the room's own space).
func room_light(id: String, i: int, pos: Vector3, col: Color) -> void:
	var r: Dictionary = _rooms[id]
	r.pos[i] = pos + r.origin
	r.col[i] = Vector3(col.r, col.g, col.b)
	for m in r.mats:
		_apply_room(m, r)


func room_ambient(id: String, ambient: Color, fog := Color(-1, -1, -1)) -> void:
	var r: Dictionary = _rooms[id]
	r.ambient = ambient
	if fog.r >= 0.0:
		r.fog = fog
	for m in r.mats:
		_apply_room(m, r)


## A plain box room `w` x `d`, `h` tall, centred on the room's origin, with a
## gap in the front wall (+z) and the back wall (-z) for the elevators.
func _shell(w: float, d: float, h: float, wall: Material, carpet: Material, ceil: Material, front_gap := 1.9, back_gap := 0.0) -> void:
	_exact = true
	_box(Vector3(w + 0.4, 0.1, d + 0.4), Vector3(0, -0.05, 0), carpet, true, Vector3.ZERO, _r)
	_box(Vector3(w + 0.4, 0.1, d + 0.4), Vector3(0, h + 0.05, 0), ceil, true, Vector3.ZERO, _r)
	_box(Vector3(0.1, h, d), Vector3(-w * 0.5 - 0.05, h * 0.5, 0), wall, true, Vector3.ZERO, _r)
	_box(Vector3(0.1, h, d), Vector3(w * 0.5 + 0.05, h * 0.5, 0), wall, true, Vector3.ZERO, _r)
	for side in [[1.0, front_gap], [-1.0, back_gap]]:
		var z: float = side[0] * (d * 0.5 + 0.05)
		var gap: float = side[1]
		if gap <= 0.0:
			_box(Vector3(w, h, 0.1), Vector3(0, h * 0.5, z), wall, true, Vector3.ZERO, _r)
		else:
			var piece := (w - gap) * 0.5
			_box(Vector3(piece, h, 0.1), Vector3(-(gap + piece) * 0.5, h * 0.5, z), wall, true, Vector3.ZERO, _r)
			_box(Vector3(piece, h, 0.1), Vector3((gap + piece) * 0.5, h * 0.5, z), wall, true, Vector3.ZERO, _r)
			_box(Vector3(gap, h - 2.5, 0.1), Vector3(0, 2.5 + (h - 2.5) * 0.5, z), wall, true, Vector3.ZERO, _r)
	_exact = false


## Elevator doors in a wall gap at z (facing -z if `z` > 0), shut and solid.
func _lift_doors(z: float, steel: Material, label: String, glow: Color) -> void:
	var face := Vector3(0, PI if z > 0 else 0.0, 0)
	_exact = true
	for side in [-1.0, 1.0]:
		_box(Vector3(0.95, 2.48, 0.06), Vector3(side * 0.475, 1.24, z), steel, true, Vector3.ZERO, _r)
	_exact = false
	var dz := -0.06 if z > 0 else 0.06
	_box(Vector3(2.0, 0.08, 0.08), Vector3(0, 2.5, z + dz), steel, false, Vector3.ZERO, _r)
	_box(Vector3(0.36, 0.12, 0.03), Vector3(0, 2.36, z + dz), _glow(Color(0.02, 0.02, 0.02)), false, face, _r)
	_label(label, Vector3(0, 2.36, z + dz * 1.4), 14, glow, face, 0.0, _r)
	_box(Vector3(0.08, 0.14, 0.02), Vector3(1.25, 1.15, z + dz), steel, false, face, _r)
	_box(Vector3(0.035, 0.035, 0.012), Vector3(1.25, 1.15, z + dz * 1.5), _glow(glow), false, face, _r)


## A seated person behind a desk, like Dale and Kip.
func _seated(id: String, at: Vector3, yaw: float, look: Dictionary, desk_mat: Material, chair_mat: Material) -> Node3D:
	var r := Node3D.new()
	r.position = at
	r.rotation.y = yaw
	_r.add_child(r)
	_chair(r, chair_mat, false, 0.56)
	_box(Vector3(1.2, 0.05, 0.6), Vector3(0, 0.735, 0.62), desk_mat, true, Vector3.ZERO, r)
	_box(Vector3(1.16, 0.6, 0.03), Vector3(0, 0.42, 0.9), desk_mat, true, Vector3.ZERO, r)
	var body := Node3D.new()
	r.add_child(body)
	_person(id, body, look, "desk", r, yaw)
	return r


# ---------------------------------------------------------------- floor two

const LOOKS2 := {
	"marge": {"skin": Color(0.9, 0.72, 0.6), "shirt": Color(0.62, 0.18, 0.24), "pants": Color(0.2, 0.18, 0.22), "hair": Color(0.55, 0.32, 0.16), "hair_style": "bob", "glasses": true, "lanyard": true, "brows": 0.3},
	"chad": {"skin": Color(0.92, 0.74, 0.6), "shirt": Color(0.3, 0.42, 0.6), "pants": Color(0.75, 0.68, 0.5), "hair": Color(0.7, 0.55, 0.3), "hair_style": "slick", "sleeves": "short"},
	"brenda": {"skin": Color(0.85, 0.62, 0.5), "shirt": Color(0.95, 0.65, 0.75), "pants": Color(0.3, 0.3, 0.4), "hair": Color(0.92, 0.82, 0.5), "hair_style": "bob", "glasses": true, "lanyard": true, "brows": -0.3},
}


func _build_floor2() -> void:
	_begin_room("f2", 2, Color(0.2, 0.21, 0.26), Color(0.05, 0.06, 0.09), 5.0)
	var wall := _mat(Color(0.62, 0.66, 0.7), 6, Color.BLACK, 20.0)
	var carpet := _mat(Color(0.32, 0.38, 0.46), 1, Color(0.28, 0.33, 0.4), 30.0)
	var ceil := _mat(Color(0.85, 0.86, 0.86), 2, Color(0.6, 0.62, 0.62), 30.0)
	_shell(12.0, 10.0, 2.7, wall, carpet, ceil, 1.9, 1.9)
	var steel := _mat(Color(0.6, 0.62, 0.64), 6, Color.BLACK, 40.0)
	_lift_doors(5.0, steel, "2", Color(1.0, 0.4, 0.3))
	var gold := _mat(Color(0.78, 0.62, 0.28), 6, Color.BLACK, 40.0)
	_lift_doors(-5.0, gold, "EXEC", Color(1.0, 0.8, 0.3))
	_label("EXECUTIVE ELEVATOR", Vector3(0, 2.62, -4.9), 12, Color(1.0, 0.85, 0.5), Vector3.ZERO, 0.0, _r)
	# Ceiling tubes, cold and humming (they go out at 3:33).
	for spec in [Vector3(-3, 2.66, -1.5), Vector3(3, 2.66, -1.5), Vector3(0, 2.66, 2.0), Vector3(-3, 2.66, 2.5), Vector3(3, 2.66, 2.5), Vector3(0, 2.66, -3.6)]:
		var m := _glow(Color(0.75, 0.82, 0.85))
		_box(Vector3(1.2, 0.04, 0.3), spec, m, false, Vector3.ZERO, _r)
		tubes.append(m)
	room_light("f2", 0, Vector3(-3, 2.4, -1.5), Color(0.62, 0.7, 0.75))
	room_light("f2", 1, Vector3(3, 2.4, -1.5), Color(0.62, 0.7, 0.75))
	room_light("f2", 2, Vector3(0, 2.4, 2.2), Color(0.62, 0.7, 0.75))
	room_light("f2", 3, Vector3(5.1, 1.5, -3.8), Color(0.65, 0.45, 0.32))
	room_light("f2", 4, Vector3(-4.5, 1.3, -3.5), Color(0.15, 0.3, 0.6))
	room_light("f2", 5, Vector3(0, 2.2, -4.5), Color(0.4, 0.3, 0.1))
	# Marge's path: a grey ring worn into the carpet.
	var worn := _mat(Color(0.25, 0.28, 0.33), 1, Color(0.22, 0.25, 0.3), 30.0)
	for i in 4:
		var a: Vector3 = ROUTE[i]
		var b: Vector3 = ROUTE[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var len := a.distance_to(b) + 0.5
		var along_x := absf(b.x - a.x) > 0.1
		_box(Vector3(len if along_x else 0.5, 0.004, 0.5 if along_x else len), mid + Vector3(0, 0.003, 0), worn, false, Vector3.ZERO, _r)
	# Six cubicles: fabric walls, a desk, a CRT with a dead spreadsheet, a phone.
	var fabric := _mat(Color(0.5, 0.52, 0.56), 1, Color(0.45, 0.47, 0.5), 40.0)
	var desk := _mat(Color(0.7, 0.66, 0.58), 6, Color.BLACK, 40.0)
	var beige := _beige()
	for cx in [-2.4, 2.4]:
		for cz in [-1.0, 1.0]:
			var open := 1.0 if cz < 0.0 else -1.0
			var c := Vector3(cx, 0, cz)
			_box(Vector3(1.7, 1.25, 0.06), c + Vector3(0, 0.625, -open * 0.75), fabric, true, Vector3.ZERO, _r)
			_box(Vector3(0.06, 1.25, 1.5), c + Vector3(-0.85, 0.625, 0), fabric, true, Vector3.ZERO, _r)
			_box(Vector3(0.06, 1.25, 1.5), c + Vector3(0.85, 0.625, 0), fabric, true, Vector3.ZERO, _r)
			_box(Vector3(1.5, 0.04, 0.55), c + Vector3(0, 0.74, -open * 0.43), desk, false, Vector3.ZERO, _r)
			var mon := Node3D.new()
			mon.position = c + Vector3(0, 0, -open * 0.5)
			mon.rotation.y = 0.0 if open > 0 else PI
			_r.add_child(mon)
			_box(Vector3(0.36, 0.3, 0.3), Vector3(0, 0.92, -0.05), beige, false, Vector3.ZERO, mon)
			var sm := _glow(Color(0.1, 0.22, 0.12))
			_box(Vector3(0.28, 0.21, 0.004), Vector3(0, 0.93, 0.103), sm, false, Vector3.ZERO, mon)
			desk_screens.append(sm)
			_box(Vector3(0.18, 0.05, 0.14), Vector3(0.45, 0.785, 0.05), _mat(Color(0.3, 0.3, 0.32)), false, Vector3(0, 0.3, 0), mon)
			_chair_at(c + Vector3(0.1, 0, open * 0.1), 0.0 if open > 0 else PI, _mat(Color(0.3, 0.32, 0.4), 1, Color(0.25, 0.27, 0.34), 50.0))
	# Theo's cubicle: a nameplate, a sticky note, a screen saver of the top floor.
	_label("THEO\nASSOC. VP OF SYNERGY", Vector3(2.4, 1.32, -1.73), 7, Color(0.95, 0.9, 0.7), Vector3.ZERO, 0.0, _r)
	_box(Vector3(0.07, 0.07, 0.004), Vector3(2.52, 1.0, -1.38), _mat(Color(1.0, 0.95, 0.5)), false, Vector3.ZERO, _r)
	# A runner of carpet down the middle aisle to the gold doors.
	_box(Vector3(1.4, 0.004, 9.0), Vector3(0, 0.007, 0), _mat(Color(0.42, 0.2, 0.22), 1, Color(0.36, 0.16, 0.18), 30.0), false, Vector3.ZERO, _r)
	# Marge, walking.
	var mh := Node3D.new()
	mh.position = ROUTE[0]
	_r.add_child(mh)
	var mb := Node3D.new()
	mh.add_child(mb)
	_person("marge", mb, LOOKS2.marge, "stand", mh, 0.0)
	# Brenda's glass HR office in the back-right corner.
	var post := _mat(Color(0.75, 0.76, 0.78), 6, Color.BLACK, 40.0)
	for z in [-2.8, -5.0]:
		_box(Vector3(0.06, 2.4, 0.06), Vector3(4.2, 1.2, z), post, true, Vector3.ZERO, _r)
	_box(Vector3(0.06, 2.4, 0.06), Vector3(6.0, 1.2, -2.8), post, true, Vector3.ZERO, _r)
	_box(Vector3(1.8, 0.06, 0.06), Vector3(5.1, 2.4, -2.8), post, false, Vector3.ZERO, _r)
	_box(Vector3(0.06, 0.06, 2.2), Vector3(4.2, 2.4, -3.9), post, false, Vector3.ZERO, _r)
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.7, 0.85, 0.95, 0.1)
	_box(Vector3(0.02, 2.3, 2.1), Vector3(4.2, 1.2, -3.9), glass, false, Vector3.ZERO, _r)
	_box(Vector3(0.9, 2.3, 0.02), Vector3(5.5, 1.2, -2.8), glass, false, Vector3.ZERO, _r)
	_label("HUMAN\nRESOURCES", Vector3(5.5, 1.75, -2.78), 12, Color(0.95, 0.75, 0.85), Vector3.ZERO, 0.0, _r)
	var pink := _mat(Color(0.95, 0.65, 0.75), 1, Color(0.9, 0.6, 0.7), 50.0)
	_seated("brenda", Vector3(5.1, 0, -4.35), 0.0, LOOKS2.brenda, _mat(Color(0.9, 0.88, 0.85), 6, Color.BLACK, 40.0), pink)
	var lamp := _glow(Color(1.0, 0.82, 0.5))
	_lump(Vector3(0.14, 0.1, 0.14), Vector3(5.55, 1.06, -3.75), lamp, _r)
	_cyl(0.012, 0.28, Vector3(5.55, 0.9, -3.75), post, Vector3.ZERO, 5, -1.0, _r)
	for i in 5:
		_box(Vector3(0.22, 0.04, 0.3), Vector3(4.6, 0.79 + i * 0.042, -3.75), _mat(Color(0.96, 0.95, 0.9)), false, Vector3(0, i * 0.2, 0), _r)
	_box(Vector3(0.5, 0.65, 0.01), Vector3(5.1, 1.75, -4.98), _mat(Color(0.55, 0.75, 0.95)), false, Vector3.ZERO, _r)
	_lump(Vector3(0.18, 0.16, 0.02), Vector3(5.1, 1.8, -4.97), _mat(Color(0.95, 0.75, 0.45)), _r, 0.7)
	_label("HANG IN THERE", Vector3(5.1, 1.5, -4.965), 8, Color(0.15, 0.15, 0.3), Vector3.ZERO, 0.0, _r)
	# Chad's TV cart in the back-left corner: the call is a little diorama
	# behind the glass (his boat, the sea, the sky), frozen.
	var cart := Node3D.new()
	cart.position = Vector3(-5.0, 0, -4.0)
	cart.rotation.y = PI * 0.25
	_r.add_child(cart)
	var dark := _mat(Color(0.2, 0.2, 0.22), 6, Color.BLACK, 40.0)
	_box(Vector3(0.8, 0.05, 0.55), Vector3(0, 0.75, 0), dark, true, Vector3.ZERO, cart)
	_box(Vector3(0.8, 0.05, 0.55), Vector3(0, 0.15, 0), dark, false, Vector3.ZERO, cart)
	for sx in [-0.36, 0.36]:
		for sz in [-0.24, 0.24]:
			_cyl(0.015, 0.75, Vector3(sx, 0.4, sz), dark, Vector3.ZERO, 5, -1.0, cart)
	var tv := _mat(Color(0.18, 0.18, 0.2), 6, Color.BLACK, 40.0)
	_box(Vector3(0.9, 0.08, 0.5), Vector3(0, 0.82, -0.02), tv, false, Vector3.ZERO, cart)
	_box(Vector3(0.9, 0.08, 0.5), Vector3(0, 1.58, -0.02), tv, false, Vector3.ZERO, cart)
	_box(Vector3(0.06, 0.7, 0.5), Vector3(-0.42, 1.2, -0.02), tv, false, Vector3.ZERO, cart)
	_box(Vector3(0.06, 0.7, 0.5), Vector3(0.42, 1.2, -0.02), tv, false, Vector3.ZERO, cart)
	chad_scene = Node3D.new()
	cart.add_child(chad_scene)
	_box(Vector3(0.78, 0.68, 0.02), Vector3(0, 1.2, -0.25), _glow(Color(0.45, 0.68, 0.95)), false, Vector3.ZERO, chad_scene)
	_box(Vector3(0.78, 0.18, 0.4), Vector3(0, 0.95, -0.05), _glow(Color(0.1, 0.3, 0.6)), false, Vector3.ZERO, chad_scene)
	_lump(Vector3(0.5, 0.08, 0.2), Vector3(0, 1.06, -0.05), _mat(Color(0.95, 0.95, 0.92)), chad_scene, 0.8)
	_cyl(0.008, 0.45, Vector3(0.12, 1.3, -0.08), _mat(Color(0.8, 0.8, 0.8)), Vector3.ZERO, 4, -1.0, chad_scene)
	var tiny := Node3D.new()
	tiny.position = Vector3(-0.08, 1.06, -0.04)
	tiny.scale = Vector3.ONE * 0.24
	chad_scene.add_child(tiny)
	var cb := Node3D.new()
	tiny.add_child(cb)
	_person("chad", cb, LOOKS2.chad, "sit", tiny, PI * 0.25)
	chad_blue = _box(Vector3(0.78, 0.68, 0.01), Vector3(0, 1.2, 0.22), _glow(Color(0.05, 0.2, 0.75)), false, Vector3.ZERO, cart)
	chad_blue.visible = false
	chad_caption = _label("CHAD (VP, WORKING FROM HOME)\nRECONNECTING...", Vector3(0, 0.92, 0.235), 7, Color(1, 1, 1), Vector3.ZERO, 0.0, cart)
	# The fax machine by the left wall.
	var fax := Node3D.new()
	fax.position = Vector3(-5.5, 0, 1.5)
	fax.rotation.y = PI / 2
	_r.add_child(fax)
	_box(Vector3(0.6, 0.8, 0.45), Vector3(0, 0.4, 0), _mat(Color(0.55, 0.5, 0.45), 6, Color.BLACK, 40.0), true, Vector3.ZERO, fax)
	_box(Vector3(0.42, 0.16, 0.34), Vector3(0, 0.88, 0), _mat(Color(0.86, 0.84, 0.78), 6, Color.BLACK, 40.0), false, Vector3.ZERO, fax)
	_box(Vector3(0.12, 0.05, 0.004), Vector3(0.1, 0.92, 0.172), _glow(Color(0.4, 1.0, 0.5)), false, Vector3.ZERO, fax)
	_label("FAX", Vector3(-0.12, 0.92, 0.172), 8, Color(0.2, 0.2, 0.2), Vector3.ZERO, 0.0, fax)
	# A poster and a dying plant.
	_box(Vector3(0.7, 0.5, 0.01), Vector3(-2.5, 1.8, -4.98), _mat(Color(0.1, 0.12, 0.2)), false, Vector3.ZERO, _r)
	_label("SYNERGY", Vector3(-2.5, 1.85, -4.97), 18, Color(0.9, 0.85, 0.6), Vector3.ZERO, 0.0, _r)
	_label("TOGETHER WE ACHIEVE\nWHATEVER THIS IS", Vector3(-2.5, 1.66, -4.97), 7, Color(0.7, 0.7, 0.75), Vector3.ZERO, 0.0, _r)
	_cyl(0.16, 0.34, Vector3(5.6, 0.17, 4.5), _mat(Color(0.62, 0.34, 0.22), 6, Color.BLACK, 40.0), Vector3.ZERO, 8, 0.21, _r)
	for i in 5:
		var a := TAU * i / 5.0
		_lump(Vector3(0.1, 0.35, 0.03), Vector3(5.6 + sin(a) * 0.08, 0.5, 4.5 + cos(a) * 0.08), _mat(Color(0.45, 0.42, 0.2)), _r, 1.0, Vector3(cos(a) * 1.0, a, -sin(a) * 1.0))
	_end_room()


func _chair_at(at: Vector3, yaw: float, fabric: Material) -> void:
	var c := Node3D.new()
	c.position = at
	c.rotation.y = yaw
	_r.add_child(c)
	_chair(c, fabric, false, 0.5)


## Where Marge is on her walk (t in metres along the loop): position and yaw.
func marge_at(t: float) -> Array:
	var total := 0.0
	var legs := []
	for i in 4:
		var d: float = (ROUTE[i] as Vector3).distance_to(ROUTE[(i + 1) % 4])
		legs.append(d)
		total += d
	t = fposmod(t, total)
	for i in 4:
		if t <= legs[i]:
			var a: Vector3 = ROUTE[i]
			var b: Vector3 = ROUTE[(i + 1) % 4]
			var dir := (b - a).normalized()
			return [a + dir * t, atan2(dir.x, dir.z)]
		t -= legs[i]
	return [ROUTE[0], 0.0]


## Marge sits at desk fourteen (floor two's front-left cubicle).
func marge_sit() -> void:
	var p: Dictionary = people.marge
	for c in p.body.get_children():
		c.queue_free()
	p.holder.position = Vector3(-2.4, 0, 1.6)
	p.holder.rotation.y = PI
	_room = "f2"
	_r = floor_nodes[2]
	var body := Node3D.new()
	p.holder.add_child(body)
	var parts: Dictionary = Puppet.build(self, body, LOOKS2.marge, Callable(self, "_mat"), "sit")
	_scan_head("marge", parts, LOOKS2.marge)
	people.marge = {"holder": p.holder, "body": body, "head": parts.head, "mouth": parts.mouth, "eyes": parts.eyes, "yaw": PI, "sat": true}
	_end_room()


func chad_state(state: String) -> void:
	match state:
		"clear":
			chad_caption.text = "CHAD (VP, WORKING FROM HOME)\nCONNECTED"
		"left":
			chad_caption.text = "MEETING ENDED"
			chad_scene.visible = false
			chad_blue.visible = true


## The blackout on floor two: the tubes die, every desk screen goes red.
func floor2_dark(on: bool) -> void:
	for m in tubes:
		m.set_shader_parameter("emission", Color(0.05, 0.02, 0.02) if on else Color(0.75, 0.82, 0.85))
	for m in desk_screens:
		m.set_shader_parameter("emission", Color(0.6, 0.05, 0.04) if on else Color(0.1, 0.22, 0.12))
	var cold := Color(0.62, 0.7, 0.75)
	for i in 3:
		var p: Vector3 = [Vector3(-3, 2.4, -1.5), Vector3(3, 2.4, -1.5), Vector3(0, 2.4, 2.2)][i]
		room_light("f2", i, p if not on else p - Vector3(0, 1.4, 0), Color(0.35, 0.03, 0.03) if on else cold)


# ---------------------------------------------------------------- floor three

func _build_floor3() -> void:
	_begin_room("f3", 3, Color(0.1, 0.08, 0.09), Color(0.04, 0.03, 0.05), 5.0)
	var wall := _mat(Color(0.42, 0.28, 0.2), 3, Color(0.36, 0.23, 0.16), 40.0)
	var carpet := _mat(Color(0.42, 0.08, 0.1), 1, Color(0.36, 0.06, 0.08), 26.0)
	var ceil := _mat(Color(0.3, 0.22, 0.18), 2, Color(0.22, 0.15, 0.12), 30.0)
	_exact = true
	# Walls round a big window on the back wall.
	_box(Vector3(10.4, 0.1, 10.4), Vector3(0, -0.05, 0), carpet, true, Vector3.ZERO, _r)
	_box(Vector3(10.4, 0.1, 10.4), Vector3(0, 3.05, 0), ceil, true, Vector3.ZERO, _r)
	_box(Vector3(0.1, 3.0, 10.0), Vector3(-5.05, 1.5, 0), wall, true, Vector3.ZERO, _r)
	_box(Vector3(0.1, 3.0, 10.0), Vector3(5.05, 1.5, 0), wall, true, Vector3.ZERO, _r)
	_box(Vector3(4.05, 3.0, 0.1), Vector3(-2.975, 1.5, 5.05), wall, true, Vector3.ZERO, _r)
	_box(Vector3(4.05, 3.0, 0.1), Vector3(2.975, 1.5, 5.05), wall, true, Vector3.ZERO, _r)
	_box(Vector3(1.9, 0.5, 0.1), Vector3(0, 2.75, 5.05), wall, true, Vector3.ZERO, _r)
	_box(Vector3(10.0, 0.5, 0.1), Vector3(0, 0.25, -5.05), wall, true, Vector3.ZERO, _r)
	_box(Vector3(10.0, 0.3, 0.1), Vector3(0, 2.85, -5.05), wall, true, Vector3.ZERO, _r)
	_exact = false
	var dark_wood := _mat(Color(0.28, 0.16, 0.1), 3, Color(0.22, 0.12, 0.08), 50.0)
	for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		_box(Vector3(0.1, 2.2, 0.12), Vector3(x, 1.6, -5.0), dark_wood, false, Vector3.ZERO, _r)
	_sunset_quad(Vector2(24.0, 9.0), Vector3(0, 1.6, -11.0), Vector3.ZERO, {"grid": 420.0, "horizon": 0.42, "sun_x": 0.55, "window_view": 1.0}, _r)
	var steel := _mat(Color(0.78, 0.62, 0.28), 6, Color.BLACK, 40.0)
	_lift_doors(5.0, steel, "TOP", Color(1.0, 0.8, 0.3))
	# The long table and its board: four suits, perfectly still.
	_box(Vector3(1.5, 0.07, 4.2), Vector3(0, 0.76, -0.4), dark_wood, true, Vector3.ZERO, _r)
	_box(Vector3(0.6, 0.72, 3.4), Vector3(0, 0.36, -0.4), dark_wood, true, Vector3.ZERO, _r)
	var leather := _mat(Color(0.14, 0.09, 0.08), 6, Color.BLACK, 40.0)
	var suits := [Color(0.15, 0.15, 0.18), Color(0.3, 0.3, 0.33), Color(0.2, 0.15, 0.25), Color(0.12, 0.2, 0.2)]
	var seats := [[Vector3(-1.2, 0, -1.4), PI / 2], [Vector3(-1.2, 0, 0.6), PI / 2], [Vector3(1.2, 0, -1.4), -PI / 2], [Vector3(1.2, 0, 0.6), -PI / 2]]
	for i in 4:
		var h := Node3D.new()
		h.position = seats[i][0]
		h.rotation.y = seats[i][1]
		_r.add_child(h)
		_chair(h, leather, false, 0.8)
		var b := Node3D.new()
		h.add_child(b)
		var look := {"shirt": suits[i], "skin": Color(0.82, 0.78, 0.74).lerp(Color(0.6, 0.6, 0.62), i * 0.15), "hair": [Color(0.8, 0.8, 0.8), Color(0.1, 0.08, 0.06), Color(0.6, 0.4, 0.2), Color(0.2, 0.15, 0.1)][i],
			"hair_style": ["short", "slick", "bob", "slick"][i], "tie": Color(0.5, 0.08, 0.1) if i % 2 == 0 else Color(0.1, 0.15, 0.4), "brows": 0.2}
		_person("board_%d" % i, b, look, "sit", h, seats[i][1])
	# The conference phone, a star in the middle of the table.
	_lump(Vector3(0.3, 0.05, 0.3), Vector3(0, 0.82, -0.3), _mat(Color(0.12, 0.12, 0.13)), _r, 0.7)
	_box(Vector3(0.03, 0.012, 0.03), Vector3(0.0, 0.85, -0.3), _glow(Color(1.0, 0.2, 0.15)), false, Vector3.ZERO, _r)
	# Two green banker's lamps.
	for at in [Vector3(-0.4, 0.8, -1.6), Vector3(0.4, 0.8, 0.9)]:
		_cyl(0.06, 0.02, at, steel, Vector3.ZERO, 8, 0.05, _r)
		_cyl(0.01, 0.2, at + Vector3(0, 0.1, 0), steel, Vector3.ZERO, 5, -1.0, _r)
		_lump(Vector3(0.24, 0.07, 0.1), at + Vector3(0, 0.22, 0), _mat(Color(0.12, 0.4, 0.22), 0, Color.BLACK, 24.0, Color(0.1, 0.3, 0.12)), _r, 0.8)
	room_light("f3", 0, Vector3(-0.4, 1.1, -1.6), Color(0.6, 0.45, 0.25))
	room_light("f3", 1, Vector3(0.4, 1.1, 0.9), Color(0.6, 0.45, 0.25))
	room_light("f3", 2, Vector3(0, 2.0, -4.4), Color(0.2, 0.28, 0.5))
	room_light("f3", 3, Vector3(4.4, 2.4, -0.5), Color(0.5, 0.35, 0.2))
	room_light("f3", 4, Vector3(-4.6, 2.3, 2.5), Color(0.05, 0.3, 0.12))
	room_light("f3", 5, Vector3(0, 2.8, -0.4), Color(0.25, 0.18, 0.12))
	# The CEO's big chair, facing the window, with nobody in it.
	ceo_chair = Node3D.new()
	ceo_chair.position = Vector3(0, 0, -3.6)
	ceo_chair.rotation.y = PI
	_r.add_child(ceo_chair)
	_chair(ceo_chair, leather, true, 1.0)
	var suit := _mat(Color(0.06, 0.06, 0.08), 6, Color.BLACK, 40.0)
	_lump(Vector3(0.46, 0.62, 0.22), Vector3(0, 1.02, -0.18), suit, ceo_chair, 0.6)
	_lump(Vector3(0.18, 0.05, 0.04), Vector3(0, 1.3, -0.06), _mat(Color(0.92, 0.92, 0.9)), ceo_chair, 0.8)
	_box(Vector3(0.05, 0.3, 0.01), Vector3(0, 1.15, -0.05), _mat(Color(0.05, 0.05, 0.06)), false, Vector3.ZERO, ceo_chair)
	_box(Vector3(0.38, 0.03, 0.02), Vector3(0, 1.36, -0.24), _mat(Color(0.5, 0.5, 0.5)), false, Vector3.ZERO, ceo_chair)
	_box(Vector3(0.06, 0.06, 0.004), Vector3(0.12, 1.25, -0.065), _mat(Color(0.72, 0.5, 0.95)), false, Vector3.ZERO, ceo_chair)
	_box(Vector3(0.24, 0.06, 0.01), Vector3(0, 0.62, 0.27), _mat(Color(0.78, 0.64, 0.3)), false, Vector3.ZERO, ceo_chair)
	# The founder's portrait on the right wall.
	var frame := Node3D.new()
	frame.position = Vector3(4.97, 1.75, -0.5)
	frame.rotation.y = -PI / 2
	_r.add_child(frame)
	var gilt := _mat(Color(0.75, 0.58, 0.25), 6, Color.BLACK, 40.0)
	_box(Vector3(0.9, 1.1, 0.06), Vector3(0, 0, 0.0), gilt, false, Vector3.ZERO, frame)
	_box(Vector3(0.76, 0.96, 0.01), Vector3(0, 0, 0.035), _mat(Color(0.28, 0.2, 0.3), 6, Color.BLACK, 30.0), false, Vector3.ZERO, frame)
	_lump(Vector3(0.28, 0.34, 0.03), Vector3(0, 0.1, 0.045), _mat(Color(0.93, 0.72, 0.58)), frame, 0.6)
	_lump(Vector3(0.34, 0.16, 0.03), Vector3(0, 0.28, 0.05), _mat(Color(0.36, 0.24, 0.15)), frame, 0.6)
	_lump(Vector3(0.14, 0.04, 0.02), Vector3(0, 0.02, 0.065), _mat(Color(0.36, 0.24, 0.15)), frame, 0.7)
	_lump(Vector3(0.5, 0.28, 0.03), Vector3(0, -0.3, 0.045), _mat(Color(0.7, 0.8, 0.88)), frame, 0.6)
	_box(Vector3(0.02, 0.1, 0.01), Vector3(0.14, 0.2, 0.068), _mat(Color(0.55, 0.25, 0.85)), false, Vector3(0, 0, 0.6), frame)
	_label("D. PRUITT  FOUNDER  1996", Vector3(0, -0.62, 0.04), 8, Color(0.95, 0.85, 0.6), Vector3.ZERO, 0.0, frame)
	# The stairwell door, and Dale (hidden until he comes up the stairs).
	_box(Vector3(0.06, 2.1, 1.0), Vector3(-5.0, 1.05, 2.5), _mat(Color(0.35, 0.36, 0.38), 6, Color.BLACK, 40.0), false, Vector3.ZERO, _r)
	_box(Vector3(0.04, 0.14, 0.4), Vector3(-4.97, 2.3, 2.5), _glow(Color(0.2, 0.9, 0.35)), false, Vector3.ZERO, _r)
	_label("STAIRS", Vector3(-4.94, 2.3, 2.5), 10, Color(0.05, 0.1, 0.05), Vector3(0, PI / 2, 0), 0.0, _r)
	dale3 = Node3D.new()
	dale3.position = Vector3(-3.6, 0, 2.4)
	dale3.rotation.y = PI / 2 + 0.35
	dale3.visible = false
	_r.add_child(dale3)
	var db := Node3D.new()
	dale3.add_child(db)
	_person("dale3", db, LOOKS.dale, "stand", dale3, PI / 2 + 0.35)
	_end_room()


## The CEO's chair turns to face the room: an empty suit.
func ceo_turn() -> void:
	var tw := ceo_chair.create_tween()
	tw.tween_property(ceo_chair, "rotation:y", 0.0, 1.4).set_trans(Tween.TRANS_SINE)


func dale_arrives() -> void:
	dale3.visible = true


## Dawn at the top: the window floods orange, the room warms up.
func floor3_dawn(k: float) -> void:
	room_light("f3", 2, Vector3(0, 2.0, -4.0), Color(0.2, 0.28, 0.5).lerp(Color(1.3, 0.8, 0.45), k))
	room_ambient("f3", Color(0.1, 0.08, 0.09).lerp(Color(0.38, 0.3, 0.26), k), Color(0.04, 0.03, 0.05).lerp(Color(0.7, 0.5, 0.35), k))


# ---------------------------------------------------------------- the field

## Past the roof: a wheat field under an impressionist sky. Whoever you got
## off the night shift stands in the wheat (field_cast() places them).
func _build_field() -> void:
	_begin_room("field", 4, Color(0.75, 0.7, 0.62), Color(1.0, 0.86, 0.66), 30.0)
	room_light("field", 0, Vector3(20, 25, -40), Color(0.9, 0.75, 0.5))
	var sky := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 90.0
	sphere.height = 180.0
	sphere.radial_segments = 32
	sphere.rings = 16
	sky.mesh = sphere
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://scenes/field/sky.gdshader")
	sky.material_override = sm
	sky.layers = LAYER_WORLD
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_r.add_child(sky)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var gm := ShaderMaterial.new()
	gm.shader = preload("res://scenes/field/ground.gdshader")
	ground.material_override = gm
	ground.layers = LAYER_WORLD
	_r.add_child(ground)
	# The wheat: one MultiMesh of tapered blades, thick round the group and
	# the camera's path, thinning out toward the haze.
	var blade := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 4
	for i in segs:
		var y0 := float(i) / segs
		var y1 := float(i + 1) / segs
		var w0 := 0.022 * (1.0 - y0 * 0.7)
		var w1 := 0.022 * (1.0 - y1 * 0.7)
		var v := [Vector3(-w0, y0, 0), Vector3(w0, y0, 0), Vector3(w1, y1, 0), Vector3(-w1, y1, 0)]
		var uv := [Vector2(0, y0), Vector2(1, y0), Vector2(1, y1), Vector2(0, y1)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uv[k])
			st.add_vertex(v[k])
	blade = st.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	var count := 7000
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 1996
	for i in count:
		var r := sqrt(rng.randf()) * 34.0
		var a := rng.randf() * TAU
		var p := Vector3(cos(a) * r, 0, sin(a) * r * 1.2 - 4.0)
		if p.distance_to(Vector3(0, 0, -4.5)) < 1.6:
			p += (p - Vector3(0, 0, -4.5)).normalized() * 1.6
		var h := rng.randf_range(0.75, 1.15)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.0, h, 1.0))
		mm.set_instance_transform(i, Transform3D(basis, p))
	var wm := MultiMeshInstance3D.new()
	wm.multimesh = mm
	wheat_mat = ShaderMaterial.new()
	wheat_mat.shader = preload("res://scenes/field/wheat.gdshader")
	wm.material_override = wheat_mat
	wm.layers = LAYER_WORLD
	wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_r.add_child(wm)
	# A lone tree on a rise, far off, and soft hills.
	for spec in [[Vector3(-30, -6, -60), Vector3(70, 16, 30), Color(0.55, 0.6, 0.35)], [Vector3(35, -7, -70), Vector3(80, 18, 34), Color(0.5, 0.58, 0.38)], [Vector3(0, -9, -85), Vector3(120, 22, 40), Color(0.5, 0.56, 0.52)]]:
		_lump(spec[1], spec[0], _mat(spec[2], 6, Color.BLACK, 6.0), _r, 1.0)
	_cyl(0.25, 3.0, Vector3(14, 1.5, -26), _mat(Color(0.35, 0.25, 0.18)), Vector3(0, 0, 0.05), 6, 0.18, _r)
	for k in 5:
		_lump(Vector3(3.2, 2.4, 3.0), Vector3(14 + (k % 3 - 1) * 1.2, 3.6 + (k / 3) * 1.1, -26 + (k % 2) * 0.8), _mat(Color(0.32, 0.45, 0.25).lerp(Color(0.5, 0.58, 0.3), k * 0.2), 6, Color.BLACK, 10.0), _r, 1.0)
	field_people = Node3D.new()
	_r.add_child(field_people)
	_end_room()


## Stand whoever you got out in the wheat, in a loose arc facing you.
func field_cast(ids: Array, coffee := false) -> void:
	for c in field_people.get_children():
		c.queue_free()
	_room = "field"
	_r = floor_nodes[4]
	var looks := {"wendy": LOOKS.wendy, "kip": LOOKS.kip, "dale": LOOKS.dale, "marge": LOOKS2.marge, "chad": LOOKS2.chad, "brenda": LOOKS2.brenda}
	var spots := []
	var n := ids.size()
	for i in n:
		var a := (float(i) - (n - 1) * 0.5) * 0.32
		spots.append([Vector3(sin(a) * 4.2, 0, -4.5 + (1.0 - cos(a)) * 4.2), PI + a * 0.8])
	for i in n:
		var id: String = ids[i]
		var h := Node3D.new()
		h.position = spots[i][0]
		h.rotation.y = spots[i][1] + PI
		field_people.add_child(h)
		if id == "printy":
			var s := 0.9
			_box(Vector3(0.8, 0.62, 0.62) * s, Vector3(0, 0.31 * s, 0), _mat(Color(0.84, 0.82, 0.74), 6, Color.BLACK, 40.0), false, Vector3.ZERO, h)
			_box(Vector3(0.8, 0.26, 0.6) * s, Vector3(0, 0.75 * s, 0), _mat(Color(0.84, 0.82, 0.74), 6, Color.BLACK, 40.0), false, Vector3.ZERO, h)
			_box(Vector3(0.2, 0.11, 0.004), Vector3(0, 0.82, 0.3), _glow(Color(0.65, 1.0, 0.4)), false, Vector3.ZERO, h)
			_label("^_^", Vector3(0, 0.82, 0.304), 22, Color(0.1, 0.25, 0.05), Vector3.ZERO, 0.0, h)
			continue
		var b := Node3D.new()
		h.add_child(b)
		var parts: Dictionary = Puppet.build(self, b, looks[id], Callable(self, "_mat"), "stand")
		_scan_head(id, parts, looks[id])
		people["field_" + id] = {"holder": h, "body": b, "head": parts.head, "mouth": parts.mouth, "eyes": parts.eyes, "yaw": spots[i][1]}
	if coffee:
		var h := Node3D.new()
		h.position = Vector3(2.4, 0, -2.6)
		field_people.add_child(h)
		_cyl(0.22, 0.45, Vector3(0, 0.22, 0), _mat(Color(0.45, 0.32, 0.2)), Vector3.ZERO, 8, 0.2, h)
		_box(Vector3(0.24, 0.36, 0.24), Vector3(0, 0.63, 0), _mat(Color(0.12, 0.12, 0.13)), false, Vector3.ZERO, h)
		_box(Vector3(0.025, 0.025, 0.01), Vector3(0.07, 0.72, 0.125), _glow(Color(0.3, 1.0, 0.4)), false, Vector3.ZERO, h)
	_end_room()
