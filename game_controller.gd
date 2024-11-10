extends Node2D

@export var current_player: int = 0
var player_priority = []  # store which players are out first
var card_in_effect = null # store which card is being played

@onready var dice_buttons = $Control/GameButtons/Dice.get_children()
@onready var card_buttons = $Control/GameButtons/Card.get_children()
const DICE_MENU_PARENT = "Control/GameButtons/Dice/"
const CARD_MENU_PARENT = "Control/GameButtons/Card/"
@onready var pause_menu = $MenuCanvas/PauseMenu

# Enum for different phases in a player's turn
enum TurnPhase {
	CHOICE,
	CARD,
	CONFIRM_OR_RESET_CARD,
	ROLL,
	REROLL,
	PLACE,
	END
}

var current_phase = TurnPhase.CHOICE

# Start the game and the first player's turn
func _ready():
	
	# connect signals
	var control_scene = get_node("/root/GameController/Control")
	control_scene.roll_phase_done.connect(_on_place_phase_done)
	
	for card_button in $Control/GameButtons/Card.get_children():
		if card_button.name.begins_with("Card"):
			card_button.card_selected.connect(_on_card_selected)
	var board_scene = get_node("/root/GameController/Map")
	board_scene.card_move_selected.connect(_on_card_move_selected)
	board_scene.card_move_reverted.connect(_on_card_move_reverted)
	$Control/GameButtons/Card/ConfirmCardButton.pressed.connect(_on_card_confirmed)
	
	# initialize players
	for i in range(Settings.num_players):
		Settings.players[i]["soldier"] = 16
		Settings.players[i]["leader"] = 1
		Settings.players[i]["active"] = true
		Settings.players[i]["score"] = 0
		Settings.players[i]["territories"] = []
		Settings.players[i]["used_card"] = false
	
	# start turn sequence
	start_turn()

func _process(delta):
	self.card_buttons = $Control/GameButtons/Card.get_children()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false  # Resume the game
		pause_menu.hide()  # Hide the pause menu
	else:
		get_tree().paused = true  # Pause the game
		pause_menu.show()  # Show the pause menu centered

# Starts a player's turn
func start_turn():
	if all_players_out():
		print("All players are out of pieces! Transitioning to scoring phase.")
		scoring_phase()
		return
	
	# Find the next active player with pieces
	while not Settings.players[self.current_player]["active"]:
		self.current_player = (self.current_player + 1) % Settings.num_players

	print(Settings.players[self.current_player]["name"], "'s turn.")
	update_stats_label()
	
	# UI: enable all relevant buttons and labels
	for card_button in self.card_buttons:
		if card_button.name.begins_with("Card"):
			card_button.disabled = not card_button.is_condition_met(self.current_player)
			card_button.update_valid_targets()
	
	for dice_button in self.dice_buttons:
		if dice_button is Button:
			if dice_button.name == "RollDiceButton":
				dice_button.disabled = false
				dice_button.visible = true
	get_node(DICE_MENU_PARENT + "ResultLabel").text = ""
	
	# UI: use player color as menu background color
	var current_color = Settings.players[self.current_player]["color"]
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = current_color
	style_box.bg_color.a = 0.2
	$Control/GameButtons.add_theme_stylebox_override("panel", style_box)  # "panel" is the default style used for the background

	current_phase = TurnPhase.CHOICE
	process_turn_phase()

func update_stats_label():
	if all_players_out():
		$Info/PlayerLabel.text = "All players out"
	else:
		$Info/PlayerLabel.text = "%s's Turn" % Settings.players[self.current_player]["name"]
	for i in range(Settings.num_players):
		$Info/PlayerLabel.text += "\n%s: %s soldier(s) left; %s leader left" % [
			Settings.players[i]["name"],
			str(Settings.players[i]["soldier"]),
			str(Settings.players[i]["leader"])
		]

# Check if all players are out of pieces
func all_players_out() -> bool:
	for player in Settings.players:
		if player["active"]:
			return false  # At least one player still has pieces
	return true  # All players are out of pieces

