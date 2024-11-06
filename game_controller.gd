extends Node2D

@export var current_player: int = 0
var player_priority = []  # store which players are out first
var card_in_effect = null # store which card is being played

@onready var dice_buttons = $Control/GameButtons/Dice.get_children()
@onready var card_buttons = $Control/GameButtons/Card.get_children()
const DICE_MENU_PARENT = "Control/GameButtons/Dice"
const CARD_MENU_PARENT = "Control/GameButtons/Card"
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
	control_scene.roll_phase_done.connect(_on_roll_phase_done)
	
	for card_button in $Control/GameButtons/Card.get_children():
		if card_button.name.begins_with("Card"):
			card_button.card_selected.connect(_on_card_selected)
	var board_scene = get_node("/root/GameController/Map")
	board_scene.card_move_selected.connect(_on_card_move_selected)
	board_scene.card_move_reverted.connect(_on_card_move_reverted)
	$Control/GameButtons/Card/ConfirmCardButton.pressed.connect(_on_card_confirmed)
	
	print(Settings.players)
	for i in range(Settings.num_players):
		Settings.players[i]["soldier"] = 16
		Settings.players[i]["leader"] = 1
		Settings.players[i]["active"] = true
		Settings.players[i]["score"] = 0
		Settings.players[i]["territories"] = []
	
	start_turn()

func _process(delta):
	card_buttons = $Control/GameButtons/Card.get_children()

func toggle_pause():
	print(get_tree().paused)
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
	while not Settings.players[current_player]["active"]:
		current_player = (current_player + 1) % Settings.num_players

	print("Player ", current_player, "'s turn.")
	update_stats_label()
	
	# UI: enable all relevant buttons and labels
	for card_button in card_buttons:
		if card_button.name.begins_with("Card"):
			card_button.disabled = not card_button.is_condition_met(current_player)
			card_button.update_valid_targets()
	
	for dice_button in dice_buttons:
		if dice_button is Button:
			if dice_button.name == "RollDiceButton":
				dice_button.disabled = false
				dice_button.visible = true
	get_node(DICE_MENU_PARENT + "/ResultLabel").text = ""

	current_phase = TurnPhase.CARD
	process_turn_phase()

func update_stats_label():
	if all_players_out():
		$Info/PlayerLabel.text = "All players out"
	else:
		$Info/PlayerLabel.text = "%s's Turn" % Settings.players[current_player]["name"]
	for i in range(Settings.num_players):
		$Info/PlayerLabel.text += "\n%s: %s soldier(s) left; %s leader left" % [
			Settings.players[i]["name"],
			str(Settings.players[i]["soldier"]),
			str(Settings.players[i]["leader"])
		]

# Check if all players are out of pieces
func all_players_out() -> bool:
	for player in Settings.players:
		print(player)
		if player["active"]:
			return false  # At least one player still has pieces
	return true  # All players are out of pieces

# Process each phase of the turn
func process_turn_phase():
	match current_phase:

		TurnPhase.CHOICE:
			print("Player ", current_player, " is in the CHOICE phase.")

		TurnPhase.CARD:
			print("Player ", current_player, " is in the CARD phase.")

		TurnPhase.CONFIRM_OR_RESET_CARD:
			print("Player ", current_player, " confirmed card actions.")
		
		TurnPhase.ROLL:
			print("Player ", current_player, " is in the ROLL phase.")
			roll_phase()
		
		TurnPhase.REROLL:
			print("Player ", current_player, " is in the REROLL phase.")
			reroll_phase()
		
		TurnPhase.PLACE:
			print("Player ", current_player, " is in the PLACE phase.")
			place_phase()

		TurnPhase.END:
			print("Player ", current_player, "'s turn is ending.")
			end_turn()

