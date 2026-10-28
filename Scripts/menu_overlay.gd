class_name MenuOverlay
extends Control

@onready var options_box: VBoxContainer = $PanelContainer/OverlayColumns/OptionsScroll/OptionsBox
@onready var info_title: RichTextLabel = $PanelContainer/OverlayColumns/InfoScroll/InfoBox/OptionTitle
@onready var info_image: TextureRect = $PanelContainer/OverlayColumns/InfoScroll/InfoBox/AspectFrame/OptionImage
@onready var info_video : VideoStreamPlayer = $PanelContainer/OverlayColumns/InfoScroll/InfoBox/AspectFrame/OptionVideo
@onready var info_text: RichTextLabel = $PanelContainer/OverlayColumns/InfoScroll/InfoBox/OptionInfo
@onready var aspect_frame : AspectRatioContainer = $PanelContainer/OverlayColumns/InfoScroll/InfoBox/AspectFrame
@onready var exit_button: TextureButton = $Exit
@onready var back_button: TextureButton = $Back

# Add future pages here using their menu names and paths relative to this overlay.
@export var menu_paths: Dictionary[StringName, NodePath] = {
	&"how_to_play": NodePath("PanelContainer/OverlayColumns"),
	&"game_menu": NodePath("PanelContainer/GameMenu")
}

var current_menu: StringName = &""
var menu_history: Array[StringName] = []

