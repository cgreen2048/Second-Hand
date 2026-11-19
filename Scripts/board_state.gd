class_name BoardState
extends Resource

var p1_card_slot_states : Array[Dictionary] = [{}, {}, {}, {}]
var p2_card_slot_states : Array[Dictionary] = [{}, {}, {}, {}]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(p1_card_slots : Array[CardSlot], p2_card_slots : Array[CardSlot]):
	for i in range(p1_card_slots.size()):
		var p1_card_slot = p1_card_slots[i]
		var p1_card_slot_state := _capture_history_state(p1_card_slot)
		p1_card_slot_states[i] = p1_card_slot_state

		var p2_card_slot = p2_card_slots[i]
		var p2_card_slot_state := _capture_history_state(p2_card_slot)
		p2_card_slot_states[i] = p2_card_slot_state

func _capture_history_state(slot: CardSlot) -> Dictionary:
	var state := slot.capture_state()
	state["is_rewinding"] = slot.rewind_actions_remaining > 0
	state["rewind_actions_remaining"] = slot.rewind_actions_remaining if slot.rewind_actions_remaining > 0 else -1
	
	return state
	#var state: Dictionary
	#if slot.rewind_actions_remaining > 0:
		#state = slot.state_before_rewind.duplicate(true)
	#else:
		#state = slot.capture_state()
	#state["is_rewinding"] = slot.rewind_actions_remaining > 0
	#state["rewind_actions_remaining"] = slot.rewind_actions_remaining if slot.rewind_actions_remaining > 0 else -1
	#return state
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
