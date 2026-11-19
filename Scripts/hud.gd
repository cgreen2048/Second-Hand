class_name Hud
extends CanvasLayer

@export var input_manager : InputManager

@onready var player_hp: Label = $Control/PlayerHP
@onready var opponent_hp: Label = $Control/OpponentHP
@onready var player_turn: Label = $Control/PlayerTurn
@onready var actions_remaining: Label = $Control/ActionsRemaining
@onready var player_turn_ui: HBoxContainer = $Control/PlayerTurnUIHBox
@onready var defending_ui: HBoxContainer = $Control/DefendingUIHBox
@onready var rollover_damage_label: Label = $Control/RolloverDamage

@onready var attack_button: Button = $Control/PlayerTurnUIHBox/AttackButton
@onready var time_action_button: Button = $Control/PlayerTurnUIHBox/TimeActionButton
@onready var time_clock_containers: Dictionary = {
	Definitions.PLAYER_ONE: $Control/PlayerTimeClocls,
	Definitions.PLAYER_TWO: $Control/OpponentTimeClocks
}

@onready var end_turn_button: Button = $Control/PlayerTurnUIHBox/EndTurnButton
@onready var cancel_button: Button = $Control/CancelActionUIHbox/CancelButton
@onready var block_button: Button = $Control/DefendingUIHBox/BlockButton
@onready var no_block_button: Button = $Control/DefendingUIHBox/NoBlockButton
@onready var discard_ui: VBoxContainer = $Control/DiscardUI
@onready var discard_prompt: Label = $Control/DiscardUI/DiscardPrompt
@onready var discard_button: Button = $Control/DiscardUI/DiscardButton


@onready var menu_button: TextureButton = $Control/OpenMenu
@onready var menu_overlay: MenuOverlay = $Control/MenuOverlay

@onready var card_tooltip: PanelContainer = $Control/CardTooltip
@onready var tooltip_name: Label = $Control/CardTooltip/VBoxContainer/CardName
@onready var tooltip_description: RichTextLabel = $Control/CardTooltip/VBoxContainer/CardDescription

@onready var attacker_status : Label = $Control/AttackerStatus
@onready var defender_status : Label = $Control/DefenderStatus


enum TimeAction {
	TEMPORAL_COLLAPSE,
	BORROWED_TIME
}

var can_use_time_stop := false
var can_use_borrowed_time := false
var can_use_temporal_collapse := false
var can_use_time_rewind := false

var tooltip_card : Card = null
var starting_actions : int = 0
var previous_actions_remaining : int = 0
var previous_player_hp : int = 25
var previous_opponent_hp : int = 25
var actions_remaining_tween : Tween
var player_hp_tween : Tween
var opponent_hp_tween : Tween
var rewind_history : BoardHistory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_discard_controls()
	defending_ui.hide()
	cancel_button.visible = false
	player_turn.text = "Player's Turn"
	actions_remaining.text = "Actions Remaining: " + str(starting_actions)
	attack_button.pressed.connect(on_attack_button_pressed)
	time_action_button.pressed.connect(input_manager.begin_time_action)
	block_button.pressed.connect(on_block_button_pressed)
	no_block_button.pressed.connect(on_no_block_button_pressed)
	end_turn_button.pressed.connect(on_end_turn_button_pressed)
	cancel_button.pressed.connect(on_cancel_button_pressed)
	discard_button.pressed.connect(input_manager.discard_selected_card)
	input_manager.discard_selection_changed.connect(set_discard_selection)
	menu_button.pressed.connect(on_menu_button_pressed)
	menu_overlay.view_changed.connect(_on_menu_view_changed)
	menu_overlay.exited.connect(_on_menu_exited)
	for participant in [get_parent().get_node("Player"), get_parent().get_node("Opponent")]:
		for pile_name in ["Deck", "Graveyard", "DiscardPile"]:
			participant.get_node(pile_name).view_requested.connect(_on_card_collection_requested)

	pass # Replace with function body.

# input manager begins, asks game manager if possible, game manager highlights cards, input manager requests attack with selected card
func on_attack_button_pressed() -> void:
	input_manager.begin_attack() # this should now call the game manager to try to attack

func on_block_button_pressed() -> void:
	input_manager.begin_defense()

func on_no_block_button_pressed() -> void:
	input_manager.defend_with_card(null)

func on_end_turn_button_pressed():
	input_manager.end_turn()

func on_cancel_button_pressed():
	input_manager.cancel_action()

func on_menu_button_pressed():
	menu_overlay.open_menu(&"game_menu")


func _on_card_collection_requested(collection_name: String, cards: Array[String]) -> void:
	if menu_overlay.visible:
		return
	menu_overlay.open_menu(&"card_collection_view")
	var view := menu_overlay.current_view as CardCollectionView
	view.open_card_collection(collection_name, cards)
	tooltip_card = null
	card_tooltip.hide()


