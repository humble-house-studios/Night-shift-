extends PanelContainer
## DEV: jump to any moment of the night (engine/dev_jump.gd plays the story
## up to it for real), unlock or wipe the card collection. Opened from the
## pause menu or the title menu while DevJump.ON.

var main: Node


func setup(m: Node) -> void:
	main = m
	visible = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.06, 0.04, 0.97)
	st.border_color = Color(0.4, 1.0, 0.5, 0.8)
	st.set_border_width_all(3)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(22)
	add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head: Label = main._label(main.PIXEL, 22, Color(0.5, 1.0, 0.6))
	head.text = "DEV · JUMP TO A MOMENT"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var labels := DevJump.labels()
	for i in labels.size():
		var b: Button = main._button(labels[i], 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		b.pressed.connect(func(): main._dev_jump(idx))
		list.add_child(b)
	for spec in [["UNLOCK ALL CARDS + RELICS", _unlock], ["WIPE COLLECTION", _wipe], ["CLOSE", _close]]:
		var b: Button = main._button(spec[0], 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(spec[1])
		list.add_child(b)


func place(l: float, t: float, r: float, b: float) -> void:
	var w := minf(r - l, 700.0)
	position = Vector2((get_viewport_rect().size.x - w) * 0.5, t)
	size = Vector2(w, b - t)


func _unlock() -> void:
	main._collect.unlock_all()
	main._toast_show("COLLECTION UNLOCKED")


func _wipe() -> void:
	main._collect.wipe_album()
	main._toast_show("COLLECTION WIPED")


func _close() -> void:
	visible = false
