class_name NightStory
extends RefCounted
## The story engine: plain data in, no scene code. Runs the conversations in
## data/night_script.gd (who you can talk to, what they say, which replies
## show up), keeps the flags, the items and the clock, and saves it all to
## user://night_shift.cfg so a run picks up where it left off.
##
## A node: {who, say: [pages], choices: [...] | to: next node, set, clock,
## wait, event, end}. A page is "text" (said by the node's `who`) or
## "speaker|text" ("narr|..." = the narrator, "you|..." = you).
## A choice: {t: text, to: node, need: cond, set: [flags], once: true}.
## A cond is "" (always), "flag", "!flag", or an Array of those (all must hold).
## set: "flag" turns it on, "-flag" off.

const SAVE := "user://night_shift.cfg"
const START_CLOCK := 1438  # 11:58 PM, in minutes after the midnight before.
const DAWN := 1800         # 6:00 AM.

var flags := {}
var seen := {}
var clock := START_CLOCK
var data: Script


func _init(story_script: Script = null) -> void:
	data = story_script if story_script else load("res://data/night_script.gd")


# ---------------------------------------------------------------- reading

func node(id: String) -> Dictionary:
	return data.NODES.get(id, {})


func ok(cond) -> bool:
	if cond == null:
		return true
	if cond is Array:
		for c in cond:
			if not ok(c):
				return false
		return true
	var s := String(cond)
	if s == "":
		return true
	if s.begins_with("!"):
		return not flags.get(s.substr(1), false)
	return flags.get(s, false)


func has(flag: String) -> bool:
	return flags.get(flag, false)


## The conversation to start when you talk to `who` now ("" = nothing).
func entry(who: String) -> String:
	for e in data.ENTRIES.get(who, []):
		if ok(e[0]):
			return e[1]
	return ""


## Is there something you haven't heard from `who` yet? (The "!" over them.)
func has_new(who: String) -> bool:
	var id := entry(who)
	return id != "" and not seen.has(id) and data.NODES.get(id, {}).get("new", true)


## A conversation that should start by itself right now (prologue, blackout,
## ...): the first AUTO entry that holds and hasn't played.
func auto() -> String:
	for e in data.AUTO:
		if ok(e[0]) and not seen.has(e[1]):
			return e[1]
	return ""


## Pages of a node as [speaker, text] pairs.
func pages(id: String) -> Array:
	var n := node(id)
	var who: String = n.get("who", "narr")
	var out := []
	for p in n.get("say", []):
		var s := String(p)
		var bar := s.find("|")
		if bar > 0 and bar < 8:
			out.append([s.substr(0, bar), s.substr(bar + 1)])
		else:
			out.append([who, s])
	return out


## The replies that show for a node right now (each keeps its index in the node).
func choices(id: String) -> Array:
	var out := []
	var list: Array = node(id).get("choices", [])
	for i in list.size():
		var c: Dictionary = list[i]
		if not ok(c.get("need", "")):
			continue
		if c.get("once", false) and seen.has(id + "#" + str(i)):
			continue
		var shown := c.duplicate()
		shown["i"] = i
		out.append(shown)
	return out


# ---------------------------------------------------------------- playing

## Enter a node: apply its flags and clock. Returns its events (in order).
func enter(id: String) -> Array:
	var n := node(id)
	seen[id] = true
	_apply(n.get("set", []))
	if n.has("clock"):
		clock = int(n.clock)
	if n.has("wait"):
		clock = mini(clock + int(n.wait), DAWN - 1)
	var events := []
	var ev = n.get("event", "")
	if ev is Array:
		events.append_array(ev)
	elif String(ev) != "":
		events.append(String(ev))
	return events


## After the pages: where the node goes with no choice ("" = conversation over).
func after(id: String) -> String:
	return String(node(id).get("to", ""))


## Pick reply `i` (its index in the node). Returns the next node ("" = over).
func pick(id: String, i: int) -> String:
	var list: Array = node(id).get("choices", [])
	if i < 0 or i >= list.size():
		return ""
	var c: Dictionary = list[i]
	seen[id + "#" + str(i)] = true
	_apply(c.get("set", []))
	return String(c.get("to", ""))


func _apply(set_list) -> void:
	if set_list is String:
		set_list = [set_list]
	for f in set_list:
		var s := String(f)
		if s.begins_with("-"):
			flags.erase(s.substr(1))
		elif s != "":
			flags[s] = true


## The time on the clock, "11:58 PM".
func clock_text() -> String:
	var m := clock % 1440
	var h := m / 60
	var ampm := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m % 60, ampm]


## Which act (floor) you're on: 1, 2 or 3.
func act() -> int:
	return 3 if has("floor3") else (2 if has("floor2") else 1)


## What this floor's elevator wants, as [label, have].
func goals() -> Array:
	var out := []
	for g in data.GOALS[act()]:
		out.append([g[0], has(g[1])])
	return out


## Who you got out (for the ending): ids from data.SAVED that hold.
func saved() -> Array:
	var out := []
	for s in data.SAVED:
		if ok(s[1]):
			out.append(s[0])
	return out


## Back to 11:58 with what you've learned (the elevator loop): the clock and
## the night's events reset, the people you've met and the things you hold stay.
func loop_back() -> void:
	clock = START_CLOCK
	flags["looped"] = true


# ---------------------------------------------------------------- saving

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("night", "flags", flags)
	cfg.set_value("night", "seen", seen)
	cfg.set_value("night", "clock", clock)
	cfg.save(SAVE)


func load_save() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return false
	flags = cfg.get_value("night", "flags", {})
	seen = cfg.get_value("night", "seen", {})
	clock = int(cfg.get_value("night", "clock", START_CLOCK))
	return true


static func has_save() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return false
	var s: Dictionary = cfg.get_value("night", "seen", {})
	return not s.is_empty() and not cfg.get_value("night", "flags", {}).get("ended", false)


static func wipe() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
