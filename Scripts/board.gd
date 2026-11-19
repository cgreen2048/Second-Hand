class_name Board
extends Node2D

const SpecialEffects = Definitions.SpecialEffects

@export var p1_card_slots : Array[CardSlot]
@export var p2_card_slots : Array[CardSlot]

var card_slots : Dictionary[int, Array]
var marker_tweens: Dictionary = {}
var time_target_markers_enabled := false

const BOARD_GAP = 60

var center_screen_x : float
var center_screen_y : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport_rect = get_viewport_rect().size
	center_screen_x = viewport_rect.x / 2
	center_screen_y = viewport_rect.y / 2
	
	var row_size := p1_card_slots.size()
	var offset := (row_size - 1) * BOARD_GAP / 2.0

	for i in range(row_size):
		p1_card_slots[i].index = i
		p1_card_slots[i].position = Vector2(
			i * BOARD_GAP - offset,
			BOARD_GAP / 1.5
		)

		p2_card_slots[i].index = i
		p2_card_slots[i].position = Vector2(
			i * BOARD_GAP - offset,
			-BOARD_GAP / 1.5
		)
	
	card_slots = {
		1: p1_card_slots,
		2: p2_card_slots
	}
	
	pass # Replace with function body.


func card_slot_in_player_slots(player: int, card_slot: CardSlot):
	if player == 1:
		if card_slot not in p1_card_slots:
			return false
	elif player == 2:
		if card_slot not in p2_card_slots:
			return false
	else:
		return false
	return true

func is_card_slot_available_for_action(active_player=null, for_attack: bool = false):
	if active_player:
		for card_slot in card_slots[active_player]:
			if card_slot.card_in_slot != null and card_slot.time_stopped == 0:
				if not for_attack or card_slot.card_in_slot.falter_turns_remaining == 0:
					return true
	else:
		for player in card_slots:
			for card_slot in card_slots[player]:
				if card_slot.card_in_slot != null and card_slot.time_stopped == 0:
					if not for_attack or card_slot.card_in_slot.falter_turns_remaining == 0:
						return true
	return false

func update_adjacency_effects(effects: Vector2i, card_index: int, player_number: int) -> void:
	if effects == Vector2i.ZERO:
		return
	var slots: Array = card_slots[player_number]
	for neighbor_index in [card_index - 1, card_index + 1]:
		if neighbor_index < 0 or neighbor_index >= slots.size():
			continue
		var card: Card = slots[neighbor_index].card_in_slot
		if card == null:
			continue
		card.adjacency_stat_modifier += effects
		card.update_card_labels()

func refresh_slots() -> void:
	for player_number in card_slots:
		for card_slot in card_slots[player_number]:
			card_slot.refresh_time_stop_display()
			card_slot.refresh_rewind_display()
			var card = card_slot.card_in_slot
			if card == null:
				continue
			card.adjacency_stat_modifier = get_adjacent_stat_modifier(card_slot.index, player_number)
			card.update_card_labels()


func get_slot(player_number: int, slot_index: int) -> CardSlot:
	if not card_slots.has(player_number):
		return null
	var slots: Array = card_slots[player_number]
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]

func rewind_slot(slot: CardSlot, player_number: int, actions_ago: int, history: BoardHistory) -> bool:
	var return_state := slot.capture_state()
	if not history.update_card_slot_by_history(actions_ago, slot, player_number):
		return false
	slot.state_before_rewind = return_state
	slot.rewind_actions_remaining = actions_ago
	refresh_slots()
	return true

func advance_rewinds(history: BoardHistory, newly_rewound_slot: CardSlot = null) -> void:
	for player_number in card_slots:
		for slot: CardSlot in card_slots[player_number]:
			if slot == newly_rewound_slot or slot.rewind_actions_remaining <= 0:
				continue
			slot.rewind_actions_remaining -= 1
			if slot.rewind_actions_remaining == 0:
				history.update_card_slot_by_state(slot.state_before_rewind, slot, player_number)
				slot.state_before_rewind = {}
	refresh_slots()

