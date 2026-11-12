class_name GameMenuView
extends Control

signal show_help_menu
signal show_main_menu


func _ready() -> void:
	$GameMenu/HowToPlay.pressed.connect(show_help_menu.emit)
	$GameMenu/MainMenu.pressed.connect(show_main_menu.emit)
	$GameMenu/QuitGame.pressed.connect(_on_quit_button_pressed)

	
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