func _on_menu_view_changed(view: Control) -> void:
	# Also runs when Back recreates the game menu.
	if view is GameMenuView:
		view.show_help_menu.connect(_on_help_menu_requested)
		view.show_main_menu.connect(_on_main_menu_requested)
	elif menu_overlay.current_menu == &"time_action":
		var time_stop: Button = view.get_node("%TimeStopButton")
		var borrowed_time: Button = view.get_node("%BorrowedTimeButton")
		var temporal_collapse: Button = view.get_node("%TemporalCollapseButton")
		var time_rewind: Button = view.get_node("%TimeRewindButton")
		time_stop.disabled = not can_use_time_stop
		borrowed_time.disabled = not can_use_borrowed_time
		temporal_collapse.disabled = not can_use_temporal_collapse
		time_rewind.disabled = not can_use_time_rewind
		time_stop.pressed.connect(input_manager.begin_time_stop)
		borrowed_time.pressed.connect(input_manager.begin_borrowed_time)
		temporal_collapse.pressed.connect(input_manager.begin_temporal_collapse)
		time_rewind.pressed.connect(input_manager.begin_time_rewind)
		input_manager.return_to_time_action_menu()
	elif view is TemporalCollapseView:
		view.confirm_temporal_collapse.connect(input_manager.confirm_temporal_collapse)
		view.cancel_action.connect(menu_overlay.go_back)
	elif view is TimeRewindView:
		view.rewind_requested.connect(_on_rewind_requested)
		view.show_history(rewind_history)
	elif view is CardCollectionView:
		view.card_hovered.connect(show_card_tooltip)
		view.card_unhovered.connect(hide_card_tooltip)
		view.tree_exiting.connect(_on_collection_view_exiting.bind(view))


func _on_rewind_requested(player_number: int, slot_index: int, actions_ago: int) -> void:
	if input_manager.confirm_time_rewind(player_number, slot_index, actions_ago):
		close_time_action_overlay()

func _on_menu_exited(menu: StringName) -> void:
	if menu in [&"time_action", &"temporal_collapse", &"time_rewind"]:
		input_manager.close_time_action_menu()


func _on_collection_view_exiting(view: CardCollectionView) -> void:
	if is_instance_valid(tooltip_card) and view.is_ancestor_of(tooltip_card):
		tooltip_card = null
		card_tooltip.hide()


func _on_help_menu_requested() -> void:
	menu_overlay.navigate_to(&"how_to_play")


func _on_main_menu_requested() -> void:
	menu_overlay.close_menu()
	get_tree().change_scene_to_file("res://title_screen.tscn")

func set_attack_buttons_visible(show_buttons: bool):
	player_turn_ui.visible = show_buttons

func set_block_buttons_visible(show_buttons: bool):
	defending_ui.visible = show_buttons

func set_cancel_visible(show_button: bool):
	cancel_button.visible = show_button
	if not show_button:
		close_time_action_overlay()

func create_time_action_clock(action_type: TimeAction, player_number: int, turns: int) -> void:
	var clock: TextureRect = preload("res://Scenes/time_clock.tscn").instantiate()
	var tooltip_format: String
	match action_type:
		TimeAction.TEMPORAL_COLLAPSE:
			clock.texture = preload("res://textures/ClockTemporalCollapse.png")
			tooltip_format = "Temporal Collapse: %d turns until time collapses on Player " + str(player_number)
		TimeAction.BORROWED_TIME:
			clock.texture = preload("res://textures/ClockBorrowedTime.png")
			tooltip_format = "[color=#FFB333]Borrowed Time[/color]: %d turns until Player " + str(player_number) + " loses one action"
	clock.get_node("Turns").text = str(turns)
	clock.set_meta("tooltip_format", tooltip_format)
	clock.tooltip_text = tooltip_format % turns
	time_clock_containers[player_number].add_child(clock)

func decrease_time_action_clocks(player_number: int) -> void:
	var container: HBoxContainer = time_clock_containers[player_number]
	for clock in container.get_children():
		var turns_label: Label = clock.get_node("Turns")
		var turns: int = int(turns_label.text) - 1
		if turns == -1:
			container.remove_child(clock)
			clock.queue_free()
		else:
			turns_label.text = str(turns)
			clock.tooltip_text = clock.get_meta("tooltip_format") % turns

func set_board_history(history: BoardHistory) -> void:
	rewind_history = history


func close_time_action_overlay() -> void:
	if menu_overlay.current_menu in [&"time_action", &"temporal_collapse", &"time_rewind"]:
		menu_overlay.close_menu()

