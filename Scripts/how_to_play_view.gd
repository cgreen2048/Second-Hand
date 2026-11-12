class_name HowToPlayView
extends Control

const TOPICS : Dictionary = {
	"HP": {
		"text": "The player and the opponent will have a set max HP that can be reduced either by taking damage from the other's attacking card or by taking a Time Action.\n\n When one side is reduced to zero HP, the other wins the game",
		"image": null
	},
	"Cards": {
		"text": "As a card battler, the player and the opponent have a deck of 30 cards, where each card is either a:\n
- Troop card: Cards placed onto the board. These have two values: Attack (Red) and Block (Blue)
- Spell card: cards played immediately from the hand and not placed onto the board
		",
		"image": preload("res://Assets/HowToPlay/Card.png")
	},
	"CardSpecialEffects": {
		"text": "Some troop cards will have certain special effects that make them more useful than just their Attack and Block values. Effects can trigger immediately when played, at the start of the player's turn, or when attacking/blocking. These can dramatically change the game.
		
Some cards has multiple Special Effects, and these effects never expire. Special Effects do not activate when the card is under Time Stop",
		"image": null
	},
	"StartOfTurnEffects": {
		"text": "These effects activate at the start of the player's turn. Each effect can have a different value per card. Check the card's tooltip for its corresponding X value.

Growth: Increases card's Attack by X
Harden: Increases card's Block by X
Wane: Decreases card's Attack by X
Soften: Decreases card's Block by X",
		"image": null
	},
	"OnPlayedEffects": {
		"text": "These effects activate immediately when the card is played and remain active until the card is removed from the board.

Bonus: The player can take X extra actions
Adjacency Effects: Applies certain stat increases/decreases or special effects to cards to the left and right of this card
		",
		"image": null
	},
	"CombatEffects": {
		"text": "These effects activate when the card is in combat (either attacking or blocking).

Falter: This card causes the card that blocks it to enter the Falter status. Until the next turn, the blocker cannot attack and takes 1.5x damage when blocking
Deathtouch: Instantly kills anything that the card attacks (not including the player/opponent). Can trigger multiple times.
Lifelink: If this card dies while blocking, it kills its attacker as well
Rollover: Any extra damage from this card attacking that is not blocked by the blocker will require the defender to choose another blocking card or take the remaining damage to their HP. Ex. After blocking 3 damage off a 4 damage Rollover attack, the opponent must block the additional 1 damage.
		",
		"image": null
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
	"Combat": {
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
	"TimeActions": {
		"text": "During their turn, the player can take one Time Action at the cost of their own HP to gain an advantage on the board. These manipulate the state of the game and can have further drawbacks beyond just HP.
		",
		"image": null
	},
	"TimeStop": {
		"text": "The player can choose a slot on the entire board to stop time for X turns. During those X turns, the slot cannot have any action taken on it, including attack, block, place card, or spell card

No special effects will take effect on a card slot that has Time Stop active on it
		",
		"image": null
	},
	"BorrowedTime": {
		"text": "For 3 HP, the player can activate Borrowed Time to gain another action without spending one to use this Borrowed Time. 
		
This time, however, is borrowed, as the player will repay their debt by losing an action 3 turns later. This can be used to take an extra action in a pivotal moment that would otherwise be impossible to avert.
		",
		"image": null
	},
	"TemporalCollapse": {
		"text": "The player can trigger a Temporal Collapse on their opponent, causing the opponent to instantly perish in 3 turns. 

Doing so comes at a price of all but 1 of the player's HP, so they must survive for those three turns for time to collapse on their opponent. If they are not able to, they lose.
		",
		"image": null
	},
	"HowToWin": {
		"text": "The game ends when the Player or Opponent's HP is reduced to zero. Each turn is vital to setting up the future board state to ensure favorable outcomes",
		"image": null
	}
}

@onready var options_box: VBoxContainer = $OverlayColumns/OptionsScroll/OptionsBox
@onready var info_title: RichTextLabel = $OverlayColumns/InfoScroll/InfoBox/OptionTitle
@onready var info_image: TextureRect = $OverlayColumns/InfoScroll/InfoBox/AspectFrame/OptionImage
@onready var info_video : VideoStreamPlayer = $OverlayColumns/InfoScroll/InfoBox/AspectFrame/OptionVideo
@onready var info_text: RichTextLabel = $OverlayColumns/InfoScroll/InfoBox/OptionInfo
@onready var aspect_frame : AspectRatioContainer = $OverlayColumns/InfoScroll/InfoBox/AspectFrame
@onready var special_effects_button: Button = $OverlayColumns/OptionsScroll/OptionsBox/CardSpecialEffects
@onready var special_effects_options: VBoxContainer = $OverlayColumns/OptionsScroll/OptionsBox/SpecialEffectsOptions
@onready var time_actions_button: Button = $OverlayColumns/OptionsScroll/OptionsBox/TimeActions
@onready var time_actions_options: VBoxContainer = $OverlayColumns/OptionsScroll/OptionsBox/TimeActionsOptions


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	info_image.hide()
	info_text.text = ""
	
	for child in options_box.get_children():
		if child is Button:
			var topic_id := String(child.name)

			if TOPICS.has(topic_id):
				child.pressed.connect(show_topic.bind(topic_id))
		elif child is VBoxContainer:
			for lower_child in child.get_children():
				var topic_id := String(lower_child.name)

				if TOPICS.has(topic_id):
					lower_child.pressed.connect(show_topic.bind(topic_id))
	
	special_effects_button.pressed.connect(_on_special_effects_pressed)
	time_actions_button.pressed.connect(_on_time_actions_pressed)


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

func _on_special_effects_pressed() -> void:
	special_effects_options.visible = not special_effects_options.visible

	special_effects_button.text = (
		"Card Special Effects ▼"
		if special_effects_options.visible
		else "Card Special Effects ▶"
	)

	show_topic("CardSpecialEffects")

func _on_time_actions_pressed() -> void:
	time_actions_options.visible = not time_actions_options.visible

	time_actions_button.text = (
		"Time Actions ▼"
		if time_actions_options.visible
		else "Time Actions ▶"
	)

	show_topic("TimeActions")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
