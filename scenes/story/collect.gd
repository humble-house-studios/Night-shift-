extends Control
## Cards and relics on screen. Under the clock: this floor's three goal
## cards as little chips (empty outlines until you earn them) and a row of
## relic icons that grows through the night. Earning one plays a reveal: the
## card flips up big in the middle of the screen with a shimmer, tap to keep.
## COLLECTION (pause menu or title) shows every card and relic you've ever
## found, across nights (user://collection.cfg); the rest are silhouettes.

const Data := preload("res://data/collectibles.gd")
const Card := preload("res://scenes/story/card.gd")
const Icons := preload("res://scenes/story/icons.gd")
const PIXEL := preload("res://addons/hh_minigames/_shared/fonts/press_start_2p.ttf")
const SAVE := "user://collection.cfg"

var main: Node
var owned := {}
var album := {}
var _queue: Array = []
var _reveal: Control
var _shade: ColorRect
var _card: Control
var _head: Label
var _sub: Label
var _chips: HBoxContainer
var _relics: HFlowContainer
var _view: PanelContainer
var _grid_box: VBoxContainer
var _count: Label
var _shown_t := 0.0
var _act := 1


func setup(m: Node) -> void:
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load()
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 10)
	add_child(_chips)
	_relics = HFlowContainer.new()
	_relics.add_theme_constant_override("h_separation", 6)
	_relics.add_theme_constant_override("v_separation", 6)
	add_child(_relics)
	# The reveal.
	_reveal = Control.new()
	_reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal.visible = false
	_reveal.gui_input.connect(_on_reveal_input)
	add_child(_reveal)
	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.01, 0.04, 0.78)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal.add_child(_shade)
	_head = _text(PIXEL, 26, Color(1.0, 0.86, 0.5))
	_reveal.add_child(_head)
	_card = Card.new()
	_reveal.add_child(_card)
	_sub = _text(PIXEL, 16, Color(1, 1, 1, 0.75))
	_sub.text = "TAP TO KEEP"
	_reveal.add_child(_sub)
	_build_view()


func _text(font: Font, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------------------------------------------------------------- state

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		album = cfg.get_value("album", "have", {})


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("album", "have", album)
	cfg.save(SAVE)


func wipe_album() -> void:
	album = {}
	_save()


func unlock_all() -> void:
	for f in Data.CARDS:
		album[f] = true
	for f in Data.RELICS:
		album[f] = true
	_save()


## Match the story without fanfare (a loaded night, a dev jump).
func sync(story: NightStory) -> void:
	owned.clear()
	_queue.clear()
	for f in Data.CARDS.keys() + Data.RELICS.keys():
		if story.has(f):
			owned[f] = true
			album[f] = true
	_save()
	refresh(story)


## Anything new since last time? Queue its reveal.
func check(story: NightStory) -> void:
	var fresh := false
	for table in [Data.CARDS, Data.RELICS]:
		for f in table:
			if story.has(f) and not owned.has(f):
				owned[f] = true
				album[f] = true
				_queue.append([f, table == Data.CARDS])
				fresh = true
	if fresh:
		_save()
		refresh(story)
		if not _reveal.visible:
			_next()


func showing() -> bool:
	return _reveal.visible or _view.visible


# ---------------------------------------------------------------- HUD

func refresh(story: NightStory) -> void:
	_act = story.act()
	for c in _chips.get_children():
		c.queue_free()
	for c in _relics.get_children():
		c.queue_free()
	for f in Data.CARDS:
		var e: Array = Data.CARDS[f]
		if e[3] != _act:
			continue
		var chip := Control.new()
		chip.custom_minimum_size = Vector2(62, 84)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var have := owned.has(f)
		chip.draw.connect(func(): _draw_chip(chip, e, have))
		_chips.add_child(chip)
	for f in Data.RELICS:
		if not owned.has(f):
			continue
		var e: Array = Data.RELICS[f]
		var ic := Control.new()
		ic.custom_minimum_size = Vector2(46, 46)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.draw.connect(func(): _draw_relic(ic, e))
		_relics.add_child(ic)


func _draw_chip(c: Control, e: Array, have: bool) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.06, 0.1, 0.85) if have else Color(0, 0, 0, 0.35)
	st.border_color = Color(1.0, 0.82, 0.4) if have else Color(1, 1, 1, 0.3)
	st.set_border_width_all(2)
	st.set_corner_radius_all(7)
	c.draw_style_box(st, r)
	if have:
		c.draw_rect(Rect2(3, 3, r.size.x - 6, 12), (e[4] as Color).darkened(0.15))
		Icons.draw(c, e[2], Rect2(9, 22, r.size.x - 18, r.size.x - 18), e[4])
	else:
		c.draw_string(PIXEL, Vector2(0, r.size.y * 0.62), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color(1, 1, 1, 0.35))


