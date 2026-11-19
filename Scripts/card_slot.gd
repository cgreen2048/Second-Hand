class_name CardSlot
extends Area2D

@onready var attacking_marker : Sprite2D = $AttackingMarker
@onready var blocking_marker : Sprite2D = $BlockingMarker
@onready var time_action_marker : Sprite2D = $TimeActionMarker
@onready var time_stopped_marker : Sprite2D = $TimeStopped
@onready var time_stopped_label : Label = $TimeStoppedLabel
@onready var rewind_label: Label = $RewindLabel

var card_in_slot : Card = null
var index : int
var rewind_actions_remaining: int = 0
var state_before_rewind: Dictionary = {}
var time_stopped : int = 0:
	set(value):
		time_stopped = value
		if is_node_ready():
			refresh_time_stop_display()
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refresh_time_stop_display()
	refresh_rewind_display()

func refresh_rewind_display(history_preview: bool = false) -> void:
	if history_preview:
		rewind_label.visible = rewind_actions_remaining >= 0
		rewind_label.text = "Rewinding"
		rewind_label.position = -rewind_label.size / 2.0
	else:
		rewind_label.visible = rewind_actions_remaining > 0
		rewind_label.text = "Rewind: %d" % rewind_actions_remaining

func capture_state() -> Dictionary:
	return {
		"card_definition_id": get_card_definition_id(),
		"card_attack": get_card_base_attack(),
		"card_block": get_card_base_block(),
		"card_falter_turns": get_card_falter_turns(),
		"time_stopped_turns": get_time_stopped_turns(),
	}

func refresh_time_stop_display() -> void:
	var is_time_stopped := time_stopped > 0
	time_stopped_marker.visible = is_time_stopped
	time_stopped_label.visible = is_time_stopped
	time_stopped_label.text = str(time_stopped)

func set_blocking_marker(enabled: bool) -> void:
	blocking_marker.visible = enabled

func set_attacking_marker(enabled: bool) -> void:
	attacking_marker.visible = enabled

func set_time_action_marker(enabled: bool) -> void:
	time_action_marker.visible = enabled
	
func get_card_definition_id():
	if card_in_slot:
		return card_in_slot.get_definition_id()
	return null

func get_card_base_attack():
	if card_in_slot:
		return card_in_slot.get_base_attack()

func get_card_base_block():
	if card_in_slot:
		return card_in_slot.get_base_block()

func get_card_falter_turns():
	if card_in_slot:
		return card_in_slot.falter_turns_remaining
	return 0
	
func get_time_stopped_turns():
	return time_stopped
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
