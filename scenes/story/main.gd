extends Control
## NIGHT SHIFT: the game. The Look Busy office after hours (night_office.gd),
## first person; tap someone to walk up and talk, tap the floor to walk, drag
## to look. Conversations come from data/night_script.gd through the story
## engine (engine/story.gd); this file shows them (typed-out lines, reply
## buttons) and plays their events (phones, blackouts, dawn).

const Office := preload("res://scenes/world/night_office.gd")
const Night := preload("res://data/night_script.gd")
const SafeArea := preload("res://addons/hh_minigames/_shared/safe_area.gd")
const PIXEL := preload("res://addons/hh_minigames/_shared/fonts/press_start_2p.ttf")
const BODY := preload("res://addons/hh_minigames/_shared/fonts/pixelify_sans.ttf")
const TITLE := preload("res://scenes/world/fonts/InterDisplay-BlackItalic.otf")

const EYE := 1.5
const SPEED := 2.2
const LOOK_SENS := 0.006
const PIXEL_SHRINK := 3
const TYPE_CPS := 44.0
const GLIDE := 0.8
const TAP_SLOP := 22.0
const TAP_TIME := 0.4
const PICK_RADIUS := 120.0
const START := Vector3(0.15, 0.0, -1.5)

enum { TITLE_SCREEN, WALK, GLIDING, TALK, ENDING }

var story := NightStory.new()
var office: Node
var _state := TITLE_SCREEN
var _world_vp: SubViewport
var _world_box: SubViewportContainer
var _player: CharacterBody3D
var _camera: Camera3D
var _yaw := 0.0
var _pitch := -0.12
var _walk_to = null
var _t := 0.0

# Gliding the camera to a talk spot (and back).
var _glide_from := Transform3D()
var _glide_to := Transform3D()
var _glide_t := 1.0
var _talk_with := ""
var _after_glide := ""
var _glide_len := 2.5

# The conversation on screen.
var _node := ""
var _pages: Array = []
var _page := 0
var _speaker := "narr"
var _typing := false
var _blip_n := 0
var _ending := ""
var _queue: Array = []

# Touch.
var _touch := {}

# UI.
var _box: PanelContainer
var _name: Label
var _text: Label
var _choices: VBoxContainer
var _more: Label
var _clock: Label
var _goals: Label
var _hint: Label
var _toast: Label
var _toast_t := 0.0
var _tags: Control
var _pause: Button
var _menu: PanelContainer
var _rules_btn: Button
var _sound_btn: Button
var _card: PanelContainer
var _fade: ColorRect
var _title: Control
var _end: Control
var _end_title: Label
var _end_lines: Label
var _end_btn: Button
var _inset := Vector4.ZERO

# Night effects.
var _blackout := 0.0
var _flicker := 0.0
var _shake := 0.0
var _dawn := -1.0
var _kip_frozen := false
var _printing := 0.0
var _smile := 0.0

# Sound.
var _amb: AudioStreamPlayer
var _drone: AudioStreamPlayer
var _music: AudioStreamPlayer
var _score: AudioStreamPlayer
const SCORE_DB := -11.0
var _blip: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _voices_on := true
var _voices_btn: Button
var _cps := TYPE_CPS
var _sfx := {}
var _muted := false


func _ready() -> void:
	_build_world()
	_build_ui()
	_build_sound()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_show_title()


# ---------------------------------------------------------------- world

func _build_world() -> void:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.stretch_shrink = PIXEL_SHRINK
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	_world_box = box
	_world_vp = SubViewport.new()
	_world_vp.audio_listener_enable_3d = true
	box.add_child(_world_vp)
	var world := Node3D.new()
	_world_vp.add_child(world)
	office = Office.new()
	add_child(office)
	office.build(world)
	_player = CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.8
	_player.add_child(shape)
	_player.position = START
	world.add_child(_player)
	_camera = Camera3D.new()
	_camera.near = 0.05
	_camera.far = 30.0
	_camera.fov = 68.0
	world.add_child(_camera)
	_camera.current = true


func _spot(id: String) -> Array:
	var s: Array = Night.SPOTS[id].duplicate()
	if id == "dale" and story.has("dale_going") and office.people.has("dale"):
		s[1] = Vector3(-2.3, 1.62, -0.5)
		s[2] = Vector3(-1.2, 1.55, -0.1)
	return s


func _spot_name(id: String) -> String:
	if id == "wendy" and story.has("wendy_named"):
		return "WENDY"
	return Night.SPOTS[id][0]


func _portrait() -> bool:
	var s := get_viewport_rect().size
	return s.y > s.x


## Where the camera sits to talk to `id`: their spot, looking a bit lower on a
## phone held upright so they sit above the text box.
func _talk_view(id: String) -> Transform3D:
	var s := _spot(id)
	var eye: Vector3 = s[2]
	var look: Vector3 = s[1]
	if _portrait():
		look.y -= 0.28
		eye += (eye - look).normalized() * 0.25
	return Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)


# ---------------------------------------------------------------- UI

func _style(bg: Color, border: Color, width := 4, pad := 22) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(width)
	st.set_content_margin_all(pad)
	st.corner_radius_top_left = 2
	return st


