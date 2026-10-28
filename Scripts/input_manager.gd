class_name InputManager
extends Node2D

@export var game_manager : GameManager

signal discard_selection_changed(has_selection: bool)

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DRAG_THRESHOLD = 8.0
const PLAYER_ONE = 1
const TOOLTIP_DELAY := 0.5

enum ActionMode {
	NONE,
	ATTACK,
	TIME_ACTION,
	AWAITING_BLOCK,
	BLOCK,
	LOCKED,
	DISCARD
}

@onready var hand : Hand = $"../Hand"
var screen_size : Vector2
var pressed_element : InteractiveElement
var pressed_time_stop_slot: CardSlot = null
var press_position : Vector2
var is_dragging : bool = false
var hovered_card : Card = null
var hover_elapsed := 0.0
var tooltip_shown := false
var selected_card : Card = null

var action_mode : ActionMode = ActionMode.LOCKED
var discard_hand_limit: int = 4
var discard_in_progress: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size


func _input(event):
	if action_mode == ActionMode.LOCKED or action_mode == ActionMode.AWAITING_BLOCK:
		return
	if action_mode == ActionMode.TIME_ACTION:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed_time_stop_slot = raycast_check_for_element(COLLISION_MASK_CARD_SLOT) as CardSlot
			else:
				var released_slot = raycast_check_for_element(COLLISION_MASK_CARD_SLOT) as CardSlot
				var chosen_slot = pressed_time_stop_slot
				pressed_time_stop_slot = null

				if chosen_slot != null and chosen_slot == released_slot:
					game_manager.request_time_stop(PLAYER_ONE, chosen_slot)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed_element = raycast_check_for_element(COLLISION_MASK_CARD) as InteractiveElement
			if pressed_element is Card:
				game_manager.request_hide_card_tooltip(pressed_element)
				hover_elapsed = 0.0
				tooltip_shown = true
	
			press_position = event.position
			is_dragging = false
		else:
			if is_instance_valid(pressed_element):
				if is_dragging:
					if pressed_element.card_slot == null:
						check_for_card_slot()
					else:
						pressed_element.animate_to_position(pressed_element.stored_position)
				else:
					var released_over = raycast_check_for_element(COLLISION_MASK_CARD)
					if pressed_element == released_over:
						match action_mode:
							ActionMode.ATTACK:
								if pressed_element is Card:
									attack_with_card_on_board(pressed_element)
							ActionMode.BLOCK:
								if pressed_element is Card:
									defend_with_card(pressed_element)
							ActionMode.DISCARD:
								if pressed_element is Card:
									select_discard_card(pressed_element)
			
			pressed_element = null
			is_dragging = false
	elif is_instance_valid(pressed_element) and event is InputEventMouseMotion:
		if not is_dragging and pressed_element is Card and action_mode == ActionMode.NONE:
			if event.position.distance_to(press_position) >= DRAG_THRESHOLD:
				is_dragging = true
		
		if is_dragging:
			var mouse_pos = get_global_mouse_position()
			pressed_element.global_position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))


func check_for_card_slot():
	# Called on release of a dragged Card; mouse cleanup stays in _input().
	var card_to_place: Card = pressed_element as Card
	var card_slot_found = raycast_check_for_element(COLLISION_MASK_CARD_SLOT)
	if card_slot_found is CardSlot:
		var success = game_manager.request_card_placement(PLAYER_ONE, card_to_place, card_slot_found)
		if success: 
			hand.remove_card_from_hand(card_to_place)
		else:
			card_to_place.animate_to_position(card_to_place.stored_position)
	else:
		card_to_place.animate_to_position(card_to_place.stored_position)

func begin_attack():
	if action_mode != ActionMode.NONE:
		return
	if game_manager.request_to_begin_attack():
		action_mode = ActionMode.ATTACK

func attack_with_card_on_board(attacking_card: Card):
	# translate to signals eventually so input manager doesn't know what game manager does
	game_manager.request_attack_with_card_on_board(PLAYER_ONE, attacking_card)
	# display error if false

func begin_time_stop():
	if action_mode != ActionMode.NONE:
		return
	if game_manager.request_to_begin_time_stop():
		action_mode = ActionMode.TIME_ACTION



