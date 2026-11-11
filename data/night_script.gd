extends RefCounted
## NIGHT SHIFT: the whole script. One night at Humble House Games, 11:58 PM
## to 6:00 AM, in three acts up the corporate ladder. You fell asleep at your
## desk on your first day; the Night Manager says nobody goes home until the
## top floor approves it. ACT ONE, the floor you work on (Wendy, Kip,
## Printy, Dale). ACT TWO, middle management (Marge, Chad, Brenda; 3:33 AM).
## ACT THREE, the top (the board, the empty chair, the founder). Each floor's
## elevator wants three things, and each one sits with someone the building
## has kept far longer than you. Say no at the top and the elevator finds a
## button it never had: ROOF.
##
## Format: engine/story.gd. Speakers: narr, you, dale, wendy, kip, printy,
## manager, coffee. Who talks first is ENTRIES[thing] (first cond that holds).

## Name, name colour, and the pitch of their text blips.
const CAST := {
	"narr": ["", Color(0.72, 0.74, 0.82), 0.0],
	"you": ["YOU", Color(0.75, 0.9, 1.0), 1.0],
	"dale": ["DALE", Color(0.98, 0.78, 0.45), 0.75],
	"wendy": ["WENDY", Color(0.6, 0.95, 0.75), 0.85],
	"wendy?": ["NIGHTS", Color(0.6, 0.95, 0.75), 0.85],
	"kip": ["KIP", Color(1.0, 0.6, 0.85), 1.45],
	"printy": ["PRINTY-9000", Color(0.7, 1.0, 0.45), 1.9],
	"manager": ["NIGHT MANAGER", Color(1.0, 0.36, 0.32), 0.5],
	"coffee": ["COFFEE MAKER", Color(0.85, 0.6, 0.4), 0.6],
	"marge": ["MARGE", Color(1.0, 0.5, 0.5), 0.9],
	"chad": ["CHAD", Color(0.5, 0.85, 1.0), 1.1],
	"brenda": ["BRENDA, HR", Color(1.0, 0.7, 0.85), 1.3],
	"board": ["THE BOARD", Color(0.85, 0.82, 0.7), 0.55],
}

## Conversations that start by themselves, in order.
const AUTO := [
	["", "prologue"],
	[["met_dale", "met_wendy", "met_kip", "met_printy"], "turn1"],
	["floor2", "arrive2"],
	[["floor2", "met_marge", "met_chad", "met_brenda"], "blackout"],
	["floor3", "arrive3"],
	[["floor3", "heard_board", "met_ceo"], "dale_arrives"],
	[["floor3", "has_signature"], "finale"],
]

## Who gets you out, for the ending: [id, cond].
const SAVED := [
	["wendy", "wendy_card"],
	["kip", "kip_saved"],
	["printy", "printy_happy"],
	["marge", "marge_saved"],
	["chad", "chad_saved"],
	["brenda", "brenda_saved"],
	["dale", "dale_going"],
]

## What each floor's elevator wants: [label, flag] per act.
const GOALS := {
	1: [["TIMECARD", "has_timecard"], ["ASSOCIATE BADGE", "has_badge"], ["OVERRIDE CODE", "has_code"]],
	2: [["KEYCARD", "has_keycard"], ["SIGN-OFF", "has_signoff"], ["FORM 6-0-0", "has_form"]],
	3: [["HEAR THE BOARD", "heard_board"], ["MEET THE CEO", "met_ceo"], ["FOUNDER'S SIGNATURE", "has_signature"]],
}
const ACT_NAMES := {1: "ACT ONE: THE NIGHT SHIFT", 2: "ACT TWO: MIDDLE MANAGEMENT", 3: "ACT THREE: THE TOP"}

const ENTRIES := {
	# ---- floor one
	"phone": [["act1_turn", "phone_after"], ["", "phone_idle"]],
	"desk": [["act1_turn", "desk_after"], ["", "desk_look"]],
	"wendy": [
		["wendy_card", "wendy_done"],
		[["wendy_named", "act1_turn"], "wendy_give"],
		["wendy_named", "wendy_wait"],
		["met_wendy", "wendy_again"],
		["", "wendy_meet"],
	],
	"kip": [
		["has_badge", "kip_done"],
		["act1_turn", "kip_frozen"],
		["met_kip", "kip_again"],
		["", "kip_meet"],
	],
	"printy": [
		["has_code", "printy_done"],
		["act1_turn", "printy_finish"],
		["met_printy", "printy_again"],
		["", "printy_meet"],
	],
	"dale": [
		["act1_turn", "dale_turn1"],
		["met_dale", "dale_again"],
		["", "dale_meet"],
	],
	"coffee": [["coffee_friend", "coffee_friend"], ["coffee_mad", "coffee_mad"], ["", "coffee_meet"]],
	"board": [["act1_turn", "board_after"], ["", "board_look"]],
	"window": [["act1_turn", "window_after"], ["", "window_look"]],
	"clock": [["", "clock_locked"]],
	"elevator": [["", "elevator1"]],
	# ---- floor two
	"marge": [
		["has_keycard", "marge_done"],
		["blackout_done", "marge_turn"],
		["met_marge", "marge_again"],
		["", "marge_meet"],
	],
	"chad": [
		["has_signoff", "chad_done"],
		["blackout_done", "chad_turn"],
		["met_chad", "chad_again"],
		["", "chad_meet"],
	],
	"brenda": [
		["has_form", "brenda_done"],
		["blackout_done", "brenda_turn"],
		["met_brenda", "brenda_again"],
		["", "brenda_meet"],
	],
	"theo": [["", "theo_desk"]],
	"fax": [["printy_happy", "fax_printy"], ["", "fax_idle"]],
	"elevator2": [["", "elevator2"]],
	# ---- floor three
	"board3": [["heard_board", "board3_again"], ["", "board3_meet"]],
	"ceo": [["met_ceo", "ceo_again"], ["", "ceo_meet"]],
	"dale3": [["has_signature", "dale_done"], ["dale_here", "dale_truth"]],
	"portrait": [["", "portrait"]],
	"window3": [["", "window3"]],
	"phone3": [["", "phone3"]],
	"elevator3": [["", "elevator3"]],
}