func _label(font: Font, size: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, size := 32) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 88)
	b.add_theme_font_override("font", BODY)
	b.add_theme_font_size_override("font_size", size)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.09, 0.14, 0.95), Color(0.4, 0.38, 0.5), 3, 14))
	b.add_theme_stylebox_override("hover", _style(Color(0.18, 0.16, 0.26, 0.98), Color(0.95, 0.8, 0.45), 3, 14))
	b.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.22, 0.12, 1.0), Color(1.0, 0.85, 0.5), 3, 14))
	b.add_theme_stylebox_override("focus", _style(Color(0.18, 0.16, 0.26, 0.98), Color(0.95, 0.8, 0.45), 3, 14))
	b.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))
	return b


func _build_ui() -> void:
	# Name tags over people and things.
	_tags = Control.new()
	_tags.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tags.draw.connect(_draw_tags)
	add_child(_tags)

	_clock = _label(PIXEL, 34, Color(1.0, 0.45, 0.35))
	add_child(_clock)
	_goals = _label(PIXEL, 20, Color(0.85, 0.85, 0.9))
	_goals.add_theme_constant_override("line_spacing", 10)
	add_child(_goals)
	_hint = _label(BODY, 28, Color(0.75, 0.75, 0.85, 0.8))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "Tap to talk or walk  ·  drag to look"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hint)
	_toast = _label(PIXEL, 24, Color(1.0, 0.9, 0.5))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	add_child(_toast)

	_pause = _button("II", 26)
	_pause.add_theme_font_override("font", PIXEL)
	_pause.custom_minimum_size = Vector2(88, 88)
	_pause.pressed.connect(_open_menu)
	add_child(_pause)

	# The talk box.
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", _style(Color(0.04, 0.035, 0.07, 0.93), Color(0.5, 0.45, 0.62)))
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.visible = false
	add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(v)
	_name = _label(PIXEL, 24)
	v.add_child(_name)
	_text = _label(BODY, 40, Color(0.95, 0.94, 0.9))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(0, 120)
	v.add_child(_text)
	_more = _label(PIXEL, 18, Color(0.7, 0.7, 0.8))
	_more.text = "TAP ▼"
	_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_more)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 10)
	v.add_child(_choices)

	# Pause menu.
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", _style(Color(0.05, 0.045, 0.08, 0.97), Color(0.5, 0.45, 0.62), 4, 30))
	_menu.visible = false
	add_child(_menu)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 14)
	_menu.add_child(mv)
	var mt := _label(PIXEL, 26, Color(1.0, 0.45, 0.35))
	mt.text = "BREAK ROOM"
	mt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(mt)
	var resume := _button("BACK TO WORK")
	resume.pressed.connect(func(): _menu.visible = false)
	mv.add_child(resume)
	_rules_btn = _button("WENDY'S RULES")
	_rules_btn.pressed.connect(_show_rules)
	mv.add_child(_rules_btn)
	_sound_btn = _button("SOUND: ON")
	_sound_btn.pressed.connect(_toggle_sound)
	mv.add_child(_sound_btn)
	_voices_btn = _button("VOICES: ON")
	_voices_btn.pressed.connect(func():
		_voices_on = not _voices_on
		_voices_btn.text = "VOICES: ON" if _voices_on else "VOICES: OFF"
		if not _voices_on:
			_voice.stop())
	mv.add_child(_voices_btn)
	var again := _button("START THE NIGHT OVER")
	again.pressed.connect(_new_night)
	mv.add_child(again)

	# A card for the rules / anything read.
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", _style(Color(0.95, 0.93, 0.84), Color(0.55, 0.5, 0.4), 6, 30))
	_card.visible = false
	add_child(_card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 16)
	_card.add_child(cv)
	var ct := _label(PIXEL, 22, Color(0.3, 0.15, 0.1))
	ct.text = "THE RULES OF THE NIGHT SHIFT"
	ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(ct)
	var cb := _label(BODY, 36, Color(0.15, 0.12, 0.1))
	cb.text = "\n\n".join(Night.RULES)
	cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(cb)
	var close := _button("GOT IT")
	close.pressed.connect(func(): _card.visible = false)
	cv.add_child(close)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	move_child(_fade, _box.get_index())

	_build_title()
	_build_end()


func _build_title() -> void:
	_title = preload("res://scenes/story/title.gd").new()
	add_child(_title)
	_title.setup(self)


func _build_end() -> void:
	_end = Control.new()
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.visible = false
	add_child(_end)
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(shade)
	var holder := CenterContainer.new()
	holder.name = "Stack"
	_end.add_child(holder)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.02, 0.04, 0.78), Color(0.95, 0.75, 0.4, 0.6), 3, 34))
	holder.add_child(panel)
	var v := VBoxContainer.new()
	v.name = "Lines"
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	_end_title = _label(TITLE, 64, Color(1.0, 0.82, 0.5))
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_end_title)
	_end_lines = _label(BODY, 34, Color(0.96, 0.94, 0.9))
	_end_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_lines.add_theme_constant_override("line_spacing", 6)
	_end_lines.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_end_lines.add_theme_constant_override("outline_size", 6)
	v.add_child(_end_lines)
	_end_btn = _button("WORK ANOTHER NIGHT", 32)
	_end_btn.pressed.connect(_new_night)
	_end_btn.visible = false
	v.add_child(_end_btn)


