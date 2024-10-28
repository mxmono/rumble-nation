extends Control

signal dice_rolled()
signal game_started()
signal dice_selected(territory_option, deploy_option, is_leader)
signal piece_used(player, n, is_leader)
signal roll_phase_done()

var dice_move_options = []
const DICE_BUTTONS_PARENT = "GameButtons/Dice/"
@onready var roll_dice_button = get_node(DICE_BUTTONS_PARENT + "RollDiceButton")
@onready var dice_option1 = get_node(DICE_BUTTONS_PARENT + "DiceOption1")
@onready var dice_option2 = get_node(DICE_BUTTONS_PARENT + "DiceOption2")
@onready var dice_option3 = get_node(DICE_BUTTONS_PARENT + "DiceOption3")
@onready var dice_option1_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption1L")
@onready var dice_option2_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption2L")
@onready var dice_option3_leader = get_node(DICE_BUTTONS_PARENT + "DiceOption3L")
@onready var dice_result_label = get_node(DICE_BUTTONS_PARENT + "ResultLabel")

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


func start_game():
	$Menu/StartButton.pressed.connect(_on_game_started)
	game_started.emit()

func _on_game_started():
	game_started.emit()

# Handle the dice roll button press
func _on_roll_dice_button_pressed():
	#$RollDiceButton.disabled = true
	# Clear button text
	for button in [dice_option1, dice_option2, dice_option3]:
		button.text = ""
	var dice_results = []
	var possible_moves = {}
	dice_results = [roll_dice(), roll_dice(), roll_dice()]
	dice_results.sort()
	possible_moves = combine_dice(dice_results)
	dice_rolled.emit()
	dice_result_label.text = "  ".join(dice_results)

	# Show dice options and connect the click action
	var i = 0
	var buttons = [dice_option1, dice_option2, dice_option3]
	for territory_option in possible_moves:
		var deploy_option = possible_moves[territory_option]
		dice_move_options.append({"territory": territory_option, "deploy": deploy_option})
		var button = buttons[i]
		i += 1
		button.text = "Place " + str(deploy_option) + " on " + str(territory_option)

func roll_dice():
		randomize()
		return randi() % 6 + 1

func combine_dice(dice_results) -> Dictionary:
	# Get current player for piece counting
	var players = get_node("/root/GameController").players
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
			players[current_player - 1]["soldier"] + players[current_player - 1]["leader"]
		)

	return possible_moves

#region Handle rolled dice options
func _on_dice_option_1_pressed():
	_on_dice_option_selected(dice_move_options[0]["territory"], dice_move_options[0]["deploy"], false)

func _on_dice_option_2_pressed():
	_on_dice_option_selected(dice_move_options[1]["territory"], dice_move_options[1]["deploy"], false)

func _on_dice_option_3_pressed():
	_on_dice_option_selected(dice_move_options[2]["territory"], dice_move_options[2]["deploy"], false)

func _on_dice_option_1_leader_pressed():
		_on_dice_option_selected(dice_move_options[0]["territory"], dice_move_options[0]["deploy"], true)

func _on_dice_option_2_leader_pressed():
		_on_dice_option_selected(dice_move_options[1]["territory"], dice_move_options[1]["deploy"], true)
		
func _on_dice_option_3_leader_pressed():
		_on_dice_option_selected(dice_move_options[2]["territory"], dice_move_options[2]["deploy"], true)

func _on_dice_option_selected(territory_option, deploy_option, has_leader):
	var current_player = get_node("/root/GameController").current_player
	dice_selected.emit(territory_option, deploy_option, has_leader)
	piece_used.emit(current_player, deploy_option, has_leader)
	# reset all options (declared as attribute)
	dice_move_options = []
	# Clear button text
	for button in [dice_option1, dice_option2, dice_option3]:
		button.text = ""
	roll_phase_done.emit()
#endregion
