extends Control

signal dice_rolled(dice_results: Array, move_options: Array)
signal dice_selected(territory_index: int, deploy_count: int, is_leader: bool)
signal roll_phase_done()

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
@onready var dice_option_buttons = [dice_option1, dice_option2, dice_option3]
@onready var dice_option_buttons_leader = [dice_option1_leader, dice_option2_leader, dice_option3_leader]
var dice_move_options = []

# cards
#var cards = ["Kasei", "Monomi", "Hitojichi", "Tsuihou", "Muhon", "Otori", "Suigun", "Yamagoe", "Taikyaku", "Shinobi", "Buntai", "Jouraku"]
var cards = ["Jouraku"]

# Called when the node enters the scene tree for the first time.
func _ready():
	# connect dice buttons
	roll_dice_button.pressed.connect(_on_roll_dice_button_pressed)
	for i in range(3):
		dice_option_buttons[i].pressed.connect(_on_dice_option_selected.bind(i, false))
		dice_option_buttons_leader[i].pressed.connect(_on_dice_option_selected.bind(i, true))
	
	# deal cards based on number of players
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
		get_node("GameButtons/Card/CardTray").add_child(new_card)

# Handle the dice roll button press
func _on_roll_dice_button_pressed():
	
	# roll the dice, get results, and possible moves
	var dice_results = [roll_dice(), roll_dice(), roll_dice()]
	dice_results.sort()
	var move_options = combine_dice(dice_results)
	
	# emit signal
	dice_rolled.emit(dice_results, move_options)

func _on_dice_rolled(dice_results, move_options):
	var current_player = get_node("/root/GameController").current_player
	self.dice_move_options = move_options
	
	# UI: display dice results
	dice_result_label.text = "  ".join(dice_results)
	for dice_button in dice_option_buttons:
		dice_button.text = ""
	
	# UI: disable and hide option buttons before showing them based on moves
	# otherwise, reroll phase will show all 3 all the time
	for button in dice_option_buttons + dice_option_buttons_leader:
		button.visible = false
		button.disabled = true

	# UI: show dice options and buttons
	for i in range(move_options.size()):
		var button = dice_option_buttons[i]
		var button_leader = dice_option_buttons_leader[i]
		
		button.visible = true
		button_leader.visible = true
		button.text =  "Place %s on %s" % [
			str(move_options[i]["deploy_count"]), str(move_options[i]["territory_score"])
		]
		
		# if leader already played, disable the leader button
		if Settings.players[current_player]["leader"] <= 0:
			button_leader.disabled = true
		else:
			button_leader.disabled = false
		
		# only enable the regular button if the deploy is all soldier
		# (eg can happen last round, deploy = 2 but with 1 leader, 1 solider left)
		if move_options[i]["deploy_count"] > Settings.players[current_player]["soldier"]:
			button.disabled = true
		else:
			button.disabled = false
	
	print("dice option 3 button visibile: ", dice_option3.visible, " disabled:", dice_option3.disabled)

func roll_dice() -> int:
		randomize()
		return randi() % 6 + 1

func combine_dice(dice_results: Array) -> Array:
	var current_player = get_node("/root/GameController").current_player
	var territory_points_to_index = get_node("/root/GameController/Map").territory_points_to_index
	
	# calculate all move options
	var move_options = []
	for i in range(3):
		# deploy count is bound by how many pieces are left
		var deploy_count = (dice_results[i % 3] + 1) / 2
		deploy_count = min(
			deploy_count,
			Settings.players[current_player]["soldier"] + Settings.players[current_player]["leader"]
		)
		var territory_score = dice_results[(i + 1) % 3] + dice_results[(i + 2) % 3]
		var territory_index = territory_points_to_index[territory_score]
		var option = {
			"deploy_count": deploy_count,
			"territory_score": territory_score, 
			"territory_index": territory_index
		}
		# only add if the move is not repeated
		if not move_options.has(option):
			move_options.append(option)

	return move_options

func _on_dice_option_selected(i, has_leader):
	var current_player = get_node("/root/GameController").current_player
	dice_selected.emit(
		self.dice_move_options[i]["territory_index"],
		self.dice_move_options[i]["deploy_count"],
		has_leader,
	)
	
	# reset all options
	self.dice_move_options = []
	roll_phase_done.emit()