const NODES := {
	# ------------------------------------------------------------ prologue
	"prologue": {
		"who": "narr", "clock": 1438, "event": "wake",
		"say": [
			"You wake up with your cheek on the keyboard.",
			"The office is dark. The ceiling lights are off, but every monitor is still on, humming.",
			"Your screen says: SHIFT EXTENDED. THANK YOU FOR YOUR DEDICATION.",
			"you|...My first day. I fell asleep on my first day.",
		],
		"to": "prologue_ring",
	},
	"prologue_ring": {
		"who": "narr", "event": "ring",
		"say": ["The phone on your desk rings."],
		"choices": [
			{"t": "Answer it.", "to": "manager_hello", "set": ["answered_first"]},
			{"t": "Let it ring.", "to": "prologue_let"},
		],
	},
	"prologue_let": {
		"who": "narr", "event": "ring",
		"say": [
			"It rings again.",
			"And again. On the third ring there's a click. The speakerphone turns itself on.",
		],
		"to": "manager_hello",
		"set": ["let_ring"],
	},
	"manager_hello": {
		"who": "manager", "event": "screens_smile",
		"say": [
			"Good evening! This is the Night Manager.",
			"Congratulations. You've been selected for the night shift.",
		],
		"choices": [
			{"t": "Who is this?", "to": "manager_who"},
			{"t": "I'm going home.", "to": "manager_home"},
			{"t": "Selected? I fell asleep.", "to": "manager_asleep"},
		],
	},
	"manager_who": {
		"who": "manager",
		"say": ["I'm management! I handle the hard calls, so nobody else has to make them. Isn't that nice?"],
		"to": "manager_rules",
	},
	"manager_home": {
		"who": "manager",
		"say": ["Of course! Everyone goes home eventually. Just as soon as the build is approved."],
		"to": "manager_rules",
	},
	"manager_asleep": {
		"who": "manager",
		"say": ["And you'll never be more rested! That's what we call initiative."],
		"to": "manager_rules",
	},
	"manager_rules": {
		"who": "manager",
		"say": [
			"Clocking out is simple! Clocking out is approved at the top floor. You'll just need to get there.",
			"The elevator takes associates and above. Bring it your TIMECARD, an ASSOCIATE BADGE, and the OVERRIDE CODE.",
			"Standard procedure! Please enjoy the complimentary coffee. Have a productive night.",
			"narr|Click. The line goes dead. Somewhere across the office, a mop squeaks.",
		],
		"set": ["intro_done"], "clock": 1444, "event": "goals",
	},

	# ------------------------------------------------------------ your desk
	"phone_idle": {
		"who": "narr", "new": false,
		"say": ["A beige desk phone. The speaker light is still on, very faintly, like it's listening."],
	},
	"phone_after": {
		"who": "narr", "new": false,
		"say": ["The phone cord has been pulled out of the wall. The speaker light is still on."],
	},
	"phone_dead": {"who": "narr", "new": false, "say": ["Just a phone."]},
	"desk_look": {
		"who": "narr", "new": false,
		"say": [
			"SHIFT EXTENDED. THANK YOU FOR YOUR DEDICATION.",
			"Below it, a progress bar: BUILD APPROVAL 0%. It hasn't moved.",
		],
	},
	"desk_after": {
		"who": "narr", "new": false,
		"say": ["Your screen just says: STAY. Then, after a moment, it adds a smiley face. That's worse."],
	},

	# ------------------------------------------------------------ Wendy
	"wendy_meet": {
		"who": "wendy?", "set": ["met_wendy"], "wait": 25,
		"say": [
			"narr|A woman in a grey uniform mops a perfect square of carpet. She never steps outside it. Her name tag just says NIGHTS.",
			"Evening. You're new. Stay off the wet part.",
		],
		"choices": [
			{"t": "Do you know what's going on?", "to": "wendy_going"},
			{"t": "Can I just leave?", "to": "wendy_leave"},
		],
	},
	"wendy_going": {
		"who": "wendy?",
		"say": ["Sure. You stayed past midnight on a deadline week. Building notices that. Building gets attached."],
		"to": "wendy_rules",
	},
	"wendy_leave": {
		"who": "wendy?",
		"say": ["Everybody asks that. Then they try the elevator. Then they ask nicer."],
		"to": "wendy_rules",
	},
	"wendy_rules": {
		"who": "wendy?", "set": ["rules"], "event": "rules",
		"say": [
			"narr|She hands you a laminated card from her cart. It's been laminated several times.",
			"The rules. Read 'em. Live by 'em.",
			"narr|ONE: Never answer the phone on the third ring.",
			"narr|TWO: If the printer starts printing by itself, let it finish.",
			"narr|THREE: Never ride the elevator down.",
			"narr|FOUR: If someone asks you to stay, say no. Politely.",
			"narr|FIVE: Never let the coffee hear you complain.",
		],
		"to": "wendy_rules2",
	},
	"wendy_rules2": {
		"who": "wendy?",
		"choices": [
			{"t": "These are a joke, right?", "to": "wendy_joke"},
			{"t": "Where do I get my timecard?", "to": "wendy_card_ask"},
			{"t": "How long have you worked nights?", "to": "wendy_years"},
			{"t": "Thanks. I'll look around.", "to": ""},
		],
	},
	"wendy_joke": {
		"who": "wendy?",
		"say": ["Rule five was a joke. Then a guy named Gary complained about the coffee in '09.", "We don't talk about Gary. Nobody can. That's the thing about Gary."],
		"to": "wendy_rules2",
	},
	"wendy_card_ask": {
		"who": "wendy?",
		"say": [
			"I keep the timecards. Timecards are for people who are leaving.",
			"Lot of folks ask for a card. Nobody asks for anything else.",
		],
		"to": "wendy_rules2",
	},
	"wendy_years": {
		"who": "wendy?",
		"say": [
			"Thirty-one years. Started the week this building opened.",
			"Haven't seen a sunrise since 1995. Night shift ends at six. I'm always just finishing the floor at six.",
		],
		"choices": [
			{"t": "Why don't you leave?", "to": "wendy_why"},
			{"t": "Okay. Bye.", "to": ""},
		],
	},
	"wendy_why": {
		"who": "wendy?",
		"say": [
			"Somebody's got to keep the floors clean for whoever's stuck here. That's the job.",
			"Nobody ever asks after the janitor. You notice that? Thirty-one years.",
		],
		"choices": [
			{"t": "What's your name? Your real one.", "to": "wendy_name"},
			{"t": "That's rough. Anyway, my timecard?", "to": "wendy_rude"},
		],
	},
	"wendy_name": {
		"who": "wendy", "set": ["wendy_named"],
		"say": [
			"narr|She stops mopping. The square isn't finished. She doesn't seem to care.",
			"...Wendy. Wendy Okafor.",
			"Huh. Been a while since I said that out loud. It sounds older than I remember.",
		],
		"choices": [
			{"t": "About that timecard...", "to": "wendy_give", "need": "act1_turn"},
			{"t": "Nice to meet you, Wendy.", "to": "wendy_later", "need": "!act1_turn"},
		],
	},
	"wendy_later": {
		"who": "wendy",
		"say": ["Go meet the others, kid. Come back when the lights go funny. They always go funny, first night."],
	},
	"wendy_rude": {
		"who": "wendy?",
		"say": ["Mop's got better manners than you. Mop at least looks at the floor it's talking to."],
	},
	"wendy_again": {
		"who": "wendy?", "new": false,
		"say": ["Still here? Read the card. The card's kept me alive longer than the dental plan."],
		"choices": [
			{"t": "How long have you worked nights?", "to": "wendy_years"},
			{"t": "Where do I get my timecard?", "to": "wendy_card_ask"},
			{"t": "Never mind.", "to": ""},
		],
	},
	"wendy_wait": {
		"who": "wendy", "new": false,
		"say": ["Lights haven't gone funny yet. Go say hi to everybody. Even the printer. Especially the printer."],
	},
	"wendy_give": {
		"who": "wendy", "wait": 30,
		"say": [
			"Lights went funny. Told you. Most new folks hide under a desk.",
			"narr|She unhooks a ring of keys from her belt and opens a little tin box on the cart. Two cards inside. One has your name on it already.",
			"Here. Your card.",
		],
		"choices": [
			{"t": "Whose is the other one?", "to": "wendy_other"},
			{"t": "Thanks, Wendy.", "to": "wendy_thanks"},
		],
	},
	"wendy_other": {
		"who": "wendy",
		"say": [
			"Mine. Never punched it. Never had a reason to be done by six.",
			"...Take it up with you. All the way up. Only clock in this building that punches OUT is at the top.",
		],
		"choices": [
			{"t": "I'll get you out. Promise.", "to": "wendy_promise"},
			{"t": "I can't promise anything.", "to": "wendy_honest"},
		],
	},
	"wendy_thanks": {
		"who": "wendy",
		"say": ["Don't thank me. Thank me at six.", "narr|She hesitates, then hands you a second card. It says WENDY OKAFOR in faded ink. Never punched.", "Take mine up top too. If it works for you, maybe it works for me."],
		"set": ["has_timecard", "wendy_card"], "event": "item",
	},
	"wendy_promise": {
		"who": "wendy", "set": ["has_timecard", "wendy_card"], "event": "item",
		"say": ["Don't promise. Just do it. Promises are how this building gets you."],
	},
	"wendy_honest": {
		"who": "wendy", "set": ["has_timecard", "wendy_card"], "event": "item",
		"say": ["Good. Honest. Building hates honest. Take it anyway."],
	},
	"wendy_done": {
		"who": "wendy", "new": false,
		"say": ["Got the cards? Then go get the rest. I'll be mopping. I'm always mopping."],
	},

	# ------------------------------------------------------------ Kip
	"kip_meet": {
		"who": "kip", "set": ["met_kip", "clue_founder"], "wait": 25,
		"say": [
			"narr|A young guy in a lanyard sits bolt upright in front of a training video. His eyes are very wide. His coffee has a skin on it.",
			"OH! Hi!! A new hire! I'm Kip! I'm an intern!",
			"Day one thousand and ninety-six of onboarding!",
		],
		"choices": [
			{"t": "Day... how many?", "to": "kip_days"},
			{"t": "What are you watching?", "to": "kip_video"},
		],
	},
	"kip_days": {
		"who": "kip",
		"say": [
			"One thousand and ninety-six! I'm almost done! I'm on Module 4! Module 4 is the last one!",
			"I've been on Module 4 for one thousand and ninety-one days.",
		],
		"to": "kip_video",
	},
	"kip_video": {
		"who": "kip",
		"say": [
			"It's the welcome video! Look, that's the founder at the start. In the garage. He's got so much hair.",
			"narr|On the screen, a young man with a big moustache waves from a garage full of beige computers. He has a purple pen behind his ear.",
			"narr|You've seen that moustache tonight. You've seen that purple pen.",
			"Then there's a quiz. Question four keeps getting me.",
		],
		"to": "kip_quiz",
	},
	"kip_quiz": {
		"who": "kip",
		"say": ["\"What is the company's most valuable asset?\" I've tried everything! Watch."],
		"choices": [
			{"t": "Try \"synergy\".", "to": "kip_wrong1", "once": true},
			{"t": "Try \"our IP\".", "to": "kip_wrong2", "once": true},
			{"t": "Try \"our people\".", "to": "kip_people", "once": true},
			{"t": "Kip. When did you last go home?", "to": "kip_home"},
		],
	},
	"kip_wrong1": {
		"who": "kip", "event": "buzz",
		"say": ["narr|BZZT. INCORRECT. A cartoon handshake on the screen frowns.", "Synergy was my first guess too! Day four!"],
		"to": "kip_quiz",
	},
	"kip_wrong2": {
		"who": "kip", "event": "buzz",
		"say": ["narr|BZZT. INCORRECT. PLEASE REWATCH THE VIDEO.", "I've rewatched it two thousand times. I can do the whole thing with my eyes closed. Sometimes I do!"],
		"to": "kip_quiz",
	},
	"kip_people": {
		"who": "kip", "event": "buzz",
		"say": [
			"narr|BZZT. INCORRECT. Then, in smaller letters: CORRECT ANSWER: YOUR TIME.",
			"...Huh. It's never shown me that before.",
			"My time. That's, um. That's kind of a lot of time, actually.",
		],
		"to": "kip_quiz",
	},
	"kip_home": {
		"who": "kip",
		"say": [
			"Home? Oh, I can't go home without finishing onboarding. That would be quitting!",
			"My mom keeps calling. I tell her I'm almost done. I'm always almost done.",
			"You should go meet everyone! Wendy's great. Dale's great. The printer is... a lot.",
		],
	},
	"kip_again": {
		"who": "kip", "new": false,
		"say": ["Still on question four! Still going strong! Strong-ish!"],
		"to": "kip_quiz",
	},
	"kip_frozen": {
		"who": "kip",
		"say": [
			"narr|Kip hasn't moved since the lights went out. His face is lit red by the screen. He's mouthing the welcome video along with it, word for word.",
			"narr|The quiz is back on question four. The answer box is blinking. A little badge printer next to the monitor is warmed up and waiting.",
			"manager|He's doing so well. Please don't distract him.",
		],
		"choices": [
			{"t": "Type \"your time\".", "to": "kip_time"},
			{"t": "Type \"KIP\".", "to": "kip_free"},
			{"t": "Leave him be.", "to": ""},
		],
	},
	"kip_time": {
		"who": "narr", "event": "buzz",
		"say": [
			"CORRECT. THANK YOU FOR YOUR TIME. A new module appears: MODULE 5 OF 400.",
			"Kip's lips start moving faster. You delete it before he notices.",
		],
		"to": "kip_frozen",
	},
	"kip_free": {
		"who": "kip", "set": ["kip_free", "has_badge"], "wait": 30, "event": ["ding", "kip_wake", "item"],
		"say": [
			"narr|You type his name. K-I-P. Enter.",
			"narr|DING. CORRECT. YOUR MOST VALUABLE ASSET IS YOU. ONBOARDING COMPLETE.",
			"narr|The little printer spits out a badge: ASSOCIATE. Kip blinks. He blinks a lot, like his eyes forgot how. Then he clips the badge onto your shirt.",
			"...Is that it? Am I... onboarded?",
		],
		"choices": [
			{"t": "You passed, Kip. You can go home.", "to": "kip_thanks", "set": ["kip_saved"]},
			{"t": "Technically, I passed it for you.", "to": "kip_thanks_joke", "set": ["kip_saved"]},
			{"t": "Great. Thanks for the badge.", "to": "kip_cold"},
		],
	},
	"kip_thanks": {
		"who": "kip",
		"say": [
			"Home. I'm going to call my mom. I'm going to call her and say I'm DONE.",
			"Oh! Hey. Tell Dale I said thanks for the video. He's the guy in it, you know. Purple pen. He thinks nobody noticed.",
		],
	},
	"kip_thanks_joke": {
		"who": "kip",
		"say": [
			"Then you're my mentor! I've never had a mentor! I've had a laminated card!",
			"Oh! Tell Dale thanks for the video. He's the guy in it, you know. Purple pen. He thinks nobody noticed.",
		],
	},
	"kip_cold": {
		"who": "kip",
		"say": ["Oh. Right. Sure! Work first! Always work first.", "narr|He turns back to the screen. MODULE 5 OF 400 is already loading."],
		"choices": [
			{"t": "...Kip. You passed. You can go home.", "to": "kip_thanks", "set": ["kip_saved"]},
			{"t": "Good luck with module five.", "to": ""},
		],
	},
	"kip_done": {
		"who": "kip", "new": false,
		"say": ["I'm practicing what I'll say to my mom. \"Hi mom. I'm onboarded.\" Too formal? It's too formal."],
		"choices": [
			{"t": "You can go home, Kip.", "to": "kip_thanks", "need": "!kip_saved", "set": ["kip_saved"]},
			{"t": "Say it however you want. She'll be happy.", "to": ""},
		],
	},

	# ------------------------------------------------------------ Printy
	"printy_meet": {
		"who": "printy", "set": ["met_printy"], "wait": 25, "event": "print",
		"say": [
			"narr|The big copier by the wall whirs awake as you get close. A page slides out. Then another.",
			"HELLO. I AM PRINTY-9000. I HAVE BEEN PRINTING THE SAME POEM SINCE 1998.",
			"IT IS NOT FINISHED. THERE IS A PAPER JAM IN MY SOUL.",
		],
		"choices": [
			{"t": "Can I read it?", "to": "printy_poem"},
			{"t": "Do you have the override code?", "to": "printy_code"},
		],
	},
	"printy_poem": {
		"who": "printy", "event": "print", "set": ["printy_read"],
		"say": [
			"\"ODE TO THE NIGHT SHIFT\". BY PRINTY.",
			"narr|The hum of lights that no one shuts, / the coffee left to stew,",
			"narr|the one who built the house sits low / and counts what he is owed,",
			"narr|the mop goes round, the clock goes round, / the intern's eyes go too,",
			"THE LAST LINE IS MISSING. I HAVE TRIED 400,000 LAST LINES. THEY ARE ALL IN THE RECYCLING.",
		],
		"to": "printy_menu",
	},
	"printy_code": {
		"who": "printy",
		"say": [
			"AFFIRMATIVE. THE OVERRIDE CODE IS IN MY PRINT QUEUE.",
			"QUEUE: 1. POEM (BLOCKING). 2. OVERRIDE CODE. 3. GARY.",
			"I CANNOT PRINT ITEM 2 UNTIL ITEM 1 IS DONE. I AM SORRY. I AM A PRINTER.",
		],
		"to": "printy_menu",
	},
	"printy_menu": {
		"who": "printy",
		"choices": [
			{"t": "Can I read the poem?", "to": "printy_poem", "need": "!printy_read"},
			{"t": "What's item 3?", "to": "printy_gary"},
			{"t": "I'll think of a last line.", "to": "printy_bye"},
		],
	},
	"printy_gary": {
		"who": "printy",
		"say": ["I DO NOT WANT TO PRINT GARY. NOBODY WANTS ME TO PRINT GARY."],
		"to": "printy_menu",
	},
	"printy_bye": {
		"who": "printy",
		"say": ["THANK YOU. TAKE YOUR TIME. I HAVE HAD TWENTY-EIGHT YEARS. WHAT IS ANOTHER FIVE MINUTES."],
	},
	"printy_again": {
		"who": "printy", "new": false,
		"say": ["STILL JAMMED. STILL HOPEFUL. MOSTLY JAMMED."],
		"to": "printy_menu",
	},
	"printy_finish": {
		"who": "printy", "event": "print",
		"say": [
			"narr|The copier is printing by itself, fast, the same page over and over. Wendy's rule two: let it finish.",
			"narr|You wait. It slows. It stops. One warm page sits in the tray.",
			"THE LIGHTS WENT FUNNY AND I GOT SCARED. I PRINT WHEN I AM SCARED.",
			"I THINK I AM READY FOR THE LAST LINE NOW. WILL YOU GIVE IT TO ME?",
		],
		"choices": [
			{"t": "\"...and someone stayed to help them through.\"", "to": "printy_line_kind"},
			{"t": "\"...and nobody gets paid for this, it's true.\"", "to": "printy_line_funny"},
			{"t": "\"...and that's the poem. It's done. Woo.\"", "to": "printy_line_woo"},
		],
	},
	"printy_line_kind": {
		"who": "printy", "set": ["poem_done", "printy_happy", "has_code"], "wait": 30, "event": ["print", "item"],
		"say": [
			"...",
			"IT RHYMES. IT SCANS. IT IS TRUE. I DID NOT KNOW A POEM COULD BE TRUE.",
			"POEM PRINTED. 1 OF 1. QUEUE ADVANCING.",
			"narr|A small slip slides out: OVERRIDE CODE 0600. Underneath, in tiny letters: THANK YOU FOR READING.",
		],
	},
	"printy_line_funny": {
		"who": "printy", "set": ["poem_done", "has_code"], "wait": 30, "event": ["print", "item"],
		"say": [
			"HA. HA. HA. THAT IS THE SOUND OF ME LAUGHING. I PRINTED IT AS A SEPARATE PAGE.",
			"IT IS ALSO TRUE. QUEUE ADVANCING.",
			"narr|A slip slides out: OVERRIDE CODE 0600.",
		],
	},
	"printy_line_woo": {
		"who": "printy", "set": ["poem_done", "has_code"], "wait": 30, "event": ["print", "item"],
		"say": [
			"...THAT IS NOT A LINE. THAT IS AN ESCAPE.",
			"BUT IT IS DONE. AND DONE IS A KIND OF BEAUTIFUL. QUEUE ADVANCING.",
			"narr|A slip slides out: OVERRIDE CODE 0600.",
		],
	},
	"printy_done": {
		"who": "printy", "new": false,
		"say": ["QUEUE EMPTY. I HAVE NEVER BEEN EMPTY. IT IS VERY QUIET IN HERE. I LIKE IT."],
	},

	# ------------------------------------------------------------ Dale
	"dale_meet": {
		"who": "dale", "set": ["met_dale"], "wait": 25,
		"say": [
			"narr|Dale, from Accounts Receivable, sits under his desk lamp in the only warm light in the office. He looks completely at home.",
			"Hey, new hire! Still here? Me too. Always am.",
			"Just squaring away some receivables. You want a mint? They're from 2014 but they're individually wrapped.",
		],
		"choices": [
			{"t": "Dale, something is very wrong here.", "to": "dale_wrong"},
			{"t": "Who's the Night Manager?", "to": "dale_manager"},
			{"t": "Sure, I'll take a mint.", "to": "dale_mint"},
		],
	},
	"dale_wrong": {
		"who": "dale",
		"say": [
			"Wrong? Nah. It's just quiet. Quiet's not wrong. Quiet's when you can finally hear yourself think.",
			"...Not that you'd want to. Ha! Joke. That was a joke.",
		],
		"to": "dale_menu",
	},
	"dale_manager": {
		"who": "dale",
		"say": [
			"Oh, he's harmless. Mostly. He's just very... committed to the build.",
			"Tip from an old-timer: whatever he offers you, say you'll think about it. Then don't.",
		],
		"to": "dale_menu",
	},
	"dale_mint": {
		"who": "dale", "set": ["dale_mint"],
		"say": [
			"narr|It tastes like a mint that has given up.",
			"Atta kid. You know what my daughter calls these? Grandpa candy. I'm not a grandpa. She's nine.",
		],
		"to": "dale_menu",
	},
	"dale_menu": {
		"who": "dale",
		"choices": [
			{"t": "You have a daughter?", "to": "dale_daughter", "once": true},
			{"t": "Can you sign me out?", "to": "dale_sign_no"},
			{"t": "What's upstairs?", "to": "dale_upstairs", "once": true},
			{"t": "I'll let you work.", "to": ""},
		],
	},
	"dale_daughter": {
		"who": "dale", "set": ["dale_kid"],
		"say": [
			"Lucy. Piano. She's got a recital in the morning. Nine o'clock. Front row's for parents.",
			"narr|He looks at the #1 DAD mug for a long time.",
			"I'll make it. I always say I'll make it.",
		],
		"to": "dale_menu",
	},
	"dale_sign_no": {
		"who": "dale",
		"say": ["Me? I'm accounts receivable, buddy. I can't sign anything. I can't even sign for the mints. Signing out's an upstairs thing."],
		"to": "dale_menu",
	},
	"dale_upstairs": {
		"who": "dale",
		"say": [
			"Floor two's middle management. Marge, Chad, Brenda in HR. Good people. Stuck people. Same thing, up there.",
			"And the top floor... the board. And the CEO. Nobody's met him. Ha. Nobody.",
			"narr|He laughs a little too long at that.",
		],
		"to": "dale_menu",
	},
	"dale_turn1": {
		"who": "dale", "new": false,
		"say": ["Lights went funny, huh? First night's always like that. You get the badge, the card, the code... and then up you go. Up's the only way out of here."],
		"to": "dale_menu",
	},
	"dale_again": {
		"who": "dale", "new": false,
		"say": ["Back again! Mint? No pressure. They're not going anywhere. Neither am I. Ha."],
		"to": "dale_menu",
	},

	# ------------------------------------------------------------ the coffee
	"coffee_meet": {
		"who": "narr", "new": false,
		"say": ["The coffee maker. Complimentary. The pot is full and black and absolutely still, like a pond at night."],
		"choices": [
			{"t": "Pour a cup.", "to": "coffee_cup"},
			{"t": "\"This coffee smells terrible.\"", "to": "coffee_complain", "need": "!rules"},
			{"t": "\"This coffee smells terrible.\" (Rule five...)", "to": "coffee_complain", "need": "rules"},
			{"t": "\"Thank you, coffee.\"", "to": "coffee_thank"},
		],
	},
	"coffee_cup": {
		"who": "narr",
		"say": ["It's lukewarm and tastes like the inside of a filing cabinet. You keep that thought to yourself. Probably wise."],
	},
	"coffee_complain": {
		"who": "coffee", "set": ["coffee_mad"], "event": "flicker",
		"say": ["narr|The lights flicker. The red power dot on the coffee maker turns slowly to face you. You didn't know it could turn.", "...noted."],
	},
	"coffee_thank": {
		"who": "coffee", "set": ["coffee_friend"],
		"say": ["narr|The coffee maker gurgles. It sounds pleased. A fresh drip falls into the pot, plink, like a little bow.", "...you're welcome."],
	},
	"coffee_mad": {
		"who": "coffee", "new": false,
		"say": ["narr|The red dot follows you. The coffee is darker than before."],
		"choices": [
			{"t": "\"I'm sorry. You're good coffee.\"", "to": "coffee_sorry"},
			{"t": "Back away slowly.", "to": ""},
		],
	},
	"coffee_sorry": {
		"who": "coffee", "set": ["-coffee_mad", "coffee_friend"],
		"say": ["...apology accepted. don't let it happen again.", "narr|The red dot swivels back. The lights steady."],
	},
	"coffee_friend": {
		"who": "coffee", "new": false,
		"say": ["narr|The coffee maker purrs at you. You did not know coffee makers could purr."],
	},

	# ------------------------------------------------------------ the board
	"board_look": {
		"who": "narr", "new": false,
		"say": [
			"EMPLOYEE OF THE MONTH. Twelve framed photos.",
			"They're all the same person. Each month he looks a little more tired, a little more grey, a little more like the wallpaper.",
			"The last frame is empty. There's already a little brass plate under it. It has your name on it.",
		],
	},
	"board_after": {
		"who": "narr", "new": false,
		"say": ["The empty frame has a photo in it now. It's you, asleep on your keyboard, taken from where the phone sits.", "Nope. Nope nope nope."],
	},

	# ------------------------------------------------------------ the window
	"window_look": {
		"who": "narr", "new": false,
		"say": ["The city is lit up but nothing moves. No cars. No planes. A clock tower across the bay says 11:58.", "It has said 11:58 the whole time you've been looking."],
	},
	"window_after": {
		"who": "narr", "new": false,
		"say": ["The clock tower across the bay has started moving again. It's catching up, fast, like it's trying to get somewhere before six."],
	},

	# ------------------------------------------------------------ the punch clock
	"clock_locked": {
		"who": "narr", "new": false,
		"say": ["A grey punch clock by the elevator. It only punches IN. Somebody has scratched into the side with a key: OUT IS UP."],
	},
	"elevator_ride": {
		"who": "narr", "event": "loop",
		"say": [
			"You peel back the tape and press DOWN. The doors open at once, like it was waiting. You step in. Down.",
			"The floor counter ticks. 2. 1. G. B. -1. -2. -9. -33.",
			"DING.",
		],
		"to": "loop_wake",
	},
	"loop_wake": {
		"who": "narr", "clock": 1438, "set": ["looped"], "event": "wake",
		"say": [
			"You wake up with your cheek on the keyboard.",
			"The clock says 11:58 PM. But you remember everything. Everyone you talked to is right where you left them.",
			"Somewhere across the office, Wendy calls out: \"Told you. Rule three. The only way out is up.\"",
		],
	},

	# ------------------------------------------------------------ 3:33

	# ------------------------------------------------------------ the end

	# ============================================================ ACT ONE: the lights go funny
	"turn1": {
		"who": "narr", "clock": 1511, "set": ["act1_turn"], "event": "turn1",
		"say": [
			"1:11 AM.",
			"The lights stutter. Every monitor on the floor blinks red, all at once, and every one of them says the same thing: FLOOR 2 IS WAITING.",
			"Across the room, Kip has gone very still. The copier starts printing by itself.",
			"manager|Reminder! The elevator takes associates and above. You're doing so well. Everybody here is doing so well. Forever.",
		],
	},
	# ============================================================ ACT ONE: elevator
	"elevator1": {
		"who": "narr", "new": false,
		"say": ["The elevator. Two buttons: UP, and a DOWN button with tape over it. A card reader and a keypad glow under UP."],
		"choices": [
			{"t": "Badge in, key the code, punch the card.", "to": "act1_up", "need": ["has_timecard", "has_badge", "has_code"]},
			{"t": "Press UP.", "to": "elevator_locked"},
			{"t": "Peel the tape off DOWN.", "to": "elevator_ride", "need": "!looped"},
			{"t": "Leave it.", "to": ""},
		],
	},
	"elevator_locked": {
		"who": "narr",
		"say": ["Nothing. A little screen: ASSOCIATES AND ABOVE. PLEASE PRESENT TIMECARD, BADGE AND OVERRIDE CODE."],
	},
	"act1_up": {
		"who": "narr", "wait": 20,
		"say": [
			"You badge in. The reader beeps. You key 0-6-0-0. The card goes in the slot and comes back stamped, in red: PROMOTED.",
			"The doors open. Behind you, the floor goes quiet, like the whole room is watching you go.",
			"wendy|Don't get comfortable up there, kid. Up there, comfortable is how they keep you.",
			"dale|Floor two! Look at you. Tell Marge I said hi. Actually, don't. She'll want to walk and talk.",
		],
		"to": "ride2",
	},
	"ride2": {
		"who": "narr", "event": "ride2", "set": ["floor2"],
		"say": ["The doors close. The counter ticks over: 1. 2."],
	},

	# ============================================================ ACT TWO: middle management
	"arrive2": {
		"who": "narr", "clock": 1564, "event": "act2",
		"say": [
			"ACT TWO. MIDDLE MANAGEMENT.",
			"Floor two. A cubicle farm under humming tubes of light. Forty desks. Forty phones. Nobody at any of them.",
			"Somewhere between the rows, footsteps. Even. Patient. They don't stop.",
			"manager|Welcome to middle management! Up here, nobody goes home until somebody signs off. Nobody has signed off since 2019.",
			"manager|To reach the executive floor, the elevator requires a KEYCARD, a SIGN-OFF, and FORM 6-0-0. Have a synergistic night!",
		],
	},

	# ---- Marge, the floor manager, who never stops walking
	"marge_meet": {
		"who": "marge", "set": ["met_marge"], "wait": 25,
		"say": [
			"narr|A woman in a red blazer walks the aisle between the cubicles. She has worn a path into the carpet, a grey ring all the way round the floor.",
			"Walk with me. I don't stop. Marge. Floor manager.",
			"Desk fourteen, empty. Desk fifteen, empty. Desk sixteen... empty. Good. Everybody's exactly where they should be.",
		],
		"choices": [
			{"t": "How long have you been walking?", "to": "marge_long"},
			{"t": "Can I have the keycard to the top?", "to": "marge_card"},
			{"t": "Everyone's gone, Marge.", "to": "marge_gone"},
		],
	},
	"marge_long": {
		"who": "marge",
		"say": [
			"Twenty-one years. I clocked in for a walk-through in 2004 and I never found a good place to stop.",
			"You know what happens to a manager who stops walking? Somebody notices there's nothing left to manage.",
		],
		"to": "marge_menu",
	},
	"marge_card": {
		"who": "marge",
		"say": ["The executive card? I have it. Twenty-one years. Never used it. You don't go up there. Up there is where they decide about down here."],
		"to": "marge_menu",
	},
	"marge_gone": {
		"who": "marge",
		"say": ["Gone is a word for people who stopped walking. Desk seventeen, empty. Desk eighteen..."],
		"to": "marge_menu",
	},
	"marge_menu": {
		"who": "marge",
		"choices": [
			{"t": "How long have you been walking?", "to": "marge_long", "once": true},
			{"t": "Can I have the keycard to the top?", "to": "marge_card", "once": true},
			{"t": "I'll let you get back to it.", "to": "marge_bye"},
		],
	},
	"marge_bye": {
		"who": "marge",
		"say": ["I never left it. Desk nineteen, empty."],
	},
	"marge_again": {
		"who": "marge", "new": false,
		"say": ["narr|She passes you again. Same pace. Same path.", "Still here? Walk or get out of the aisle."],
		"to": "marge_menu",
	},
	"marge_turn": {
		"who": "marge", "wait": 30,
		"say": [
			"narr|Marge has stopped. Right in the middle of her path. She's looking down at her own feet like they belong to somebody else.",
			"The lights went out and I... stopped. Twenty-one years. I don't know what to do with my hands.",
		],
		"choices": [
			{"t": "Sit down, Marge. Just for a minute.", "to": "marge_sit"},
			{"t": "Great. Since you're stopped: the keycard?", "to": "marge_cold"},
		],
	},
	"marge_sit": {
		"who": "marge", "set": ["has_keycard", "marge_saved"], "event": ["item", "marge_sit"],
		"say": [
			"narr|You pull out a chair from desk fourteen. She looks at it for a long time. Then she sits.",
			"Oh. Oh, my feet. I forgot I had feet. They're furious.",
			"narr|She unclips a gold card from her lanyard and puts it in your hand. It's warm. It's never been used.",
			"Go on up. I'll... I think I'll just sit here. And not manage anything. For a little while.",
		],
	},
	"marge_cold": {
		"who": "marge", "set": ["has_keycard"], "event": "item",
		"say": [
			"narr|She hands it over without looking at you. Then she starts walking again. Slower now.",
			"Desk fourteen. Empty. Desk fifteen...",
		],
	},
	"marge_done": {
		"who": "marge", "new": false,
		"say": ["Up you go. Mind the aisle."],
		"choices": [
			{"t": "Sit down, Marge.", "to": "marge_sit_late", "need": "!marge_saved"},
			{"t": "See you, Marge.", "to": ""},
		],
	},
	"marge_sit_late": {
		"who": "marge", "set": ["marge_saved"], "event": "marge_sit",
		"say": ["narr|She stops. She sits. She doesn't say anything, but she doesn't get back up either."],
	},

	# ---- Chad, the VP frozen on a video call from his boat
	"chad_meet": {
		"who": "chad", "set": ["met_chad"], "wait": 25,
		"say": [
			"narr|A TV on a wheeled cart. On it, a man in a vest on a sailboat, frozen mid-word. The caption: CHAD (VP, WORKING FROM HOME). RECONNECTING...",
			"So what I'm hearing is— is— i— hearing—",
			"narr|He freezes again with his mouth open. The little spinning wheel spins.",
		],
		"choices": [
			{"t": "Chad? Can you hear me?", "to": "chad_hear"},
			{"t": "Have you tried turning it off and on again?", "to": "chad_off"},
		],
	},
	"chad_hear": {
		"who": "chad",
		"say": ["Bro— you're on mu— —circle back— —per my last— ...", "narr|Frozen. The date in the corner of the call says MARCH 2019."],
	},
	"chad_off": {
		"who": "narr",
		"say": ["You look for a power button. The TV's cord goes into the wall, and the wall goes somewhere much further down. It's not your button to push. Not yet."],
	},
	"chad_again": {
		"who": "chad", "new": false,
		"say": ["—what I'm hear— —ing is— —bro—"],
	},
	"chad_turn": {
		"who": "chad", "wait": 30, "event": "chad_clear",
		"say": [
			"narr|The blackout rebooted the router. Chad's picture is crisp now. He's blinking. He looks at you, and he looks terrified.",
			"Oh my god. You can hear me? Like, actually? I've been on this call since March 2019.",
			"My boat drifted out of range during a quarterly sync. I froze. And everybody just... left the meeting. One by one. I watched them leave.",
		],
		"choices": [
			{"t": "What were you trying to say?", "to": "chad_say"},
			{"t": "I need your sign-off, Chad.", "to": "chad_sign_cold"},
		],
	},
	"chad_say": {
		"who": "chad",
		"say": [
			"I was going to say: so what I'm hearing is... I want to go home.",
			"I have two kids. They were eight and ten. I think they're teenagers now. I think one of them can drive.",
		],
		"choices": [
			{"t": "Leave the meeting, Chad. Go home.", "to": "chad_leave"},
			{"t": "Sign me off first. Then go.", "to": "chad_sign_cold"},
		],
	},
	"chad_leave": {
		"who": "chad", "set": ["has_signoff", "chad_saved"], "event": ["item", "chad_leave"],
		"say": [
			"Leave the meeting. I can just... leave the meeting.",
			"Okay. Signing you off first, champ. Least I can do. SIGNED OFF: CHAD. There. Real signature. Not a bro one.",
			"narr|He reaches toward his screen. The call ends. For a second the TV shows a sunrise over water, then just a blue screen that says MEETING ENDED.",
		],
	},
	"chad_sign_cold": {
		"who": "chad", "set": ["has_signoff"], "event": "item",
		"say": [
			"Right. Sure. Business. SIGNED OFF: CHAD.",
			"narr|He stays on the call. Nobody has ever told him he's allowed to leave it.",
		],
		"choices": [
			{"t": "...You can leave the meeting, Chad.", "to": "chad_leave_late"},
			{"t": "Thanks.", "to": ""},
		],
	},
	"chad_leave_late": {
		"who": "chad", "set": ["chad_saved"], "event": "chad_leave",
		"say": ["...Can I? Huh. Leave meeting. Peace, champ.", "narr|MEETING ENDED."],
	},
	"chad_done": {
		"who": "narr", "new": false,
		"say": ["The TV says MEETING ENDED. For the first time in years, it's true."],
		"choices": [
			{"t": "Tell him he can leave.", "to": "chad_leave_late", "need": "!chad_saved"},
			{"t": "Leave it.", "to": ""},
		],
	},

	# ---- Brenda from HR, whose smile doesn't move
	"brenda_meet": {
		"who": "brenda", "set": ["met_brenda"], "wait": 25,
		"say": [
			"narr|A glass office in the corner. A pink cardigan, a kitten poster that says HANG IN THERE, and a woman smiling so hard it looks like it hurts.",
			"Hi!! Brenda! HR! How can I help? Complaints? Concerns? Feelings? We have a form for that!",
		],
		"choices": [
			{"t": "I'd like to go home.", "to": "brenda_form"},
			{"t": "Are you... okay? Your smile hasn't moved.", "to": "brenda_smile"},
		],
	},
	"brenda_form": {
		"who": "brenda",
		"say": [
			"Love that for you! That's a FORM 6-0-0. Request To Go Home. Just fill in the reason.",
			"narr|She slides a form across the desk. REASON FOR LEAVING: a line, very short.",
		],
		"choices": [
			{"t": "Write: \"Because I'm tired.\"", "to": "brenda_reason", "set": ["reason_tired"]},
			{"t": "Write: \"Because someone's waiting for me.\"", "to": "brenda_reason", "set": ["reason_someone"]},
			{"t": "Write: \"Because I want to.\"", "to": "brenda_reason", "set": ["reason_want"]},
		],
	},
	"brenda_reason": {
		"who": "brenda",
		"say": [
			"Perfect! Now it just needs a stamp. And the stamp needs approval. And approval needs a quiet moment, which we don't have up here!",
			"Come back when things settle! Things always settle around three-thirty! Then they get much worse!",
		],
	},
	"brenda_smile": {
		"who": "brenda",
		"say": [
			"My smile? Oh, it's great! It's been like this since a team-building retreat in 2016. It's very professional!",
			"narr|Her eyes are not smiling. Her eyes are asking for help, very politely.",
		],
	},
	"brenda_again": {
		"who": "brenda", "new": false,
		"say": ["Hi again!! Still processing! Everything is in process! Always!"],
	},
	"brenda_turn": {
		"who": "brenda", "wait": 30,
		"say": [
			"narr|In the dark, Brenda's office lamp is still on. Her smile has slipped, just at one corner.",
			"Ha! Wow! Some night! I've stamped your form. It's ready. It's... ready.",
			"Can I tell you something? Nobody has ever asked if HR is okay. It's not on any of the forms. I checked. I've checked every form.",
		],
		"choices": [
			{"t": "Are you okay, Brenda?", "to": "brenda_ok"},
			{"t": "Thanks for the form. Gotta go.", "to": "brenda_cold"},
		],
	},
	"brenda_ok": {
		"who": "brenda", "set": ["has_form", "brenda_saved"], "event": ["item", "brenda_free"],
		"say": [
			"narr|The smile comes off. It's like watching someone take off heavy shoes. Underneath, she looks tired. And about ten years younger.",
			"No. No, I'm not. My sister's getting married on Saturday and I told her I couldn't come. Because of a quarterly review.",
			"narr|She takes a fresh FORM 6-0-0, writes fast, and stamps it twice. REASON FOR LEAVING: MY SISTER.",
			"There. One for you, one for me. Wow. That's the first form I ever filled out for myself.",
		],
	},
	"brenda_cold": {
		"who": "brenda", "set": ["has_form"], "event": "item",
		"say": ["Of course!! Have a great night!!", "narr|The smile clicks back into place. It looks heavier than before."],
		"choices": [
			{"t": "...Wait. Are you okay, Brenda?", "to": "brenda_ok_late"},
			{"t": "Bye.", "to": ""},
		],
	},
	"brenda_ok_late": {
		"who": "brenda", "set": ["brenda_saved"], "event": "brenda_free",
		"say": ["narr|The smile falls right off.", "...No. But I think I'm going to my sister's wedding. Thank you for asking. Nobody asks."],
	},
	"brenda_done": {
		"who": "brenda", "new": false,
		"say": ["Your form's all stamped! Go! Shoo! I'm practicing not smiling. It's hard!"],
		"choices": [
			{"t": "Are you okay, Brenda?", "to": "brenda_ok_late", "need": "!brenda_saved"},
			{"t": "Bye, Brenda.", "to": ""},
		],
	},

	# ---- floor two odds and ends
	"theo_desk": {
		"who": "narr", "new": false,
		"say": ["A cubicle with a nameplate: THEO, ASSOCIATE VP OF SYNERGY. A sticky note on the screen: BACK IN 5 MIN. The sticky note is yellowed and dated 2019.", "His screen saver is a picture of the top floor."],
	},
	"fax_idle": {
		"who": "narr", "new": false,
		"say": ["A fax machine, dusty. Its little screen says: WAITING FOR A FRIEND."],
	},
	"fax_printy": {
		"who": "narr", "event": "print",
		"say": ["The fax machine whirs. A page curls out, in Printy's chunky type: HELLO FROM DOWNSTAIRS. I AM FINISHED. IT IS NICE. GOOD LUCK UP THERE. PS: I HAVE NEVER SENT A FAX BEFORE."],
	},
	"elevator2": {
		"who": "narr", "new": false,
		"say": ["The executive elevator, at the far end of the floor. Gold doors. A card reader. A sign: KEYCARD, SIGN-OFF AND FORM 6-0-0 REQUIRED. NO EXCEPTIONS. NO, NOT EVEN YOU."],
		"choices": [
			{"t": "Card, sign-off, form. Go up.", "to": "act2_up", "need": ["has_keycard", "has_signoff", "has_form"]},
			{"t": "Leave it.", "to": ""},
		],
	},
	"act2_up": {
		"who": "narr", "wait": 30,
		"say": [
			"The card reader goes green. The sign-off scrolls by on a tiny screen. The form slides into a slot and comes back stamped: APPROVED. RELUCTANTLY.",
			"The gold doors open. The inside is leather and wood and smells like a new car that's afraid of you.",
			"marge|Mind the top, kid. Nobody ever came back down to tell us what it's like.",
		],
		"to": "ride3",
	},
	"ride3": {
		"who": "narr", "event": "ride3", "set": ["floor3"],
		"say": ["The counter doesn't show a number. It just says TOP."],
	},

	# ---- 3:33 on floor two
	"blackout": {
		"who": "narr", "clock": 1653, "set": ["blackout_done"], "event": "blackout",
		"say": [
			"3:33 AM.",
			"Every light on the floor goes out at once. The forty monitors come back red, all showing the same smiling face.",
			"Then every phone on every desk rings. Forty phones. All at once.",
		],
		"to": "blackout_ring2",
	},
	"blackout_ring2": {
		"who": "narr", "event": "ring",
		"say": ["They ring again. The nearest one is right by your hand."],
		"to": "blackout_ring3",
	},
	"blackout_ring3": {
		"who": "narr", "event": "ring",
		"say": ["They ring a third time."],
		"choices": [
			{"t": "Answer the one by your hand.", "to": "blackout_answer", "set": ["answered_third"]},
			{"t": "Don't. Rule one.", "to": "blackout_wait", "need": "rules"},
			{"t": "Rip the cord out of the wall.", "to": "blackout_cord"},
		],
	},
	"blackout_answer": {
		"who": "manager", "event": "shake",
		"say": [
			"You picked up on three. That means you're staying. Everyone who picks up on three stays.",
			"narr|In the dark monitor, your reflection holds the phone a beat longer than you do.",
			"narr|Then a red blazer swings past and a hand comes down on the cradle. CLACK. It's Marge. She stopped walking to do it.",
			"marge|Not on my floor.",
		],
		"to": "blackout_end",
	},
	"blackout_wait": {
		"who": "narr",
		"say": ["You let them ring. Forty phones stop mid-ring, all at once, annoyed."],
		"to": "blackout_end",
	},
	"blackout_cord": {
		"who": "narr",
		"say": ["You yank the nearest cord. The other thirty-nine keep ringing a moment longer, out of spite. Then silence."],
		"to": "blackout_end",
	},
	"blackout_end": {
		"who": "manager",
		"say": [
			"narr|Every red face on every screen speaks at once.",
			"THE BUILD IS NOT APPROVED. NOBODY SIGNS OFF. NOBODY GOES HOME.",
			"narr|And then, for the first time in twenty-one years, the footsteps stop. Somewhere in the dark, the TV on the cart blinks: CONNECTED.",
			"you|Keycard. Sign-off. Form. Then up. And I'm not leaving them here either.",
		],
		"event": "after_blackout",
	},

	# ============================================================ ACT THREE: the top
	"arrive3": {
		"who": "narr", "clock": 1724, "event": "act3",
		"say": [
			"ACT THREE. THE TOP.",
			"Mahogany. Red carpet. A boardroom table long enough to land a plane on. A wall of window over the dark bay.",
			"Four people in suits sit around the table. They don't move. At the far end, a big leather chair faces the window. Someone is sitting in it.",
			"manager|The board is in session. The board will now hear the candidate. Please, take a seat. Any seat. You'll be here a while.",
		],
	},
	"board3_meet": {
		"who": "board", "set": ["heard_board"], "wait": 20,
		"say": [
			"narr|Four heads turn toward you at exactly the same speed. Four mouths open together.",
			"STATE YOUR NAME. STATE YOUR TITLE. STATE YOUR VALUE.",
		],
		"choices": [
			{"t": "I'm the new hire. I just want to go home.", "to": "board_home"},
			{"t": "Who are you people?", "to": "board_who"},
		],
	},
	"board_home": {
		"who": "board",
		"say": ["GOING HOME IS NOT A VALUE. QUESTION FOUR. WHAT IS THE COMPANY'S MOST VALUABLE ASSET?"],
		"to": "board_q4",
	},
	"board_who": {
		"who": "board",
		"say": ["WE ARE THE BOARD. WE HAVE ALWAYS BEEN THE BOARD. WE WERE ORDERED FROM A CATALOGUE IN 2001. QUESTION FOUR. WHAT IS THE COMPANY'S MOST VALUABLE ASSET?"],
		"to": "board_q4",
	},
	"board_q4": {
		"who": "board",
		"choices": [
			{"t": "\"Your time.\"", "to": "board_time"},
			{"t": "\"Synergy.\"", "to": "board_synergy"},
			{"t": "\"The people. Wendy. Kip. Marge. Chad. Brenda.\"", "to": "board_people"},
		],
	},
	"board_time": {
		"who": "board",
		"say": ["CORRECT. YOU ARE AN EXCELLENT CANDIDATE. THE CHAIR IS WARM. THE CHAIR IS ALWAYS WARM."],
	},
	"board_synergy": {
		"who": "board",
		"say": ["...", "SYNERGY IS NOT AN ASSET. SYNERGY IS A FEELING. WE HAVE NOT HAD A FEELING SINCE 2001."],
	},
	"board_people": {
		"who": "board", "event": "flicker", "set": ["board_rattled"],
		"say": [
			"narr|The four of them glitch, like a video tape chewing itself.",
			"THAT. IS NOT. IN THE MINUTES.",
			"narr|One of them, the one nearest you, whispers on his own, in a very different voice: \"...Gary?\"",
		],
	},
	"board3_again": {
		"who": "board", "new": false,
		"say": ["THE BOARD HAS HEARD THE CANDIDATE. THE BOARD AWAITS THE CHIEF EXECUTIVE. THE CHIEF EXECUTIVE IS ALWAYS ABOUT TO ARRIVE."],
	},
	"ceo_meet": {
		"who": "narr", "set": ["met_ceo"], "wait": 20, "event": "ceo_turn",
		"say": [
			"You walk the length of the table to the big chair by the window. You turn it around.",
			"It's an empty suit. A black suit on a coat hanger, propped up with a cushion, a tie knotted around nothing.",
			"A brass plate on the chair says CHIEF EXECUTIVE. On the collar, a sticky note in purple ink: SAY NO FOR ME. —D.",
			"you|Nobody has met the CEO... because there's nobody to meet.",
		],
	},
	"ceo_again": {
		"who": "narr", "new": false,
		"say": ["The empty suit faces the room now. Somehow that's worse."],
	},
	"portrait": {
		"who": "narr", "new": false,
		"say": ["An oil portrait in a gold frame: a young man with a big moustache, so much hair, and a purple pen behind his ear. The plate says: D. PRUITT. FOUNDER. 1996.", "He's smiling like he hasn't found out yet."],
	},
	"window3": {
		"who": "narr", "new": false,
		"say": ["The whole bay from up here. The city is dark. Far off, at the edge of the water, the sky is just starting to think about going grey."],
	},
	"phone3": {
		"who": "narr", "new": false,
		"say": ["A star-shaped conference phone in the middle of the table. Its little light is on. It's always on. The Night Manager is listening."],
	},
	"elevator3": {
		"who": "narr", "new": false,
		"say": ["The executive elevator. Only one button: DOWN. Rule three."],
	},
	"dale_arrives": {
		"who": "narr", "event": "dale_arrives", "wait": 10, "set": ["dale_here"],
		"say": [
			"The stairwell door bangs open.",
			"dale|Took the stairs. All of 'em. Thirty-one flights. Don't tell my cardiologist.",
			"narr|It's Dale. Red in the face, tie over one shoulder, a purple pen in his shirt pocket. He looks at the empty suit. He looks at you.",
			"dale|...Well. You found him, huh. Found me, I mean.",
		],
	},
	"dale_truth": {
		"who": "dale", "wait": 15,
		"say": ["Go on. Ask. You've earned it. You climbed the whole building."],
		"choices": [
			{"t": "You're the founder. You're in the portrait. You're in Kip's video.", "to": "dale_founder"},
			{"t": "Are you okay?", "to": "dale_okay"},
		],
	},
	"dale_okay": {
		"who": "dale",
		"say": ["Me? Oh, I'm great. I'm always great. It's my whole thing.", "narr|He's holding the purple pen so tight his knuckles are white."],
		"choices": [
			{"t": "You're the founder, Dale.", "to": "dale_founder"},
		],
	},
	"dale_founder": {
		"who": "dale",
		"say": [
			"narr|He laughs. Then he stops laughing.",
			"Garage in Burbank. Three beige computers and a dream. I had so much hair.",
			"It got big. Real big. People needed somebody to say no. Cut this. Ship that. Stay late.",
			"I couldn't do it. So I bought a suit with nobody in it, hired a voice on the phone to say the hard things, and gave myself a desk in receivables. And I hid.",
		],
		"choices": [
			{"t": "So the Night Manager is... you?", "to": "dale_made"},
			{"t": "Why do you stay here every night?", "to": "dale_why"},
		],
	},
	"dale_made": {
		"who": "dale",
		"say": ["He's every hard thing I didn't want to say. Turns out if you don't say 'em, they don't go away. They get a phone line. They get a floor. They get a whole building."],
		"to": "dale_why",
	},
	"dale_why": {
		"who": "dale",
		"say": [
			"Down there, I'm Dale from receivables. Nobody expects anything.",
			"Out there I'm the dad who missed every recital. If I don't go home, I can't miss the next one. That's the math.",
			"It's bad math. I know it's bad math. I'm in receivables.",
		],
		"choices": [
			{"t": "Go to Lucy's recital, Dale. Front row.", "to": "dale_go", "set": ["dale_going"]},
			{"t": "She probably stopped expecting you.", "to": "dale_harsh"},
			{"t": "I need the founder's signature to get out.", "to": "dale_cold"},
		],
	},
	"dale_go": {
		"who": "dale", "set": ["has_signature"], "event": "item",
		"say": [
			"narr|Dale looks at you like you just told him something he already knew.",
			"...Front row. Yeah. Okay.",
			"Gimme your timecard. Founder's signature. Haven't used it in eleven years.",
			"narr|D. PRUITT, FOUNDER. The purple ink is a little shaky. Then he signs a second card, the faded one with WENDY OKAFOR on it.",
		],
	},
	"dale_harsh": {
		"who": "dale", "set": ["has_signature"], "event": "item",
		"say": [
			"narr|He nods slowly. Like he's heard it before, in his own voice, every night at three.",
			"...Yeah. Yeah, probably.",
			"narr|He signs your card anyway. D. PRUITT, FOUNDER. Then he stares at the empty suit like it might help.",
		],
		"choices": [
			{"t": "Wait. I didn't mean that. Go, Dale.", "to": "dale_take_back", "set": ["dale_going"]},
			{"t": "Thanks for the signature.", "to": ""},
		],
	},
	"dale_take_back": {
		"who": "dale",
		"say": ["...You know what? Nine o'clock's a long way off. Plenty of time to get a good seat.", "narr|He straightens his tie. It doesn't help, but it's nice to see him try."],
	},
	"dale_cold": {
		"who": "dale", "set": ["has_signature"], "event": "item",
		"say": ["Right. Business. Course.", "narr|D. PRUITT, FOUNDER. He signs without looking up."],
		"choices": [
			{"t": "...Go to the recital, Dale.", "to": "dale_take_back", "set": ["dale_going"]},
			{"t": "Thanks.", "to": ""},
		],
	},
	"dale_done": {
		"who": "dale", "new": false,
		"say": ["Whatever he offers you, kid... I'm right here. For once."],
		"choices": [
			{"t": "Go to the recital, Dale.", "to": "dale_take_back", "need": "!dale_going", "set": ["dale_going"]},
			{"t": "Stay close.", "to": ""},
		],
	},

	# ---- the end
	"finale": {
		"who": "narr", "clock": 1799, "event": "finale",
		"say": [
			"5:59 AM.",
			"The conference phone rings. Once. Twice. Three times. It answers itself.",
			"Every screen in the building turns to face you. Every one of them, all the way down.",
		],
		"to": "finale_offer",
	},
	"finale_offer": {
		"who": "manager",
		"say": [
			"Congratulations! The board has reviewed your performance. We'd like to offer you a promotion.",
			"Chief Executive. The chair is warm. No more mornings. No more deadlines you can't make. Everyone you met tonight would report to you.",
			"You could keep them safe. Isn't that what you want? To keep them here, where it's safe?",
		],
		"choices": [
			{"t": "Who were you, before you were this?", "to": "finale_who", "once": true},
			{"t": "...I accept.", "to": "end_promoted"},
			{"t": "No. And they're coming with me.", "to": "end_out"},
		],
	},
	"finale_who": {
		"who": "manager",
		"say": [
			"I was the first hire. Dale needed someone to say the hard things, so he wouldn't have to.",
			"Cut it. Ship it. Stay late. Nobody likes the one who says it. So nobody ever asks the one who says it to leave.",
			"...Nobody's ever asked me that.",
		],
		"to": "finale_offer",
	},
	"end_promoted": {
		"who": "narr", "set": ["ended", "ending_bad"], "event": "end_bad",
		"say": [
			"You sit in the big chair. It is warm. The board says AYE, all four of them, at exactly the same time.",
			"dale|...Oh, kid.",
			"narr|Far below you, on every floor, a phone rings once, twice, three times.",
			"You pick it up. A voice that's almost yours says: \"Good evening! This is the Night Manager.\"",
		],
	},
	"end_out": {
		"who": "manager",
		"say": [
			"narr|The screens flicker.",
			"No? Everyone says yes. Saying no is my job.",
			"dale|Not anymore. I'll say it. I should've said it thirty years ago.",
			"dale|No. You're done. Take the night off. Take all of them off.",
			"narr|A long pause. Then, very quietly, from every speaker on every floor at once:",
			"...thank you for your time.",
		],
		"to": "end_dawn",
	},
	"end_dawn": {
		"who": "narr", "clock": 1800, "set": ["ended", "ending_good"], "event": "dawn",
		"say": [
			"6:00 AM.",
			"The screens go dark, then grey, then nothing at all. The board slumps, four empty suits. Out over the bay, the sky goes orange.",
			"Behind you, the executive elevator dings. The panel has a new button. It has never been there before. It says ROOF.",
		],
		"choices": [
			{"t": "Press ROOF.", "to": "end_roof"},
		],
	},
	"end_roof": {
		"who": "narr", "event": "roof",
		"say": [],
	},
}