## Lay everything out for the screen's shape (upright phone or sideways/PC),
## clear of the notch.
func _layout() -> void:
	var win := Vector2(DisplayServer.window_get_size())
	var wide := win.x > win.y
	get_tree().root.content_scale_size = Vector2i(1280, 720) if wide else Vector2i(720, 1280)
	var size := get_viewport_rect().size
	_inset = SafeArea.get_insets(size)
	var l := _inset.x + 24.0
	var t := _inset.y + 20.0
	var r := size.x - _inset.z - 24.0
	var b := size.y - _inset.w - 20.0
	_clock.position = Vector2(l, t + 6)
	_goals.position = Vector2(l, t + 60)
	_pause.position = Vector2(r - 88, t)
	_pause.size = Vector2(88, 88)
	_text.add_theme_font_size_override("font_size", 34 if wide else 40)
	for btn in _choices.get_children():
		btn.add_theme_font_size_override("font_size", 28 if wide else 32)
	var box_w := minf(r - l, 1000.0)
	_box.size = Vector2(box_w, 0)
	_box.custom_minimum_size = Vector2(box_w, 0)
	_text.custom_minimum_size = Vector2(box_w - 52.0, 120)
	for btn in _choices.get_children():
		btn.custom_minimum_size.x = box_w - 52.0
	_box.position = Vector2((size.x - box_w) * 0.5, b - _box.get_combined_minimum_size().y)
	_hint.size = Vector2(r - l, 80)
	_hint.position = Vector2(l, b - 80)
	_toast.size = Vector2(r - l, 80)
	_toast.position = Vector2(l, size.y * (0.3 if wide else 0.24))
	var mw := minf(560.0, r - l)
	_menu.custom_minimum_size = Vector2(mw, 0)
	_menu.size = Vector2(mw, 0)
	_menu.position = (size - _menu.get_combined_minimum_size()) * 0.5
	var cw := minf(620.0, r - l)
	_card.custom_minimum_size = Vector2(cw, 0)
	_card.size = Vector2(cw, 0)
	_card.position = (size - _card.get_combined_minimum_size()) * 0.5
	var es: Control = _end.get_node("Stack")
	es.position = Vector2(l, t)
	es.size = Vector2(r - l, b - t)
	var ew := minf(640.0, r - l) - 68.0
	_end_lines.custom_minimum_size = Vector2(ew, 0)
	_end_title.custom_minimum_size = Vector2(ew, 0)
	_end_btn.custom_minimum_size = Vector2(ew, 88)


# ---------------------------------------------------------------- sound

func _stream(path: String, loop := false) -> AudioStream:
	var s: AudioStream = load(path)
	if loop and s is AudioStreamOggVorbis:
		s = s.duplicate()
		s.loop = true
	return s


