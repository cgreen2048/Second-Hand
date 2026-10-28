class_name GameManager
extends Node2D

@export var board : Board
@export var player : Player
@export var opponent : Opponent
@export var controllers : Dictionary
@onready var participants: Dictionary = {
	1: player,
	2: opponent
}
@onready var hud = $HUD
@onready var game_status : Label = $GameStatus

signal turn_changed(active_player : int, actions_remaining : int)
signal defense_requested(pending_defender : int, card: Card)
signal action_complete(active_player : int)

const MAX_CARDS_IN_END_OF_TURN_HAND = 4
const STARTING_ACTION_COUNT = 2
const PLAYER_ONE = 1
const PLAYER_TWO = 2


enum Phase {
	SETUP,
	TURN_START,
	ACTION,
	ATTACK,
	AWAITING_DEFENSE,
	RESOLVING_ACTION,
	TURN_END,
	GAME_OVER
}

var phase : Phase = Phase.SETUP
var active_player : int = PLAYER_ONE
var turn_number : int = 0
var actions_remaining : int = 0
var starting_actions : int = 0
var time_action_taken: bool = false
var pending_attacker : Card = null
var pending_defender : int = 0
var remaining_damage: float = 0.0
var pending_rollover: bool = false
var pending_attack_slot: CardSlot = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for controller_num in controllers:
		var controller = get_node(controllers[controller_num])

	start_match()


func start_match():
	for i in range(MAX_CARDS_IN_END_OF_TURN_HAND - 1):
		player.draw_card()
		opponent.draw_card()
	
	start_turn(PLAYER_ONE)

func start_turn(player_number : int):
	active_player = player_number
	phase = Phase.TURN_START
	time_action_taken = false
	starting_actions = STARTING_ACTION_COUNT + board.apply_start_turn_card_effects(active_player)
	actions_remaining = starting_actions
	
	if active_player == PLAYER_ONE:
		turn_number += 1
		# potentially update this in hud later)
		
	var hud_state = {
		"active_player": active_player,
		"actions_remaining": actions_remaining,
		"starting_actions": starting_actions,
		"time_action_taken": time_action_taken,
		"has_attack_card": board.is_card_slot_available_for_action(PLAYER_ONE, true),
	}
	hud.update_state(hud_state)
	
	participants[active_player].draw_card()
	phase = Phase.ACTION
	update_controllers()
	if active_player == PLAYER_TWO:
		var controller = get_node(controllers[PLAYER_TWO])
		controller.take_turn_action(actions_remaining)
	

func request_end_turn(hand_size: int):
	phase = Phase.TURN_END
	update_controllers()
	board.set_all_card_highlights(false)
	hud.set_attack_buttons_visible(false)
	hud.set_block_buttons_visible(false)
	hud.set_cancel_visible(false)
	check_remaining_discards(hand_size)
	return true
	

func check_remaining_discards(hand_size : int):
	if hand_size > MAX_CARDS_IN_END_OF_TURN_HAND:
		if active_player == PLAYER_ONE:
			hud.show_discard_controls(hand_size - MAX_CARDS_IN_END_OF_TURN_HAND)
		var controller = get_node(controllers[active_player])
		controller.begin_discarding(MAX_CARDS_IN_END_OF_TURN_HAND)
	else:
		hud.hide_discard_controls()
		end_turn()
		

func end_turn():
	board.decrease_time_stops(active_player)
	start_turn(PLAYER_TWO if active_player == PLAYER_ONE else PLAYER_ONE)

func request_card_placement(player: int, card: Card, card_slot: CardSlot):
	if (
		player != active_player
		or not board.card_slot_in_player_slots(card.player_number, card_slot)
		or card_slot.time_stopped > 0
		or card_slot.card_in_slot != null
	):
		return false
	
	card_slot.card_in_slot = card
	card.card_slot = card_slot
	card.stored_position = card_slot.global_position
	card.reparent(board)
	card.show()
	card.adjacency_stat_modifier = board.get_adjacent_stat_modifier(card.index, active_player)
	card.update_card_labels()
	board.update_adjacency_effects(card.adjacency_effects, card.index, active_player)
	
	var human_input := get_node(controllers[PLAYER_ONE]) as InputManager
	human_input.register_card_hover(card)
	
	actions_remaining -= 1
	
	update_game_state()
	return true