# Process each phase of the turn
func process_turn_phase():
	var current_player_name = Settings.players[self.current_player]
	match current_phase:

		TurnPhase.CHOICE:
			print(current_player_name, " is in the CHOICE phase.")

		TurnPhase.CARD:
			print(current_player_name, " is in the CARD phase.")
			card_phase()

		TurnPhase.CONFIRM_OR_RESET_CARD:
			print(current_player_name, " to confirm or reset CARD actions.")
			comfirm_or_reset_card_phase()
		
		TurnPhase.ROLL:
			print(current_player_name, " is in the ROLL phase.")
			roll_phase()
		
		TurnPhase.REROLL:
			print(current_player_name, " is in the REROLL phase.")
			reroll_phase()
		
		TurnPhase.PLACE:
			print(current_player_name, " is in the PLACE phase.")
			place_phase()

		TurnPhase.END:
			print(current_player_name, "'s turn is ending.")
			end_turn()

#region handles card selection and application actions
func card_phase():
	# UI: disable all buttons in dice menu
	for dice_button in self.dice_buttons:
		if dice_button is Button:
			dice_button.visible = false
			dice_button.disabled = true
		else:  # it's the label
			dice_button.text = "Cannot use dice, a card has been selected"
			
	# UI: disable confirm or reset buttons
	get_node(CARD_MENU_PARENT + "ConfirmCardButton").disabled = true
	get_node(CARD_MENU_PARENT + "ResetCardButton").disabled = true

func comfirm_or_reset_card_phase():
	# UI: enable confirm or reset buttons
	get_node(CARD_MENU_PARENT + "ConfirmCardButton").disabled = false
	get_node(CARD_MENU_PARENT + "ResetCardButton").disabled = false

func _on_card_selected(card):
	# when clicked on a card, user has made a choice, ending the choice phase
	current_phase = TurnPhase.CARD
	process_turn_phase()
	
	# when player clicks on a playable card in the card tray
	# make sure globally we know which card is being player
	card_in_effect = card
	
	# UI: highlight the selected card
	card.modulate = Color(1, 0, 0)
	
	# UI: disable all card buttons
	for card_button in card_buttons:
		if card_button.name.begins_with("Card"):
			card_button.disabled = true

func _on_card_move_selected(moves):
	# moves is an array of [[player, territory_index, deploy_count, has_leader]]
	# when player clicked on territories to apply effect of the card
	# proceed to confirm or reset card
	current_phase = TurnPhase.CONFIRM_OR_RESET_CARD
	process_turn_phase()

func _on_card_move_reverted(moves):	
	# go back to CARD phase where user needs to take actions to apply effect of card
	current_phase = TurnPhase.CARD
	process_turn_phase()
	
func _on_card_confirmed():
	# the used card disappears
	card_in_effect.queue_free()
	
	# mark player
	Settings.players[self.current_player]["used_card"] = true
	
	# once the player confirmed the card action, transition to next turn
	current_phase = TurnPhase.END
	process_turn_phase()

	# reset for next card play
	card_in_effect = null
#endregion

#region handles dice rolling and piece placement actions
func roll_phase():
	print(Settings.players[self.current_player]["name"], " rolls.")

func reroll_phase():
	get_node(DICE_MENU_PARENT + "RollDiceButton").text = "Reroll"
	
func _on_dice_rolled(dice_results, move_options):
	# allow reroll if current player has used a card, otherwise the turn ends
	if Settings.players[self.current_player]["used_card"]:
		if current_phase != TurnPhase.REROLL:
			current_phase = TurnPhase.REROLL
		else:  # already rerolled
			current_phase = TurnPhase.PLACE
	else:
		current_phase = TurnPhase.PLACE
	process_turn_phase()
	
	# disable all card actions in card menu:
	for card_button in self.card_buttons:
		card_button.disabled = true

func place_phase():
	get_node(DICE_MENU_PARENT + "RollDiceButton").disabled = true
	
