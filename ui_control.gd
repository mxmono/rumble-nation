extends Node

signal roll_dice_requested()
signal dice_option_selected(i: int, has_leadr: bool)
signal card_selected(card: Card)
signal card_move_reverted(moves: Array) # move is an array of [player, territory_index, deploy_count, has_leader]s
signal card_move_confirmed()

@onready var turn_logic = get_node("/root/Game")
@onready var control_scene = get_node("/root/Game/Control")
@onready var board_scene = get_node("/root/Game/Board")
const DICE_BUTTONS_PARENT = "../GameButtons/Dice/"
const CARD_BUTTONS_PARENT = "../GameButtons/Card/"
const LEADER_BUTTONS_PARENT = "../GameButtons/Leader/"
const CONTROL_PANEL = "../GameButtons/"
@onready var roll_dice_button = get_node(DICE_BUTTONS_PARENT + "RollDiceButton")
@onready var dice_result_label = get_node(DICE_BUTTONS_PARENT + "ResultLabel")
@onready var dice_option_buttons = get_node(DICE_BUTTONS_PARENT + "DiceOptions").get_children()
@onready var dice_option_buttons_soldier = [
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption1"),
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption2"),
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption3"),
]
@onready var dice_option_buttons_leader = [
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption1L"),
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption2L"),
	get_node(DICE_BUTTONS_PARENT + "DiceOptions/DiceOption3L"),
]
@onready var card_tray = get_node(CARD_BUTTONS_PARENT + "CardTray")
@onready var leader_tray = get_node(LEADER_BUTTONS_PARENT + "CardTray")
@onready var card_buttons: Array = []  # updated on ready and _process
@onready var card_action_buttons = get_node(CARD_BUTTONS_PARENT + "ActionButtons").get_children() + get_node(LEADER_BUTTONS_PARENT + "ActionButtons").get_children()


func _ready() -> void:
	
	# inbound signals
	turn_logic.phase_started.connect(_on_phase_started)
	control_scene.dice_rolled.connect(_on_dice_rolled)
	board_scene.card_move_selected.connect(_on_card_move_selected)
	
	# self signals
	roll_dice_button.pressed.connect(_on_roll_dice_button_pressed)
	for i in range(3):
		dice_option_buttons_soldier[i].pressed.connect(_on_dice_option_selected.bind(i, false))
		dice_option_buttons_leader[i].pressed.connect(_on_dice_option_selected.bind(i, true))
	# card confirm and reset buttons
	get_node(CARD_BUTTONS_PARENT + "ActionButtons/ResetCardButton").pressed.connect(_on_card_reset_button_pressed)
	get_node(LEADER_BUTTONS_PARENT + "ActionButtons/ResetCardButton").pressed.connect(_on_card_reset_button_pressed)
	get_node(CARD_BUTTONS_PARENT + "ActionButtons/ConfirmCardButton").pressed.connect(_on_card_confirm_button_pressed)
	get_node(LEADER_BUTTONS_PARENT + "ActionButtons/ConfirmCardButton").pressed.connect(_on_card_confirm_button_pressed)
	
	
	# display cards and leaders based on drafted cards in game state
	display_cards()
	display_leaders()
	
	# once the cards are initialized, connect their signals
	self.card_buttons = card_tray.get_children() + leader_tray.get_children()
	for card_button in card_buttons:
		print(card_button.card_name)
		card_button.card_selected.connect(_on_card_selected)


func _process(delta):
	self.card_buttons = self.card_tray.get_children()
	self.card_buttons += self.leader_tray.get_children()


func _on_phase_started(phase):
	
	match phase:

		GameState.TurnPhase.CHOICE:
			set_control_to_player_color()
			
			enable_roll_dice()
			disable_dice_options()
			
			enable_cards_if_all_players_active()
			disable_card_actions()
			
		GameState.TurnPhase.CARD:
			highlight_selected_card()
			
			disable_roll_dice()
			disable_dice_options()
			
			disable_card_actions()

		GameState.TurnPhase.CONFIRM_OR_RESET_CARD:
			disable_roll_dice()
			disable_dice_options()
			
			enable_card_actions_if_all_players_active()
		
		GameState.TurnPhase.ROLL:
			enable_roll_dice()
			disable_dice_options()
			
			disable_cards()
			disable_card_actions()

		GameState.TurnPhase.REROLL:
			roll_dice_button.text = "Reroll"
			
			enable_roll_dice()
			disable_dice_options()
			
			disable_cards()
			disable_card_actions()
		
		GameState.TurnPhase.PLACE:
			roll_dice_button.text = "Roll Dice"
			
			disable_roll_dice()
			disable_dice_options()
			
			disable_cards()
			disable_card_actions()

		GameState.TurnPhase.END:
			roll_dice_button.text = "Roll Dice"
			
			disable_roll_dice()
			disable_dice_options()
			
			disable_cards()
			disable_card_actions()


func _on_roll_dice_button_pressed():
	roll_dice_requested.emit()


func _on_card_selected(card):
	card_selected.emit(card)
	
	# TODO: highlight the card selected
	
	# disable all other cards
	disable_cards()
	disable_card_actions()


