extends GutTest
## Every dev checkpoint plays through to where it says it is.


func test_checkpoints_reach_their_moment() -> void:
	var expect := [
		["prologue", 1], ["", 1], ["turn1", 1], ["", 1], ["arrive2", 2], ["blackout", 2], ["", 2],
		["arrive3", 3], ["dale_arrives", 3], ["finale", 3], ["", 3], ["", 3],
	]
	assert_eq(DevJump.CHECKPOINTS.size(), expect.size())
	for i in DevJump.CHECKPOINTS.size():
		var s := DevJump.reach(i)
		assert_eq(s.auto(), expect[i][0], DevJump.CHECKPOINTS[i][0])
		assert_eq(s.act(), expect[i][1], DevJump.CHECKPOINTS[i][0])
	assert_true(DevJump.reach(3).goals().all(func(g): return g[1]), "act one cards")
	assert_true(DevJump.reach(6).goals().all(func(g): return g[1]), "act two cards")
	assert_true(DevJump.reach(10).has("ending_good"))
	assert_eq(DevJump.reach(10).saved().size(), 7)
	assert_true(DevJump.reach(11).has("ending_bad"))


func test_every_collectible_has_a_flag_the_story_sets() -> void:
	const C := preload("res://data/collectibles.gd")
	var s := DevJump.reach(10)
	for f in C.CARDS.keys() + C.RELICS.keys():
		assert_true(s.has(f), "earned on the kind path: " + f)