func request_to_begin_attack():
	# InputManager only enters here from its normal-action mode.
	if board.is_card_slot_available_for_action(active_player, true):
		board.set_player_card_highlights(true, true)
		hud.set_attack_buttons_visible(false)
		hud.set_cancel_visible(true)
		return true
	else:
		return false
		# eventually, show error

func request_attack_with_card_on_board(attacker: int, attacking_card: Card):
	if not can_take_action(attacker):
		return false
	if not owns_board_card(attacker, attacking_card):
		return false
	if attacking_card.card_slot.time_stopped > 0 or attacking_card.falter_turns_remaining > 0:
		return false
	
	pending_attacker = attacking_card
	pending_defender = PLAYER_TWO if attacker == PLAYER_ONE else PLAYER_ONE
	remaining_damage = attacking_card.attack
	pending_rollover = CardDefinitions.SpecialEffects.ROLLOVER in attacking_card.special_effects
	pending_attack_slot = attacking_card.card_slot
	request_pending_attack_defense()
	return true


func request_pending_attack_defense() -> void:
	if pending_rollover and is_zero_approx(remaining_damage):
		finish_pending_attack()
		return
	phase = Phase.AWAITING_DEFENSE
	
	if pending_defender == PLAYER_ONE:
		if is_instance_valid(pending_attacker):
			board.set_card_attacking_marker(pending_attack_slot, true)
	else:
		board.set_player_card_highlights(false)
		hud.set_cancel_visible(false)
	update_controllers()
	hud.set_rollover_damage(remaining_damage, pending_rollover and pending_defender == PLAYER_ONE)
	
	if board.is_card_slot_available_for_action(pending_defender):
		if pending_defender == PLAYER_ONE:
			hud.set_block_buttons_visible(true)
		else:
			var controller = get_node(controllers[PLAYER_TWO])
			controller.call_deferred("choose_defense")
	else:
		# No blockers left: all damage still pending goes to the participant.
		call_deferred("request_defense_with_card", pending_defender, null)


func request_to_begin_defense():
	# InputManager already requires AWAITING_BLOCK; attack setup checked for cards.
	# turns block buttons off, cancel on
	board.set_player_card_highlights(true)
	hud.set_block_buttons_visible(false)
	hud.set_cancel_visible(true)
	return true

func request_defense_with_card(defender : int, defending_card: Card):
	if (
		defender != pending_defender
		or phase != Phase.AWAITING_DEFENSE
		or (
			defending_card != null
			and defending_card.card_type == CardDefinitions.CardType.BOARD
			and not owns_board_card(defender, defending_card)
		)
		or (
			defending_card != null
			and defending_card.card_type == CardDefinitions.CardType.SPELL
			and defending_card.card_slot != null
		)
		or (
			defending_card != null
			and defending_card.card_slot != null
			and defending_card.card_slot.time_stopped > 0
		)
	):
		return false
	
	phase = Phase.RESOLVING_ACTION
	board.set_player_card_highlights(false)
	update_controllers()
	
	var defending_slot : CardSlot = null
	if pending_defender == PLAYER_ONE:
		# turn block and cancel off
		hud.set_block_buttons_visible(false)
		hud.set_cancel_visible(false)
	elif defending_card != null and defending_card.card_slot != null:
		defending_slot = defending_card.card_slot
		board.set_card_attacking_marker(defending_slot, true)
		await get_tree().create_timer(1).timeout
	
	if is_instance_valid(pending_attacker):
		remaining_damage = await resolve_attack_with_card_on_board(pending_attacker, defending_card, remaining_damage)
	else:
		remaining_damage = await resolve_rollover_damage(remaining_damage, defending_card)
	
	if pending_attack_slot != null:
		board.set_card_attacking_marker(pending_attack_slot, false)
	if defending_slot != null:
		board.set_card_attacking_marker(defending_slot, false)

	hud.set_rollover_damage(remaining_damage, pending_rollover and pending_defender == PLAYER_ONE)
	if pending_rollover and remaining_damage > 0.0:
		request_pending_attack_defense()
	else:
		finish_pending_attack()
	return true


