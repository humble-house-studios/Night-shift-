extends SceneTree
## Writes data/voice_lines.json: every spoken page in the script as
## {file, who, text}, the file being where the game looks the clip up
## (audio/voice/<md5("who|text")[:12]>.ogg). tools/record_voices.py records
## them in CI. Re-run after editing the script (tests/test_voices.gd checks):
##   godot --headless -s res://tools/export_lines.gd

const Night := preload("res://data/night_script.gd")


func _init() -> void:
	var f := FileAccess.open("res://data/voice_lines.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(lines(), "\t") + "\n")
	print("%d lines" % lines().size())
	quit()


static func lines() -> Array:
	var s := NightStory.new(Night)
	var seen := {}
	var out := []
	var add := func(who: String, text: String) -> void:
		var key := clip(who, text)
		if text.strip_edges() == "" or seen.has(key):
			return
		seen[key] = true
		out.append({"file": key, "who": who.trim_suffix("?"), "text": text})
	var ids: Array = Night.NODES.keys()
	ids.sort()
	for id in ids:
		for p in s.pages(id):
			add.call(p[0], p[1])
	for d in [Night.EPILOGUE, Night.LEFT]:
		for k in d:
			add.call("narr", d[k])
	add.call("narr", Night.COFFEE_BYE)
	return out


## The clip name for a page (main.gd looks it up the same way).
static func clip(who: String, text: String) -> String:
	return (who + "|" + text).md5_text().substr(0, 12)
