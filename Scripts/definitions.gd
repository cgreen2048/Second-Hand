class_name Definitions
extends RefCounted

const PLAYER_ONE = 1
const PLAYER_TWO = 2

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const COLLISION_MASK_PILE = 4
const COLLISION_MASK_INTERACTIVE = COLLISION_MASK_CARD | COLLISION_MASK_PILE

enum CardType {
	BOARD,
	SPELL
}

enum SpecialEffects {
	START_TURN,
	FALTER,
	DEATHTOUCH,
	LIFELINK,
	ROLLOVER,
	BONUS,
}

const EFFECT_STYLES := {
	SpecialEffects.START_TURN: ["start_turn", "#FFB333"],
	SpecialEffects.FALTER: ["falter", "#FFB333"],
	SpecialEffects.DEATHTOUCH: ["deathtouch", "#7F01FE"],
	SpecialEffects.LIFELINK: ["lifelink", "#780606"],
	SpecialEffects.ROLLOVER: ["rollover", "#B99C96"],
	SpecialEffects.BONUS: ["bonus", "#4EA847"],
}

const ADJACENCY_EFFECT_LABEL := "[img=16x16]res://Assets/UI/effect_adjacency.svg[/img] [b][color=#69CCF0]Adjacenct Cards[/color][/b]"

static func format_effect(effect: SpecialEffects, label: String) -> String:
	var style: Array = EFFECT_STYLES[effect]
	return "[img=16x16]res://Assets/UI/effect_%s.svg[/img] [b][color=%s]%s[/color][/b]" % [style[0], style[1], label]

const CARDS = {
	"knight": {
		"display_name": "Knight",
		"adjacency_effects": Vector2i.ZERO,
		"attack": 4,
		"block": 3,
		"special_effects": {
			SpecialEffects.ROLLOVER: 1
		},
		"card_type": CardType.BOARD
	},
	"tank": {
		"display_name": "Tank",
		"adjacency_effects": Vector2i.ZERO,
		"attack": 1,
		"block": 5,
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"goblin": {
		"display_name": "Goblin",
		"adjacency_effects": Vector2i.ZERO,
		"attack": 1,
		"block": 1,
		"special_effects": {
			SpecialEffects.FALTER: 1
		},
		"card_type": CardType.BOARD
	},
	# Block is a destruction threshold, not cumulative HP. Defenses must have
	# starting-stat counters; durable/stacking support needs a vulnerable setup.
	# Reliable generalist, aggressive fighter, and a temporary defensive wall.
	"bladeguard": {
		"display_name": "Bladeguard",
		"attack": 3,
		"block": 4,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"raider": {
		"display_name": "Raider",
		"attack": 5,
		"block": 2,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"bulwark": {
		"display_name": "Bulwark",
		"attack": 0,
		"block": 4,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.LIFELINK: 1, SpecialEffects.START_TURN: Vector2i(0, -1)},
		"card_type": CardType.BOARD
	},
	# Fragile breakthrough attackers; the siege engine deteriorates each turn.
	"lancer": {
		"display_name": "Lancer",
		"attack": 5,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.ROLLOVER: 1},
		"card_type": CardType.BOARD
	},
	"siegebreaker": {
		"display_name": "Siegebreaker",
		"attack": 6,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.ROLLOVER: 1, SpecialEffects.START_TURN: Vector2i(-2, 0)},
		"card_type": CardType.BOARD
	},
	# Low-stat removal, defensive retaliation, and attack suppression.
	"venomblade": {
		"display_name": "Venomblade",
		"attack": 1,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.DEATHTOUCH: 1},
		"card_type": CardType.BOARD
	},
	"thornwarden": {
		"display_name": "Thornwarden",
		"attack": 1,
		"block": 3,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.LIFELINK: 1},
		"card_type": CardType.BOARD
	},
	"hexweaver": {
		"display_name": "Hexweaver",
		"attack": 2,
		"block": 2,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.FALTER: 1},
		"card_type": CardType.BOARD
	},
	# Scaling threats start weak and reward surviving multiple owner turns.
	"seedling": {
		"display_name": "Seedling",
		"attack": 1,
		"block": 2,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.START_TURN: Vector2i(1, 0)},
		"card_type": CardType.BOARD
	},
	"stoneheart": {
		"display_name": "Stoneheart",
		"attack": 0,
		"block": 2,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.START_TURN: Vector2i(0, 1)},
		"card_type": CardType.BOARD
	},
	"chronodrake": {
		"display_name": "Chronodrake",
		"attack": 1,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.START_TURN: Vector2i(1, 1)},
		"card_type": CardType.BOARD
	},
	# Immediate power trades away longevity.
	"berserker": {
		"display_name": "Berserker",
		"attack": 6,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.START_TURN: Vector2i(-2, -1)},
		"card_type": CardType.BOARD
	},
	"glass_oracle": {
		"display_name": "Glass Oracle",
		"attack": 4,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.FALTER: 1, SpecialEffects.START_TURN: Vector2i(-1, 0)},
		"card_type": CardType.BOARD
	},
	# Extra actions require protecting a non-attacking, deteriorating support.
	"timekeeper": {
		"display_name": "Timekeeper",
		"attack": 0,
		"block": 1,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.BONUS: 1, SpecialEffects.START_TURN: Vector2i(0, -1)},
		"card_type": CardType.BOARD
	},
	# Adjacency affects immediate friendly neighbors only.
	"war_drummer": {
		"display_name": "War Drummer",
		"attack": 2,
		"block": 1,
		"adjacency_effects": Vector2i(1, 0),
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"shield_bearer": {
		"display_name": "Shield Bearer",
		"attack": 1,
		"block": 1,
		"adjacency_effects": Vector2i(0, 1),
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"battle_captain": {
		"display_name": "Battle Captain",
		"attack": 1,
		"block": 1,
		"adjacency_effects": Vector2i(1, 1),
		"special_effects": {SpecialEffects.START_TURN: Vector2i(0, -1)},
		"card_type": CardType.BOARD
	},
	"reckless_banner": {
		"display_name": "Reckless Banner",
		"attack": 3,
		"block": 3,
		"adjacency_effects": Vector2i(1, -1),
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"sapping_totem": {
		"display_name": "Sapping Totem",
		"attack": 0,
		"block": 2,
		"adjacency_effects": Vector2i(-1, 1),
		"special_effects": {},
		"card_type": CardType.BOARD
	},
	"doomed_champion": {
		"display_name": "Doomed Champion",
		"attack": 5,
		"block": 4,
		"adjacency_effects": Vector2i.ZERO,
		"special_effects": {SpecialEffects.START_TURN: Vector2i(-1, -2)},
		"card_type": CardType.BOARD
	}
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
