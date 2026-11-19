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
@onready var board_history: BoardHistory = $BoardHistory
@onready var game_status : Label = $GameStatus

const MAX_CARDS_IN_END_OF_TURN_HAND = 4
const STARTING_ACTION_COUNT = 2


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
var active_player : int = Definitions.PLAYER_ONE
var turn_number : int = 0
var actions_remaining : int = 0
var starting_actions : int = 0
var time_action_taken: bool = false
var pending_attacker : Card = null
var pending_defender : int = 0
var remaining_damage: float = 0.0
var pending_rollover: bool = false
var pending_board_snapshot: BoardState
var pending_attack_slot: CardSlot = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for controller_num in controllers:
		var controller = get_node(controllers[controller_num])
		
	

	start_match()


func start_match():
	player.deck.generate_random_card_deck()
	opponent.deck.generate_random_card_deck()
	await get_tree().create_timer(0.5).timeout
	for i in range(MAX_CARDS_IN_END_OF_TURN_HAND - 1):
		player.draw_card()
		opponent.draw_card()
		await get_tree().create_timer(0.25).timeout
		
	start_turn(Definitions.PLAYER_ONE)

#region START TURN
func start_turn(player_number : int):
	active_player = player_number
	phase = Phase.TURN_START
	time_action_taken = false
	starting_actions = STARTING_ACTION_COUNT + board.apply_start_turn_card_effects(active_player)
	var active_participant = participants[active_player]
	if active_participant.borrowed_time_payback == 0:
		active_participant.borrowed_time_payback = -1
		starting_actions = maxi(0, starting_actions - 1)
	actions_remaining = starting_actions

	if active_player == Definitions.PLAYER_ONE:
		turn_number += 1
		# potentially update this in hud later)
		

	active_participant.draw_card()
	phase = Phase.ACTION
	update_controllers()
	hud.hide_discard_controls()
	hud.show_action_selection(InputManager.ActionMode.NONE if active_player == Definitions.PLAYER_ONE else InputManager.ActionMode.LOCKED)

	var hud_state = {
		"active_player": active_player,
		"actions_remaining": actions_remaining,
		"starting_actions": starting_actions,
		"time_action_taken": time_action_taken,
		"borrowed_time_payback": player.borrowed_time_payback,
		"is_player_action_phase": active_player == Definitions.PLAYER_ONE,
		"time_actions_disabled": player.time_actions_disabled,
		"collapse_active": player.temporal_collapse_timer != -1 or opponent.temporal_collapse_timer != -1,
		"has_attack_card": board.is_card_slot_available_for_action(Definitions.PLAYER_ONE, true),
		"player_hp": player.get_hp(),
		"opponent_hp": opponent.get_hp()
	}
	hud.update_state(hud_state)

	if active_player == Definitions.PLAYER_TWO:
		var controller = get_node(controllers[Definitions.PLAYER_TWO])
		controller.take_turn_action(actions_remaining)
#endregion

#region END TURN
func request_end_turn(hand_size: int):
	phase = Phase.TURN_END
	update_controllers()
	board.clear_player_combat_markers()
	board.set_time_target_markers(false)
	hud.set_attack_buttons_visible(false)
	hud.set_block_buttons_visible(false)
	hud.set_cancel_visible(false)
	check_remaining_discards(hand_size)
	return true


func check_remaining_discards(hand_size : int):
	if hand_size > MAX_CARDS_IN_END_OF_TURN_HAND:
		if active_player == Definitions.PLAYER_ONE:
			hud.show_discard_controls(hand_size - MAX_CARDS_IN_END_OF_TURN_HAND)
		var controller = get_node(controllers[active_player])
		controller.begin_discarding(MAX_CARDS_IN_END_OF_TURN_HAND)
	else:
		hud.hide_discard_controls()
		end_turn()


func end_turn():
	phase = Phase.TURN_END
	update_game_state(true)
	if phase == Phase.GAME_OVER:
		return
	board.decrease_time_stops(active_player)
	start_turn(Definitions.PLAYER_TWO if active_player == Definitions.PLAYER_ONE else Definitions.PLAYER_ONE)
#endregion

