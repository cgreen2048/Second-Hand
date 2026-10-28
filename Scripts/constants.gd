class_name CardDefinitions
extends RefCounted

enum CardType {
	BOARD,
	SPELL
}

enum SpecialEffects {
	GROWTH,
	HARDEN,
	WANE,
	SOFTEN,
	FALTER,
	DEATHTOUCH,
	LIFELINK,
	ROLLOVER,
	BONUS,
}

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
	}
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