func set_rollover_damage(damage: float, show_label: bool) -> void:
	var damage_text: String = str(roundi(damage)) if is_equal_approx(damage, roundf(damage)) else String.num(damage, 2)
	rollover_damage_label.text = damage_text + " damage remaining"
	rollover_damage_label.visible = show_label


func show_discard_controls(cards_remaining: int) -> void:
	discard_prompt.text = "Select a hand card. Discard %d more." % cards_remaining
	discard_button.disabled = true
	discard_ui.visible = true


func hide_discard_controls() -> void:
	discard_ui.visible = false
	discard_button.disabled = true


func set_discard_selection(has_selection: bool) -> void:
	discard_button.disabled = not has_selection


func show_card_tooltip(card: Card) -> void:
	tooltip_card = card

	tooltip_name.text = card.display_name
	var description := "[color=#FF7D78]Attack: %d[/color]\n[color=#69CCF0]Block: %d[/color]\n" % [card.attack, card.block]
	const WHILE_ON_BOARD_HEADING := "While on [b][color=#BD9B83]Board[/color][/b]:"
	var while_on_board_description := WHILE_ON_BOARD_HEADING
	if card.adjacency_effects != Vector2i.ZERO:
		while_on_board_description += "\n\t %s: [color=#FF7D78]%+d[/color]/[color=#69CCF0]%+d[/color]" % [Definitions.ADJACENCY_EFFECT_LABEL, card.adjacency_effects.x, card.adjacency_effects.y]
	var effect_names: Array[String] = []
	for effect in Definitions.SpecialEffects.values():
		if effect not in card.special_effects:
			continue
		if effect == Definitions.SpecialEffects.START_TURN:
			var stat_change: Vector2i = card.special_effects[effect]
			var turn_label := Definitions.format_effect(effect, "At start of turn")
			effect_names.append("%s, [color=#FF7D78]%+d[/color]/[color=#69CCF0]%+d[/color]" % [turn_label, stat_change.x, stat_change.y])
			continue
		if effect == Definitions.SpecialEffects.BONUS:
			var num_bonus_actions = card.special_effects[effect]
			var action_label := "+%d action" % num_bonus_actions
			if num_bonus_actions != 1:
				action_label += "s"
			while_on_board_description += "\n\t- " + Definitions.format_effect(effect, action_label)
			continue

		var effect_name: String = Definitions.SpecialEffects.find_key(effect).capitalize()
		effect_names.append(Definitions.format_effect(effect, effect_name))

	if not effect_names.is_empty():
		description += "\n".join(effect_names) + "\n"

	if while_on_board_description != WHILE_ON_BOARD_HEADING:
		description += while_on_board_description + "\n"

	if card.falter_turns_remaining > 0:
		description += "\n" + Definitions.format_effect(Definitions.SpecialEffects.FALTER, "Faltered")
		description += ": Cannot attack.\nTakes [b]1.5x combat damage[/b]."
	tooltip_description.text = description
	card_tooltip.reset_size()
	card_tooltip.show()
	position_card_tooltip(card)
	# Wrapped labels and containers finish sizing after the text changes.
	position_card_tooltip.call_deferred(card)


func position_card_tooltip(card: Card) -> void:
	if not is_instance_valid(card) or tooltip_card != card:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var position: Vector2 = card.get_global_transform_with_canvas().origin + Vector2(16, 16)
	position.x = clampf(position.x, 0.0, maxf(0.0, viewport_size.x - card_tooltip.size.x))
	position.y = clampf(position.y, 0.0, maxf(0.0, viewport_size.y - card_tooltip.size.y))
	card_tooltip.global_position = position


func hide_card_tooltip(card: Card) -> void:
	if tooltip_card != card:
		return

	tooltip_card = null
	card_tooltip.hide()

func attacker_attacks(attacker: Card, player : int):
	var attacker_label_offset = Vector2(0, attacker.size.y / 2 + 20) if player == Definitions.PLAYER_ONE else Vector2(0, -(attacker.size.y / 2 + 20))
	attacker_status.text = "Attacking!"
	attacker_status.add_theme_color_override("font_color", Color("#FF7D78"))
	attacker_status.global_position = attacker.global_position + attacker_label_offset
	attacker_status.show()

func show_combat_status(card: Card, player: int, status_label: Label, message: String) -> void:
	status_label.text = message
	match message:
		"Attacking!":
			status_label.add_theme_color_override("font_color", Color("#FF7D78"))
		"Blocked!":
			status_label.add_theme_color_override("font_color", Color("#69CCF0"))
		_:
			status_label.remove_theme_color_override("font_color")
	status_label.reset_size()

	var sprite: Sprite2D = card.get_node("KnightCard")
	var half_height : int =  sprite.get_rect().size.y * abs(sprite.global_scale.y) / 2.0

	var gap = 5.0
	var offset = Vector2(-status_label.size.x / 2, half_height + gap)

	if player == Definitions.PLAYER_TWO:
		offset.y = -half_height - gap - status_label.size.y

	status_label.global_position = card.global_position + offset
	status_label.show()

