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
	assert_true(s.has("intro_done"))
	assert_eq(s.auto(), "")
	assert_eq(s.clock_text(), "12:04 AM")


func _good_night() -> void:
	talk(s.auto())
	talk(s.entry("wendy"), ["How long", "Why don't", "What's your name", "Nice to meet"])
	talk(s.entry("kip"), ["home"])
	talk(s.entry("printy"), ["think of"])
	assert_eq(s.auto(), "", "no blackout before meeting Dale")
	talk(s.entry("dale"), ["let you work"])
	assert_eq(s.auto(), "blackout")
	talk("blackout", ["Rule one"])
	assert_eq(s.clock_text(), "3:33 AM")
	talk(s.entry("kip"), ["KIP", "You passed"])
	talk(s.entry("printy"), ["someone stayed"])
	talk(s.entry("wendy"), ["Whose", "Promise"])
	talk(s.entry("dale"), ["founder", "Why do you stay", "Front row"])


func test_good_ending_saves_everyone() -> void:
	_good_night()
	assert_true(s.has("has_timecard") and s.has("has_signature") and s.has("has_code"))
	assert_eq(s.entry("clock"), "finale")
	talk("finale", ["Who were you", "clocking out"])
	assert_true(s.has("ending_good"))
	assert_eq(s.clock_text(), "6:00 AM")
	assert_eq(s.saved().size(), 4)


func test_bad_ending() -> void:
	_good_night()
	talk("finale", ["accept"])
	assert_true(s.has("ending_bad"))


func test_clock_never_reaches_dawn_early() -> void:
	_good_night()
	assert_lt(s.clock, NightStory.DAWN)


func test_elevator_loops_back() -> void:
	talk(s.auto())
	talk(s.entry("wendy"), ["Can I just leave", "look around"])
	talk(s.entry("elevator"), ["anyway"])
	assert_true(s.has("looped"))
	assert_eq(s.clock_text(), "11:58 PM")
	assert_eq(s.entry("elevator"), "elevator_again")
	assert_true(s.has("met_wendy"), "you keep what you learned")


func test_once_choices_hide() -> void:
	talk(s.auto())
	s.enter("kip_quiz")
	var before := s.choices("kip_quiz").size()
	s.pick("kip_quiz", 0)
	assert_eq(s.choices("kip_quiz").size(), before - 1)


func test_save_round_trip() -> void:
	talk(s.auto())
	s.save()
	var t := NightStory.new(Night)
	assert_true(t.load_save())
	assert_eq(t.clock, s.clock)
	assert_true(t.has("intro_done"))
	NightStory.wipe()
