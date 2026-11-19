class_name MenuOverlay
extends Control

signal view_changed(view: Control)
signal exited(menu: StringName)

@onready var exit_button: TextureButton = $Exit
@onready var back_button: TextureButton = $Back
@onready var content: PanelContainer = $Content

@export var menu_scenes: Dictionary[StringName, PackedScene] = {
	&"game_menu": preload("res://Scenes/game_menu_view.tscn"),
	&"how_to_play": preload("res://Scenes/how_to_play_view.tscn"),
	&"time_action": preload("res://Scenes/time_action_view.tscn"),
	&"temporal_collapse": preload("res://Scenes/temporal_collapse_view.tscn"),
	&"time_rewind": preload("res://Scenes/time_rewind_view.tscn"),
	&"card_collection_view": preload("res://Scenes/card_collection_view.tscn")
}

var current_menu: StringName = &""
# Previous pages only; current_menu identifies the displayed page.
var menu_history: Array[StringName] = []
var current_view: Control


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(go_back)
	back_button.hide()
	hide()


func _clear_view() -> void:
	if is_instance_valid(current_view):
		content.remove_child(current_view)
		current_view.queue_free()
	current_view = null
	

# The only replacement path: validate before removing the existing view,
# commit navigation state, then announce the ready instance to its host.
func _replace_menu(menu_name: StringName, next_history: Array[StringName]) -> bool:
	var instance = menu_scenes[menu_name].instantiate()

	_clear_view()
	current_view = instance as Control
	current_menu = menu_name
	menu_history = next_history.duplicate()
	content.add_child(current_view)
	back_button.visible = not menu_history.is_empty()
	show()
	view_changed.emit(current_view)
	return true
	
	
# Public use methods
# Start a new session. Invalid menus leave the current session unchanged.
func open_menu(menu_name: StringName) -> bool:
	set_exit_button_visible(true)
	return _replace_menu(menu_name, [])


# Enter a child page while remembering where Back should return.
func navigate_to(menu_name: StringName) -> bool:
	if not visible or not is_instance_valid(current_view):
		return open_menu(menu_name)
	if menu_name == current_menu:
		return true
	var next_history: Array[StringName] = menu_history.duplicate()
	next_history.append(current_menu)
	return _replace_menu(menu_name, next_history)


func go_back() -> bool:
	if menu_history.is_empty():
		return false
	var next_history: Array[StringName] = menu_history.duplicate()
	var previous_menu: StringName = next_history.pop_back()
	return _replace_menu(previous_menu, next_history)


func _on_exit_pressed() -> void:
	var closed_menu := current_menu
	close_menu()
	exited.emit(closed_menu)


func close_menu() -> void:
	hide()
	_clear_view()
	menu_history.clear()
	current_menu = &""
	back_button.hide()
	
func set_exit_button_visible(value : bool):
	exit_button.visible = value
