extends Node2D

@export var num_players: int = 2
@export var current_player: int = 1
@export var players = []
var player_priority = []  # store which players are out first

# Enum for different phases in a player's turn
enum TurnPhase {
	CARD,
	ROLL,
	REROLL,
	PLACE,
	END
}

var current_phase = TurnPhase.CARD

# Start the game and the first player's turn
func _ready():
	var control_scene = get_node("/root/GameController/Control")
	control_scene.roll_phase_done.connect(_on_roll_phase_done)
	control_scene.piece_used.connect(_on_piece_used)

	for i in range(num_players):
		players.append({
			"soldier": 16,
			"leader": 1,
			"active": true,
			"score": 0,
		})

	start_turn()

# Starts a player's turn
func start_turn():
	if all_players_out():
		print("All players are out of pieces! Transitioning to scoring phase.")
		scoring_phase()
		return
	
	# Find the next active player with pieces
	while not players[current_player - 1]["active"]:
		current_player = current_player % num_players + 1

	print("Player ", current_player, "'s turn.")
	update_stats_label()

	current_phase = TurnPhase.CARD
	process_turn_phase()

func update_stats_label():
	if all_players_out():
		$Info/PlayerLabel.text = "All players out"
	else:
		$Info/PlayerLabel.text = "Player %s's Turn" % current_player
	for i in range(num_players):
		$Info/PlayerLabel.text += "\nPlayer %s: %s soldier(s) left; %s leader left" % [
			str(i + 1),  str(players[i]["soldier"]), str(players[i]["leader"])
		]

# Check if all players are out of pieces
func all_players_out() -> bool:
	for player in players:
		if player["active"]:
			return false  # At least one player still has pieces
	return true  # All players are out of pieces

# Process each phase of the turn
func process_turn_phase():
	match current_phase:
		TurnPhase.CARD:
			print("Player ", current_player, " is in the CARD phase.")
			card_phase()
		
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

# Handles move phase actions
func card_phase():
	print("Player ", current_player, " decides if to use a card.")
	
	# After moving, go to the ROLL phase
	current_phase = TurnPhase.ROLL
	process_turn_phase()

# Handles attack phase actions
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

func reroll_phase():
	pass
	
func place_phase():
	#$Control/DiceOption1.visible = true
	#$Control/DiceOption2.visible = true
	#$Control/DiceOption3.visible = true
	pass

func _on_roll_phase_done():
	#$Control/DiceOption1.visible = false
	#$Control/DiceOption2.visible = false
	#$Control/DiceOption3.visible = false
	current_phase = TurnPhase.END
	process_turn_phase()

func _on_piece_used(player, n, has_leader):
	if has_leader:
		players[player - 1]["leader"] -= 1
		players[player - 1]["soldier"] -= n - 1
	else:
		players[player - 1]["soldier"] -= n

# Ends the player's turn and switches to the next player
func end_turn():
	print("Player ", current_player, "'s turn is over.")
	
	# Update player pieces and check if they are out
	if players[current_player - 1]["leader"] + players[current_player - 1]["soldier"] <= 0:
		print("Player ", current_player, " is out of pieces!")
		players[current_player - 1]["active"] = false
		# store player out sequence for tie-breaker
		player_priority.append(current_player)

	# Switch to the next player
	current_player = current_player % num_players + 1
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
		for player in territory_tally:
			scores.append(territory_tally[player]["soldier"] + territory_tally[player]["leader"] * 2)
		var winning_player = get_winning_player(scores, player_priority)
		print(territory.get("territory_points"), ":  player", str(winning_player), " wins")
		if winning_player == -1:  # if no one wins, go to next territory
			continue

		# reinforce to adjacent territories
		territory.reinforce(num_players, winning_player)
		
		# credit score to the player
		players[winning_player - 1]["score"] += territory.get("territory_points")
	
	# annouce the winner
	var current_max = 0
	var i = 1
	var winners = [-1]
	for player in players:
		if player["score"] > current_max:
			current_max = player["score"]
			winners[0] = i
			i += 1
		elif player["score"] == current_max:
			winners.append(i)
	$Info/PlayerLabel.text += "\nPlayer %s wins! Player 1: %s; Player 2: %s" % [
		str(winners), str(players[0]["score"]), str(players[1]["score"])
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
			player_index.append(i + 1)  # index = 0 -> player = 1

	# if tie, check which player is out first, eg players [1, 2] tie
	# then if the player priority is [2, 1], player 2 wins
	if player_index.size() > 1:
		for player in player_priority:
			if player_index.find(player) != -1:
				return player
	
	# otherwise if only 1 winner, return the winner
	return player_index[0]