const TOPICS : Dictionary = {
	"HP": {
		"text": "The player and the opponent will have a set max HP that can be reduced either by taking damage from the other's attacking card or by taking a Time Action.\n\n When one side is reduced to zero HP, the other wins the game",
		"image": null
	},
	"Cards": {
		"text": "As a card battler, the player and the opponent have a deck of 20 cards, where each card is either a:\n
- Troop card: Cards placed onto the board. These have two values: Attack (Red) and Block (Blue)
- Spell card: cards played immediately from the hand and not placed onto the board
		",
		"image": preload("res://Assets/HowToPlay/Card.png")
	},
	"Hand": {
		"text": "The Hand contains the cards that the each player can play on their turn. At the start of each turn, the player draws a card from their Deck into their Hand

At the end of the turn, if the player has more than 4 cards in their Hand, they must discard down to 4.

Each player's hand is hidden to the opponent.
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/Hand.ogv"),
		"video_ratio": 1920.0 / 600.0
	},
	"Deck": {
		"text": "The Deck is the source of the player/opponent's cards during the match. The Deck can have up to  20 cards with no limit on duplicate cards. Outside of a match, the player can configure which cards are in their Deck.
		
At the start of the match, both Decks will be shuffled randomly. During the match, the player/opponent will draw a card from the Deck at the start of each turn. If the Deck is empty, the Discard Pile is shuffled to become the new Deck, and the Discard Pile is emptied. The player/opponent then draws from the new Deck. 
- If there are no cards in either the Deck or Discard Pile, the player/opponent does not draw a card

The player can view all cards in their Deck mid-match by clicking their Deck.
		",
		"image": null
	},
	"DiscardPile": {
		"text": "The Discard Pile contains all cards that the player/opponent has discarded from their Hand. Once the Deck is empty, the Discard Pile is shuffled into the Deck and the Discard Pile is emptied.
		
The player can view all cards in their Discard Pile by clicking their Discard Pile.
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/DiscardPile.ogv"),
		"video_ratio": 1920.0 / 400.0
	},
	"Graveyard": {
		"text": "The player/opponent's Graveyard contains all cards that have perished at any point during the match. When a card perishes, it is transferred to its owner's Graveyard and cannot re-enter the Deck without a spell card to do so.
		
The player can view all cards in their Graveyard by clicking their Graveyard
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/Graveyard.ogv")
	},
	"GameBoard": {
		"text": "The board will contain two rows with four spaces on each row, where one card can occupy one space. The player can only play cards on the 4 spaces in their row and vice versa for the opponent except in special cases.
		
When a card is in a space, it cannot be removed unless killed by an attack (either by the player or the opponent) exiled into the graveyard by a spell card, or temporarily removed by Time Rewind

The Game Board can be modified in individual spaces by specific Time Actions (ex. time rewind), but the history of the last X turns of the Board is stored.
		",
		"image": preload("res://Assets/HowToPlay/GameBoard.png")
	},
	"TakingATurn": {
		"text": "At the start of their turn, the player/opponent will draw a card from their deck. Then, they can take up to 2 of the following actions:
- Place a troop card from their hand onto one of the open spaces on their board
- This can trigger a Reactionary Time Stop from the other
- Cast a spell card from their hand
- Take a time action at the cost of HP
	- If the player uses Borrowed Time, it will not consume an action. Rather, it will add 1 extra action
- Attack with a card on the board
			
The above actions can be taken more than once in one turn (ex. if the player just wants to attack twice, they are able to) except for time action.
		",
		"image": null
	},
	"PlayingCards": {
		"text": "To play a card, click and drag a card from your hand to one of the open slots on your side of the board",
		"image": null,
		"video": preload("res://Assets/HowToPlay/PlayingCards.ogv")
	},
	"AttackingAndBlocking": {
		"text": "The player can choose to Attack on their turn. After selecting Attack, the player can select a card in one of their card slots to attack with. Once selecting, however, they do not get to choose their target.
		
The other player can then choose one of two responses:

Block: The other player chooses one card on their side of the board. If the blocking card's Block is lower than the attacking card's Attack, the blocking card perishes. If the blocking card's Attack is higher than the attacking card's Block, the attacking card perishes. If neither of these, neither card perishes, but if both, both cards perish.

No Block: The other player chooses not to block, reducing their HP by the attacking card's Attack

Spell Card Nullification: If the other player has a spell card in Hand that can nullify damage, they can instantly play that card

When the Player is attacking, the cards that the Player can attack with are highlighted in blue. If the opponent blocks, their blocking card will be highlighted in red.
When the Opponent is attacking, the card that they are attacking with will be highlighted in red. Then, the Player can choose to block with a card highlighted in blue, no block, or spell card nullification.
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/AttackingAndBlocking.ogv")
	},
	"TimeAction": {
		"text": "During their turn, the player can take one Time Action at the cost of their own HP to gain an advantage on the board. These include:
- Time Stop: Choose a slot on the entire board to stop time for 2 turns. During those two turns, the slot cannot have any action taken on it, including attack, block, place card, or spell card
- Time Rewind
- Future Sight
- Borrowed Time
- Temporal Collapse
		",
		"image": null
	},
	"HowToWin": {
		"text": "The game ends when the Player or Opponent's HP is reduced to zero. Each turn is vital to setting up the future board state to ensure favorable outcomes",
		"image": null
	}
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	info_image.hide()
	info_text.text = ""
	
	for child in options_box.get_children():
		if child is Button:
			var topic_id := String(child.name)

			if TOPICS.has(topic_id):
				child.pressed.connect(show_topic.bind(topic_id))
				
	exit_button.pressed.connect(close_menu)
	back_button.pressed.connect(go_back)
	$PanelContainer/GameMenu/HowToPlay.pressed.connect(navigate_to.bind(&"how_to_play"))
	$PanelContainer/GameMenu/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$PanelContainer/GameMenu/QuitGame.pressed.connect(_on_quit_game_button_pressed)
	_hide_pages()
	back_button.hide()
	self.hide()

func show_topic(topic_id: String) -> void:
	aspect_frame.ratio = 16.0 / 9.0
	var topic: Dictionary = TOPICS[topic_id]
	info_title.text = topic_id.capitalize()
	info_text.text = topic["text"]
	
	info_image.texture = topic["image"]
	info_image.visible = topic["image"] != null
	
	info_video.stop()
	info_video.stream = topic.get("video")
	if info_video.stream != null:
		aspect_frame.ratio = topic.get("video_ratio", 16.0 / 9.0)
		info_video.show()
		info_video.play()
	
	aspect_frame.visible = topic["image"] != null or info_video.stream != null
	
# Start a new overlay session with no previous page.
func open_menu(menu_name: StringName) -> void:
	if not _is_valid_menu(menu_name):
		return
	menu_history.clear()
	_show_menu(menu_name)
	self.show()


# Enter a child page while remembering where Back should return.
func navigate_to(menu_name: StringName) -> void:
	if not _is_valid_menu(menu_name):
		return
	if not self.visible or current_menu == &"":
		open_menu(menu_name)
		return
	if menu_name == current_menu:
		return
	menu_history.append(current_menu)
	_show_menu(menu_name)


func go_back() -> void:
	if menu_history.is_empty():
		return
	var previous_menu: StringName = menu_history.pop_back()
	_show_menu(previous_menu)


func close_menu() -> void:
	self.hide()
	_hide_pages()
	menu_history.clear()
	current_menu = &""
	back_button.hide()


func _is_valid_menu(menu_name: StringName) -> bool:
	if not menu_paths.has(menu_name):
		push_warning("Unknown menu: %s" % menu_name)
		return false
	if not get_node_or_null(menu_paths[menu_name]) is Control:
		push_warning("Menu must point to a Control: %s" % menu_name)
		return false
	return true


func _hide_pages() -> void:
	for path in menu_paths.values():
		var page := get_node_or_null(path) as Control
		if page:
			page.hide()
	info_video.stop()
	info_video.hide()


func _show_menu(menu_name: StringName) -> void:
	_hide_pages()
	var page := get_node(menu_paths[menu_name]) as Control
	page.show()
	current_menu = menu_name
	back_button.visible = not menu_history.is_empty()


func _on_main_menu_button_pressed() -> void:
	close_menu()
	get_tree().change_scene_to_file("res://title_screen.tscn")
	
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
