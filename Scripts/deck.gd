class_name Deck
extends InteractiveElement

var deck = ["knight", "goblin", "tank", "knight", "goblin", "tank", "knight"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	pass

# update to move draw_card to here and only instantiate the Card to be passed back to Player. Have Player add to hand
func handle_interaction(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# open deck view
		pass


func draw_card():
	if deck.size():
		return deck.pop_back()
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
