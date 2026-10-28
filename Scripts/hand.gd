class_name Hand
extends Node2D

@export var player_number: int = 1
@export var hand_y: float = 390.0

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
const CARD_WIDTH = 50


@onready var deck : Deck = $"../Deck"
@onready var discard_pile : DiscardPile = $"../DiscardPile"
@onready var graveyard : Graveyard = $"../Graveyard"
var hand = []
var center_screen_x : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport_rect().size.x / 2


func add_card_to_hand(definition_id : String, pos: Vector2):
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate() as Card
	
	new_card.setup(definition_id, player_number)
	self.add_child(new_card)
	
	new_card.global_position = pos
	hand.append(new_card)
	update_card_positions()
	
	return new_card


func remove_card_from_hand(card: Card):
	hand.erase(card)
	update_card_positions()


func discard_card(card : Card):
	# The departing card no longer participates in mouse picking.
	card.input_pickable = false
	card.collision_layer = 0
	discard_pile.add_card(card.definition_id)
	remove_card_from_hand(card)
	card.stored_position = discard_pile.global_position
	
	await card.movement_tween.finished
	card.queue_free()

func send_card_to_graveyard(card : Card):
	graveyard.add_card(card.definition_id)
	remove_card_from_hand(card)
	card.stored_position = graveyard.global_position
	
	await card.movement_tween.finished
	card.queue_free()

func update_card_positions():
	var hand_size = hand.size()
	var offset = (hand_size - 1) * CARD_WIDTH / 2
	for i in range(hand_size):
		var x_pos = center_screen_x + i * CARD_WIDTH - offset
		var pos = Vector2(x_pos, hand_y)
		var card = hand[i]
		card.stored_position = pos

func get_size() -> int:
	return hand.size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
