class_name TimeRewindView
extends MarginContainer

signal rewind_requested(player_number: int, slot_index: int, actions_ago: int)

@onready var board_viewport: SubViewport = $VBoxContainer/BoardRow/BoardPreview/BoardViewport
@onready var history_position_label : Label = $VBoxContainer/HistoryPosition
@onready var backward_button : TextureButton = $VBoxContainer/BoardRow/BackwardWrapper/BackwardInTime
@onready var forward_button : TextureButton = $VBoxContainer/BoardRow/ForwardWrapper/ForwardInTime
@onready var rewind_time_button : Button = $VBoxContainer/Buttons/RewindTime
@onready var cancel_button : Button = $VBoxContainer/Buttons/Cancel

var board_history: BoardHistory
var current_snapshot : int
var selected_slot : CardSlot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board_viewport.size_changed.connect(_center_preview_board)
	backward_button.pressed.connect(_on_backward_button_pressed)
	forward_button.pressed.connect(_on_forward_button_pressed)
	rewind_time_button.pressed.connect(_on_rewind_time_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

func _input(event : InputEvent) -> void:
	if board_history == null or board_history.past_board_states.is_empty():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var slot := get_slot_under_mouse()
			if slot != null:
				select_card_slot(slot)

func show_history(history: BoardHistory) -> void:
	board_history = history
	if board_history.past_board_states.is_empty():
		return

	var preview_board := board_history.current_history_board
	if preview_board.get_parent() == null:
		board_viewport.add_child(preview_board)
	
	_center_preview_board()
	
	show_snapshot(1)
	if board_history.get_size() > 1:
		backward_button.show()

func show_snapshot(actions_ago: int) -> void:
	if actions_ago < 1 or actions_ago > board_history.past_board_states.size():
		return
	_on_cancel_button_pressed()
	
	board_history.reconstruct_whole_board_from_history(actions_ago)
	current_snapshot = actions_ago
	history_position_label.text = "1 action ago" if actions_ago == 1 else "%d actions ago" % [actions_ago]

func get_slot_under_mouse() -> CardSlot:
	var preview_board = board_history.current_history_board

	var query = PhysicsPointQueryParameters2D.new()
	query.position = preview_board.get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = Definitions.COLLISION_MASK_CARD_SLOT

	var space_state = preview_board.get_world_2d().direct_space_state
	var hits = space_state.intersect_point(query)

	for hit in hits:
		if hit["collider"] is CardSlot:
			return hit["collider"]

	return null

func select_card_slot(card_slot : CardSlot) -> void:
	if card_slot.rewind_actions_remaining > 0:
		return
	if selected_slot != null:
		selected_slot.scale = Vector2.ONE
	selected_slot = card_slot
	rewind_time_button.show()
	rewind_time_button.text = "Rewind Time" # add cost
	cancel_button.show()
	
	card_slot.set_blocking_marker(false)
	card_slot.set_time_action_marker(true)
	card_slot.scale = Vector2.ONE * 1.1

func _center_preview_board() -> void:
	if board_history == null:
		return

	var preview_board := board_history.current_history_board
	if is_instance_valid(preview_board) and preview_board.get_parent() == board_viewport:
		preview_board.position = Vector2(board_viewport.size) / 2.0

func _on_backward_button_pressed():
	var history_size = board_history.get_size()
	if current_snapshot == history_size:
		return
		
	show_snapshot(current_snapshot + 1)
	
	if current_snapshot == history_size:
		backward_button.hide()
	forward_button.show()
	
func _on_forward_button_pressed():
	if current_snapshot == 1:
		return
	show_snapshot(current_snapshot - 1)
	
	if current_snapshot == 1:
		forward_button.hide()
	backward_button.show()

func _on_rewind_time_button_pressed() -> void:
	var preview_board := board_history.current_history_board
	var player_number := Definitions.PLAYER_ONE
	player_number = Definitions.PLAYER_ONE if selected_slot in preview_board.p1_card_slots else Definitions.PLAYER_TWO
	rewind_requested.emit(player_number, selected_slot.index, current_snapshot)
	
	selected_slot.scale = Vector2.ONE
	selected_slot = null

func _on_cancel_button_pressed() -> void:
	if  selected_slot != null:
		selected_slot.scale = Vector2.ONE
	selected_slot = null
	rewind_time_button.hide()
	cancel_button.hide()

func _exit_tree() -> void:
	if not is_instance_valid(board_history):
		return

	var preview_board := board_history.current_history_board
	if is_instance_valid(preview_board):
		if preview_board.get_parent() == board_viewport:
			board_viewport.remove_child(preview_board)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
