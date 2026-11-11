extends "res://tools/shot.gd"
## Screenshots of the trip between scenes and the 30 s head glitch.
## xvfb-run godot -s res://tools/fx_shot.gd   (OUT=dir, SIZE=720x1280)


func _run() -> void:
	await wait(2.0)
	main._title._press()
	await wait(0.5)
	main._start_new()
	await wait(3.0)
	await talk(["Answer"])
	await wait(0.5)
	main._talk("wendy", main.story.entry("wendy"))
	for t in [0.18, 0.18, 0.18, 0.18, 0.4]:
		await wait(t)
		await shot("warp")
	await wait(1.0)
	main.office.glitch_heads()
	for t in [0.05, 0.12, 0.3, 0.6]:
		await wait(t)
		await shot("glitch")
	await wait(3.3)
	await shot("glitch_back")
	await wait(1.5)
	await shot("after")
	print("PASS")
	quit()
