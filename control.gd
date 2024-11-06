extends Control

signal dice_rolled()
signal game_started()
signal dice_selected(territory_index, deploy_count, is_leader)
signal roll_phase_done()

var dice_move_options = []
const DICE_BUTTONS_PARENT = "GameButtons/Dice/"
const CARD_BUTTONS_PARENT = "GameButtons/Card/"
@onready var roll_dice_button = get_node(DICE_BUTTONS_PARENT + "RollDiceButton")
@onready var dice_option1 = get_node(DICE_BUTTONS_PARENT + "DiceOption1")
@onready var dice_option2 = get_node(DICE_BUTTONS_PARENT + "DiceOption2")
@onready var dice_option3 = get_node(DICE_BUTTONS_PARENT + "DiceOption3")
@onready var dice_option1_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption1L")
@onready var dice_option2_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption2L")
@onready var dice_option3_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption3L")
@onready var dice_result_label = get_node(DICE_BUTTONS_PARENT + "ResultLabel")
@onready var dice_buttons = [dice_option1, dice_option2, dice_option3]
@onready var dice_buttons_leader = [dice_option1_leader, dice_option2_leader, dice_option3_leader]

# cards
var cards = ["Kasei", "Monomi", "Hitojichi"]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the RollDiceButton signal to the dice roll function
	roll_dice_button.pressed.connect(_on_roll_dice_button_pressed)
	dice_option1.pressed.connect(_on_dice_option_1_pressed)
	dice_option2.pressed.connect(_on_dice_option_2_pressed)
	dice_option3.pressed.connect(_on_dice_option_3_pressed)
	dice_option1_leader.pressed.connect(_on_dice_option_1_leader_pressed)
	dice_option2_leader.pressed.connect(_on_dice_option_2_leader_pressed)
	dice_option3_leader.pressed.connect(_on_dice_option_3_leader_pressed)
	
	# Deal cards based on number of players
	var n_cards = Settings.num_players + 1
	var drawn_cards = []
	cards.shuffle()
	if cards.size() >= n_cards:
		drawn_cards = cards.slice(0, n_cards)
	else:
		# Allow replacements: draw numbers with potential duplicates
		for i in range(n_cards):
			var random_index = randi() % cards.size()
			drawn_cards.append(cards[random_index])
	# initiate these cards
	var i = 0
	var card_template: PackedScene = load("res://card_template.tscn")
	for card_name in drawn_cards:
		var card_script = load("res://cards/card_%s.gd" % card_name.to_lower())
		# instantiate the drawn card scene and add to parent
		var new_card = card_template.instantiate()
		new_card.set_script(card_script)
		new_card.name = "Card" + str(i) + card_name
		i += 1
		get_node("GameButtons/Card").add_child(new_card)
		get_node("GameButtons/Card").move_child(new_card, 0)  # move before confirm and reset buttons

func _process(delta):
	var card = get_node("/root/GameController").card_in_effect
	if card != null:
		if card.effect_index + 1 == card.effect.size():
			get_node(CARD_BUTTONS_PARENT + "ConfirmCardButton").disabled = false

# Handle the dice roll button press
func _on_roll_dice_button_pressed():
	# clear button text
	for button in [dice_option1, dice_option2, dice_option3]:
		button.text = ""
	var dice_results = []
	var possible_moves = {}
	dice_results = [roll_dice(), roll_dice(), roll_dice()]
	dice_results.sort()
	possible_moves = combine_dice(dice_results)
	dice_result_label.text = "  ".join(dice_results)

	# UI: show dice options and connect the click action
	var current_player = get_node("/root/GameController").current_player
	var i = 0
	for territory_option in possible_moves:
		var deploy_count = possible_moves[territory_option]
		var territory_index = get_node("/root/GameController/Map").territory_points_to_index[territory_option]
		dice_move_options.append({"territory_index": territory_index, "deploy": deploy_count})
		var button = dice_buttons[i]
		var button_leader = dice_buttons_leader[i]
		
		# only enable the button if the deploy is all soldier
		# (eg can happen last round, deploy = 2 but with 1 leader, 1 solider left)
		button.disabled = false
		button_leader.disabled = false
		if deploy_count > Settings.players[current_player]["soldier"]:
			button.disabled = true
		button.visible = true
		button_leader.visible = true
		i += 1
		button.text = "Place " + str(deploy_count) + " on " + str(territory_option)
	
	dice_rolled.emit()

func roll_dice():
		randomize()
		return randi() % 6 + 1

func combine_dice(dice_results) -> Dictionary:
	# Get current player for piece counting
	var current_player = get_node("/root/GameController").current_player

	# Calculate moves
	var possible_territories = []
	var possible_deploys = []
	var possible_moves = {}
	possible_territories = [
		dice_results[0] + dice_results[1],
		dice_results[0] + dice_results[2],
		dice_results[1] + dice_results[2],
	]
	possible_deploys = [
		(dice_results[2] + 1) / 2,
		(dice_results[1] + 1) / 2,
		(dice_results[0] + 1) / 2
	]
	
	# Combine options
	for i in range(3):
		possible_moves[possible_territories[i]] = min(
			possible_deploys[i],
			Settings.players[current_player]["soldier"] + Settings.players[current_player]["leader"]
		)

	return possible_moves

#region Handle rolled dice options
func _on_dice_option_1_pressed():
	_on_dice_option_selected(dice_move_options[0]["territory_index"], dice_move_options[0]["deploy"], false)

func _on_dice_option_2_pressed():
	_on_dice_option_selected(dice_move_options[1]["territory_index"], dice_move_options[1]["deploy"], false)

func _on_dice_option_3_pressed():
	_on_dice_option_selected(dice_move_options[2]["territory_index"], dice_move_options[2]["deploy"], false)

func _on_dice_option_1_leader_pressed():
		_on_dice_option_selected(dice_move_options[0]["territory_index"], dice_move_options[0]["deploy"], true)

func _on_dice_option_2_leader_pressed():
		_on_dice_option_selected(dice_move_options[1]["territory_index"], dice_move_options[1]["deploy"], true)
		
func _on_dice_option_3_leader_pressed():
		_on_dice_option_selected(dice_move_options[2]["territory_index"], dice_move_options[2]["deploy"], true)

func _on_dice_option_selected(territory_index, deploy_count, has_leader):
	var current_player = get_node("/root/GameController").current_player
	dice_selected.emit(territory_index, deploy_count, has_leader)
	# reset all options (declared as attribute)
	dice_move_options = []
	# Clear button text
	for button in [dice_option1, dice_option2, dice_option3]:
		button.text = ""
	roll_phase_done.emit()
#endregion
