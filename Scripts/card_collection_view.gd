class_name CardCollectionView
extends Control

signal card_hovered(card: Card)
signal card_unhovered(card: Card)


@onready var card_rows : VBoxContainer = $ScrollContainer/MarginContainer/CardRows
@onready var collection_name_label : Label = $ScrollContainer/MarginContainer/CardRows/CollectionName

const PLAYER_ONE = 1

var card_scene = preload("res://Scenes/card.tscn")
var collection_name: String:
	get:
		return collection_name
	set(value):
		collection_name = value
		collection_name_label.text = collection_name
var collection_cards: Array[String]:
	get:
		return collection_cards
	set(value):
		collection_cards = value
		_display_cards(collection_cards)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _display_cards(cards: Array[String]) -> void:
	# Sort alphabetically so the player doesn't know what card they'll draw next
	var sorted_cards = cards.duplicate()
	sorted_cards.sort()
	
	var current_row : HBoxContainer

	for i in range(len(cards)):
		if i % 4 == 0:
			current_row = HBoxContainer.new()
			current_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_row.add_theme_constant_override("separation", 16)
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER
			card_rows.add_child(current_row)
		
		var card_holder = Control.new()
		card_holder.custom_minimum_size = Vector2(50, 70)
		current_row.add_child(card_holder)

		var new_card := card_scene.instantiate() as Card
		new_card.setup(sorted_cards[i], PLAYER_ONE)
		# Collection previews never participate in world picking or card actions.
		new_card.collision_layer = 0
		new_card.collision_mask = 0
		new_card.input_pickable = false
		
		card_holder.add_child(new_card)
		# The holder handles GUI hover; preview stat labels must not intercept it.
		for control in new_card.find_children("*", "Control", true, false):
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		card_holder.mouse_entered.connect(card_hovered.emit.bind(new_card))
		card_holder.mouse_exited.connect(card_unhovered.emit.bind(new_card))

		# Area2D card artwork is centered around its origin.
		new_card.position = card_holder.custom_minimum_size / 2

func open_card_collection(name : String, cards : Array[String]):
	collection_name = name
	collection_cards = cards
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