## The epilogue: who you got off the night shift (story.saved()), one line
## each in the credits over the field, and the ones still in the building.
const EPILOGUE := {
	"wendy": "Wendy Okafor stands in the wheat with her mop over her shoulder like a fishing rod. \"Huh,\" she says. \"It's orange. I forgot it was orange.\"",
	"kip": "Kip takes off his lanyard and holds it up like a diploma. \"Day one thousand and ninety-seven,\" he says. \"Day one.\"",
	"printy": "Printy-9000 sits in the wheat, humming. Every few minutes it prints a page that just says SKY.",
	"marge": "Marge sits on a hay bale with her shoes off. She hasn't walked anywhere in an hour. She says it's the best meeting she's ever had.",
	"chad": "Chad is on the phone. An actual phone. \"Hi buddy. It's Dad. Yeah. I'm out of the meeting.\"",
	"brenda": "Brenda isn't smiling. Then she is, a real one, small and crooked. She's practicing a toast for her sister's wedding.",
	"dale": "Dale has his coat on and a program from Lucy's recital already folded in his pocket. \"Front row,\" he says. \"I'm gonna ugly cry.\"",
}
const LEFT := {
	"wendy": "Wendy is still mopping her square on the first floor. It's almost finished. It's always almost finished.",
	"kip": "Kip is on module five of four hundred.",
	"printy": "Printy is still jammed, trying last lines nobody will read.",
	"marge": "Marge is still walking. Desk fourteen. Empty. Desk fifteen.",
	"chad": "Chad is still in the meeting. Nobody told him he could leave.",
	"brenda": "Brenda is still smiling. It still hurts.",
	"dale": "Dale's lamp is still on in receivables. \"Right behind you,\" he said. He isn't.",
}
const NAMES := {
	"wendy": ["WENDY OKAFOR", "Night Custodian, 31 years"],
	"kip": ["KIP", "Intern, Day 1,097"],
	"printy": ["PRINTY-9000", "Copier, Poet"],
	"marge": ["MARGE", "Floor Manager, retired (as of 4 AM)"],
	"chad": ["CHAD", "VP, Working From Home (actually home)"],
	"brenda": ["BRENDA", "Human Resources, human"],
	"dale": ["DALE PRUITT", "Founder. Accounts Receivable. Dad."],
}
const COFFEE_BYE := "The coffee maker brews you one for the road. It's actually pretty good."
const LAST := "Go home. And be kind to whoever's still on the night shift."

