extends Control
## The title sequence, Xbox 360 style: the real office filmed live by a
## cinematic camera while the sun goes down. It opens close on "Golden Hour"
## (the painting on the front wall), its sun sinking; dips through warm white
## to Dale at his desk against the window; then a crane up over the office as
## the light dies and the monitors come on: 11:58 PM. The logo lands, PRESS
## START, then a menu with a sliding glossy bar. Tap at any point to skip to
## the logo. Bloom, grade, grain and letterbox from title_post.gdshader.

const POST := preload("res://scenes/world/title_post.gdshader")
const LOGO := preload("res://scenes/world/night_logo.gdshader")
const PIXEL := preload("res://addons/hh_minigames/_shared/fonts/press_start_2p.ttf")
const BODY := preload("res://addons/hh_minigames/_shared/fonts/pixelify_sans.ttf")
const BOLD := preload("res://scenes/world/fonts/InterDisplay-BlackItalic.otf")
const P := Vector3(-1.45, 1.62, 3.975)

## [seconds, eye from, look from, eye to, look to, night from, night to]
var SHOTS := [
	[7.5, P + Vector3(0.0, 0.0, -0.42), P, P + Vector3(0.08, -0.06, -1.35), P + Vector3(0.0, -0.08, 0.0), 0.0, 0.18],
	[7.0, Vector3(-1.45, 1.5, -0.35), Vector3(-3.05, 1.28, -0.62), Vector3(-1.95, 1.42, -0.55), Vector3(-3.05, 1.3, -0.6), 0.18, 0.4],
	[9.5, Vector3(0.7, 0.45, 2.3), Vector3(0.0, 0.7, -1.2), Vector3(1.25, 2.15, 3.3), Vector3(-0.6, 0.95, -2.2), 0.4, 1.0],
]
const SETTLE := [Vector3(1.25, 2.15, 3.3), Vector3(-0.6, 0.95, -2.2)]

var main: Node
var _t := 0.0
var _shot := 0
var _phase := "shots"   # shots, logo, menu, credits
var _post: ShaderMaterial
var _bars: Array[ColorRect] = []
var _logo: Label
var _sub: Label
var _start: Label
var _stamp: Label
var _menu: VBoxContainer
var _bar: Panel
var _items: Array[Button] = []
var _pick := 0
var _credits: PanelContainer
var _logo_t := 0.0
var _last_press := 0
var _screens_on := false


func setup(m: Node) -> void:
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_post = ShaderMaterial.new()
	_post.shader = POST
	for i in 2:
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)
		_bars.append(b)
	_stamp = _text(PIXEL, 20, Color(1.0, 0.9, 0.75, 0.0))
	_stamp.text = "HUMBLE HOUSE GAMES\n11:58 PM"
	_logo = _text(BOLD, 132, Color(1, 1, 1))
	_logo.text = "NIGHT\nSHIFT"
	_logo.add_theme_constant_override("line_spacing", -40)
	_logo.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.05))
	_logo.add_theme_constant_override("outline_size", 22)
	var lm := ShaderMaterial.new()
	lm.shader = LOGO
	_logo.material = lm
	_sub = _text(PIXEL, 22, Color(1.0, 0.86, 0.7))
	_sub.text = "A LOOK BUSY STORY"
	_start = _text(PIXEL, 26, Color(1, 1, 1))
	_start.text = "TAP TO START" if DisplayServer.is_touchscreen_available() else "PRESS START"
	_start.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_start.add_theme_constant_override("outline_size", 10)
	# The menu: items on a dark blade, the glossy bar slides behind the pick.
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 6)
	add_child(_menu)
	_bar = Panel.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1.0, 0.55, 0.2, 0.9)
	gloss.border_color = Color(1.0, 0.92, 0.7)
	gloss.set_border_width_all(2)
	gloss.set_corner_radius_all(10)
	gloss.shadow_color = Color(1.0, 0.4, 0.1, 0.45)
	gloss.shadow_size = 14
	_bar.add_theme_stylebox_override("panel", gloss)
	add_child(_bar)
	move_child(_bar, _menu.get_index())
	_credits = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.02, 0.05, 0.94)
	st.border_color = Color(1.0, 0.6, 0.3, 0.7)
	st.set_border_width_all(3)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(30)
	_credits.add_theme_stylebox_override("panel", st)
	_credits.visible = false
	add_child(_credits)
	var cl := Label.new()
	cl.name = "Text"
	cl.add_theme_font_override("font", BODY)
	cl.add_theme_font_size_override("font_size", 26)
	cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits.add_child(cl)
	get_viewport().size_changed.connect(_layout)