func finish_pending_attack() -> void:
	if pending_attack_slot != null:
		board.set_card_attacking_marker(pending_attack_slot, false)
	pending_attacker = null
	pending_defender = -1
	pending_attack_slot = null
	pending_rollover = false
	remaining_damage = 0.0
	hud.set_rollover_damage(0.0, false)
	actions_remaining -= 1
	phase = Phase.ACTION
	update_game_state()
	

func resolve_attack_with_card_on_board(attacker: Card, defender: Card, damage: float = -1.0) -> float:
	var incoming_damage: float = attacker.attack if damage < 0.0 else damage
	var has_rollover: bool = CardDefinitions.SpecialEffects.ROLLOVER in attacker.special_effects
	hud.show_combat_status(attacker, active_player, hud.attacker_status, "Attacking!")
	await get_tree().create_timer(1).timeout
	
	if defender == null:
		hud.attacker_status.hide()
		participants[pending_defender].take_damage(ceili(incoming_damage))
		return 0.0
	
	var damage_left: float = defender.get_remaining_rollover_damage(incoming_damage) if has_rollover else 0.0
	var attacker_died = attacker.take_damage(defender.attack)
	var defender_died = defender.take_damage(incoming_damage)
	# Both cards make contact, so Deathtouch works when attacking or blocking.
	if CardDefinitions.SpecialEffects.DEATHTOUCH in attacker.special_effects:
		defender_died = true
	if CardDefinitions.SpecialEffects.DEATHTOUCH in defender.special_effects:
		attacker_died = true
	# Lifelink only triggers when its owner dies while blocking.
	if defender_died and CardDefinitions.SpecialEffects.LIFELINK in defender.special_effects:
		attacker_died = true
	# Inflict after resolving damage so the initial hit uses the old status.
	if not defender_died and incoming_damage > 0 and CardDefinitions.SpecialEffects.FALTER in attacker.special_effects:
		defender.apply_falter()

	hud.show_combat_status(attacker,active_player,hud.attacker_status, "Destroyed!" if attacker_died else "Survived!")
	hud.show_combat_status(defender, pending_defender, hud.defender_status, "Destroyed!" if defender_died else "Blocked!")
	
	await get_tree().create_timer(1).timeout
	
	hud.hide_status_labels()
	
	# The damage continues independently of the attacker node after it perishes.
	if attacker_died and has_rollover and damage_left > 0.0:
		pending_attacker = null
	if attacker_died:
		remove_card_from_board(attacker, active_player)
	if defender_died:
		remove_card_from_board(defender, pending_defender)
	return damage_left


func resolve_rollover_damage(damage: float, defender: Card) -> float:
	if defender == null:
		participants[pending_defender].take_damage(ceili(damage))
		return 0.0
	# No attacker remains to retaliate against or to apply contact abilities.
	var damage_left: float = defender.get_remaining_rollover_damage(damage)
	var defender_died: bool = defender.take_damage(damage)
	hud.show_combat_status(defender, pending_defender, hud.defender_status, "Destroyed!" if defender_died else "Blocked!")
	await get_tree().create_timer(1).timeout
	hud.hide_status_labels()
	if defender_died:
		remove_card_from_board(defender, pending_defender)
	return damage_left


