class_name CardSlot
extends Area2D

@onready var highlight : Sprite2D = $Highlight
@onready var attacking_marker : Sprite2D = $AttackingMarker
@onready var time_stopped_marker : Sprite2D = $TimeStopped
@onready var time_stopped_label : Label = $TimeStoppedLabel

var card_in_slot : Card = null
var index : int
var time_stopped : int = 0:
	set(value):
		time_stopped = value
		if time_stopped > 0:
			time_stopped_marker.visible = true
			time_stopped_label.visible = true
			time_stopped_label.text = str(time_stopped)
		else:
			time_stopped_marker.visible = false
			time_stopped_label.visible = false
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_highlighted(enabled: bool) -> void:
	highlight.visible = enabled

func set_attacking_marker(enabled: bool) -> void:
	attacking_marker.visible = enabled

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