func begin_awaiting_defense():
	action_mode = ActionMode.AWAITING_BLOCK
	
func begin_defense():
	if action_mode != ActionMode.AWAITING_BLOCK:
		return
	if game_manager.request_to_begin_defense():
		action_mode = ActionMode.BLOCK

func defend_with_card(blocking_card: Card):
	game_manager.request_defense_with_card(PLAYER_ONE, blocking_card)
	
func end_turn():
	if discard_in_progress or game_manager.active_player != PLAYER_ONE:
		return
	game_manager.request_end_turn(hand.get_size())


func begin_discarding(max_hand_size: int) -> void:
	discard_hand_limit = max_hand_size
	clear_selected_card()
	action_mode = ActionMode.DISCARD


func select_discard_card(card: Card) -> void:
	if action_mode != ActionMode.DISCARD or card not in hand.hand:
		return
	_on_card_selected(card)
	discard_selection_changed.emit(true)


func discard_selected_card() -> void:
	if action_mode != ActionMode.DISCARD or discard_in_progress:
		return
	if selected_card not in hand.hand or hand.get_size() <= discard_hand_limit:
		return

	var card_to_discard = selected_card
	discard_in_progress = true
	action_mode = ActionMode.LOCKED
	if hovered_card == card_to_discard:
		hovered_card = null
	clear_selected_card()
	await hand.discard_card(card_to_discard)
	discard_in_progress = false
	end_turn()


func clear_selected_card() -> void:
	var previous = selected_card
	selected_card = null
	if is_instance_valid(previous):
		update_card_highlight(previous)
	discard_selection_changed.emit(false)


func cancel_action():
	if action_mode in [ActionMode.ATTACK, ActionMode.TIME_ACTION, ActionMode.BLOCK]:
		if action_mode == ActionMode.BLOCK:
			action_mode = ActionMode.AWAITING_BLOCK
		else:
			action_mode = ActionMode.NONE
		game_manager.cancel_action()

func update_state(allow_actions: bool, allow_defense: bool) -> void:
	# Called at game transitions, not during an ongoing card selection.
	if allow_defense:
		action_mode = ActionMode.AWAITING_BLOCK
	elif allow_actions:
		action_mode = ActionMode.NONE
	else:
		action_mode = ActionMode.LOCKED

func register_card(card: Card) -> void:
	card.connect("select_card", _on_card_selected)
	register_card_hover(card)


func register_card_hover(card: Card) -> void:
	if not card.hovered.is_connected(_on_hovered_over_card):
		card.hovered.connect(_on_hovered_over_card)

	if not card.stop_hover.is_connected(_on_stop_hover_over_card):
		card.stop_hover.connect(_on_stop_hover_over_card)

func update_card_highlight(card: Card) -> void:
	if card == selected_card:
		card.scale = Vector2.ONE * 1.12
		card.z_index = 3
	elif card == hovered_card:
		card.scale = Vector2.ONE * 1.05
		card.z_index = 2
	else:
		card.scale = Vector2.ONE
		card.z_index = 1


func _on_card_selected(card: Card) -> void:
	var previous = selected_card
	selected_card = card

	if is_instance_valid(previous):
		update_card_highlight(previous)

	update_card_highlight(card)


func _on_hovered_over_card(card: Card) -> void:
	if hovered_card != card:
		if is_instance_valid(hovered_card):
			game_manager.request_hide_card_tooltip(hovered_card)

		hover_elapsed = 0.0
		tooltip_shown = false
	var previous = hovered_card
	hovered_card = card

	if is_instance_valid(previous):
		update_card_highlight(previous)

	update_card_highlight(card)


func _on_stop_hover_over_card(card: Card) -> void:
	if hovered_card == card:
		game_manager.request_hide_card_tooltip(card)
		hovered_card = null
		hover_elapsed = 0.0
		tooltip_shown = false

	update_card_highlight(card)


func raycast_check_for_element(collision_mask: int = COLLISION_MASK_CARD | COLLISION_MASK_CARD_SLOT):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = collision_mask
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider
	return null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(hovered_card) and not tooltip_shown:
		hover_elapsed += delta

	if hover_elapsed >= TOOLTIP_DELAY:
		game_manager.request_show_card_tooltip(hovered_card)
		tooltip_shown = true
