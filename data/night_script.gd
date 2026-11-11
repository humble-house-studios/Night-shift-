extends RefCounted
## NIGHT SHIFT: the whole script. One night at Humble House Games, 11:58 PM
## to 6:00 AM. You fell asleep at your desk on your first day; the office has
## extended your shift. To clock out you need three things (your TIMECARD,
## a MANAGER'S SIGNATURE, the OVERRIDE CODE), and each one sits with someone
## who has been stuck here far longer than you.
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
}

## Conversations that start by themselves, in order.
const AUTO := [
	["", "prologue"],
	[["met_dale", "met_wendy", "met_kip", "met_printy"], "blackout"],
]

## Who gets you out, for the ending: [id, cond].
const SAVED := [
	["wendy", "wendy_card"],
	["kip", "kip_free"],
	["dale", "dale_going"],
	["printy", "poem_done"],
]

const ENTRIES := {
	"phone": [
		["ended", "phone_dead"],
		["blackout_done", "phone_after"],
		["", "phone_idle"],
	],
	"desk": [
		["blackout_done", "desk_after"],
		["", "desk_look"],
	],
	"wendy": [
		["wendy_card", "wendy_done"],
		[["wendy_named", "blackout_done"], "wendy_give"],
		["wendy_named", "wendy_wait"],
		["met_wendy", "wendy_again"],
		["", "wendy_meet"],
	],
	"kip": [
		["kip_free", "kip_done"],
		["blackout_done", "kip_frozen"],
		["met_kip", "kip_again"],
		["", "kip_meet"],
	],
	"printy": [
		["has_code", "printy_done"],
		["blackout_done", "printy_finish"],
		["met_printy", "printy_again"],
		["", "printy_meet"],
	],
	"dale": [
		["has_signature", "dale_done"],
		[["clue_founder", "blackout_done"], "dale_truth"],
		["met_dale", "dale_again"],
		["", "dale_meet"],
	],
	"coffee": [
		["coffee_friend", "coffee_friend"],
		["coffee_mad", "coffee_mad"],
		["", "coffee_meet"],
	],
	"board": [
		["blackout_done", "board_after"],
		["", "board_look"],
	],
	"window": [
		["blackout_done", "window_after"],
		["", "window_look"],
	],
	"clock": [
		[["has_timecard", "has_signature", "has_code"], "finale"],
		["", "clock_locked"],
	],
	"elevator": [
		["looped", "elevator_again"],
		["", "elevator"],
	],
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
			"Clocking out is simple. Bring the punch clock by the elevator three things:",
			"Your TIMECARD. A MANAGER'S SIGNATURE. And the OVERRIDE CODE.",
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
			"narr|THREE: Don't take the elevator before six.",
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
			{"t": "About that timecard...", "to": "wendy_give", "need": "blackout_done"},
			{"t": "Nice to meet you, Wendy.", "to": "wendy_later", "need": "!blackout_done"},
		],
	},
	"wendy_later": {
		"who": "wendy",
		"say": ["Go meet the others, kid. Come back when the lights go funny. They always go funny around three."],
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
			"You made it through three-thirty-three. Most new folks hide under a desk.",
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
			"...Take it. Punch mine when you punch yours. If it works for you, maybe it works for me.",
		],
		"choices": [
			{"t": "I'll get you out. Promise.", "to": "wendy_promise"},
			{"t": "I can't promise anything.", "to": "wendy_honest"},
		],
	},
	"wendy_thanks": {
		"who": "wendy",
		"say": ["Don't thank me. Thank me at six.", "narr|She hesitates, then hands you a second card. It says WENDY OKAFOR in faded ink. Never punched.", "Punch mine too. If it works for you, maybe it works for me."],
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
			"narr|The quiz is back on question four. The answer box is blinking.",
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
		"who": "kip", "set": ["kip_free"], "wait": 30, "event": ["ding", "kip_wake"],
		"say": [
			"narr|You type his name. K-I-P. Enter.",
			"narr|DING. CORRECT. YOUR MOST VALUABLE ASSET IS YOU. ONBOARDING COMPLETE.",
			"narr|A certificate slides out of the printer across the room. Kip blinks. He blinks a lot, like his eyes forgot how.",
			"...Is that it? Am I... onboarded?",
		],
		"choices": [
			{"t": "You passed, Kip. You can go home.", "to": "kip_thanks"},
			{"t": "Technically, I passed it for you.", "to": "kip_thanks_joke"},
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
	"kip_done": {
		"who": "kip", "new": false,
		"say": ["I'm practicing what I'll say to my mom. \"Hi mom. I'm onboarded.\" Too formal? It's too formal."],
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
			"THE LIGHTS WENT OUT AND I GOT SCARED. I PRINT WHEN I AM SCARED.",
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
		"say": ["Me? I'm accounts receivable, buddy. I can't sign anything. I can't even sign for the mints."],
		"to": "dale_menu",
	},
	"dale_again": {
		"who": "dale", "new": false,
		"say": ["Back again! Mint? No pressure. They're not going anywhere. Neither am I. Ha."],
		"to": "dale_menu",
	},
	"dale_truth": {
		"who": "dale", "wait": 30,
		"say": [
			"narr|Dale's lamp is the only light that survived the blackout. He's turning the purple pen over in his fingers.",
			"Pretty spooky out there, huh? It's always like that around three. You get used to it.",
		],
		"choices": [
			{"t": "You're the founder, Dale. You're in Kip's video.", "to": "dale_founder"},
			{"t": "Are you okay?", "to": "dale_okay"},
		],
	},
	"dale_okay": {
		"who": "dale",
		"say": ["Me? Oh, I'm great. I'm always great. It's my whole thing.", "narr|He's holding the pen so tight his knuckles are white."],
		"choices": [
			{"t": "You're the founder, Dale. You're in Kip's video.", "to": "dale_founder"},
		],
	},
	"dale_founder": {
		"who": "dale",
		"say": [
			"narr|He laughs. Then he stops laughing.",
			"...Garage in Burbank. Three beige computers and a dream. I had so much hair.",
			"It got big. Real big. People needed somebody to say no. Cut this. Ship that. Stay late.",
			"I couldn't do it. So I made a guy who could. A manager. A voice on the phone. Then I gave myself a desk in receivables and hid.",
		],
		"choices": [
			{"t": "So the Night Manager is... you?", "to": "dale_made"},
			{"t": "Why do you stay here every night?", "to": "dale_why"},
		],
	},
	"dale_made": {
		"who": "dale",
		"say": [
			"He's every hard thing I didn't want to say. Turns out if you don't say 'em, they don't go away. They get a phone line.",
		],
		"to": "dale_why",
	},
	"dale_why": {
		"who": "dale",
		"say": [
			"Here, I'm Dale from receivables. Nobody expects anything.",
			"Out there I'm the dad who missed every recital. If I don't go home, I can't miss the next one. That's the math.",
			"It's bad math. I know it's bad math. I'm in receivables.",
		],
		"choices": [
			{"t": "Go to Lucy's recital, Dale. Front row.", "to": "dale_go", "set": ["dale_going"]},
			{"t": "She probably stopped expecting you.", "to": "dale_harsh"},
			{"t": "I need your signature to get out.", "to": "dale_cold"},
		],
	},
	"dale_go": {
		"who": "dale", "set": ["has_signature"], "event": ["item", "dale_stand"],
		"say": [
			"narr|Dale looks at you like you just told him something he already knew.",
			"...Front row. Yeah. Okay.",
			"Gimme your timesheet. Founder's signature. Haven't used it in eleven years.",
			"narr|D. PRUITT, FOUNDER. The purple ink is a little shaky. He caps the pen and stands up for the first time all night.",
			"Huh. My knees forgot how to do that.",
		],
	},
	"dale_harsh": {
		"who": "dale", "set": ["has_signature"], "event": "item",
		"say": [
			"narr|He nods slowly. Like he's heard it before, in his own voice, every night at three.",
			"...Yeah. Yeah, probably.",
			"narr|He signs your sheet anyway. D. PRUITT, FOUNDER. Then he turns the lamp a little toward himself and goes back to his receivables.",
		],
		"choices": [
			{"t": "Wait. I didn't mean that. Go, Dale.", "to": "dale_take_back", "set": ["dale_going"]},
			{"t": "Thanks for the signature.", "to": ""},
		],
	},
	"dale_take_back": {
		"who": "dale", "event": "dale_stand",
		"say": ["...You know what? Nine o'clock's a long way off. Plenty of time to get a good seat.", "narr|He stands up. His knees crack like a drum fill."],
	},
	"dale_cold": {
		"who": "dale", "set": ["has_signature"], "event": "item",
		"say": [
			"Right. Business. Course.",
			"narr|D. PRUITT, FOUNDER. He signs without looking up. The lamp hums.",
		],
		"choices": [
			{"t": "...Go to the recital, Dale.", "to": "dale_take_back", "set": ["dale_going"]},
			{"t": "Thanks.", "to": ""},
		],
	},
	"dale_done": {
		"who": "dale", "new": false,
		"say": ["You go on. I'm right behind you. Probably. Ha."],
		"choices": [
			{"t": "Go to the recital, Dale.", "to": "dale_take_back", "need": "!dale_going", "set": ["dale_going"]},
			{"t": "See you at six.", "to": ""},
		],
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
		"say": ["A grey punch clock by the elevator, with a keypad bolted on. A sticker: TIMECARD + MANAGER SIGNATURE + OVERRIDE CODE = HAVE A NICE DAY."],
	},
	"elevator": {
		"who": "narr", "new": false,
		"say": ["The elevator doors are shut. The call button glows a soft, inviting green."],
		"choices": [
			{"t": "Press the button.", "to": "elevator_ride", "need": "!rules"},
			{"t": "Press it anyway. (Rule three...)", "to": "elevator_ride", "need": "rules"},
			{"t": "Leave it.", "to": ""},
		],
	},
	"elevator_ride": {
		"who": "narr", "event": "loop",
		"say": [
			"The doors open at once, like it was waiting. You step in. The doors close. Down.",
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
			"Somewhere across the office, Wendy calls out: \"Told you. Rule three.\"",
		],
	},
	"elevator_again": {
		"who": "narr", "new": false,
		"say": ["The call button glows green. You know exactly where it goes. You don't press it."],
	},

	# ------------------------------------------------------------ 3:33
	"blackout": {
		"who": "narr", "clock": 1653, "set": ["blackout_done"], "event": "blackout",
		"say": [
			"3:33 AM.",
			"The monitors die all at once. Then they come back red. Every one of them shows the same smiling face.",
			"The phone on your desk rings.",
		],
		"to": "blackout_ring2",
	},
	"blackout_ring2": {
		"who": "narr", "event": "ring",
		"say": ["It rings again."],
		"to": "blackout_ring3",
	},
	"blackout_ring3": {
		"who": "narr", "event": "ring",
		"say": ["It rings a third time."],
		"choices": [
			{"t": "Answer it.", "to": "blackout_answer", "set": ["answered_third"]},
			{"t": "Don't. Rule one.", "to": "blackout_wait", "need": "rules"},
			{"t": "Pull the cord out of the wall.", "to": "blackout_cord"},
		],
	},
	"blackout_answer": {
		"who": "manager", "event": "shake",
		"say": [
			"You picked up on three. That means you're staying. Everyone who picks up on three stays.",
			"narr|Your reflection in the dark monitor holds the phone a beat longer than you do.",
			"narr|Then Wendy's mop handle comes down on the cradle. CLACK.",
			"wendy|Hands off the phone, kid. I've lost enough new hires to that thing. Go. Finish up.",
		],
		"to": "blackout_end",
	},
	"blackout_wait": {
		"who": "narr",
		"say": ["You let it ring. The ringing stops mid-ring, annoyed."],
		"to": "blackout_end",
	},
	"blackout_cord": {
		"who": "narr",
		"say": ["You yank the cord out of the wall. The phone keeps ringing for one more ring anyway. Then it stops, like it's sulking."],
		"to": "blackout_end",
	},
	"blackout_end": {
		"who": "manager",
		"say": [
			"narr|Every red face on every screen speaks at once.",
			"THE BUILD IS NOT APPROVED. NOBODY GOES HOME.",
			"narr|Across the room, Kip has gone very still. The copier starts printing by itself. Dale's lamp is the only warm light left.",
			"you|Okay. Timecard, signature, code. Then I am out of here. And I'm not leaving them here either.",
		],
		"event": "after_blackout",
	},

	# ------------------------------------------------------------ the end
	"finale": {
		"who": "narr", "clock": 1799, "event": "finale",
		"say": [
			"5:59 AM.",
			"You feed the timecard into the punch clock. You hold up the signature. You key in the code: 0-6-0-0.",
			"The punch clock doesn't punch. Every screen in the office turns to you.",
		],
		"to": "finale_offer",
	},
	"finale_offer": {
		"who": "manager",
		"say": [
			"Before you go! One more thing. We'd like to offer you a promotion.",
			"Night Manager. No more mornings. No more deadlines you can't make. Everyone you met tonight would report to you.",
			"You could keep them safe. Isn't that what you want? To keep them here, where it's safe?",
		],
		"choices": [
			{"t": "Who were you, before you were this?", "to": "finale_who", "once": true},
			{"t": "...I accept.", "to": "end_promoted"},
			{"t": "No thank you. I'm clocking out.", "to": "end_out"},
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
			"The punch clock goes CHUNK. Your card comes back stamped: PROMOTED.",
			"The screens go back to smiling. Somewhere far away, a phone rings, once, twice, three times.",
			"You pick it up. A voice that's almost yours says:",
			"\"Good evening! This is the Night Manager.\"",
		],
	},
	"end_out": {
		"who": "manager",
		"say": [
			"narr|The screens flicker.",
			"No? Everyone says yes. Saying no is my job.",
			"you|Then take the night off. You've earned it more than anyone.",
			"narr|A long pause. Then, very quietly, from every speaker at once:",
			"...thank you for your time.",
		],
		"to": "end_dawn",
	},
	"end_dawn": {
		"who": "narr", "clock": 1800, "set": ["ended", "ending_good"], "event": "dawn",
		"say": [
			"CHUNK. 6:00 AM. CLOCKED OUT.",
			"The screens go dark, then grey, then nothing at all. Outside the window, the sky is going orange.",
		],
		"to": "end_people",
	},
	"end_people": {
		"who": "narr", "event": "epilogue",
		"say": [],
	},
}

## The epilogue, a line for each person you got out (story.saved()), then
## the ones still on the night shift.
const EPILOGUE := {
	"wendy": "You punch Wendy's card too. She stands at the window a long time. \"Huh,\" she says. \"It's orange. I forgot it was orange.\"",
	"kip": "Kip takes off his lanyard and holds it like a diploma. \"Day one thousand and ninety-seven,\" he says. \"Day one.\"",
	"dale": "Dale already has his coat on. \"Nine o'clock,\" he says. \"Front row. I'm gonna cry so hard. I'm gonna ugly cry.\"",
	"printy": "Behind you, the copier prints one last page and lets it drift to the floor: THANK YOU FOR READING.",
}
const LEFT := {
	"wendy": "Wendy keeps mopping. The square is almost finished. It's always almost finished.",
	"kip": "Kip is still on question four. You can hear him whisper the welcome video from the elevator.",
	"dale": "Dale's lamp stays on. He waves you off without looking up. \"Right behind you,\" he says. He isn't.",
	"printy": "The copier is still jammed. As the doors close you hear it start a new last line.",
}
const COFFEE_BYE := "The coffee maker brews you one for the road. It's actually pretty good."
const LAST := "Go home. And be kind to whoever's still on the night shift."

## Wendy's laminated card (the RULES button once she's given it to you).
const RULES := [
	"ONE: Never answer the phone on the third ring.",
	"TWO: If the printer starts printing by itself, let it finish.",
	"THREE: Don't take the elevator before six.",
	"FOUR: If someone asks you to stay, say no. Politely.",
	"FIVE: Never let the coffee hear you complain.",
]

## What you can tap, and where you stand to talk: [name, focus, view, person].
const SPOTS := {
	"desk": ["YOUR DESK", Vector3(0.0, 1.17, -2.38), Vector3(0.05, 1.4, -1.45), false],
	"phone": ["PHONE", Vector3(0.5, 0.86, -2.3), Vector3(0.3, 1.45, -1.55), false],
	"dale": ["DALE", Vector3(-3.0, 1.25, -0.6), Vector3(-1.75, 1.38, -0.45), true],
	"kip": ["KIP", Vector3(3.0, 1.25, -0.9), Vector3(1.9, 1.4, -1.45), true],
	"printy": ["PRINTY-9000", Vector3(2.85, 0.98, 1.15), Vector3(2.0, 1.4, 1.0), true],
	"wendy": ["NIGHTS", Vector3(-0.75, 1.62, 2.45), Vector3(-0.55, 1.55, 1.25), true],
	"coffee": ["COFFEE", Vector3(-2.55, 1.1, 3.62), Vector3(-2.35, 1.5, 2.7), false],
	"board": ["EMPLOYEE OF THE MONTH", Vector3(-3.45, 1.72, 2.0), Vector3(-2.05, 1.55, 2.0), false],
	"window": ["WINDOW", Vector3(-3.55, 1.55, -0.5), Vector3(-1.85, 1.6, -0.15), false],
	"clock": ["PUNCH CLOCK", Vector3(0.35, 1.3, 3.95), Vector3(0.4, 1.5, 2.95), false],
	"elevator": ["ELEVATOR", Vector3(1.8, 1.3, 4.0), Vector3(1.8, 1.5, 2.85), false],
}