#region CARD PLACEMENT
func request_card_placement(player: int, card: Card, card_slot: CardSlot):
	if (
		not board.card_slot_in_player_slots(player, card_slot)
		or card_slot.time_stopped > 0
		or card_slot.card_in_slot != null
	):
		return false

	_capture_board_state_before_action()
	card_slot.card_in_slot = card
	card.card_slot = card_slot
	card.stored_position = card_slot.global_position
	card.reparent(board)
	card.show()

	var human_input := get_node(controllers[Definitions.PLAYER_ONE]) as InputManager
	human_input.register_card_hover(card)

	actions_remaining -= 1

	board.refresh_slots()
	update_game_state()
	return true
#endregion

#region COMBAT
func request_to_begin_attack():
	# InputManager's normal-action mode already establishes turn/action permission.
	return board.is_card_slot_available_for_action(active_player, true)

func request_attack_with_card_on_board(attacker: int, attacking_card: Card):
	if (
		attacking_card.player_number != attacker
		or attacking_card.card_slot == null
		or attacking_card.card_slot.time_stopped > 0
		or attacking_card.falter_turns_remaining > 0
	):
		return false

	_capture_board_state_before_action()
	pending_attacker = attacking_card
	pending_defender = Definitions.PLAYER_TWO if attacker == Definitions.PLAYER_ONE else Definitions.PLAYER_ONE
	remaining_damage = attacking_card.attack
	pending_rollover = Definitions.SpecialEffects.ROLLOVER in attacking_card.special_effects
	pending_attack_slot = attacking_card.card_slot
	request_pending_attack_defense()
	return true


func request_pending_attack_defense() -> void:
	if pending_rollover and is_zero_approx(remaining_damage):
		finish_pending_attack()
		return
	phase = Phase.AWAITING_DEFENSE

	if pending_defender == Definitions.PLAYER_ONE:
		if is_instance_valid(pending_attacker):
			board.set_card_attacking_marker(pending_attack_slot, true)
	else:
		board.clear_player_combat_markers()
		hud.set_cancel_visible(false)
	update_controllers()
	hud.set_rollover_damage(remaining_damage, pending_rollover and pending_defender == Definitions.PLAYER_ONE)

	if board.is_card_slot_available_for_action(pending_defender):
		var controller = get_node(controllers[pending_defender])
		if pending_defender == Definitions.PLAYER_ONE:
			controller.choose_defense()
		else:
			controller.call_deferred("choose_defense")
	else:
		# No blockers left: all damage still pending goes to the participant.
		call_deferred("request_defense_with_card", pending_defender, null)


func request_defense_with_card(defender : int, defending_card: Card):
	if defending_card != null:
		if defending_card.player_number != defender:
			return false
		if defending_card.card_type == Definitions.CardType.BOARD and defending_card.card_slot == null:
			return false
		if defending_card.card_slot != null and defending_card.card_slot.time_stopped > 0:
			return false

	phase = Phase.RESOLVING_ACTION
	board.clear_player_combat_markers()
	update_controllers()

	var defending_slot : CardSlot = null
	if pending_defender == Definitions.PLAYER_ONE:
		# turn block and cancel off
		hud.set_block_buttons_visible(false)
		hud.set_cancel_visible(false)
	elif defending_card != null and defending_card.card_slot != null:
		defending_slot = defending_card.card_slot
		board.set_card_blocking_marker(defending_slot, true)
		await get_tree().create_timer(1).timeout

	if is_instance_valid(pending_attacker):
		remaining_damage = await resolve_attack_with_card_on_board(pending_attacker, defending_card, remaining_damage)
	else:
		remaining_damage = await resolve_rollover_damage(remaining_damage, defending_card)

	if pending_attack_slot != null:
		board.set_card_attacking_marker(pending_attack_slot, false)
	if defending_slot != null:
		board.set_card_blocking_marker(defending_slot, false)

	hud.set_rollover_damage(remaining_damage, pending_rollover and pending_defender == Definitions.PLAYER_ONE)
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
	var has_rollover: bool = Definitions.SpecialEffects.ROLLOVER in attacker.special_effects
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
	if Definitions.SpecialEffects.DEATHTOUCH in attacker.special_effects:
		defender_died = true
	if Definitions.SpecialEffects.DEATHTOUCH in defender.special_effects:
		attacker_died = true
	# Lifelink only triggers when its owner dies while blocking.
	if defender_died and Definitions.SpecialEffects.LIFELINK in defender.special_effects:
		attacker_died = true
	# Inflict after resolving damage so the initial hit uses the old status.
	if not defender_died and incoming_damage > 0 and Definitions.SpecialEffects.FALTER in attacker.special_effects:
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
	active_card_slot.card_in_slot = null
	board.refresh_slots()

	participants[player].move_card_to_graveyard(card)