func _on_card_move_selected(moves: Array):
	var card = GameState.current_card
	
	# enable confirm/reset if early finish allowed
	if card.effect[moves.size() -1].get("finish_allowed"):
		enable_card_actions_if_all_players_active()
	
	# or if card step is finished, enable confirm/reset
	if card.effect.size() == card.effect_index:
		enable_card_actions_if_all_players_active()


func _on_card_reset_button_pressed():
	var moves = GameState.current_card.staged_moves
	
	# reset card before emitting the signals, so that downstreams can grab correct info
	GameState.current_card.reset_card()
	card_move_reverted.emit(moves)


func _on_card_confirm_button_pressed():
	board_scene.get_node("UI").unhighlight_territories()
	card_move_confirmed.emit()


func _on_dice_option_selected(i: int, has_leader: bool):
	dice_option_selected.emit(i, has_leader)
	dice_result_label.text = ""


func set_control_to_player_color():
	var current_color = GameState.players[GameState.current_player]["color"]
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = current_color
	style_box.bg_color.a = 0.5
	get_node(CONTROL_PANEL).add_theme_stylebox_override("panel", style_box)


func enable_roll_dice():
	self.roll_dice_button.disabled = false


func disable_roll_dice():
	self.roll_dice_button.disabled = true


func enable_dice_options():
	for button in self.dice_option_buttons:
		button.disabled = false
		button.visible = true


func disable_dice_options():
	for button in self.dice_option_buttons:
		button.disabled = true
		button.visible = false
	for button in self.dice_option_buttons_soldier:
		button.text = ""


func enable_cards_if_all_players_active():
	for button in self.card_buttons:
		button.disabled = not button.is_condition_met(GameState.current_player)
		button.visible = true
	
	# if used card or leader already, cannot use again
	if GameState.players[GameState.current_player]["used_card"]:
		for button in self.card_tray.get_children():
			button.disabled = true
	
	if GameState.players[GameState.current_player]["used_leader"]:
		for button in self.leader_tray.get_children():
			button.disabled = true

	# however, if any player is out, cannot use card any more
	for player in range(GameState.num_players):
		if not GameState.players[player]["active"]:
			for card_button in self.card_buttons:
				card_button.disabled = true
	
	#for button in self.card_buttons:
		#print(button.card_name," enabled: ", not button.disabled )


func disable_cards():
	for button in self.card_buttons:
		button.disabled = true
		button.visible = true


func highlight_selected_card():
	GameState.current_card.modulate = GameState.players[GameState.current_player]["color"]


func enable_card_actions_if_all_players_active():
	for button in self.card_action_buttons:
		button.disabled = false
		button.visible = true
	
	# however, if any player is out, cannot use card any more
	for player in range(GameState.num_players):
		if not GameState.players[player]["active"]:
			for card_button in self.card_action_buttons:
				card_button.disabled = true


func disable_card_actions():
	for button in self.card_action_buttons:
		button.disabled = true
		button.visible = true


func display_cards():
	var i = 0
	var card_template: PackedScene = load("res://card_template.tscn")
	for card_name in GameState.drawn_cards:
		var card_script = load("res://cards/card_%s.gd" % card_name.to_lower())
		# instantiate the drawn card scene and add to parent
		var new_card = card_template.instantiate()
		new_card.set_script(card_script)
		new_card.get_node("Mask").custom_minimum_size = new_card.custom_minimum_size
		new_card.name = "Card" + str(i) + card_name
		i += 1
		card_tray.add_child(new_card)


func display_leaders():
	var i = 0
	var leader_template: PackedScene = load("res://card_template.tscn")
	for leader_name in GameState.drawn_leaders:
		var leader_script = load("res://cards/leader_%s.gd" % leader_name.to_lower())
		# instantiate the drawn card scene and add to parent
		var new_leader = leader_template.instantiate()
		new_leader.set_script(leader_script)
		new_leader.name = "Leader" + str(i) + leader_name
		new_leader.custom_minimum_size.y = 120
		for node in ["ColorRect", "CardBorder", "Mask"]:
			new_leader.get_node(node).custom_minimum_size = new_leader.custom_minimum_size
		i += 1
		leader_tray.add_child(new_leader)


func _on_dice_rolled(dice_results: Array, move_options: Array):
	var current_player = GameState.current_player
	
	# show dice results on label
	dice_result_label.text = "  ".join(dice_results)

	# show dice options and buttons
	for i in range(move_options.size()):
		var button = dice_option_buttons_soldier[i]
		var button_leader = dice_option_buttons_leader[i]
		
		button.visible = true
		button_leader.visible = true
		button.text =  "Place %s on %s" % [
			str(move_options[i]["deploy_count"]), str(move_options[i]["territory_score"])
		]
		
		# if leader already played, disable the leader button
		if GameState.players[current_player]["leader"] <= 0:
			button_leader.disabled = true
		else:
			button_leader.disabled = false
		
		# only enable the regular button if the deploy is all soldier
		# (eg can happen last round, deploy = 2 but with 1 leader, 1 solider left)
		if move_options[i]["deploy_count"] > GameState.players[current_player]["soldier"]:
			button.disabled = true
		else:
			button.disabled = false
