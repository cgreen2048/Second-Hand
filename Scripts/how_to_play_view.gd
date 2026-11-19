class_name HowToPlayView
extends Control

const TOPICS : Dictionary = {
	"HP": {
		"text": "The player and the opponent will have a set max HP that can be reduced either by taking damage from the other's [color=#FF7D78]Attack[/color] or by taking a [color=#FFB333]Time Action[/color].\n\n When one side is reduced to [b]zero HP[/b], the other wins the game",
		"image": null
	},
	"Cards": {
		"text": "As a card battler, the player and the opponent have a deck of 30 cards, where each card is either a:\n
- [b]Troop card:[/b] Cards placed onto the board. These have two values: [color=#FF7D78]Attack[/color] and [color=#69CCF0]Block[/color]
- [b]Spell card:[/b] cards played immediately from the hand and not placed onto the board
		",
		"image": preload("res://Assets/HowToPlay/Card.png")
	},
	"CardSpecialEffects": {
		"text": "Some troop cards will have certain special effects that make them more useful than just their [color=#FF7D78]Attack[/color] and [color=#69CCF0]Block[/color] values. Effects can trigger immediately when played, at the start of the player's turn, or when attacking or blocking. These can dramatically change the game.
		
Some cards has multiple Special Effects, and these effects [b]never expire[/b]. Special Effects do not activate when the card is under [color=#FFB333]Time Stop[/color]",
		"image": null
	},
	"StartOfTurnEffects": {
		"text": "The card tooltip shows how its stats change at the start of its owner's turn.

In [b]At start of turn[/b], the first number changes [color=#FF7D78]Attack[/color] and the second changes [color=#69CCF0]Block[/color].
For example, a card with [color=#FF7D78]+2[/color]/[color=#69CCF0]-1[/color] will gain 2 [color=#FF7D78]Attack[/color] and lose 1 [color=#69CCF0]Block[/color] at the start of the turn.",
		"image": null
	},
	"CombatEffects": {
		"text": "These effects activate when the card is in combat.

[b]Falter:[/b] This card causes the card that [color=#69CCF0]blocks[/color] it to enter the Falter status. Until the next turn, the card [b]cannot [color=#FF7D78]attack[/color][/b] and takes [b]1.5x damage[/b] when blocking
[b]Deathtouch:[/b] Instantly kills anything that the card [color=#FF7D78]attacks[/color] (not including the player/opponent). Can trigger multiple times.
[b]Lifelink:[/b] If this card dies while it [color=#69CCF0]blocks[/color], it kills its attacker as well
[b]Rollover:[/b] Any extra damage from this card when it [color=#FF7D78]attacks[/color] that is not blocked by the blocker will require the defender to choose another blocking card or take the remaining damage to their HP. For example, after blocking 3 damage off a 4 damage Rollover attack, the opponent must block the additional 1 damage.
		",
		"image": null
	},
	"OnPlayedEffects": {
		"text": "These effects activate immediately when the card is played and remain active until the card is removed from the board.

[b]Bonus:[/b] The player can take X extra actions
[b]Adjacency Effects:[/b] Applies certain stat increases/decreases or special effects to cards to the left and right of this card
		",
		"image": null
	},
	"Hand": {
		"text": "The Hand contains the cards that the each player can play on their turn. At the start of each turn, the player draws a card from their Deck into their Hand

At the end of the turn, if the player has more than 4 cards in their Hand, they must [b]discard until they hold 4 cards in their hand[/b].

Each player's hand is [b]hidden to the opponent[/b].
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/Hand.ogv"),
		"video_ratio": 1920.0 / 600.0
	},
	"Deck": {
		"text": "The Deck is the source of the player/opponent's cards during the match. The Deck can have up to  20 cards with no limit on duplicate cards. Outside of a match, the player can configure which cards are in their Deck.
		
At the start of the match, both Decks will be shuffled randomly. During the match, the player/opponent will draw a card from the Deck at the start of each turn. If the Deck is empty, [b]the Discard Pile is shuffled to become the new Deck[/b], and the Discard Pile is emptied. The player/opponent then draws from the new Deck.
- If there are no cards in either the Deck or Discard Pile, the player/opponent [b]does not draw a card[/b]

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
		"text": "The player/opponent's Graveyard contains all cards that have perished at any point during the match. When a card perishes, it is transferred to its owner's Graveyard and [b]cannot re-enter the Deck[/b] without a spell card to do so.
		
The player can view all cards in their Graveyard by clicking their Graveyard
		",
		"image": null,
		"video": preload("res://Assets/HowToPlay/Graveyard.ogv")
	},
	"GameBoard": {
		"text": "The board will contain two rows with [b]four spaces on each row[/b], where [b]one card can occupy one space[/b]. The player can only play cards on the 4 spaces in their row and vice versa for the opponent except in special cases.
		
When a card is in a space, it [b]cannot be removed[/b] unless killed by an [color=#FF7D78]attack[/color] (either by the player or the opponent) exiled into the graveyard by a spell card, or temporarily removed by [color=#FFB333]Time Rewind[/color]

The Game Board can be modified in individual spaces by specific [color=#FFB333]Time Actions[/color], but the history of the last X turns of the Board is stored.
		",
		"image": preload("res://Assets/HowToPlay/GameBoard.png")
	},
	"TakingATurn": {
		"text": "At the start of their turn, the player/opponent will draw a card from their deck. Then, they can take [b]up to 2[/b] of the following actions:
- Place a troop card from their hand onto one of the open spaces on their board
- Cast a spell card from their hand
- Take a [color=#FFB333]Time Action[/color] at the cost of HP
- [color=#FF7D78]Attack[/color] with a card on the board
			
The above actions can be taken more than once in one turn except for [color=#FFB333]Time Action[/color].
		",
		"image": null
	},
	"PlayingCards": {
		"text": "To play a card, [b]click and drag[/b] a card from your hand to one of the open slots on [b]your side of the board[/b]",
		"image": null,
		"video": preload("res://Assets/HowToPlay/PlayingCards.ogv")
	},
	"Attacking": {
		"text": "The player can choose to [color=#FF7D78]Attack[/color] on their turn. After selecting Attack, the player can select a card in one of their card slots to attack with. Once selecting, however, they [b]do not get to choose their target[/b].

The defender chooses how to respond. An unblocked attack reduces their HP by the attacking card’s [color=#FF7D78]Attack[/color].

While you choose an attacker, eligible cards show the [color=#FF7D78]Attack[/color] marker. If the opponent blocks, their card shows the [color=#69CCF0]Block[/color] marker.",
		"image": null,
		"video": preload("res://Assets/HowToPlay/AttackingAndBlocking.ogv")
	},
	"Blocking": {
		"text": "When the opponent uses an [color=#FF7D78]Attacks[/color], choose whether to [color=#69CCF0]Block[/color] with a card, take the damage, or use a spell that can nullify it.

[b][color=#69CCF0]Block[/color]:[/b] The other player chooses one card on their side of the board. If the blocking card's [color=#69CCF0]Block[/color] is lower than the attacking card's [color=#FF7D78]Attack[/color], the blocking card perishes. If the blocking card's [color=#FF7D78]Attack[/color] is higher than the attacking card's [color=#69CCF0]Block[/color], the attacking card perishes. If neither of these, neither card perishes, but if both, both cards perish.

[b]No Block:[/b] The other player chooses not to block, reducing their HP by the attacking card's [color=#FF7D78]Attack[/color]

[b]Spell Card:[/b] If the other player has a spell card in Hand that can nullify damage, they can instantly play that card

The attacking opponent card shows the [color=#FF7D78]Attack[/color] marker. While you choose a blocker, eligible cards show the [color=#69CCF0]Block[/color] marker.",
		"image": null,
		"video": preload("res://Assets/HowToPlay/AttackingAndBlocking.ogv")
	},
	"TimeActions": {
		"text": "During their turn, the player can take [b]one [color=#FFB333]Time Action[/color][/b] at the [b]cost of their own HP[/b] to gain an advantage on the board. These manipulate the state of the game and can have further drawbacks beyond just HP.
		",
		"image": null
	},
	"TimeStop": {
		"text": "The player can pay [b][color=#D65B5B]2 HP[/color][/b] to choose a slot on the entire board to [b][color=#FFB333]stop time[/color][/b] for 2 turns. During those 2 turns, the slot [b]cannot have any action taken on it[/b], including attack, block, place card, or spell card

[b]No special effects[/b] will take effect on a card slot that has [color=#FFB333]Time Stop[/color] active on it
		",
		"image": null
	},
	"TimeRewind": {
		"text": "The player can pay [b][color=#D65B5B]3 HP[/color][/b] to choose a slot on the entire board to [b][color=#FFB333]rewind time[/color][/b] on to a point in history at a chosen number of actions ago.
		
Scroll through the board history to determine which slot at which point in history to rewind to. Click a slot to select it and then rewind time.

[b]Note:[/b] The rewind is only temporary, and time must complete its loop. After rewinding back X actions, once X actions are taken after the rewind, the slot will [b]return to its original state prior to the rewind.[/b] This includes all card placements, stat changes, falter, time stop, etc.",
		"image": null,
		"video": preload("res://Assets/HowToPlay/TimeRewind.ogv")
	},
	"BorrowedTime": {
		"text": "For [b][color=#D65B5B]3 HP[/color][/b], the player can activate [color=#FFB333]Borrowed Time[/color] to [b]gain another action[/b] without spending one to use this [color=#FFB333]Borrowed Time[/color].
		
This time, however, is borrowed, as the player will repay their debt by [b]losing an action 3 turns later[/b]. This can be used to take an extra action in a pivotal moment that would otherwise be impossible to avert.
		",
		"image": null
	},
	"TemporalCollapse": {
		"text": "The player can trigger a [color=#FFB333]Temporal Collapse[/color] on their opponent, causing the opponent to instantly [b]die in 3 turns[/b].

Doing so reduces the player to [b][color=#D65B5B]1 HP[/color][/b], so they must survive for those three turns for time to collapse on their opponent. If they are not able to, they lose.
		",
		"image": null
	},
	"HowToWin": {
		"text": "The game ends when the Player or Opponent's [b]HP is reduced to zero[/b]. Each turn is vital to setting up the future board state to ensure favorable outcomes",
		"image": null
	}
}

const PILE_SECTIONS := {
	"Deck": "Deck",
	"DiscardPile": "Discard Pile",
	"Graveyard": "The Graveyard",
}

@onready var options_box: VBoxContainer = $OverlayColumns/OptionsScroll/OptionsBox
@onready var info_scroll: ScrollContainer = $OverlayColumns/InfoScroll
@onready var info_title: RichTextLabel = $OverlayColumns/InfoScroll/InfoBox/OptionTitle
@onready var sections: VBoxContainer = $OverlayColumns/InfoScroll/InfoBox/Sections
@onready var first_section: VBoxContainer = $OverlayColumns/InfoScroll/InfoBox/Sections/Topic


func _ready() -> void:
	first_section.hide()
	_connect_options(options_box)


func _connect_options(container: VBoxContainer) -> void:
	for child in container.get_children():
		if child is not Button:
			continue
		var button: Button = child
		var topic_id := String(button.name)
		var title := button.text
		var options := container.get_node_or_null(topic_id + "Options") as MarginContainer
		if options:
			button.text = "▸ " + title
			button.toggled.connect(_toggle_options.bind(options, button, title, topic_id))
			_connect_options(options.get_node("Topics") as VBoxContainer)
		else:
			button.pressed.connect(show_topic.bind(topic_id, title))


func _toggle_options(
	expanded: bool, options: MarginContainer, button: Button, title: String, topic_id: String
) -> void:
	options.visible = expanded
	button.text = ("▾ " if expanded else "▸ ") + title
	if expanded and TOPICS.has(topic_id):
		show_topic(topic_id, title)


func show_topic(topic_id: String, title: String = "") -> void:
	for child in sections.get_children():
		if child != first_section:
			sections.remove_child(child)
			child.queue_free()

	first_section.show()
	info_scroll.scroll_vertical = 0
	var display_title := title if not title.is_empty() else topic_id.capitalize()
	match topic_id:
		"Attacking":
			display_title = "[color=#FF7D78]%s[/color]" % display_title
		"Blocking":
			display_title = "[color=#69CCF0]%s[/color]" % display_title
		"TimeActions", "TimeStop", "TimeRewind", "BorrowedTime", "TemporalCollapse":
			display_title = "[color=#FFB333]%s[/color]" % display_title
	info_title.text = display_title
	if topic_id == "CardPiles":
		_show_section(first_section, "Deck", PILE_SECTIONS["Deck"])
		for section_id in ["DiscardPile", "Graveyard"]:
			var section := first_section.duplicate() as VBoxContainer
			sections.add_child(section)
			_show_section(section, section_id, PILE_SECTIONS[section_id])
	else:
		_show_section(first_section, topic_id)


func _show_section(section: VBoxContainer, topic_id: String, heading: String = "") -> void:
	var topic: Dictionary = TOPICS[topic_id]
	var section_title: RichTextLabel = section.get_node("SectionTitle")
	var info_text: RichTextLabel = section.get_node("OptionInfo")
	var frame: AspectRatioContainer = section.get_node("AspectFrame")
	var info_image: TextureRect = frame.get_node("OptionImage")
	var info_video: VideoStreamPlayer = frame.get_node("OptionVideo")

	section_title.text = heading
	section_title.visible = not heading.is_empty()
	var body: String = topic["text"]
	match topic_id:
		"StartOfTurnEffects":
			body = body.replace("[b]At start of turn[/b]", Definitions.format_effect(Definitions.SpecialEffects.START_TURN, "At start of turn"))
		"OnPlayedEffects":
			body = body.replace("[b]Bonus:[/b]", Definitions.format_effect(Definitions.SpecialEffects.BONUS, "Bonus") + ":")
			body = body.replace("[b]Adjacency Effects:[/b]", Definitions.ADJACENCY_EFFECT_LABEL + ":")
		"CombatEffects":
			for effect in [Definitions.SpecialEffects.FALTER, Definitions.SpecialEffects.DEATHTOUCH, Definitions.SpecialEffects.LIFELINK, Definitions.SpecialEffects.ROLLOVER]:
				var label: String = Definitions.SpecialEffects.find_key(effect).capitalize()
				body = body.replace("[b]%s:[/b]" % label, Definitions.format_effect(effect, label) + ":")
	info_text.text = body
	info_image.texture = topic["image"]
	info_image.visible = info_image.texture != null

	info_video.stop()
	info_video.stream = topic.get("video")
	info_video.visible = info_video.stream != null
	frame.ratio = topic.get("video_ratio", 16.0 / 9.0)
	frame.visible = info_image.visible or info_video.visible
	if info_video.visible:
		info_video.play()
