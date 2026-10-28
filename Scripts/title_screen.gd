extends Control

@onready var play_match_button: Button = $TitleScreenButtonBox/PlayMatch
@onready var how_to_play_button: Button = $TitleScreenButtonBox/HowToPlay
@onready var quit_game_button: Button = $TitleScreenButtonBox/QuitGame
@onready var menu_overlay: MenuOverlay = $MenuOverlay

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_match_button.pressed.connect(_on_play_match_button_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	quit_game_button.pressed.connect(_on_quit_game_button_pressed)
	menu_overlay.hide()
	

func _on_play_match_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game_manager.tscn")

func _on_how_to_play_button_pressed() -> void:
	menu_overlay.open_menu(&"how_to_play")

func _on_quit_game_button_pressed() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