#endregion 

#region TIME ACTIONS
func request_to_begin_time_action(player_number: int = Definitions.PLAYER_ONE) -> bool:
	return (
		player_number == active_player
		and phase == Phase.ACTION
		and not time_action_taken
		and not participants[player_number].time_actions_disabled
		and (actions_remaining > 0 or participants[player_number].borrowed_time_payback == -1)
	)

func request_to_begin_temporal_collapse() -> bool:
	return actions_remaining > 0 and player.temporal_collapse_timer == -1 and opponent.temporal_collapse_timer == -1

func request_temporal_collapse(player_number: int) -> bool:
	_capture_board_state_before_action()
	participants[player_number].hp = 1
	var receiving_player: int = Definitions.PLAYER_TWO if player_number == Definitions.PLAYER_ONE else Definitions.PLAYER_ONE
	participants[receiving_player].temporal_collapse_timer = 3
	participants[player_number].time_actions_disabled = true
	time_action_taken = true
	actions_remaining -= 1
	hud.create_time_action_clock(Hud.TimeAction.TEMPORAL_COLLAPSE, receiving_player, participants[receiving_player].temporal_collapse_timer)
	update_game_state()
	return true

func request_borrowed_time(player_number : int):
	if participants[player_number].borrowed_time_payback != -1:
		return false

	_capture_board_state_before_action()
	participants[player_number].borrowed_time_payback = 3
	participants[player_number].take_damage(3)
	time_action_taken = true

	# Borrowed Time gives one extra action without costing one
	actions_remaining += 1
	hud.create_time_action_clock(Hud.TimeAction.BORROWED_TIME, player_number, participants[player_number].borrowed_time_payback)

	update_game_state()
	return true

func request_to_begin_time_stop():
	# Shared Time Action permission was established when opening the submenu.
	if actions_remaining <= 0:
		return false

	board.set_time_target_markers(true)
	hud.close_time_action_overlay()
	hud.set_attack_buttons_visible(false)
	hud.set_cancel_visible(true)
	return true

func request_time_stop(slot: CardSlot):
	# InputManager supplies a board slot after entering Time Stop selection.
	if slot.time_stopped > 0:
		return false

	_capture_board_state_before_action()
	slot.time_stopped = 2
	participants[active_player].take_damage(2)
	time_action_taken = true
	actions_remaining -= 1
	update_game_state()
	return true

func request_to_begin_time_rewind():
	if actions_remaining <= 0:
		return false
	return true

# Temporarily restore this slot to an earlier state. When Rewind ends, the slot returns to how it was when you activated it.
# During Rewind, history preserves the return state and marks it as unavailable.
func request_time_rewind(player_number: int, slot_index: int, actions_ago: int) -> bool:
	var snapshot := board_history.past_board_states[actions_ago - 1]
	var states := snapshot.p1_card_slot_states if player_number == Definitions.PLAYER_ONE else snapshot.p2_card_slot_states
	if states[slot_index].get("is_rewinding", false):
		return false

	var slot := board.get_slot(player_number, slot_index)
	_capture_board_state_before_action()
	if not board.rewind_slot(slot, player_number, actions_ago, board_history):
		pending_board_snapshot = null
		return false

	participants[active_player].take_damage(3)
	time_action_taken = true
	actions_remaining -= 1
	update_game_state(false, slot)
	return true
#endregion

func sync_action_selection(mode: InputManager.ActionMode) -> void:
	board.clear_player_combat_markers()
	board.set_time_target_markers(false)
	if mode == InputManager.ActionMode.ATTACK:
		board.set_player_attack_markers()
	elif mode == InputManager.ActionMode.BLOCK:
		board.set_player_block_markers()
	elif mode == InputManager.ActionMode.TIME_STOP:
		board.set_time_target_markers(true)
	elif mode == InputManager.ActionMode.TIME_REWIND_MENU:
		hud.set_board_history(board_history)
	hud.show_action_selection(mode)

func cancel_action(next_mode : InputManager.ActionMode = InputManager.ActionMode.NONE):
	#hud.set_cancel_visible(false)
	board.clear_player_combat_markers()
	board.set_time_target_markers(false)

	# Card input stays locked at zero actions; End Turn and borrowing remain visible.
	if next_mode == InputManager.ActionMode.LOCKED and phase == Phase.ACTION and active_player == Definitions.PLAYER_ONE:
		hud.show_action_selection(InputManager.ActionMode.NONE)
	else:
		hud.show_action_selection(next_mode)
	#if phase == Phase.ACTION:
		#sync_action_selection(next_mode)
		##hud.set_attack_buttons_visible(true)
	#if phase == Phase.AWAITING_DEFENSE:
		#hud.set_block_buttons_visible(true)


