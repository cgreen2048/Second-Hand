class_name Graveyard
extends InteractiveElement

signal view_requested(collection_name: String, cards: Array[String])

@export_enum("Player One:1", "Player Two:2") var owner_player: int = Definitions.PLAYER_ONE

var graveyard = []

func handle_interaction(event: InputEvent) -> void:
	if owner_player != Definitions.PLAYER_ONE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var cards: Array[String] = []
		cards.assign(graveyard)
		view_requested.emit("Graveyard", cards)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func add_card(definition_id : String):
	graveyard.append(definition_id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
