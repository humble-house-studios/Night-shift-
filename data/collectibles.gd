extends RefCounted
## The things you collect on the way up. GOAL CARDS: one for each of the nine
## things the elevators want (three a floor), revealed with a flourish when
## you earn them. RELICS: little keepsakes people give you for being kind,
## shown as icons on screen as the night goes on. Both stay in your
## COLLECTION across nights (user://collection.cfg).
##
## Each entry: flag (story flag that earns it) -> [name, flavour line, icon,
## act, colour]. Icons are drawn in code (scenes/story/icons.gd).

const CARDS := {
	"has_timecard": ["TIMECARD", "Your name, already typed in. Wendy had it ready.", "timecard", 1, Color(0.95, 0.72, 0.35)],
	"has_badge": ["ASSOCIATE BADGE", "Printed the moment Kip typed his own name.", "badge", 1, Color(0.4, 0.75, 1.0)],
	"has_code": ["OVERRIDE CODE", "0600. Printy's queue, finally empty.", "code", 1, Color(0.6, 1.0, 0.45)],
	"has_keycard": ["EXECUTIVE KEYCARD", "Twenty-one years on a lanyard. Never swiped.", "keycard", 2, Color(1.0, 0.78, 0.3)],
	"has_signoff": ["SIGN-OFF", "SIGNED OFF: CHAD. A real one, not a bro one.", "signoff", 2, Color(0.5, 0.85, 1.0)],
	"has_form": ["FORM 6-0-0", "Request To Go Home. Stamped twice.", "form", 2, Color(1.0, 0.65, 0.8)],
	"heard_board": ["AN AUDIENCE", "Four suits, one voice, question four again.", "board", 3, Color(0.85, 0.82, 0.7)],
	"met_ceo": ["THE EMPTY SUIT", "Nobody has met the CEO. Now you have.", "suit", 3, Color(0.7, 0.7, 0.78)],
	"has_signature": ["FOUNDER'S SIGNATURE", "D. PRUITT, FOUNDER. Purple ink, a little shaky.", "pen", 3, Color(0.75, 0.5, 1.0)],
}

const RELICS := {
	"rules": ["THE RULES", "Laminated several times. Kept Wendy alive longer than the dental plan.", "rules", 1, Color(0.6, 0.95, 0.75)],
	"dale_mint": ["2014 MINT", "Individually wrapped. Tastes like a mint that has given up.", "mint", 1, Color(0.65, 0.95, 0.9)],
	"coffee_friend": ["THE GOOD MUG", "The coffee maker likes you. That's rare.", "mug", 1, Color(0.85, 0.6, 0.4)],
	"kip_saved": ["KIP'S LANYARD", "Day one thousand and ninety-seven. Day one.", "lanyard", 1, Color(1.0, 0.6, 0.85)],
	"printy_happy": ["THE LAST LINE", "\"...and someone stayed to help them through.\"", "page", 1, Color(0.7, 1.0, 0.45)],
	"marge_saved": ["MARGE'S PEDOMETER", "21 years. 40 million steps. Paused.", "pedometer", 2, Color(1.0, 0.5, 0.5)],
	"chad_saved": ["BOAT KEYCHAIN", "Shaped like a little sailboat. Out of range, finally.", "boat", 2, Color(0.5, 0.85, 1.0)],
	"brenda_saved": ["HANG IN THERE", "The kitten sticker off Brenda's poster. She's done hanging.", "kitten", 2, Color(1.0, 0.7, 0.85)],
	"board_rattled": ["GARY'S NAMEPLATE", "We don't talk about Gary. Somebody up top remembered him.", "nameplate", 3, Color(0.85, 0.82, 0.7)],
	"dale_going": ["PURPLE PEN", "The founder's pen. Front row, nine o'clock.", "pen", 3, Color(0.75, 0.5, 1.0)],
}

const ACT_NAME := {1: "FLOOR 1 · THE NIGHT SHIFT", 2: "FLOOR 2 · MIDDLE MANAGEMENT", 3: "FLOOR 3 · THE TOP"}
