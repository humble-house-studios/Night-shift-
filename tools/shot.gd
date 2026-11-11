extends SceneTree
## Plays the night through main.gd's own functions and saves screenshots.
## xvfb-run godot -s res://tools/shot.gd   (OUT=dir, SIZE=720x1280)
## Prints PASS/FAIL: the good ending is reached.

var main: Node
var out := OS.get_environment("OUT")
var n := 0


func _init() -> void:
	if out == "":
		out = "/tmp/ns_shots"
	DirAccess.make_dir_recursive_absolute(out)
	var size := OS.get_environment("SIZE")
	if size != "":
		var p := size.split("x")
		DisplayServer.window_set_size(Vector2i(int(p[0]), int(p[1])))
	NightStory.wipe()
	main = load("res://scenes/story/main.tscn").instantiate()
	root.add_child(main)
	_run()


func wait(sec: float) -> void:
	await create_timer(sec).timeout


func shot(tag: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var img := root.get_texture().get_image()
	n += 1
	img.save_png("%s/%02d_%s.png" % [out, n, tag])


## Talk through the current conversation, taking replies containing `wants`.
func talk(wants: Array = [], shots := false) -> void:
	var guard := 0
	while main._state != main.WALK and main._state != main.ENDING and guard < 400:
		guard += 1
		await wait(0.05)
		if main._state == main.GLIDING:
			continue
		if main._choices.get_child_count() > 0:
			if shots:
				await shot("choice_" + main._node)
			var pick: Button = main._choices.get_child(0)
			for w in wants:
				var found := false
				for b in main._choices.get_children():
					if b.text.contains(w):
						pick = b
						found = true
						break
				if found:
					break
			pick.emit_signal("pressed")
			await wait(0.1)
		elif main._state == main.TALK:
			main._advance()


func visit(id: String, wants: Array, shots := false) -> void:
	main._talk(id, main.story.entry(id))
	await wait(1.0)
	if shots:
		await shot("talk_" + id)
	await talk(wants, shots)
	await wait(0.4)
	# A blackout can start by itself after a conversation.
	if main._state == main.TALK:
		await wait(2.0)
		await shot("auto")
		await talk(["Rule one", "Pull"], true)


func _run() -> void:
	await wait(2.0)
	await shot("title")
	main._start_new()
	await wait(3.0)
	await shot("wake")
	await talk(["Answer"], true)
	await wait(0.5)
	await shot("walk")
	await visit("wendy", ["How long", "Why don't", "What's your name", "Nice to meet"], true)
	await visit("kip", ["home"], true)
	await visit("printy", ["Can I read", "think of"], true)
	await visit("coffee", ["Thank you"], true)
	await visit("dale", ["daughter", "let you work"], true)
	await wait(1.0)
	await shot("after_blackout")
	await visit("kip", ["KIP", "You passed"], true)
	await visit("printy", ["someone stayed"], true)
	await visit("wendy", ["Whose", "Promise"], true)
	await visit("dale", ["founder", "Why do you stay", "Front row"], true)
	await visit("board", [], true)
	await visit("clock", ["Who were you", "clocking out"], true)
	await wait(6.0)
	await shot("dawn")
	await wait(6.0)
	await shot("ending")
	var ok: bool = main.story.has("ending_good") and main.story.saved().size() == 4 and main._state == main.ENDING
	print("PASS" if ok else "FAIL state=%s flags=%s" % [main._state, main.story.flags])
	NightStory.wipe()
	quit(0 if ok else 1)
