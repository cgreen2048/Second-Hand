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
@onready var end_turn_button: Button = $Control/PlayerTurnUIHBox/EndTurnButton
@onready var cancel_button: Button = $Control/CancelActionUIHbox/CancelButton
@onready var block_button: Button = $Control/DefendingUIHBox/BlockButton
@onready var no_block_button: Button = $Control/DefendingUIHBox/NoBlockButton
@onready var discard_ui: VBoxContainer = $Control/DiscardUI
@onready var discard_prompt: Label = $Control/DiscardUI/DiscardPrompt
@onready var discard_button: Button = $Control/DiscardUI/DiscardButton
@onready var menu_button: TextureButton = $Control/OpenMenu
@onready var menu_overlay = $Control/MenuOverlay

@onready var card_tooltip: PanelContainer = $Control/CardTooltip
@onready var tooltip_name: Label = $Control/CardTooltip/VBoxContainer/CardName
@onready var tooltip_description: Label = $Control/CardTooltip/VBoxContainer/CardDescription

@onready var attacker_status : Label = $Control/AttackerStatus
@onready var defender_status : Label = $Control/DefenderStatus

const PLAYER_ONE = 1
const PLAYER_TWO = 2

var tooltip_card : Card = null
var starting_actions : int = 0
var previous_actions_remaining : int = 0
var previous_player_hp : int = 25
var previous_opponent_hp : int = 25
var actions_remaining_tween : Tween
var player_hp_tween : Tween
var opponent_hp_tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	block_button.visible = false
	no_block_button.visible = false
	cancel_button.visible = false
	hide_discard_controls()
	player_turn.text = "Player's Turn" 
	actions_remaining.text = "Actions Remaining: " + str(starting_actions)
	attack_button.pressed.connect(on_attack_button_pressed)
	time_action_button.pressed.connect(input_manager.begin_time_stop)
	block_button.pressed.connect(on_block_button_pressed)
	no_block_button.pressed.connect(on_no_block_button_pressed)
	end_turn_button.pressed.connect(on_end_turn_button_pressed)
	cancel_button.pressed.connect(on_cancel_button_pressed)
	discard_button.pressed.connect(input_manager.discard_selected_card)
	input_manager.discard_selection_changed.connect(set_discard_selection)
	menu_button.pressed.connect(on_menu_button_pressed)

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

func set_attack_buttons_visible(show_buttons: bool):
	attack_button.visible = show_buttons
	time_action_button.visible = show_buttons
	end_turn_button.visible = show_buttons

func set_block_buttons_visible(show_buttons: bool):
	block_button.visible = show_buttons
	no_block_button.visible = show_buttons

func set_cancel_visible(show_button: bool):
	cancel_button.visible = show_button

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
	tooltip_description.text = "Attack: %d\nBlock: %d" % [card.attack, card.block]
	if card.adjacency_effects != Vector2i.ZERO:
		tooltip_description.text += "\nAdjacent cards: %+d/%+d" % [card.adjacency_effects.x, card.adjacency_effects.y]
	var effect_names: Array[String] = []
	for effect in CardDefinitions.SpecialEffects.values():
		if effect not in card.special_effects:
			continue
		var effect_name: String = CardDefinitions.SpecialEffects.find_key(effect).capitalize()
		match effect:
			CardDefinitions.SpecialEffects.GROWTH, CardDefinitions.SpecialEffects.HARDEN, CardDefinitions.SpecialEffects.WANE, CardDefinitions.SpecialEffects.SOFTEN, CardDefinitions.SpecialEffects.BONUS:
				effect_name += " %d" % card.special_effects[effect]
		effect_names.append(effect_name)
	if not effect_names.is_empty():
		tooltip_description.text += "\nSpecial Effects:\n" + "\n".join(effect_names)

	if card.falter_turns_remaining > 0:
		tooltip_description.text += "\nFaltered: Cannot attack.\nTakes 1.5x combat damage."
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
	var attacker_label_offset = Vector2(0, attacker.size.y / 2 + 20) if player == PLAYER_ONE else Vector2(0, -(attacker.size.y / 2 + 20))
	attacker_status.text = "Attacking!"
	attacker_status.global_position = attacker.global_position + attacker_label_offset
	attacker_status.show()

func show_combat_status(card: Card, player: int, status_label: Label, message: String) -> void:
	status_label.text = message
	status_label.reset_size()

	var sprite: Sprite2D = card.get_node("KnightCard")
	var half_height : int =  sprite.get_rect().size.y * abs(sprite.global_scale.y) / 2.0

	var gap = 5.0
	var offset = Vector2(-status_label.size.x / 2, half_height + gap)

	if player == PLAYER_TWO:
		offset.y = -half_height - gap - status_label.size.y

	status_label.global_position = card.global_position + offset
	status_label.show()

func hide_status_labels():
	attacker_status.text = ""
	defender_status.text = ""
	attacker_status.hide()
	defender_status.hide()

func update_state(game_state):
	hide_discard_controls()
	
	var active_player = game_state["active_player"]
	player_turn.text = "Player's Turn" if active_player == PLAYER_ONE else "Opponent's Turn"
	player_turn.label_settings.font_color = Color8(0,191,253) if active_player == PLAYER_ONE else Color8(251,121,122)
	
	var num_actions_remaining = game_state["actions_remaining"]
	# Only start_turn supplies this key; never compare a new turn to the old one.
	if "starting_actions" in game_state:
		starting_actions = game_state["starting_actions"]
		previous_actions_remaining = num_actions_remaining
		if actions_remaining_tween:
			actions_remaining_tween.kill()
			actions_remaining_tween = null
		actions_remaining.label_settings.font_color = Color.WHITE

	var decreased_actions_remaining = previous_actions_remaining >= 0 and num_actions_remaining < previous_actions_remaining
	actions_remaining.text = "Actions Remaining: " + str(num_actions_remaining)
	previous_actions_remaining = num_actions_remaining
	if decreased_actions_remaining:
		actions_remaining_tween = flash_label_color(actions_remaining, actions_remaining_tween, Color("#FFB347"), Color.RED if num_actions_remaining == 0 else Color.WHITE)
	
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
	
	var human_turn = active_player == PLAYER_ONE

	attack_button.visible = human_turn
	time_action_button.visible = human_turn
	attack_button.disabled = num_actions_remaining <= 0 or not game_state["has_attack_card"]
	time_action_button.disabled = num_actions_remaining <= 0 or game_state["time_action_taken"]
	end_turn_button.visible = human_turn
	set_cancel_visible(false)
	set_block_buttons_visible(false)

func toggle_attack_buttons():
	attack_button.visible = not attack_button.visible
	time_action_button.visible = not time_action_button.visible
	end_turn_button.visible = not end_turn_button.visible
	
func toggle_block_buttons():
	block_button.visible = not block_button.visible
	no_block_button.visible = not no_block_button.visible

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
