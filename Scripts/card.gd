class_name Card
extends InteractiveElement

signal hovered 
signal stop_hover
signal select_card(card: Card)

var definition_id : String
var display_name : String
var base_attack: int = 0
var base_block: int = 0
# Outgoing left/right modifiers, separate from special abilities and received stats.
var adjacency_effects: Vector2i = Vector2i.ZERO
var adjacency_stat_modifier: Vector2i = Vector2i.ZERO
var attack: int:
	get:
		return maxi(0, base_attack + adjacency_stat_modifier.x)
	set(value):
		base_attack = maxi(0, value)
var block: int:
	get:
		return maxi(0, base_block + adjacency_stat_modifier.y)
	set(value):
		base_block = maxi(0, value)
var card_type = null
# Effect type -> magnitude. Each card owns its own mutable collection.
var special_effects: Dictionary[Definitions.SpecialEffects, Variant] = {}
var falter_turns_remaining: int = 0

var card_slot : CardSlot = null
var index: int:
	get:
		return card_slot.index if card_slot != null else -1
var player_number : int = 0

var movement_tween : Tween
var stored_position: Vector2:
	set(value):
		stored_position = value
		animate_to_position(value)

@onready var attack_value_label : Label = $AttackValue
@onready var block_value_label : Label = $BlockValue
@onready var faltered_status_icon: TextureRect = $Faltered
@onready var deathtouch_icon: TextureRect = $SpecialEffectsList/Deathtouch
@onready var retaliation_icon: TextureRect = $SpecialEffectsList/Retaliation
@onready var piercing_icon: TextureRect = $SpecialEffectsList/Piercing
@onready var falter_icon: TextureRect = $SpecialEffectsList/Falter
@onready var bonus_icon: TextureRect = $SpecialEffectsList/Bonus
@onready var start_turn_icon: TextureRect = $SpecialEffectsList/StartTurn
@onready var adjacency_effects_icon: TextureRect = $SpecialEffectsList/AdjacencyEffects

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_card_labels()
	update_special_effect_indicators()

func update_special_effect_indicators() -> void:
	deathtouch_icon.visible = special_effects.has(Definitions.SpecialEffects.DEATHTOUCH)
	retaliation_icon.visible = special_effects.has(Definitions.SpecialEffects.RETALIATION)
	piercing_icon.visible = special_effects.has(Definitions.SpecialEffects.PIERCING)
	falter_icon.visible = special_effects.has(Definitions.SpecialEffects.FALTER)
	bonus_icon.visible = special_effects.has(Definitions.SpecialEffects.BONUS)
	start_turn_icon.visible = special_effects.has(Definitions.SpecialEffects.START_TURN)
	adjacency_effects_icon.visible = adjacency_effects != Vector2i.ZERO


func update_card_labels() -> void:
	attack_value_label.text = str(attack)
	block_value_label.text = str(block)
	faltered_status_icon.visible = falter_turns_remaining > 0
	
func set_face_down(cards_face_down : bool) -> void:
	$CardBack.visible = cards_face_down
	$KnightCard.visible = not cards_face_down
	$AttackValue.visible = not cards_face_down
	$BlockValue.visible = not cards_face_down
	$SpecialEffectsList.visible = not cards_face_down
	if cards_face_down:
		$Faltered.hide()
	else:
		update_card_labels()
	

func apply_falter() -> void:
	# Existing Falter cannot be refreshed or stacked.
	if falter_turns_remaining == 0:
		falter_turns_remaining = 2
		update_card_labels()

func handle_interaction(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		set_selected_card()


func setup(id : String, owner : int):
	var definition = Definitions.CARDS[id]
	
	definition_id = id
	display_name = definition["display_name"]
	attack = definition["attack"]
	block = definition["block"]
	adjacency_effects = definition.get("adjacency_effects", Vector2i.ZERO)
	adjacency_stat_modifier = Vector2i.ZERO
	card_type = definition["card_type"]
	special_effects.assign(definition.get("special_effects", {}))
	falter_turns_remaining = 0
	player_number = owner
	if is_node_ready():
		update_card_labels()
		update_special_effect_indicators()


func set_selected_card():
	emit_signal("select_card", self)


func animate_to_position(target: Vector2) -> void:
	if movement_tween and movement_tween.is_valid():
		movement_tween.kill()

	movement_tween = create_tween()
	movement_tween.tween_property(self, "global_position", target, 0.2)


func take_damage(amount: float) -> bool:
	amount *= get_incoming_damage_multiplier()
	return amount > 0 and amount >= block

func get_incoming_damage_multiplier() -> float:
	return 1.5 if falter_turns_remaining > 0 else 1.0

func get_remaining_piercing_damage(amount: float) -> float:
	var damage_left: float = maxf(0.0, amount - block / get_incoming_damage_multiplier())
	# Fractional absorption must not turn a whole HP result into an extra point.
	return roundf(damage_left) if is_equal_approx(damage_left, roundf(damage_left)) else damage_left

func get_definition_id():
	return definition_id

func get_base_attack():
	return base_attack

func get_base_block():
	return base_block
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_mouse_exited() -> void:
	emit_signal("stop_hover", self)