func _text(font: Font, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _item(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.custom_minimum_size = Vector2(0, 92)
	b.add_theme_font_override("font", PIXEL)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", Color(0.92, 0.9, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	b.add_theme_constant_override("outline_size", 8)
	var i := _items.size()
	b.mouse_entered.connect(func(): _pick = i)
	b.pressed.connect(func():
		_pick = i
		main._play("choice", -8.0)
		action.call())
	_menu.add_child(b)
	_items.append(b)


## Roll the sequence from the top.
func start() -> void:
	visible = true
	_t = 0.0
	_shot = 0
	_phase = "shots"
	_screens_on = false
	main._world_box.material = _post
	main.office.set_lights(1.0)
	main.office.set_night(0.0)
	_day_screens()
	for c in _items:
		c.queue_free()
	_items.clear()
	_item("CLOCK IN", main._start_new)
	if NightStory.has_save():
		_item("CONTINUE THE NIGHT", main._continue)
	_item("CREDITS", _show_credits)
	_pick = 1 if NightStory.has_save() else 0
	for n in [_logo, _sub, _start, _menu, _bar, _credits]:
		n.visible = false
	_post.set_shader_parameter("flash", 1.0)
	_layout()


func stop() -> void:
	visible = false
	main._world_box.material = null


func _day_screens() -> void:
	for id in main.office.screen_ids():
		if id != "printy":
			main.office.screen(id, "HUMBLE\nHOUSE", Color(0.55, 0.8, 1.0))


func _layout() -> void:
	var size := get_viewport_rect().size
	var wide := size.x > size.y
	var bar_h := size.y * (0.1 if wide else 0.12)
	var k := 1.0 if _phase == "shots" else clampf(1.0 - _logo_t * 1.5, 0.0, 1.0)
	_bars[0].position = Vector2(0, -bar_h * (1.0 - k))
	_bars[0].size = Vector2(size.x, bar_h)
	_bars[1].position = Vector2(0, size.y - bar_h * k)
	_bars[1].size = Vector2(size.x, bar_h)
	var w := minf(size.x - 48.0, 660.0)
	_logo.add_theme_font_size_override("font_size", 104 if wide else 132)
	_logo.size = Vector2(size.x, 0)
	_logo.position = Vector2(0, size.y * (0.1 if wide else 0.17))
	var lm: ShaderMaterial = _logo.material
	lm.set_shader_parameter("height", _logo.get_combined_minimum_size().y)
	lm.set_shader_parameter("width", size.x)
	_sub.size = Vector2(size.x, 0)
	_sub.position = Vector2(0, _logo.position.y + _logo.get_combined_minimum_size().y + 8)
	_start.size = Vector2(size.x, 0)
	_start.position = Vector2(0, size.y * 0.72)
	_stamp.size = Vector2(size.x, 0)
	_stamp.position = Vector2(0, size.y - bar_h - 90)
	_menu.size = Vector2(w, 0)
	_menu.position = Vector2((size.x - w) * 0.5, size.y * (0.56 if wide else 0.6))
	_credits.size = Vector2(w, 0)
	_credits.position = Vector2((size.x - w) * 0.5, size.y * 0.12)
	_credits.get_node("Text").custom_minimum_size = Vector2(w - 60, 0)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var fl: float = _post.get_shader_parameter("flash")
	_post.set_shader_parameter("flash", move_toward(fl, 0.0, delta * 1.4))
	if _phase == "shots":
		var s: Array = SHOTS[_shot]
		var k := clampf(_t / s[0], 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k) * 0.7 + k * 0.3
		_aim((s[1] as Vector3).lerp(s[3], e), (s[2] as Vector3).lerp(s[4], e))
		main.office.set_night(lerpf(s[5], s[6], k))
		if _shot == 2:
			# The monitors flick on as the light goes; the time stamp fades in.
			if k > 0.72 and not _screens_on:
				_screens_on = true
				main._play("thump", -16.0, 1.6)
				for id in main.office.screen_ids():
					main.office.screen(id)
			_stamp.add_theme_color_override("font_color", Color(1.0, 0.9, 0.75, clampf((k - 0.6) * 4.0, 0.0, 1.0) * clampf((1.0 - k) * 6.0, 0.0, 1.0)))
		if k >= 1.0:
			_shot += 1
			_t = 0.0
			if _shot >= SHOTS.size():
				_to_logo()
			else:
				_post.set_shader_parameter("flash", 0.75)
				main._play("swell", -14.0, 0.8)
	else:
		# Settled: the dark office, a slow breathing drift.
		var a := Time.get_ticks_msec() / 1000.0 * 0.12
		_aim(SETTLE[0] + Vector3(sin(a) * 0.25, sin(a * 0.7) * 0.05, cos(a) * 0.1), SETTLE[1])
		_logo_t += delta
		_logo.modulate.a = clampf(_logo_t * 2.0, 0.0, 1.0)
		_logo.scale = Vector2.ONE * lerpf(1.25, 1.0, clampf(_logo_t * 2.5, 0.0, 1.0))
		_logo.pivot_offset = _logo.size * 0.5
		var lm: ShaderMaterial = _logo.material
		lm.set_shader_parameter("glint", fmod(_logo_t * 0.45, 2.6) - 0.6)
		_sub.modulate.a = clampf(_logo_t * 2.0 - 0.8, 0.0, 1.0)
		_start.modulate.a = 0.45 + 0.55 * absf(sin(_logo_t * 2.4)) if _phase == "logo" else 0.0
		if _phase == "menu" and _items.size() > 0:
			var target: Button = _items[clampi(_pick, 0, _items.size() - 1)]
			var r := target.get_global_rect()
			var want := Rect2(r.position - Vector2(10, 0), r.size + Vector2(20, 0))
			_bar.position = _bar.position.lerp(want.position, minf(1.0, delta * 14.0))
			_bar.size = _bar.size.lerp(want.size, minf(1.0, delta * 14.0))
		_layout()


func _aim(eye: Vector3, look: Vector3) -> void:
	main._camera.global_transform = Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)


func _to_logo() -> void:
	_phase = "logo"
	_logo_t = 0.0
	main.office.set_night(1.0)
	if not _screens_on:
		_screens_on = true
		for id in main.office.screen_ids():
			main.office.screen(id)
	_stamp.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	_post.set_shader_parameter("flash", 0.9)
	main._play("shimmer", -6.0, 0.7)
	for n in [_logo, _sub, _start]:
		n.visible = true


func _to_menu() -> void:
	_phase = "menu"
	_start.visible = false
	_menu.visible = true
	_bar.visible = true
	_layout()
	await get_tree().process_frame
	var r := _items[_pick].get_global_rect()
	_bar.position = r.position - Vector2(10, 0)
	_bar.size = r.size + Vector2(20, 0)


func _show_credits() -> void:
	_phase = "credits"
	_menu.visible = false
	_bar.visible = false
	_logo.visible = false
	_sub.visible = false
	_credits.get_node("Text").text = main._credits_text() + "\n\n(tap to go back)"
	_credits.visible = true
	_layout()


## Any tap or button: wake the sound, skip ahead, or move through the menu.
func _press() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_press < 300:
		return
	_last_press = now
	match _phase:
		"shots":
			_to_logo()
		"logo":
			main._play("choice", -6.0)
			_to_menu()
		"credits":
			_credits.visible = false
			_logo.visible = true
			_sub.visible = true
			_to_menu()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _phase != "menu":
			_press()
			accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var go := false
	if event is InputEventKey and event.pressed and not event.echo:
		if _phase == "menu" and event.keycode in [KEY_UP, KEY_W]:
			_pick = (_pick - 1 + _items.size()) % _items.size()
			main._play("page", -6.0)
		elif _phase == "menu" and event.keycode in [KEY_DOWN, KEY_S]:
			_pick = (_pick + 1) % _items.size()
			main._play("page", -6.0)
		elif event.keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			go = true
	if event is InputEventJoypadButton and event.pressed:
		if _phase == "menu" and event.button_index == JOY_BUTTON_DPAD_UP:
			_pick = (_pick - 1 + _items.size()) % _items.size()
		elif _phase == "menu" and event.button_index == JOY_BUTTON_DPAD_DOWN:
			_pick = (_pick + 1) % _items.size()
		elif event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			go = true
	if go:
		if _phase == "menu":
			_items[_pick].emit_signal("pressed")
		else:
			_press()
		get_viewport().set_input_as_handled()
