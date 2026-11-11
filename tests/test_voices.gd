extends GutTest
## data/voice_lines.json (what CI records) matches the script. If this fails,
## run: godot --headless -s res://tools/export_lines.gd

const Export := preload("res://tools/export_lines.gd")


func test_voice_lines_up_to_date() -> void:
	var f := FileAccess.open("res://data/voice_lines.json", FileAccess.READ)
	assert_not_null(f, "voice_lines.json exists")
	var saved = JSON.parse_string(f.get_as_text())
	var now := Export.lines()
	assert_eq(saved.size(), now.size(), "same number of lines")
	var names := {}
	for l in saved:
		names[l.file] = true
	for l in now:
		assert_true(names.has(l.file), "recorded list has: " + l.text.left(40))


func test_clip_name_matches_main() -> void:
	assert_eq(Export.clip("dale", "Hi"), ("dale" + "|" + "Hi").md5_text().substr(0, 12))
