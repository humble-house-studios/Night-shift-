class_name DevJump
extends RefCounted
## Dev mode: jump to any moment of the night. Each checkpoint is reached by
## really playing the story up to it (the same conversations and kind
## choices the tests take), so every flag, item and clock time is exactly
## what a player would have there. main.gd's DEV panel lists CHECKPOINTS.

const ON := true   # set false to hide the DEV buttons before shipping

## [label, steps]. A step is [thing to talk to ("auto" = what starts by
## itself), replies to take (first reply containing each word)].
const _ACT1 := [["auto", []], ["wendy", ["How long", "Why don't", "What's your name", "Nice to meet"]], ["kip", ["home"]], ["printy", ["think of"]], ["coffee", ["Thank you"]], ["dale", ["mint", "daughter", "upstairs", "let you work"]]]
const _ACT1B := [["auto", []], ["kip", ["KIP", "You passed"]], ["printy", ["someone stayed"]], ["wendy", ["Whose", "Promise"]]]
const _ACT2 := [["elevator", ["Badge in"]], ["auto", []], ["marge", ["How long", "get back"]], ["chad", ["hear me"]], ["brenda", ["go home", "someone's waiting"]]]
const _ACT2B := [["auto", ["Rule one"]], ["marge", ["Sit down"]], ["chad", ["What were you", "Leave the meeting"]], ["brenda", ["Are you okay"]]]
const _ACT3 := [["elevator2", ["Card, sign-off"]], ["auto", []], ["board3", ["home", "The people"]], ["ceo", []]]
const _ACT3B := [["auto", []], ["dale3", ["founder", "Why do you stay", "Front row"]]]

const CHECKPOINTS := [
	["ACT 1 · Wake up (11:58)", []],
	["ACT 1 · Explore the floor", [["auto", []]]],
	["ACT 1 · Lights go funny (1:11)", ["_ACT1"]],
	["ACT 1 · All 3 cards, take the elevator", ["_ACT1", "_ACT1B"]],
	["ACT 2 · Arrive on floor 2", ["_ACT1", "_ACT1B", ["elevator", ["Badge in"]]]],
	["ACT 2 · 3:33 blackout", ["_ACT1", "_ACT1B", "_ACT2"]],
	["ACT 2 · All 3 cards, exec elevator", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B"]],
	["ACT 3 · Arrive at the top", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B", ["elevator2", ["Card, sign-off"]]]],
	["ACT 3 · Dale comes up the stairs", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B", "_ACT3"]],
	["ACT 3 · The offer (5:59)", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B", "_ACT3", "_ACT3B"]],
	["ENDING · Field + credits", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B", "_ACT3", "_ACT3B", ["auto", ["Who were you", "coming with me"]]]],
	["ENDING · Promoted", ["_ACT1", "_ACT1B", "_ACT2", "_ACT2B", "_ACT3", "_ACT3B", ["auto", ["accept"]]]],
]


static func labels() -> Array:
	var out := []
	for c in CHECKPOINTS:
		out.append(c[0])
	return out


## The story as it stands at checkpoint i (the conversation that starts
## there, if any, is left for the game to play).
static func reach(i: int) -> NightStory:
	var s := NightStory.new()
	var groups := {"_ACT1": _ACT1, "_ACT1B": _ACT1B, "_ACT2": _ACT2, "_ACT2B": _ACT2B, "_ACT3": _ACT3, "_ACT3B": _ACT3B}
	var steps := []
	for part in CHECKPOINTS[i][1]:
		if part is String:
			steps.append_array(groups[part])
		else:
			steps.append(part)
	for st in steps:
		var id: String = s.auto() if st[0] == "auto" else s.entry(st[0])
		if id != "":
			_talk(s, id, st[1])
	return s


static func _talk(s: NightStory, start: String, wants: Array) -> void:
	var id := start
	var guard := 0
	while id != "" and guard < 80:
		guard += 1
		s.enter(id)
		var cs := s.choices(id)
		if cs.is_empty():
			id = s.after(id)
			continue
		var pick: Dictionary = cs[0]
		var found := false
		for w in wants:
			for c in cs:
				if String(c.t).contains(w):
					pick = c
					found = true
					break
			if found:
				break
		id = s.pick(id, pick.i)
