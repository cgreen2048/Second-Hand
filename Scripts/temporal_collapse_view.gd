class_name TemporalCollapseView
extends Control

signal confirm_temporal_collapse
signal cancel_action

@onready var temporal_collapse_yes: Button = $OverlayVBox/Buttons/Yes
@onready var temporal_collapse_no: Button = $OverlayVBox/Buttons/No

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	temporal_collapse_yes.pressed.connect(_on_temporal_collapse_yes_pressed)
	temporal_collapse_no.pressed.connect(_on_temporal_collapse_no_pressed)
	# The overlay finishes showing this instance after add_child() runs _ready().
	_focus_cancel.call_deferred()

func _focus_cancel() -> void:
	if is_inside_tree() and is_visible_in_tree():
		temporal_collapse_no.grab_focus()

func _on_temporal_collapse_yes_pressed() -> void:
	emit_signal("confirm_temporal_collapse")

func _on_temporal_collapse_no_pressed() -> void:
	emit_signal("cancel_action")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