func remove_card_from_board(card : Card, player : int):
	var active_card_slot = card.card_slot
	board.update_adjacency_effects(-card.adjacency_effects, card.index, player)
	active_card_slot.card_in_slot = null
	card.card_slot = null
	card.adjacency_stat_modifier = Vector2i.ZERO
	card.update_card_labels()
	hud.hide_card_tooltip(card)
	
	participants[player].move_card_to_graveyard(card)

func request_to_begin_time_stop():
	if not can_take_action(PLAYER_ONE) or time_action_taken:
		return false

	board.set_all_card_highlights(true)
	hud.set_attack_buttons_visible(false)
	hud.set_cancel_visible(true)
	return true


func request_time_stop(player_number: int, slot: CardSlot):
	if not can_take_action(player_number) or time_action_taken:
		return false

	if slot == null:
		return false
	if (
		not board.card_slot_in_player_slots(PLAYER_ONE, slot)
		and not board.card_slot_in_player_slots(PLAYER_TWO, slot)
	):
		return false
	if slot.time_stopped > 0:
		return false

	slot.time_stopped = 2
	time_action_taken = true
	actions_remaining -= 1
	update_game_state()
	return true


func cancel_action():
	hud.set_cancel_visible(false)
	board.set_all_card_highlights(false)
	
	if phase == Phase.ACTION:
		hud.set_attack_buttons_visible(true)
	if phase == Phase.AWAITING_DEFENSE:
		hud.set_block_buttons_visible(true)


func request_show_card_tooltip(hovered_card : Card) -> void:
	hud.show_card_tooltip(hovered_card)
	
func request_hide_card_tooltip(hovered_card : Card) -> void:
	hud.hide_card_tooltip(hovered_card)
	
func update_game_state():
	# at the end of an action, we want to 
	
	#1. Flip UI back to targeted state (i.e. if actions remaining and player turn, normal buttons)
	#- if actions remaining and not player turn, no UI
	#- if no actions remain, set attack and time action to invisible
	#2. Update HP for player and opponent
	#3. Update actions remaining
	var hud_state = {
		"active_player": active_player,
		"actions_remaining": actions_remaining,
		"player_hp": player.get_hp(),
		"has_attack_card": board.is_card_slot_available_for_action(PLAYER_ONE, true),
		"time_action_taken": time_action_taken,
		"opponent_hp": opponent.get_hp()
	}
	hud.update_state(hud_state)
	board.set_all_card_highlights(false)
	update_controllers()
	
	if player.get_hp() == 0:
		game_status.visible = true
		game_status.text = "You lose!"
		await get_tree().create_timer(5).timeout
		get_tree().quit()
	elif opponent.get_hp() == 0:
		game_status.visible = true
		game_status.text = "You win!"
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://title_screen.tscn")
	
	if active_player == PLAYER_TWO and phase == Phase.ACTION:
		call_deferred("continue_opponent_turn")
		
	# board.update_history()


func update_controllers() -> void:
	for controller_num in controllers:
		var controller = get_node(controllers[controller_num])
		var owns_action_phase = phase == Phase.ACTION and active_player == controller_num
		controller.update_state(
			owns_action_phase and actions_remaining > 0,
			phase == Phase.AWAITING_DEFENSE and pending_defender == controller_num
		)

func continue_opponent_turn():
	if active_player != PLAYER_TWO or phase != Phase.ACTION:
		return

	var controller = get_node(controllers[PLAYER_TWO])
	controller.take_turn_action(actions_remaining)


# Helpers
func can_take_action(player_number: int) -> bool:
	return (
		player_number == active_player
		and phase == Phase.ACTION
		and actions_remaining > 0
	)

func owns_board_card(player_number: int, card: Card) -> bool:
	if card.player_number != player_number:
		return false
	if card.card_type != CardDefinitions.CardType.BOARD:
		return false
	if not is_instance_valid(card.card_slot):
		return false

	return (
		board.card_slot_in_player_slots(player_number, card.card_slot)
		and card.card_slot.card_in_slot == card
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
