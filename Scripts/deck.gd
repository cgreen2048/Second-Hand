class_name Deck
extends InteractiveElement

signal view_requested(collection_name: String, cards: Array[String])

const PLAYER_ONE := 1
@export_enum("Player One:1", "Player Two:2") var owner_player: int = PLAYER_ONE

const STARTING_DECK_SIZE := 30
const MAX_COPIES_PER_CARD := 2

var deck: Array = []


func generate_random_card_deck() -> void:
	var card_pool: Array[String] = []
	for definition_id in CardDefinitions.CARDS:
		for copy_index in range(MAX_COPIES_PER_CARD):
			card_pool.append(definition_id)
	assert(card_pool.size() >= STARTING_DECK_SIZE, "Not enough unique cards to generate a full deck.")
	card_pool.shuffle()
	deck = card_pool.slice(0, STARTING_DECK_SIZE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	pass

func handle_interaction(event: InputEvent) -> void:
	if owner_player != PLAYER_ONE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var cards: Array[String] = []
		cards.assign(deck)
		view_requested.emit("Deck", cards)


func draw_card():
	if deck.size():
		return deck.pop_back()
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