func hide_status_labels():
	attacker_status.text = ""
	defender_status.text = ""
	attacker_status.hide()
	defender_status.hide()


func show_action_selection(mode : InputManager.ActionMode) -> void:
	set_attack_buttons_visible(false)
	set_block_buttons_visible(false)
	cancel_button.hide()

	if mode not in [InputManager.ActionMode.TIME_ACTION_MENU, InputManager.ActionMode.TEMPORAL_COLLAPSE_CONFIRMATION, InputManager.ActionMode.TIME_REWIND_MENU]:
		close_time_action_overlay()
		
	match mode:
		InputManager.ActionMode.ATTACK:
			cancel_button.show()
		InputManager.ActionMode.AWAITING_BLOCK:
			set_block_buttons_visible(true)
		InputManager.ActionMode.BLOCK:
			set_block_buttons_visible(false)
			cancel_button.show()
		InputManager.ActionMode.TIME_ACTION_MENU:
			if menu_overlay.current_menu != &"time_action":
				menu_overlay.open_menu(&"time_action")
		InputManager.ActionMode.TIME_STOP:
			cancel_button.show()
		InputManager.ActionMode.TEMPORAL_COLLAPSE_CONFIRMATION:
			menu_overlay.navigate_to(&"temporal_collapse")
		InputManager.ActionMode.TIME_REWIND_MENU:
			menu_overlay.navigate_to(&"time_rewind")
		InputManager.ActionMode.NONE:
			set_attack_buttons_visible(true)

func update_state(game_state):
	var active_player = game_state["active_player"]
	player_turn.text = "Player's Turn" if active_player == Definitions.PLAYER_ONE else "Opponent's Turn"
	player_turn.label_settings.font_color = Color8(0,191,253) if active_player == Definitions.PLAYER_ONE else Color8(251,121,122)

	var num_actions_remaining = game_state["actions_remaining"]
	# Only start_turn supplies this key; never compare a new turn to the old one.
	if "starting_actions" in game_state:
		starting_actions = game_state["starting_actions"]
		previous_actions_remaining = num_actions_remaining
		if actions_remaining_tween:
			actions_remaining_tween.kill()
			actions_remaining_tween = null
		actions_remaining.label_settings.font_color = Color.WHITE

	actions_remaining.text = "Actions Remaining: " + str(num_actions_remaining)
	if not "starting_actions" in game_state:
		actions_remaining_tween = flash_label_color(actions_remaining, actions_remaining_tween, Color("4ea847ff"), Color.RED if num_actions_remaining == 0 else Color.WHITE)

	if "player_hp" in game_state:
		var new_hp: int = game_state["player_hp"]
		var took_damage := previous_player_hp >= 0 and new_hp < previous_player_hp

		player_hp.text = "HP: %d" % new_hp
		previous_player_hp = new_hp

		if took_damage:
			player_hp_tween = flash_label_color(player_hp, player_hp_tween, Color.RED)

	if "opponent_hp" in game_state:
		var new_hp: int = game_state["opponent_hp"]
		var took_damage := previous_opponent_hp >= 0 and new_hp < previous_opponent_hp

		opponent_hp.text = "HP: %d" % new_hp
		previous_opponent_hp = new_hp

		if took_damage:
			opponent_hp_tween = flash_label_color(opponent_hp, opponent_hp_tween, Color.RED)

	attack_button.disabled = num_actions_remaining <= 0 or not game_state["has_attack_card"]
	var time_actions_available: bool = game_state["is_player_action_phase"] and not game_state["time_action_taken"] and not game_state["time_actions_disabled"]
	var can_spend_time_action: bool = time_actions_available and num_actions_remaining > 0
	can_use_time_stop = can_spend_time_action
	can_use_borrowed_time = time_actions_available and game_state["borrowed_time_payback"] == -1
	can_use_temporal_collapse = can_spend_time_action and not game_state["collapse_active"]
	can_use_time_rewind = can_spend_time_action
	time_action_button.disabled = not can_use_time_stop and not can_use_borrowed_time

func toggle_attack_buttons():
	player_turn_ui.visible = not player_turn_ui.visible

func toggle_block_buttons():
	defending_ui.visible = not defending_ui.visible

func toggle_cancel_button():
	cancel_button.visible = not cancel_button.visible

func flash_label_color(label : Label, tween: Tween, flash_color: Color = Color.RED, end_color: Color = Color.WHITE):
	if tween:
		tween.kill()

	label.label_settings.font_color = flash_color

	var new_tween := create_tween()
	new_tween.tween_interval(0.5)
	new_tween.tween_callback(
		func():
			label.label_settings.font_color = end_color
	)
	return new_tween

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
