extends GutTest
## The script holds together, and a whole night plays through to each ending.

const Night := preload("res://data/night_script.gd")
var s: NightStory


func before_each() -> void:
	s = NightStory.new(Night)


## Play a conversation, always taking the reply whose text contains `want`
## (or the first one). Returns the nodes visited.
func talk(start: String, wants: Array = []) -> Array:
	var visited := []
	var id := start
	var guard := 0
	while id != "" and guard < 60:
		guard += 1
		visited.append(id)
		s.enter(id)
		var cs := s.choices(id)
		if cs.is_empty():
			id = s.after(id)
			continue
		var pick: Dictionary = cs[0]
		for w in wants:
			for c in cs:
				if String(c.t).contains(w):
					pick = c
					break
			if pick != cs[0] or String(cs[0].t).contains(w):
				break
		id = s.pick(id, pick.i)
	return visited


func test_every_link_exists() -> void:
	for id in Night.NODES:
		var n: Dictionary = Night.NODES[id]
		var to := String(n.get("to", ""))
		assert_true(to == "" or Night.NODES.has(to), "%s -> %s" % [id, to])
		for c in n.get("choices", []):
			var ct := String(c.get("to", ""))
			assert_true(ct == "" or Night.NODES.has(ct), "%s choice -> %s" % [id, ct])
		for p in s.pages(id):
			assert_true(Night.CAST.has(p[0]), "%s speaker %s" % [id, p[0]])
	for who in Night.ENTRIES:
		for e in Night.ENTRIES[who]:
			assert_true(Night.NODES.has(e[1]), "entry %s" % e[1])


func test_prologue_runs_first() -> void:
	assert_eq(s.auto(), "prologue")
	talk("prologue")
	assert_eq(s.act(), 1)
	assert_true(s.has("intro_done"))
	assert_eq(s.auto(), "")
	assert_eq(s.clock_text(), "12:04 AM")


## Talk through whatever starts by itself (arrivals, the blackout...).
func autos(wants: Array = []) -> void:
	var guard := 0
	while s.auto() != "" and guard < 10:
		guard += 1
		talk(s.auto(), wants)


func _good_night() -> void:
	autos()
	# ACT ONE
	talk(s.entry("wendy"), ["How long", "Why don't", "What's your name", "Nice to meet"])
	talk(s.entry("kip"), ["home"])
	talk(s.entry("printy"), ["think of"])
	assert_eq(s.auto(), "", "no turn before meeting Dale")
	talk(s.entry("dale"), ["upstairs", "let you work"])
	assert_eq(s.auto(), "turn1")
	autos()
	assert_eq(s.clock_text(), "1:11 AM")
	talk(s.entry("kip"), ["KIP", "You passed"])
	talk(s.entry("printy"), ["someone stayed"])
	talk(s.entry("wendy"), ["Whose", "Promise"])
	assert_eq(s.act(), 1)
	assert_true(s.goals().all(func(g): return g[1]), "act one goals done")
	talk(s.entry("elevator"), ["Badge in"])
	assert_eq(s.act(), 2)
	# ACT TWO
	autos()
	talk(s.entry("marge"), ["How long", "get back"])
	talk(s.entry("chad"), ["hear me"])
	talk(s.entry("brenda"), ["go home", "someone's waiting"])
	assert_eq(s.auto(), "blackout")
	autos(["Rule one"])
	assert_eq(s.clock_text(), "3:33 AM")
	talk(s.entry("marge"), ["Sit down"])
	talk(s.entry("chad"), ["What were you", "Leave the meeting"])
	talk(s.entry("brenda"), ["Are you okay"])
	talk(s.entry("elevator2"), ["Card, sign-off"])
	assert_eq(s.act(), 3)
	# ACT THREE
	autos()
	talk(s.entry("board3"), ["home", "The people"])
	talk(s.entry("ceo"))
	assert_eq(s.auto(), "dale_arrives")
	talk("dale_arrives")
	talk(s.entry("dale3"), ["founder", "Why do you stay", "Front row"])
	assert_true(s.has("has_signature"))
	assert_eq(s.auto(), "finale")


func test_good_ending_saves_everyone() -> void:
	_good_night()
	talk("finale", ["Who were you", "coming with me", "ROOF"])
	assert_true(s.has("ending_good"))
	assert_eq(s.clock_text(), "6:00 AM")
	assert_eq(s.saved().size(), 7)


func test_bad_ending() -> void:
	_good_night()
	talk("finale", ["accept"])
	assert_true(s.has("ending_bad"))


func test_clock_never_reaches_dawn_early() -> void:
	_good_night()
	assert_lt(s.clock, NightStory.DAWN)


func test_cold_choices_still_get_you_up() -> void:
	autos()
	talk(s.entry("wendy"), ["How long", "Why don't", "What's your name", "Nice to meet"])
	talk(s.entry("kip"), ["home"])
	talk(s.entry("printy"), ["think of"])
	talk(s.entry("dale"), ["let you work"])
	autos()
	talk(s.entry("kip"), ["KIP", "Thanks for the badge", "module five"])
	talk(s.entry("printy"), ["Woo"])
	talk(s.entry("wendy"), ["Thanks, Wendy"])
	talk(s.entry("elevator"), ["Badge in"])
	autos()
	for who in ["marge", "chad", "brenda"]:
		talk(s.entry(who))
	autos(["Pull", "Rip"])
	talk(s.entry("marge"), ["keycard"])
	talk(s.entry("chad"), ["I need your sign-off", "Thanks."])
	talk(s.entry("brenda"), ["Gotta go", "Bye."])
	talk(s.entry("elevator2"), ["Card, sign-off"])
	autos()
	talk(s.entry("board3"), ["Who are you", "Time"])
	talk(s.entry("ceo"))
	autos()
	talk(s.entry("dale3"), ["founder", "Why do you stay", "I need the founder's", "Thanks."])
	talk("finale", ["coming with me", "ROOF"])
	assert_true(s.has("ending_good"))
	assert_eq(s.saved(), ["wendy"], "only Wendy (her card comes with yours)")


func test_elevator_down_loops_back() -> void:
	autos()
	talk(s.entry("elevator"), ["Peel"])
	assert_true(s.has("looped"))
	assert_eq(s.clock_text(), "11:58 PM")
	talk(s.entry("elevator"), ["Leave"])


func test_once_choices_hide() -> void:
	autos()
	s.enter("kip_quiz")
	var before := s.choices("kip_quiz").size()
	s.pick("kip_quiz", 0)
	assert_eq(s.choices("kip_quiz").size(), before - 1)


func test_save_round_trip() -> void:
	autos()
	s.save()
	var t := NightStory.new(Night)
	assert_true(t.load_save())
	assert_eq(t.clock, s.clock)
	assert_true(t.has("intro_done"))
	NightStory.wipe()


func test_spots_have_floors() -> void:
	for id in Night.SPOTS:
		assert_true(Night.SPOTS[id].size() == 5 and Night.ENTRIES.has(id), id)
