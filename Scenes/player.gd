class_name Player
extends Node2D

@onready var hand: Hand = $Hand
@onready var deck: Deck = $Deck
@onready var graveyard: Graveyard = $Graveyard
@onready var discard_pile: DiscardPile = $DiscardPile
@onready var input_manager: InputManager = $InputManager

var hp : int = 25
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func draw_card():
	var definition_id = deck.draw_card()
	if definition_id == null:
		deck.deck = discard_pile.discard_pile.duplicate()
		discard_pile.discard_pile.clear()
		deck.deck.shuffle()
		definition_id = deck.draw_card()

	if definition_id == null:
		return
		
	var new_card = hand.add_card_to_hand(definition_id, deck.global_position)
	
	input_manager.register_card(new_card)

func move_card_to_graveyard(card : Card):
	graveyard.add_card(card.definition_id)
	card.stored_position = graveyard.global_position
	
	await card.movement_tween.finished
	card.queue_free()

func take_damage(attack : int):
	hp = max(hp - attack, 0)

func get_hp():
	return hp

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
