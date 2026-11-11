# Night Shift — read before every change

A talk-only story game: the Look Busy office after hours (split off from
`humble-house-studios/Look-busy`), one night from 11:58 PM to 6:00 AM, new
characters, choices and endings. Godot 4.3, GDScript only.

Samuel builds from his phone: Claude writes and pushes the code, GitHub builds a
web version, and he playtests it in Safari. Keep replies short and in plain
words, and handle git, builds and fixes yourself.
**End every reply with the play link:** https://humble-house-studios.github.io/Night-shift-/

## Same rules as Look Busy
- Base 720×1280, `canvas_items` + `expand`; sideways swaps to 1280×720
  (`main.gd` `_layout()`), phones lock portrait, desktop opens 1280×720.
- Compatibility renderer, nothing web-only (wrap in `OS.has_feature`), touch
  and mouse both work, buttons at least 88 px tall, respect the safe area,
  web build light (no threads).
- **Everything is hand-made**: build models from `addons/hh_minigames/_shared/handmade.gd`
  through `_box` / `_cyl` / `_lump` / `_ball` in `scenes/world/night_office.gd`
  (copied from Look Busy's office.gd so the two games look like one).
  People are puppets (`scenes/world/puppet.gd`, Look Busy's). No image generation.
- Sounds: Look Busy's in `audio/`, plus Night Shift's own from
  `tools/make_audio.py` (blip, print, thump, night drone).

## Where things are
- `data/night_script.gd`: the whole story. Nodes (who, pages, choices, flags,
  clock, events), who you can tap (`SPOTS`), which conversation each thing
  starts (`ENTRIES`, first condition that holds), conversations that start by
  themselves (`AUTO`: prologue, the 3:33 blackout), the rules card, the
  epilogue lines. Pages are `"text"` or `"speaker|text"`.
- `engine/story.gd` (`NightStory`): runs the script, no scene code. Flags,
  clock, items, save (`user://night_shift.cfg`).
- `scenes/world/night_office.gd`: builds the room, the people and props; lights
  (`set_night`, `set_lights`, `set_slot`), screens (`screen()`), Dale standing,
  printer pages, elevator doors, clocks.
- `scenes/story/main.gd`: camera, walking, tapping, the talk box, HUD, events
  (`_event()`: ring, blackout, print, dawn...), title and ending screens.

## Testing
- `godot --headless -s addons/gut/gut_cmdln.gd`: every link in the script
  exists and whole nights play to each ending (`tests/test_story.gd`). Add a
  test path when you add a branch.
- `xvfb-run -a godot --rendering-driver opengl3 -s res://tools/shot.gd`
  plays the whole night through the real UI, saves screenshots (`OUT=`,
  `SIZE=720x1280` for upright) and prints PASS/FAIL.
- After each change: push to `main`, wait for the build, send Samuel the play
  link with one line on what changed and what to playtest.