#region Handles card selection actions
func _on_card_selected(card):
	# when player clicks on a playable card in the card tray
	# make sure globally we know which card is being player
	card_in_effect = card
	
	# disable all buttons in dice menu
	for dice_button in dice_buttons:
		if dice_button.name != "ResultLabel":
			dice_button.visible = false
			dice_button.disabled = true
		else:
			dice_button.text = "Cannot use dice, a card has been selected"
	
	# disable all choices under card
	for card_button in card_buttons:
		card_button.disabled = true
	
	# UI: highlight the selected card
	card.modulate = Color(1, 0, 0)

func _on_card_move_selected(moves):
	# moves is an array of [[player, territory_index, deploy_count, has_leader]]
	# when player clicked on territories to apply effect of the card
	# proceed to confirm or reset card
	current_phase = TurnPhase.CONFIRM_OR_RESET_CARD
	process_turn_phase()
	
	## reset card_moves_queued array
	#card_moves_queued = []
	
	# enable confirm or reset buttons
	get_node(CARD_MENU_PARENT + "/ConfirmCardButton").disabled = false
	get_node(CARD_MENU_PARENT + "/ResetCardButton").disabled = false

func _on_card_move_reverted(moves):
	# when player clicked on reset after selecting the moves
	# the reset has been passed through, clear the queue
	#card_moves_stage = []
	
	# go back to CARD phase where user needs to take actions to apply effect of card
	current_phase = TurnPhase.CARD
	process_turn_phase()
	
	# disable the confirm button as player must take moves before confirmation
	get_node(CARD_MENU_PARENT + "/ConfirmCardButton").disabled = true
	
	
func _on_card_confirmed():
	# once the player confirmed the card action, transition to next turn
	current_phase = TurnPhase.END
	process_turn_phase()
	
	# the used card disappears
	card_in_effect.queue_free()

	# reset for next card play
	card_in_effect = null
	#card_moves_stage = []
	
	# all remaining card buttons are enable again
	for card_button in card_buttons:
		if card_button.name.begins_with("Card"):
			card_button.disabled = false
#endregion

# Handles roll phase actions
func roll_phase():
	print("Player ", current_player, " rolls.")
	#$Control/RollDiceButton.visible = true
	#$Control/RollDiceButton.disabled = false
	#
	## Hide dice option buttons
	#$Control/DiceOption1.visible = false
	#$Control/DiceOption2.visible = false
	#$Control/DiceOption3.visible = false

func _on_dice_rolled():
	print("Dice rolled, handling the result in the GameController.")
	current_phase = TurnPhase.PLACE
	process_turn_phase()
	
	# UI: display dice options
	#for dice_button in dice_buttons:
		#if dice_button.name.begins_with("DiceOption"):
			#dice_button.disabled = false
			#dice_button.visible = true
	
	# if leader already played, disable the leader button
	if Settings.players[current_player]["leader"] <= 0:
		for dice_button in dice_buttons:
			if dice_button.name.begins_with("DiceOption") and dice_button.name.ends_with("L"):
				dice_button.disabled = true
	
	# disable all card actions in card menu:
	for card_button in card_buttons:
		card_button.disabled = true

func reroll_phase():
	pass
	
func place_phase():
	#$Control/DiceOption1.visible = true
	#$Control/DiceOption2.visible = true
	#$Control/DiceOption3.visible = true
	pass

func _on_roll_phase_done():
	for button in dice_buttons:
		if button is Button and button.name.begins_with("DiceOption"):
			button.visible = false
			button.disabled = true
	current_phase = TurnPhase.END
	process_turn_phase()

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
	print("Player ", current_player, "'s turn is over.")
	
	# Update player pieces and check if they are out
	if Settings.players[current_player]["leader"] + Settings.players[current_player]["soldier"] <= 0:
		print("Player ", current_player, " is out of pieces!")
		Settings.players[current_player]["active"] = false
		# store player out sequence for tie-breaker
		player_priority.append(current_player)

	# Switch to the next player
	current_player = (current_player + 1) % Settings.num_players
	update_stats_label()

	# Start the next player's turn
	start_turn()

func scoring_phase():
	print("entering scoring phase")
	# TODO: disable the buttons
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