func _on_place_phase_done():
	# UI: disable buttons
	for button in self.dice_buttons:
		if button is Button and button.name.begins_with("DiceOption"):
			button.visible = false
			button.disabled = true
		if button.name == "RollDiceButton":
			button.disabled = true
			button.text = "Roll Dice"
			

	current_phase = TurnPhase.END
	process_turn_phase()
#endregion 

func update_player_piece_count(player, deploy_count, has_leader):
	# update player piece count on deployment
	# if adding pieces (normal game play)
	if deploy_count > 0:
		if has_leader:
			Settings.players[player]["leader"] -= 1
			Settings.players[player]["soldier"] -= deploy_count - 1
		else:
			Settings.players[player]["soldier"] -= deploy_count
	
	# if reverting (deploy_count will be negative)
	elif deploy_count < 0:  # eg, if -2
		if has_leader:  # eg if has leader, then go up 1 leader, 1 solder
			Settings.players[player]["leader"] += 1
			Settings.players[player]["soldier"] += (-deploy_count) - 1
		else:  # eg, go up 2 soldiers
			Settings.players[player]["soldier"] += (-deploy_count)

# Ends the player's turn and switches to the next player
func end_turn():
	print(Settings.players[self.current_player]["name"], "'s turn is over.")
	# Update player pieces and check if they are out
	if Settings.players[self.current_player]["leader"] + Settings.players[self.current_player]["soldier"] <= 0:
		print(Settings.players[self.current_player]["name"], " is out of pieces!")
		Settings.players[self.current_player]["active"] = false
		# store player out sequence for tie-breaker
		player_priority.append(self.current_player)

	# Switch to the next player
	self.current_player = (self.current_player + 1) % Settings.num_players
	update_stats_label()

	# Start the next player's turn
	start_turn()

func scoring_phase():
	print("entering scoring phase")
	# UI: disable the buttons
	for dice_button in self.dice_buttons:
		if dice_button is Button:
			dice_button.disabled = true
		if dice_button is Label:
			dice_button.text = ""
	for card_button in self.card_buttons:
		if card_button is Button:
			card_button.disabled = true
	
	# logic for scoring
	var territories = get_node("/root/GameController/Map").territories

	for territory in territories:
		# check who wins
		var territory_tally = territory.get("territory_tally")
		var scores = []
		for player_tally in territory_tally:
			scores.append(player_tally["soldier"] + player_tally["leader"] * 2)
		var winning_player = get_winning_player(scores, player_priority)
		print(territory.get("territory_points"), ":  player", str(winning_player), " wins")
		if winning_player == -1:  # if no one wins, go to next territory
			continue

		# reinforce to adjacent territories
		territory.reinforce(Settings.num_players, winning_player)
		
		# credit score to the player
		Settings.players[winning_player]["score"] += territory.get("territory_points")
	
	# annouce the winner
	var current_max = 0
	var i = 0
	var winners = [-1]
	for player in Settings.players:
		if player["score"] > current_max:
			current_max = player["score"]
			winners[0] = i
			i += 1
		elif player["score"] == current_max:
			winners.append(i)
	
	# UI: update winding label
	$Info/PlayerLabel.text += "\nPlayer %s wins! Player 1: %s; Player 2: %s" % [
		str(winners), str(Settings.players[0]["score"]), str(Settings.players[1]["score"])
	]

func get_winning_player(scores, player_priority) -> int:
	"""Based on total score and out sequence (player priority), return winning player"""
	var max_value = scores.max()  # Find the maximum value in the array
	
	# no one wins if no pieces
	if max_value == 0:
		return -1
	var player_index = []  # Array to store the indices of the max value
	
	# Loop through the array to find players with the highest score
	for i in range(scores.size()):
		if scores[i] == max_value:
			player_index.append(i)
	
	# if tie, check which player is out first, eg players [1, 2] tie
	# then if the player priority is [2, 1], player 2 wins
	if player_index.size() > 1:
		for player in player_priority:
			if player_index.find(player) != -1:
				return player
	
	# otherwise if only 1 winner, return the winner
	return player_index[0]
