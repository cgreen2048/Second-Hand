class_name DiscardPile
extends Area2D

var discard_pile = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func add_card(definition_id : String):
	discard_pile.append(definition_id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
