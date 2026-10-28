class_name FSM
extends Node2D

@export var game_manager : GameManager
@export var card_slots: Array[CardSlot]
const PLAYER_TWO = 2

var can_take_actions: bool = false
var can_choose_defense: bool = false
var discard_in_progress: bool = false

@onready var hand : Hand = $"../Hand"

var filled_slots: Array[CardSlot] = []
var empty_slots: Array[CardSlot] = []
var available_combat_slots: Array[CardSlot] = []
var available_attack_slots: Array[CardSlot] = []
var available_placement_slots: Array[CardSlot] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func take_turn_action(actions_remaining : int):
	await get_tree().create_timer(1).timeout
	# A queued decision must not play a card after turn-end discarding begins.
	if game_manager.active_player != PLAYER_TWO or game_manager.phase != GameManager.Phase.ACTION:
		return
	refresh_slots()
	
	if actions_remaining >= 2 and not available_placement_slots.is_empty() and not hand.hand.is_empty():
		place_random_card()
	elif actions_remaining >= 1 and not available_attack_slots.is_empty():
		attack_with_random_card_on_board()
	else:
		end_turn()

func place_random_card():
	var card_to_place = hand.hand[randi_range(0, hand.hand.size() - 1)]
	var chosen_slot = available_placement_slots[randi_range(0, available_placement_slots.size() - 1)]
	
	if game_manager.request_card_placement(PLAYER_TWO, card_to_place, chosen_slot):
		hand.remove_card_from_hand(card_to_place)

func attack_with_random_card_on_board():
	var chosen_slot = available_attack_slots[randi_range(0, available_attack_slots.size() - 1)]
	var chosen_card = chosen_slot.card_in_slot
	game_manager.request_attack_with_card_on_board(PLAYER_TWO, chosen_card)
	
func choose_defense():
	refresh_slots()

	var blocking_card: Card = null
	
	# 75% chance to block if possible
	if not available_combat_slots.is_empty() and randi_range(0, 3) != 0:
		var slot = available_combat_slots[randi_range(0, available_combat_slots.size() - 1)]
		blocking_card = slot.card_in_slot

	game_manager.request_defense_with_card(PLAYER_TWO, blocking_card)


func end_turn():
	game_manager.request_end_turn(hand.get_size())

func begin_discarding(max_hand_size: int) -> void:
	if discard_in_progress:
		return
	discard_in_progress = true
	while hand.get_size() > max_hand_size:
		var card = hand.hand[randi_range(0, hand.get_size() - 1)]
		await hand.discard_card(card)
	discard_in_progress = false
	end_turn()

func update_state(allow_actions: bool, allow_defense: bool) -> void:
	# Store permissions only. The future AI decides which request to submit.
	can_take_actions = allow_actions
	can_choose_defense = allow_defense
	
	
func refresh_slots() -> void:
	filled_slots.clear()
	empty_slots.clear()
	available_combat_slots.clear()
	available_attack_slots.clear()
	available_placement_slots.clear()

	for slot in card_slots:
		if slot.card_in_slot == null:
			empty_slots.append(slot)
			if slot.time_stopped == 0:
				available_placement_slots.append(slot)
		else:
			filled_slots.append(slot)
			if slot.time_stopped == 0:
				available_combat_slots.append(slot)
				if slot.card_in_slot.falter_turns_remaining == 0:
					available_attack_slots.append(slot)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
