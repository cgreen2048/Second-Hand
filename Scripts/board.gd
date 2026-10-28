class_name Board
extends Node2D

const SpecialEffects = CardDefinitions.SpecialEffects

@export var p1_card_slots : Array[CardSlot]
@export var p2_card_slots : Array[CardSlot]

var card_slots : Dictionary[int, Array]
var highlight_tweens: Dictionary = {}

const BOARD_GAP = 60

var center_screen_x : float
var center_screen_y : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport_rect = get_viewport_rect().size
	center_screen_x = viewport_rect.x / 2
	center_screen_y = viewport_rect.y / 2
	
	var row_size = p1_card_slots.size()
	var offset = (row_size - 1) * BOARD_GAP / 2
	for i in range(p1_card_slots.size()):
		p1_card_slots[i].index = i
		p1_card_slots[i].global_position = Vector2(
			center_screen_x + i * BOARD_GAP - offset, center_screen_y + BOARD_GAP / 1.5
		)
		
		p2_card_slots[i].index = i
		p2_card_slots[i].global_position = Vector2(
			center_screen_x + i * BOARD_GAP - offset, center_screen_y - BOARD_GAP / 1.5
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
		
		# Combine changes before clamping so effect insertion order cannot change results.
		var attack_change: int = card.special_effects.get(SpecialEffects.GROWTH, 0) - card.special_effects.get(SpecialEffects.WANE, 0)
		var block_change: int = card.special_effects.get(SpecialEffects.HARDEN, 0) - card.special_effects.get(SpecialEffects.SOFTEN, 0)
		card.base_attack = maxi(0, card.base_attack + attack_change)
		card.base_block = maxi(0, card.base_block + block_change)
		card.update_card_labels()
	return bonus_actions


func decrease_time_stops(active_player : int) -> void:
	for card_slot in card_slots[active_player]:
		if card_slot.time_stopped > 0:
			card_slot.time_stopped -= 1


func set_player_card_highlights(enabled: bool, for_attack: bool = false) -> void:
	for card_slot in p1_card_slots:
		var eligible: bool = card_slot.card_in_slot != null and card_slot.time_stopped == 0
		if eligible and for_attack:
			eligible = card_slot.card_in_slot.falter_turns_remaining == 0
		card_slot.set_highlighted(enabled and eligible)
	
	update_highlight_flicker(enabled, "highlight")

func set_all_card_highlights(enabled: bool) -> void:
	for card_slot in p1_card_slots:
		card_slot.set_highlighted(enabled and card_slot.time_stopped == 0)
	for card_slot in p2_card_slots:
		card_slot.set_highlighted(enabled and card_slot.time_stopped == 0)
	
	update_highlight_flicker(enabled, "highlight")

func set_card_attacking_marker(card_slot: CardSlot, enabled: bool) -> void:
	card_slot.set_attacking_marker(enabled)
	
	update_highlight_flicker(enabled, "attack")

func set_highlight_alpha(alpha: float, highlight_type: String) -> void:
	for slot in p1_card_slots:
		set_slot_highlight_alpha(slot, alpha, highlight_type)
	for slot in p2_card_slots:
		set_slot_highlight_alpha(slot, alpha, highlight_type)

func set_slot_highlight_alpha(
	slot: CardSlot,
	alpha: float,
	highlight_type: String
) -> void:
	match highlight_type:
		"highlight":
			slot.highlight.modulate.a = alpha
		"attack":
			slot.attacking_marker.modulate.a = alpha

func update_highlight_flicker(enabled: bool, highlight_type: String) -> void:
	if highlight_tweens.has(highlight_type):
		var previous_tween: Tween = highlight_tweens[highlight_type]
		previous_tween.kill()
		highlight_tweens.erase(highlight_type)

	set_highlight_alpha(1.0, highlight_type)

	if not enabled:
		return

	var tween := create_tween()
	highlight_tweens[highlight_type] = tween

	for i in range(1):
		tween.tween_interval(0.3)
		tween.tween_callback(set_highlight_alpha.bind(0.0, highlight_type))
		tween.tween_interval(0.3)
		tween.tween_callback(set_highlight_alpha.bind(1.0, highlight_type))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