func get_adjacent_stat_modifier(card_index: int, player_number: int) -> Vector2i:
	var modifier := Vector2i.ZERO
	var slots: Array = card_slots[player_number]
	for neighbor_index in [card_index - 1, card_index + 1]:
		if neighbor_index < 0 or neighbor_index >= slots.size():
			continue
		var neighbor: Card = slots[neighbor_index].card_in_slot
		if neighbor != null:
			modifier += neighbor.adjacency_effects
	return modifier

func apply_start_turn_card_effects(active_player: int) -> int:
	var bonus_actions: int = 0
	for card_slot in card_slots[active_player]:
		if card_slot.time_stopped > 0 or card_slot.card_in_slot == null:
			continue

		var card: Card = card_slot.card_in_slot
		card.falter_turns_remaining = maxi(0, card.falter_turns_remaining - 1)
		bonus_actions += card.special_effects.get(SpecialEffects.BONUS, 0)
		
		var stat_change: Vector2i = card.special_effects.get(SpecialEffects.START_TURN, Vector2i.ZERO)
		card.base_attack = maxi(0, card.base_attack + stat_change.x)
		card.base_block = maxi(0, card.base_block + stat_change.y)
		card.update_card_labels()
	return bonus_actions


func decrease_time_stops(active_player : int) -> void:
	for card_slot in card_slots[active_player]:
		if card_slot.time_stopped > 0:
			card_slot.time_stopped -= 1


func set_player_attack_markers() -> void:
	for card_slot in p1_card_slots:
		var eligible: bool = card_slot.card_in_slot != null and card_slot.time_stopped == 0 and card_slot.card_in_slot.falter_turns_remaining == 0
		card_slot.set_attacking_marker(eligible)

	update_marker_flicker(true, "attack")

func set_player_block_markers() -> void:
	for card_slot in p1_card_slots:
		var eligible: bool = card_slot.card_in_slot != null and card_slot.time_stopped == 0
		card_slot.set_blocking_marker(eligible)

	update_marker_flicker(true, "block")


func clear_player_combat_markers() -> void:
	for card_slot in p1_card_slots:
		card_slot.set_attacking_marker(false)
		card_slot.set_blocking_marker(false)


func set_time_target_markers(enabled: bool) -> void:
	if not enabled and not time_target_markers_enabled:
		return
	time_target_markers_enabled = enabled
	for card_slot in p1_card_slots:
		card_slot.set_time_action_marker(enabled and card_slot.time_stopped == 0)
	for card_slot in p2_card_slots:
		card_slot.set_time_action_marker(enabled and card_slot.time_stopped == 0)
	
	update_marker_flicker(enabled, "time_action")

func set_card_attacking_marker(card_slot: CardSlot, enabled: bool) -> void:
	card_slot.set_attacking_marker(enabled)
	update_marker_flicker(enabled, "attack")

func set_card_blocking_marker(card_slot: CardSlot, enabled: bool) -> void:
	card_slot.set_blocking_marker(enabled)
	update_marker_flicker(enabled, "block")


func set_marker_alpha(alpha: float, marker_type: String) -> void:
	for slot in p1_card_slots:
		set_slot_marker_alpha(slot, alpha, marker_type)
	for slot in p2_card_slots:
		set_slot_marker_alpha(slot, alpha, marker_type)

func set_slot_marker_alpha(
	slot: CardSlot,
	alpha: float,
	marker_type: String
) -> void:
	match marker_type:
		"attack":
			slot.attacking_marker.modulate.a = alpha
		"block":
			slot.blocking_marker.modulate.a = alpha
		"time_action":
			slot.time_action_marker.modulate.a = alpha

func update_marker_flicker(enabled: bool, marker_type: String) -> void:
	if marker_tweens.has(marker_type):
		var previous_tween: Tween = marker_tweens[marker_type]
		previous_tween.kill()
		marker_tweens.erase(marker_type)

	set_marker_alpha(1.0, marker_type)

	if not enabled:
		return

	var tween := create_tween()
	marker_tweens[marker_type] = tween

	for i in range(1):
		tween.tween_interval(0.3)
		tween.tween_callback(set_marker_alpha.bind(0.0, marker_type))
		tween.tween_interval(0.3)
		tween.tween_callback(set_marker_alpha.bind(1.0, marker_type))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