func _player_for(path: String, db: float, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _stream(path, loop)
	p.volume_db = db
	add_child(p)
	return p


func _build_sound() -> void:
	_amb = _player_for("res://audio/office_ac.ogg", -18.0, true)
	_drone = _player_for("res://audio/night_drone.ogg", -12.0, true)
	_music = _player_for("res://audio/office_title.ogg", -8.0, true)
	_score = AudioStreamPlayer.new()
	_score.volume_db = -60.0
	add_child(_score)
	_blip = _player_for("res://audio/blip.wav", -14.0)
	_blip.max_polyphony = 3
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = 0.0
	add_child(_voice)
	for n in ["ring", "bell", "creak", "busted", "lift_ding", "lift_doors", "print", "thump", "step_1", "step_2", "choice", "shimmer", "swell", "tapestop", "wrong", "page"]:
		var p := _player_for("res://audio/%s.wav" % n, -6.0)
		p.max_polyphony = 2
		_sfx[n] = p


## Crossfade the score to a cue (audio/score/<cue>.ogg, Creative Commons,
## tools/fetch_score.py). Without the file: the title falls back to Look
## Busy's "Clock-In Ballad", the night to the drone alone.
func _cue(id: String) -> void:
	var path := "res://audio/score/%s.ogg" % id
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = _stream(path, true)
	elif id == "title":
		stream = _stream("res://audio/office_title.ogg", true)
	if stream == null or (_score.playing and _score.stream == stream):
		if stream == null:
			_fade_score(-60.0)
		return
	var tw := create_tween()
	if _score.playing:
		tw.tween_property(_score, "volume_db", -50.0, 2.5)
	tw.tween_callback(func():
		_score.stream = stream
		_score.volume_db = -40.0
		_score.play())
	tw.tween_property(_score, "volume_db", SCORE_DB, 4.0)


func _fade_score(db: float, time := 3.0) -> void:
	var tw := create_tween()
	tw.tween_property(_score, "volume_db", db, time)
	if db <= -50.0:
		tw.tween_callback(_score.stop)


func _credits_text() -> String:
	var lines := ["NIGHT SHIFT", "A Humble House Games story, made with Claude.", ""]
	var f := FileAccess.open("res://audio/score/credits.json", FileAccess.READ)
	if f:
		var c = JSON.parse_string(f.get_as_text())
		if c is Dictionary and not c.is_empty():
			lines.append("MUSIC")
			for cue in c:
				lines.append("\"%s\" by %s (%s)\n%s" % [c[cue].title, c[cue].author, c[cue].license, c[cue].page])
	lines.append("\"Clock-In Ballad\" from Look Busy.")
	lines.append("")
	lines.append("VOICES: Kokoro (open-source, Apache 2.0). Dale: Orpheus via Groq.")
	lines.append("FONTS: Press Start 2P, Pixelify Sans, Inter (SIL OFL).")
	lines.append("ENGINE: Godot 4.3 (MIT).")
	return "\n".join(lines)


func _play(n: String, db := -6.0, pitch := 1.0) -> void:
	if _sfx.has(n):
		_sfx[n].volume_db = db
		_sfx[n].pitch_scale = pitch
		_sfx[n].play()


func _start_sound() -> void:
	if not _amb.playing:
		_amb.play()
	if not _drone.playing:
		_drone.play()


func _toggle_sound() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(0, _muted)
	_sound_btn.text = "SOUND: OFF" if _muted else "SOUND: ON"


# ---------------------------------------------------------------- flow

func _show_title() -> void:
	_state = TITLE_SCREEN
	_title.start()
	_update_hud()
	_hint.visible = false
	_box.visible = false
	_end.visible = false
	_fade_to(0.0, 1.5)


func _start_new() -> void:
	NightStory.wipe()
	story = NightStory.new()
	_begin()


func _continue() -> void:
	story = NightStory.new()
	story.load_save()
	_begin()


func _new_night() -> void:
	NightStory.wipe()
	get_tree().reload_current_scene()


func _begin() -> void:
	_start_sound()
	_title.stop()
	for id in office.screen_ids():
		office.screen(id)
	_menu.visible = false
	_apply_story_state()
	_player.position = START
	_yaw = 0.0
	_pitch = -0.2
	_state = WALK
	_cue("late" if story.has("blackout_done") else "night")
	_update_hud()
	_next_auto()


## Make the room match the story (after loading a save).
func _apply_story_state() -> void:
	office.set_night(1.0)
	office.set_lights(1.0)
	if story.has("blackout_done"):
		_after_blackout()
	if story.has("kip_free"):
		_kip_frozen = false
	if story.has("dale_going"):
		office.dale_stand()
	_set_printy_face()
	office.set_time(story.clock)


func _next_auto() -> void:
	var id := story.auto()
	if id == "blackout":
		_talk_with = ""
		_glide(_talk_view("phone"), id)
	elif id != "":
		_talk("", id)


## Start talking: glide to whoever (`who`, "" = stay put) and play `id`.
func _talk(who: String, id: String) -> void:
	_talk_with = who
	_walk_to = null
	if who != "":
		_glide(_talk_view(who), id)
	else:
		_state = TALK
		_play_node(id)


func _glide(to: Transform3D, then: String) -> void:
	if then != "" and _state == WALK:
		_play("swell", -16.0, randf_range(0.95, 1.05))
	_glide_from = _camera.global_transform
	_glide_to = to
	_glide_t = 0.0
	_after_glide = then
	_state = GLIDING
	_hint.visible = false


func _play_node(id: String) -> void:
	_node = id
	_state = TALK
	_box.visible = true
	_hint.visible = false
	for ev in story.enter(id):
		_event(ev)
	_pages = story.pages(id)
	if id == "end_people":
		_pages = _epilogue_pages()
	_page = 0
	_update_hud()
	if _pages.is_empty():
		_after_pages()
	else:
		_show_page()


func _show_page() -> void:
	_clear_choices()
	var p: Array = _pages[_page]
	_speaker = p[0]
	var cast: Array = Night.CAST.get(_speaker, Night.CAST.narr)
	_name.text = cast[0]
	_name.visible = cast[0] != ""
	_name.add_theme_color_override("font_color", cast[1])
	var narr := _speaker == "narr"
	_text.add_theme_color_override("font_color", Color(0.78, 0.8, 0.9) if narr else Color(0.97, 0.95, 0.9))
	_text.text = p[1]
	_text.visible_characters = 0
	_typing = true
	_cps = TYPE_CPS
	_voice.stop()
	var clip := _clip(_speaker, p[1])
	if _voices_on and clip != null:
		_voice.stream = clip
		_voice.play()
		# Type along with the voice, a little ahead of it.
		_cps = clampf(p[1].length() / maxf(0.4, clip.get_length() * 0.8), 14.0, 60.0)
	_more.visible = false
	_layout_box()


## The recorded voice for a page, if there is one (tools/record_voices.py).
func _clip(who: String, text: String) -> AudioStream:
	var path := "res://audio/voice/%s.ogg" % (who + "|" + text).md5_text().substr(0, 12)
	return load(path) if ResourceLoader.exists(path) else null


func _layout_box() -> void:
	await get_tree().process_frame
	_layout()


func _done_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	var last := _page >= _pages.size() - 1
	var has_choices := not story.choices(_node).is_empty()
	_more.visible = not (last and has_choices)
	if last and has_choices:
		_after_pages()


func _advance() -> void:
	if _typing:
		_done_typing()
		return
	if _page < _pages.size() - 1:
		_page += 1
		_play("page", -14.0, randf_range(0.9, 1.1))
		_show_page()
		return
	_after_pages()


func _after_pages() -> void:
	var cs := story.choices(_node)
	if cs.is_empty():
		var next := story.after(_node)
		if next != "":
			_play_node(next)
		else:
			_end_talk()
		return
	_show_choices(cs)


func _show_choices(cs: Array) -> void:
	_clear_choices()
	_more.visible = false
	if _pages.is_empty():
		_text.visible_characters = -1
	var inner := _box.custom_minimum_size.x - 52.0
	for c in cs:
		var b := _button(String(c.t))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(inner, 88)
		var i: int = c.i
		b.pressed.connect(func(): _choose(i))
		_choices.add_child(b)
	_layout_box()


func _clear_choices() -> void:
	for c in _choices.get_children():
		c.queue_free()


func _choose(i: int) -> void:
	_voice.stop()
	_play("choice", -9.0, randf_range(0.97, 1.03))
	var next := story.pick(_node, i)
	_clear_choices()
	if next == "":
		_end_talk()
	else:
		_play_node(next)


func _end_talk() -> void:
	_voice.stop()
	_box.visible = false
	_clear_choices()
	story.save()
	_update_hud()
	if _ending != "":
		_show_ending()
		return
	if _queue.size() > 0:
		var q: Callable = _queue.pop_front()
		q.call()
		return
	# Stand where you talked from, looking the way the camera looked.
	var xf := _camera.global_transform
	_player.global_position = Vector3(xf.origin.x, 0.0, xf.origin.z)
	var fwd := -xf.basis.z
	_yaw = atan2(-fwd.x, -fwd.z)
	_pitch = asin(clampf(fwd.y, -1.0, 1.0))
	_state = WALK
	_talk_with = ""
	_hint.visible = true
	_next_auto()


# ---------------------------------------------------------------- events

func _event(ev: String) -> void:
	match ev:
		"wake":
			_player.position = START
			_camera.global_transform = Transform3D(Basis.looking_at(Vector3(0, 1.0, -2.38) - Vector3(0.1, 1.05, -1.75), Vector3.UP), Vector3(0.1, 1.05, -1.75))
			_glide(_talk_view("desk"), "")
			_state = TALK
			_glide_len = 2.5
			_fade.color.a = 1.0
			_fade_to(0.0, 2.5)
			if story.has("looped"):
				_play("lift_ding", -4.0)
				_end_lines.text = ""
		"ring":
			_play("ring", -3.0)
			_shake = maxf(_shake, 0.15)
		"screens_smile":
			_smile = 4.0
		"goals":
			_toast_show("CLOCK OUT BY 6:00 AM")
		"rules":
			_toast_show("RULES CARD ADDED  ·  II TO READ")
		"item":
			_play("shimmer", -4.0)
			_toast_show(_item_toast())
		"buzz":
			_play("busted", -8.0, 1.4)
		"ding":
			_play("lift_ding", -4.0)
		"print":
			_printing = 2.2
		"flicker":
			_flicker = 1.2
			_play("thump", -10.0, 0.6)
		"shake":
			_shake = 0.6
			_play("thump", -2.0, 0.5)
			_play("wrong", -4.0)
		"kip_wake":
			_kip_frozen = false
		"dale_stand":
			office.dale_stand()
			_play("creak", -8.0, 0.8)
		"loop":
			_fade_to(1.0, 2.2)
			_play("lift_doors", -4.0)
			_drone.volume_db = -6.0
		"blackout":
			_blackout = 1.0
			_shake = 0.8
			_play("tapestop", -2.0)
			_play("thump", 0.0, 0.4)
			_score.stop()
			_cue("late")
			_after_blackout()
		"after_blackout":
			_kip_frozen = not story.has("kip_free")
			_printing = 3.0
		"finale":
			for id in office.screen_ids():
				office.screen(id, "• •\n‿", Color(1.0, 0.3, 0.25))
			_drone.volume_db = -4.0
		"end_bad":
			_ending = "bad"
			_play("wrong", -2.0, 0.7)
			for id in office.screen_ids():
				office.screen(id, "WELCOME,\nMANAGER", Color(1.0, 0.25, 0.2))
		"dawn":
			_dawn = 0.0
			_fade_score(-60.0, 5.0)
			_play("lift_ding", -2.0)
			var eye := Vector3(-0.2, 1.5, 1.7)
			_glide_from = _camera.global_transform
			_glide_to = Transform3D(Basis.looking_at(Vector3(-3.5, 1.4, -0.6) - eye, Vector3.UP), eye)
			_glide_t = 0.0
			_glide_len = 7.0
		"epilogue":
			_ending = "good"
	_set_printy_face()


## The sunrise epilogue, one page per person: out with you, or still here.
func _epilogue_pages() -> Array:
	var out := []
	var saved := story.saved()
	for id in ["wendy", "kip", "dale", "printy"]:
		out.append(["narr", Night.EPILOGUE[id] if saved.has(id) else Night.LEFT[id]])
	if story.has("coffee_friend"):
		out.append(["narr", Night.COFFEE_BYE])
	return out


func _item_toast() -> String:
	var got := 0
	for g in story.goals():
		if g[1]:
			got += 1
	return "GOT IT  ·  %d OF 3" % got


## The night after 3:33: the screens stay red, the lights stay low.
func _after_blackout() -> void:
	for id in office.screen_ids():
		if id != "printy":
			office.screen(id, ":)" if id != "kip" else "WELCOME TO\nHUMBLE HOUSE!\n\nQUESTION 4", Color(1.0, 0.25, 0.2))
	office.set_slot(4, Vector3(0.0, 1.2, -2.0), Color(0.45, 0.04, 0.03))
	office.set_slot(5, Vector3(2.6, 1.2, -0.9), Color(0.4, 0.03, 0.03))
	office.board_photo()
	_kip_frozen = not story.has("kip_free")


func _set_printy_face() -> void:
	if not office.screens.has("printy"):
		return
	var face := "o_o"
	if story.has("has_code"):
		face = "^_^"
	elif _printing > 0.0:
		face = ">_<"
	elif story.has("blackout_done"):
		face = "O_O"
	office.screen("printy", face)


func _toast_show(text: String) -> void:
	_toast.text = text
	_toast_t = 3.0


func _fade_to(a: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", a, time)


func _update_hud() -> void:
	_clock.text = story.clock_text()
	office.set_time(story.clock)
	var lines := []
	if story.has("intro_done") and not story.has("ended"):
		for g in story.goals():
			lines.append(("[X] " if g[1] else "[ ] ") + g[0])
	_goals.text = "\n".join(lines)
	_rules_btn.visible = story.has("rules")
	var in_game := _state != TITLE_SCREEN and _state != ENDING
	_clock.visible = in_game
	_goals.visible = in_game
	_pause.visible = in_game


func _show_rules() -> void:
	_menu.visible = false
	_card.visible = true
	_layout()


func _open_menu() -> void:
	if _state == TITLE_SCREEN or _state == ENDING:
		return
	_menu.visible = not _menu.visible
	_layout()


# ---------------------------------------------------------------- ending

func _show_ending() -> void:
	_state = ENDING
	_update_hud()
	_box.visible = false
	_hint.visible = false
	var lines := []
	if _ending == "bad":
		_end_title.text = "ENDING:\nPROMOTED"
		_end_title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
		_end.get_node("Shade").color = Color(0.12, 0.0, 0.0, 0.7)
		lines.append("The night shift has a new manager. The phones will ring on time.")
		lines.append("Wendy, Kip, Dale and the printer are still on the night shift. So are you. Forever, probably.")
		lines.append("There's another way out. You'd have to say no.")
	else:
		var saved := story.saved()
		_end_title.text = "CLOCKED OUT"
		_end_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
		_end.get_node("Shade").color = Color(0.05, 0.02, 0.0, 0.25)
		var names := {"wendy": "Wendy", "kip": "Kip", "dale": "Dale", "printy": "Printy"}
		var got := []
		for id in saved:
			got.append(names[id])
		lines.append("6:00 AM. You got %d of 4 off the night shift." % saved.size())
		if not got.is_empty():
			lines.append("Out with you: " + ", ".join(got) + ".")
		if saved.size() < 4:
			lines.append("Somebody's still waiting for someone to ask the right question.")
		lines.append(Night.LAST)
	_end_lines.text = "\n\n".join(lines)
	_end_lines.visible_characters = 0
	_end.visible = true
	_end.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(3.5 if _ending == "good" else 1.0)
	tw.tween_property(_end, "modulate:a", 1.0, 2.0)
	_layout()


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	_t += delta
	_tick_camera(delta)
	_tick_people(delta)
	_tick_effects(delta)
	_tick_type(delta)
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
	_toast.visible = _toast_t > 0.0
	if _state == ENDING and _end.modulate.a > 0.9:
		var n := _end_lines.text.length()
		if _end_lines.visible_characters >= 0:
			_end_lines.visible_characters += maxi(1, int(70.0 * delta))
			if _end_lines.visible_characters >= n:
				_end_lines.visible_characters = -1
				_end_btn.visible = true
				_layout()
	_tags.queue_redraw()


func _tick_type(delta: float) -> void:
	if not _typing:
		return
	var n := _text.text.length()
	var step := maxi(0, int(_cps * delta + randf()))
	var shown := mini(n, _text.visible_characters + step)
	_text.visible_characters = shown
	var cast: Array = Night.CAST.get(_speaker, Night.CAST.narr)
	_blip_n += step
	if cast[2] > 0.0 and _blip_n >= 3 and not _voice.playing:
		_blip_n = 0
		_blip.pitch_scale = cast[2] * randf_range(0.94, 1.06)
		_blip.play()
	if shown >= n:
		_done_typing()


func _tick_camera(delta: float) -> void:
	match _state:
		TITLE_SCREEN:
			pass  # title.gd films the office
		GLIDING:
			_glide_t = minf(1.0, _glide_t + delta / GLIDE)
			var k := _glide_t * _glide_t * (3.0 - 2.0 * _glide_t)
			var o := _glide_from.origin.lerp(_glide_to.origin, k)
			var q := Quaternion(_glide_from.basis.orthonormalized()).slerp(Quaternion(_glide_to.basis.orthonormalized()), k)
			_camera.global_transform = Transform3D(Basis(q), o)
			if _glide_t >= 1.0:
				if _after_glide != "":
					var id := _after_glide
					_after_glide = ""
					_play_node(id)
				elif _state == GLIDING:
					_state = TALK
		TALK:
			if _glide_t < 1.0:
				_glide_t = minf(1.0, _glide_t + delta / _glide_len)
				var k := _glide_t * _glide_t * (3.0 - 2.0 * _glide_t)
				var o := _glide_from.origin.lerp(_glide_to.origin, k)
				var q := Quaternion(_glide_from.basis.orthonormalized()).slerp(Quaternion(_glide_to.basis.orthonormalized()), k)
				_camera.global_transform = Transform3D(Basis(q), o)
		WALK:
			_tick_walk(delta)
		ENDING:
			if _ending == "good":
				var eye := Vector3(-0.6, 1.5, 1.4)
				var look := Vector3(-3.5, 1.4, -0.6)
				var target := Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)
				_camera.global_transform = _camera.global_transform.interpolate_with(target, minf(1.0, delta * 0.4))
	# Shake.
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		var s := _shake * 0.025
		_camera.global_position += Vector3(randf_range(-s, s), randf_range(-s, s), randf_range(-s, s))


func _tick_walk(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if pad.length() > 0.2:
		move += pad
	var look := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if look.length() > 0.2:
		_yaw -= look.x * delta * 2.4
		_pitch = clampf(_pitch - look.y * delta * 2.0, -1.2, 1.2)
	var basis := Basis(Vector3.UP, _yaw)
	var vel := Vector3.ZERO
	if move.length() > 0.1:
		_walk_to = null
		vel = basis * Vector3(move.x, 0, move.y).limit_length(1.0) * SPEED
	elif _walk_to != null:
		var d: Vector3 = _walk_to - _player.global_position
		d.y = 0.0
		if d.length() < 0.12:
			_walk_to = null
		else:
			vel = d.normalized() * SPEED
			# Turn gently toward where you're going.
			var want := atan2(-d.x, -d.z)
			_yaw = lerp_angle(_yaw, want, minf(1.0, delta * 2.5))
	_player.velocity = vel
	var before := _player.global_position
	_player.move_and_slide()
	if _walk_to != null and _player.global_position.distance_to(before) < SPEED * delta * 0.2:
		_walk_to = null
	if vel.length() > 0.1:
		_step(delta)
	var bob := sin(_t * 9.0) * 0.015 if vel.length() > 0.1 else 0.0
	_camera.global_transform = Transform3D(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch), _player.global_position + Vector3(0, EYE + bob, 0))


var _step_t := 0.0
func _step(delta: float) -> void:
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.42
		_play("step_1" if randf() < 0.5 else "step_2", -16.0, randf_range(0.9, 1.1))


func _tick_people(delta: float) -> void:
	for id in office.people:
		var p: Dictionary = office.people[id]
		if not is_instance_valid(p.head):
			continue
		var frozen: bool = id == "kip" and _kip_frozen
		p.body.scale = Vector3(1.0, 1.0 + (0.0 if frozen else sin(_t * 1.6 + id.length()) * 0.015), 1.0)
		var yaw := 0.0
		var pitch := 0.0
		if not frozen and (_talk_with == id or _camera.global_position.distance_to(p.head.global_position) < 2.6):
			var to_you: Vector3 = p.head.get_parent().to_local(_camera.global_position) - p.head.position
			yaw = clampf(atan2(to_you.x, to_you.z), -0.85, 0.85)
			pitch = clampf(-atan2(to_you.y, Vector2(to_you.x, to_you.z).length()) * 0.5, -0.3, 0.3)
		if frozen:
			yaw = -0.55 + sin(_t * 23.0) * 0.004
		p.head.rotation.y = lerp_angle(p.head.rotation.y, yaw, minf(1.0, delta * 4.0))
		p.head.rotation.x = lerpf(p.head.rotation.x, pitch, minf(1.0, delta * 4.0))
		var blink := not frozen and fmod(_t + id.length() * 1.3, 4.1) < 0.12
		for e in p.eyes:
			e.scale.y = 0.15 if blink else (1.25 if frozen else 1.0)
		var speaking: bool = (_typing or _voice.playing) and _state == TALK and _speaker.begins_with(id)
		var open := 0.6 + 0.6 * absf(sin(_t * 13.0)) if speaking or (frozen and _state != TALK) else 0.25
		p.mouth.scale.y = lerpf(p.mouth.scale.y, open, minf(1.0, delta * 20.0))


func _tick_effects(delta: float) -> void:
	# Lights: low and red after 3:33, flickers, and the dawn coming up.
	var lights := 1.0
	if story.has("blackout_done"):
		lights = 0.55
	if _blackout > 0.0:
		_blackout = maxf(0.0, _blackout - delta * 0.4)
		lights = 0.08 if fmod(_t, 0.3) < 0.2 or _blackout > 0.6 else 0.6
	if _flicker > 0.0:
		_flicker -= delta
		lights *= 0.15 if fmod(_t, 0.16) < 0.08 else 1.0
	if _dawn >= 0.0:
		_dawn = minf(1.0, _dawn + delta / 9.0)
		var k := _dawn * _dawn * (3.0 - 2.0 * _dawn)
		office.set_night(1.0 - k)
		lights = lerpf(0.55, 1.0, k)
		office.set_slot(4, Vector3(0.0, 1.2, -2.0), Color(0.45, 0.04, 0.03) * (1.0 - k))
		office.set_slot(5, Vector3(2.6, 1.2, -0.9), Color(0.4, 0.03, 0.03) * (1.0 - k))
		office.open_doors(clampf((_dawn - 0.5) * 2.0, 0.0, 1.0))
		if _dawn > 0.05 and not _music.playing:
			_music.play()
			_music.volume_db = -30.0
		_music.volume_db = lerpf(-30.0, -8.0, k)
		_drone.volume_db = lerpf(-12.0, -60.0, k)
		if _dawn > 0.15:
			for id in office.screen_ids():
				office.screen(id, "", Color(), true)
	office.set_lights(lights)
	if _smile > 0.0:
		_smile -= delta
		for id in ["desk", "board"]:
			office.screen(id, ":)" if _smile > 0.0 else "", Color(1.0, 0.85, 0.5) if _smile > 0.0 else Color())
	if _printing > 0.0:
		_printing -= delta
		if fmod(_printing, 0.7) < delta:
			office.print_page()
			_play("print", -10.0, randf_range(0.95, 1.05))
		if _printing <= 0.0:
			_set_printy_face()
	if _drone.playing and _dawn < 0.0:
		var want := -6.0 if story.has("blackout_done") else -12.0
		if _voice.playing:
			want -= 6.0
		_drone.volume_db = lerpf(_drone.volume_db, want, minf(1.0, delta * 0.5))


# ---------------------------------------------------------------- name tags

func _draw_tags() -> void:
	if _state != WALK:
		return
	var vp := get_viewport_rect().size
	var world_size := Vector2(_world_vp.size)
	if world_size.x <= 0:
		return
	var to_screen := vp / world_size
	for id in Night.SPOTS:
		if not _available(id):
			continue
		var s := _spot(id)
		var person: bool = s[3]
		var at: Vector3 = s[1] + Vector3(0, 0.38 if person else 0.12, 0)
		if _camera.is_position_behind(at):
			continue
		var dist := _camera.global_position.distance_to(at)
		var news := story.has_new(id)
		if not person and dist > 3.4 and not news:
			continue
		var p := _camera.unproject_position(at) * to_screen
		if p.x < -50 or p.x > vp.x + 50 or p.y < 0 or p.y > vp.y:
			continue
		var tag := _spot_name(id)
		var fs := 22 if person else 17
		var w := PIXEL.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var a := clampf(1.4 - dist / 8.0, 0.45, 1.0)
		_tags.draw_rect(Rect2(p.x - w * 0.5 - 10, p.y - fs - 12, w + 20, fs + 18), Color(0, 0, 0, 0.55 * a))
		_tags.draw_string(PIXEL, Vector2(p.x - w * 0.5, p.y - 4), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
		if news:
			var bob := sin(_t * 4.0) * 4.0
			_tags.draw_string(PIXEL, Vector2(p.x - 9, p.y - fs - 22 + bob), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1.0, 0.85, 0.3))


func _available(id: String) -> bool:
	return story.entry(id) != ""


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_open_menu()
			KEY_SPACE, KEY_ENTER, KEY_E:
				if _state == TALK and _choices.get_child_count() == 0:
					_advance()
				elif _state == WALK:
					_tap(get_viewport_rect().size * 0.5)
			KEY_1, KEY_2, KEY_3, KEY_4:
				var i: int = event.keycode - KEY_1
				if _state == TALK and i < _choices.get_child_count():
					_choices.get_child(i).emit_signal("pressed")
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A and _state == TALK and _choices.get_child_count() == 0:
			_advance()
		elif event.button_index == JOY_BUTTON_A and _state == WALK:
			_tap(get_viewport_rect().size * 0.5)
		elif event.button_index == JOY_BUTTON_START:
			_open_menu()
	if event is InputEventScreenTouch:
		if event.pressed:
			if _over_ui(event.position):
				return
			_touch[event.index] = {"at": event.position, "start": event.position, "t": _t, "moved": false}
		elif _touch.has(event.index):
			var t: Dictionary = _touch[event.index]
			_touch.erase(event.index)
			if not t.moved and _t - t.t < TAP_TIME * 2.0:
				_on_tap(event.position)
	elif event is InputEventScreenDrag and _touch.has(event.index):
		var t: Dictionary = _touch[event.index]
		if t.start.distance_to(event.position) > TAP_SLOP:
			t.moved = true
		if t.moved and _state == WALK:
			_yaw -= event.relative.x * LOOK_SENS
			_pitch = clampf(_pitch - event.relative.y * LOOK_SENS, -1.2, 1.2)
			_walk_to = null


## Is this point on a button or panel (they take their own taps)?
func _over_ui(pos: Vector2) -> bool:
	if _title.visible or _menu.visible or _card.visible:
		return true
	if _pause.visible and _pause.get_global_rect().grow(8).has_point(pos):
		return true
	for b in _choices.get_children():
		if b.get_global_rect().has_point(pos):
			return true
	return _end_btn.visible and _end_btn.get_global_rect().has_point(pos)


func _on_tap(pos: Vector2) -> void:
	if _menu.visible or _card.visible:
		return
	match _state:
		TALK:
			if _choices.get_child_count() == 0:
				_advance()
		WALK:
			_tap(pos)
		ENDING:
			if _end_lines.visible_characters >= 0:
				_end_lines.visible_characters = -1
				_end_btn.visible = true
				_layout()


## A tap while walking: the person or thing nearest the tap (by its spot on
## screen), else walk to that bit of floor.
func _tap(pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var to_world := Vector2(_world_vp.size) / vp
	var best := ""
	var best_d := PICK_RADIUS
	for id in Night.SPOTS:
		if not _available(id):
			continue
		var s := _spot(id)
		var at: Vector3 = s[1]
		if _camera.is_position_behind(at):
			continue
		var d := (_camera.unproject_position(at) / to_world).distance_to(pos)
		var lift := (_camera.unproject_position(at + Vector3(0, 0.38, 0)) / to_world).distance_to(pos)
		d = minf(d, lift)
		var radius := PICK_RADIUS * (1.25 if s[3] else 0.9)
		if d < radius and d / radius < best_d / PICK_RADIUS:
			best_d = d / radius * PICK_RADIUS
			best = id
	if best != "":
		_talk(best, story.entry(best))
		return
	# Floor: cast the tap through the camera onto y = 0.
	var wp := pos * to_world
	var from := _camera.project_ray_origin(wp)
	var dir := _camera.project_ray_normal(wp)
	if dir.y < -0.05:
		var hit := from + dir * (-from.y / dir.y)
		hit.x = clampf(hit.x, -3.2, 3.2)
		hit.z = clampf(hit.z, -2.7, 3.7)
		_walk_to = hit