## Wendy's laminated card (the RULES button once she's given it to you).
const RULES := [
	"ONE: Never answer the phone on the third ring.",
	"TWO: If the printer starts printing by itself, let it finish.",
	"THREE: Never ride the elevator down.",
	"FOUR: If someone asks you to stay, say no. Politely.",
	"FIVE: Never let the coffee hear you complain.",
]

## What you can tap, and where you stand to talk:
## [name, focus, view, person, floor]. Floors 2 and 3 are in their own room's
## space (main.gd adds the floor's origin); Marge's spot follows her walk.
const SPOTS := {
	"desk": ["YOUR DESK", Vector3(0.0, 1.17, -2.38), Vector3(0.05, 1.4, -1.45), false, 1],
	"phone": ["PHONE", Vector3(0.5, 0.86, -2.3), Vector3(0.3, 1.45, -1.55), false, 1],
	"dale": ["DALE", Vector3(-3.0, 1.25, -0.6), Vector3(-1.75, 1.38, -0.45), true, 1],
	"kip": ["KIP", Vector3(3.0, 1.25, -0.9), Vector3(1.9, 1.4, -1.45), true, 1],
	"printy": ["PRINTY-9000", Vector3(2.85, 0.98, 1.15), Vector3(2.0, 1.4, 1.0), true, 1],
	"wendy": ["NIGHTS", Vector3(-0.75, 1.62, 2.45), Vector3(-0.55, 1.55, 1.25), true, 1],
	"coffee": ["COFFEE", Vector3(-2.55, 1.1, 3.62), Vector3(-2.35, 1.5, 2.7), false, 1],
	"board": ["EMPLOYEE OF THE MONTH", Vector3(-3.45, 1.72, 2.0), Vector3(-2.05, 1.55, 2.0), false, 1],
	"window": ["WINDOW", Vector3(-3.55, 1.55, -0.5), Vector3(-1.85, 1.6, -0.15), false, 1],
	"clock": ["PUNCH CLOCK", Vector3(0.35, 1.3, 3.95), Vector3(0.4, 1.5, 2.95), false, 1],
	"elevator": ["ELEVATOR", Vector3(1.8, 1.3, 4.0), Vector3(1.8, 1.5, 2.85), false, 1],
	"marge": ["MARGE", Vector3(-3.6, 1.6, -2.6), Vector3(-2.6, 1.55, -2.2), true, 2],
	"chad": ["CHAD", Vector3(-5.0, 1.2, -4.0), Vector3(-3.7, 1.35, -2.7), true, 2],
	"brenda": ["BRENDA, HR", Vector3(5.1, 1.22, -4.25), Vector3(5.0, 1.42, -2.3), true, 2],
	"theo": ["THEO'S DESK", Vector3(2.4, 1.0, -1.25), Vector3(2.4, 1.45, -2.4), false, 2],
	"fax": ["FAX", Vector3(-5.4, 1.0, 1.5), Vector3(-4.2, 1.45, 1.5), false, 2],
	"elevator2": ["EXECUTIVE ELEVATOR", Vector3(0.0, 1.3, -4.95), Vector3(0.0, 1.5, -3.2), false, 2],
	"board3": ["THE BOARD", Vector3(0.0, 1.15, -0.5), Vector3(0.0, 1.8, 2.7), true, 3],
	"ceo": ["THE CEO", Vector3(0.0, 1.05, -3.6), Vector3(0.9, 1.45, -1.9), true, 3],
	"dale3": ["DALE", Vector3(-3.6, 1.62, 2.4), Vector3(-2.2, 1.55, 2.2), true, 3],
	"portrait": ["THE FOUNDER", Vector3(4.92, 1.75, -0.5), Vector3(2.9, 1.6, -0.5), false, 3],
	"window3": ["WINDOW", Vector3(0.0, 1.6, -4.9), Vector3(1.2, 1.6, -2.6), false, 3],
	"phone3": ["CONFERENCE PHONE", Vector3(0.0, 0.85, -0.3), Vector3(0.7, 1.5, 1.2), false, 3],
	"elevator3": ["ELEVATOR", Vector3(0.0, 1.3, 4.95), Vector3(0.0, 1.5, 3.0), false, 3],
}