func is_world_input_blocked() -> bool:
	return hud.menu_overlay.visible

#region UPDATE GAME STATE
func _capture_board_state_before_action() -> void:
	pending_board_snapshot = BoardState.new(board.p1_card_slots, board.p2_card_slots)

func update_game_state(turn_ended: bool = false, newly_rewound_slot: CardSlot = null):
	if turn_ended:
		var active_participant = participants[active_player]
		if active_participant.borrowed_time_payback > 0:
			active_participant.borrowed_time_payback -= 1
		if active_participant.temporal_collapse_timer > 0:
			active_participant.temporal_collapse_timer -= 1
			if active_participant.temporal_collapse_timer == 0:
				active_participant.take_damage(active_participant.get_hp())
		hud.decrease_time_action_clocks(active_player)
	if not turn_ended and pending_board_snapshot != null:
		board.advance_rewinds(board_history, newly_rewound_slot)
		_register_reconstructed_cards()
		board_history.record_snapshot(pending_board_snapshot)
		pending_board_snapshot = null

	# HP changes have already resolved. Establish terminal state before
	# updating controller permissions or restoring any action controls.
	var player_hp: int = player.get_hp()
	var opponent_hp: int = opponent.get_hp()
	var match_over := phase == Phase.GAME_OVER or player_hp <= 0 or opponent_hp <= 0
	if match_over:
		phase = Phase.GAME_OVER
	board.clear_player_combat_markers()
	board.set_time_target_markers(false)
	update_controllers()

	# Group visibility belongs to explicit action-selection presentation,
	# not the HUD's label/button-availability refresh.
	hud.hide_discard_controls()
	if phase == Phase.ACTION and active_player == Definitions.PLAYER_ONE:
		# End Turn stays available even when no card actions remain.
		hud.show_action_selection(InputManager.ActionMode.NONE)
	elif phase == Phase.AWAITING_DEFENSE and pending_defender == Definitions.PLAYER_ONE:
		hud.show_action_selection(InputManager.ActionMode.AWAITING_BLOCK)
	else:
		hud.show_action_selection(InputManager.ActionMode.LOCKED)

	var hud_state = {
		"active_player": active_player,
		"actions_remaining": actions_remaining,
		"player_hp": player_hp,
		"has_attack_card": board.is_card_slot_available_for_action(Definitions.PLAYER_ONE, true),
		"time_action_taken": time_action_taken,
		"borrowed_time_payback": player.borrowed_time_payback,
		"is_player_action_phase": phase == Phase.ACTION and active_player == Definitions.PLAYER_ONE,
		"time_actions_disabled": player.time_actions_disabled,
		"collapse_active": player.temporal_collapse_timer != -1 or opponent.temporal_collapse_timer != -1,
		"opponent_hp": opponent_hp
	}
	hud.update_state(hud_state)

	if match_over:
		game_status.visible = true
		game_status.text = "You lose!" if player_hp <= 0 else "You win!"
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://title_screen.tscn")
		return

	if active_player == Definitions.PLAYER_TWO and phase == Phase.ACTION:
		get_node(controllers[Definitions.PLAYER_TWO]).call_deferred("take_turn_action", actions_remaining)

func _register_reconstructed_cards() -> void:
	var human_input := get_node(controllers[Definitions.PLAYER_ONE]) as InputManager
	for player_number in board.card_slots:
		for slot: CardSlot in board.card_slots[player_number]:
			if slot.card_in_slot != null:
				human_input.register_card_hover(slot.card_in_slot)

func update_controllers() -> void:
	for controller_num in controllers:
		var controller = get_node(controllers[controller_num])
		var owns_action_phase = phase == Phase.ACTION and active_player == controller_num
		controller.update_state(
			owns_action_phase and actions_remaining > 0,
			phase == Phase.AWAITING_DEFENSE and pending_defender == controller_num
		)
#endregion


func request_show_card_tooltip(hovered_card : Card) -> void:
	hud.show_card_tooltip(hovered_card)

func request_hide_card_tooltip(hovered_card : Card) -> void:
	hud.hide_card_tooltip(hovered_card)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