func _draw_relic(c: Control, e: Array) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	c.draw_circle(r.get_center(), r.size.x * 0.5, Color(0.07, 0.06, 0.1, 0.8))
	c.draw_arc(r.get_center(), r.size.x * 0.5 - 1, 0, TAU, 24, Color(0.82, 0.86, 0.95, 0.9), 2.0)
	Icons.draw(c, e[2], r.grow(-8), e[4])


func layout(l: float, t: float, r: float, b: float) -> void:
	var size := get_viewport_rect().size
	_chips.position = Vector2(l, t + 92)
	_relics.position = Vector2(l, t + 186)
	_relics.size = Vector2(minf(330.0, r - l - 100.0), 0)
	var wide := size.x > size.y
	var cw := minf(size.x * (0.3 if wide else 0.62), 420.0)
	_card.size = Vector2(cw, cw * 1.42)
	_card.pivot_offset = _card.size * 0.5
	_card.position = (size - _card.size) * 0.5 + Vector2(0, 20)
	_head.size = Vector2(size.x, 0)
	_head.position = Vector2(0, _card.position.y - 70)
	_sub.size = Vector2(size.x, 0)
	_sub.position = Vector2(0, _card.position.y + _card.size.y + 30)
	var vw := minf(size.x - 32.0, 760.0)
	_view.position = Vector2((size.x - vw) * 0.5, t)
	_view.size = Vector2(vw, b - t)
	var cols := 3 if not wide else 5
	var cardw := (vw - 60.0 - (cols - 1) * 12.0) / cols
	for g in _grid_box.get_children():
		if g is GridContainer:
			g.columns = cols
			for c in g.get_children():
				c.custom_minimum_size = Vector2(cardw, cardw * 1.42)


# ---------------------------------------------------------------- reveal

func _next() -> void:
	if _queue.is_empty():
		_reveal.visible = false
		return
	var item: Array = _queue.pop_front()
	var is_card: bool = item[1]
	var e: Array = (Data.CARDS if is_card else Data.RELICS)[item[0]]
	_card.setup(e, "card" if is_card else "relic")
	_head.text = "NEW GOAL CARD" if is_card else "RELIC FOUND"
	_reveal.visible = true
	_shown_t = Time.get_ticks_msec()
	_shade.modulate.a = 0.0
	_card.scale = Vector2(0.15, 0.15)
	_card.rotation = -0.35
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_shade, "modulate:a", 1.0, 0.35)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	main._play("shimmer", -4.0, 1.0 if is_card else 1.25)


func _on_reveal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Time.get_ticks_msec() - _shown_t > 450:
		_keep()


func _unhandled_input(event: InputEvent) -> void:
	if not _reveal.visible:
		return
	if (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		if Time.get_ticks_msec() - _shown_t > 450:
			_keep()
		get_viewport().set_input_as_handled()


## Tuck the card away into the HUD, then the next one (if any).
func _keep() -> void:
	main._play("choice", -10.0, 1.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "scale", Vector2(0.18, 0.18), 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_card, "position", _chips.position - _card.size * 0.41, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_shade, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(func():
		layout_card_back()
		_next())


func layout_card_back() -> void:
	var size := get_viewport_rect().size
	_card.position = (size - _card.size) * 0.5 + Vector2(0, 20)


# ---------------------------------------------------------------- collection

func _build_view() -> void:
	_view = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.035, 0.07, 0.97)
	st.border_color = Color(1.0, 0.75, 0.4, 0.7)
	st.set_border_width_all(3)
	st.set_corner_radius_all(12)
	st.set_content_margin_all(24)
	_view.add_theme_stylebox_override("panel", st)
	_view.visible = false
	add_child(_view)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_view.add_child(v)
	_count = _text(PIXEL, 22, Color(1.0, 0.86, 0.5))
	v.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid_box = VBoxContainer.new()
	_grid_box.add_theme_constant_override("separation", 14)
	_grid_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid_box)
	var close: Button = main._button("CLOSE", 30)
	close.pressed.connect(func(): _view.visible = false)
	v.add_child(close)


func open_album() -> void:
	for c in _grid_box.get_children():
		c.queue_free()
	var have := 0
	for section in [["GOAL CARDS", Data.CARDS, "card"], ["RELICS", Data.RELICS, "relic"]]:
		var h := _text(PIXEL, 18, Color(1, 1, 1, 0.8))
		h.text = section[0]
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_grid_box.add_child(h)
		var g := GridContainer.new()
		g.add_theme_constant_override("h_separation", 12)
		g.add_theme_constant_override("v_separation", 12)
		_grid_box.add_child(g)
		for f in section[1]:
			var c := Card.new()
			var got: bool = album.get(f, false)
			if got:
				have += 1
			c.setup(section[1][f], section[2], not got)
			g.add_child(c)
	_count.text = "COLLECTION  %d / %d" % [have, Data.CARDS.size() + Data.RELICS.size()]
	_view.visible = true
	main._layout()
