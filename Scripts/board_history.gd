class_name BoardHistory
extends Node

const MAX_STORED_STATES = 10
const CARD_SCENE := preload("res://Scenes/card.tscn")
const BOARD_SCENE := preload("res://Scenes/board.tscn")

var current_history_board : Board = null 
var past_board_states : Array[BoardState] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_history_board = BOARD_SCENE.instantiate() as Board

func add_board_state(p1_card_slots : Array[CardSlot], p2_card_slots : Array[CardSlot]):
	record_snapshot(BoardState.new(p1_card_slots, p2_card_slots))

func record_snapshot(snapshot: BoardState) -> void:
	if past_board_states.size() == MAX_STORED_STATES:
		past_board_states.pop_back()
	past_board_states.push_front(snapshot)

func reconstruct_whole_board_from_history(num_actions_ago: int):
	var board_state = past_board_states[num_actions_ago - 1]
	var p1_card_slots = current_history_board.p1_card_slots
	var p2_card_slots = current_history_board.p2_card_slots

	var p1_card_slot_states = board_state.p1_card_slot_states
	var p2_card_slot_states = board_state.p2_card_slot_states
	
	for i in range(p1_card_slot_states.size()):
		update_card_slot_by_state(p1_card_slot_states[i], p1_card_slots[i], Definitions.PLAYER_ONE)
		update_card_slot_by_state(p2_card_slot_states[i], p2_card_slots[i], Definitions.PLAYER_TWO)
		_update_preview_rewind_display(p1_card_slot_states[i], p1_card_slots[i])
		_update_preview_rewind_display(p2_card_slot_states[i], p2_card_slots[i])
		
	current_history_board.set_time_target_markers(true)

func _update_preview_rewind_display(slot_state: Dictionary, slot: CardSlot) -> void:
	# Older snapshots only have the flag; keep those marked as rewinding too.
	slot.rewind_actions_remaining = slot_state.get("rewind_actions_remaining", 1 if slot_state.get("is_rewinding", false) else -1)
	slot.refresh_rewind_display(true)


func update_card_slot_by_history(num_actions_ago: int, card_slot: CardSlot, owner_number : int) -> bool:
	if num_actions_ago < 1 or num_actions_ago > past_board_states.size():
		return false

	var board_state := past_board_states[num_actions_ago - 1]
	var slot_states := board_state.p1_card_slot_states if owner_number == Definitions.PLAYER_ONE else board_state.p2_card_slot_states
	var slot_index := card_slot.index

	update_card_slot_by_state(slot_states[slot_index], card_slot, owner_number)
	return true

func update_card_slot_by_state(card_slot_state: Dictionary, card_slot: CardSlot, owner_number : int) -> void:
	card_slot.time_stopped = card_slot_state["time_stopped_turns"]

	var previous_card = card_slot.card_in_slot
	if is_instance_valid(previous_card):
		previous_card.hide()
		previous_card.queue_free()
	card_slot.card_in_slot = null

	var definition_id = card_slot_state["card_definition_id"]
	if definition_id == null:
		return

	var card = CARD_SCENE.instantiate() as Card
	card.setup(definition_id, owner_number)
	_apply_saved_card_stats(card, card_slot_state)
	card.card_slot = card_slot
	card_slot.card_in_slot = card
	card_slot.add_child(card)
	card.position = Vector2.ZERO
	card.show()

func get_size() -> int:
	return past_board_states.size()

func _apply_saved_card_stats(card: Card, slot_state: Dictionary) -> void:
	card.base_attack = slot_state["card_attack"]
	card.base_block = slot_state["card_block"]
	card.falter_turns_remaining = slot_state["card_falter_turns"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
