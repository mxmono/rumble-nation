extends Node

signal phase_started(phase)
signal game_scored()
signal card_revert_move_deployed()  # revert received and game state updated


func _ready():
	var board_scene = get_node("/root/Game/Board")
	board_scene.card_move_selected.connect(_on_card_move_selected)
	
	# connect signals
	var control_scene = get_node("/root/Game/Control")
	control_scene.dice_selected.connect(_on_dice_selected)
	control_scene.card_move_reverted.connect(_on_card_move_reverted)
	control_scene.card_move_confirmed.connect(_on_card_confirmed)
	control_scene.card_selected.connect(_on_card_selected)
	
	# start turn sequence
	start_turn()


func start_turn():
	if GameState.all_players_out():
		print("All players are out of pieces! Transitioning to scoring phase.")
		scoring_phase()
		return
	
	# Find the next active player with pieces
	while not GameState.players[GameState.current_player]["active"]:
		GameState.current_player = (GameState.current_player + 1) % GameState.num_players

	print(GameState.players[GameState.current_player]["name"], "'s turn.")

	GameState.current_phase = GameState.TurnPhase.CHOICE
	process_turn_phase()


func process_turn_phase():
	var current_player_name = GameState.players[GameState.current_player]["name"]
	match GameState.current_phase:

		GameState.TurnPhase.CHOICE:
			print(current_player_name, " is in the CHOICE phase.")
			phase_started.emit(GameState.TurnPhase.CHOICE)

		GameState.TurnPhase.CARD:
			print(current_player_name, " is in the CARD phase.")
			phase_started.emit(GameState.TurnPhase.CARD)

		GameState.TurnPhase.CONFIRM_OR_RESET_CARD:
			print(current_player_name, " to CONFIRM OR RESET CARD actions.")
			phase_started.emit(GameState.TurnPhase.CONFIRM_OR_RESET_CARD)
		
		GameState.TurnPhase.ROLL:
			print(current_player_name, " is in the ROLL phase.")
			phase_started.emit(GameState.TurnPhase.ROLL)
		
		GameState.TurnPhase.REROLL:
			print(current_player_name, " is in the REROLL phase.")
			phase_started.emit(GameState.TurnPhase.REROLL)
		
		GameState.TurnPhase.PLACE:
			print(current_player_name, " is in the PLACE phase.")
			phase_started.emit(GameState.TurnPhase.PLACE)
		
		GameState.TurnPhase.END:
			print(current_player_name, "'s turn is ENDING.")
			phase_started.emit(GameState.TurnPhase.END)
			end_turn()


#region handles card selection and application actions
func _on_card_selected(card):
	# when clicked on a card, user has made a choice, ending the choice phase
	GameState.current_card = card
	GameState.current_phase = GameState.TurnPhase.CARD
	process_turn_phase()


func _on_card_move_selected(moves):
	# moves is an array of [[player, territory_index, deploy_count, has_leader]]
	# when player clicked on territories to apply effect of the card, update deployment
	for move in moves:
		GameState.update_game_state_on_deployed(move[0], move[1], move[2], move[3], true)
	
	# proceed to confirm or reset card
	# only do so if the card effect has fully finished, as signal can be emitted for multi-step midway
	if GameState.current_card.effect_index == GameState.current_card.effect.size():
		GameState.current_phase = GameState.TurnPhase.CONFIRM_OR_RESET_CARD
		process_turn_phase()


func _on_card_move_reverted(moves):
	# update game state
	for move in moves:
		GameState.update_game_state_on_deployed(move[0], move[1], -move[2], move[3], true)
	
	# on card move reverted, same as the same card is selected again
	_on_card_selected(GameState.current_card)
	
	# signal for ui update, need to make sure that the game state update has happened
	card_revert_move_deployed.emit()


func _on_card_confirmed():
	# mark player
	if GameState.current_card.card_type == "normal":
		GameState.players[GameState.current_player]["used_card"] = true
	if GameState.current_card.card_type == "leader":
		GameState.players[GameState.current_player]["used_leader"] = true
	
	# the used card disappears
	GameState.current_card.queue_free()
	
	# once the player confirmed the card action, transition to next turn
	GameState.current_phase = GameState.TurnPhase.END
	process_turn_phase()

	# reset for next card play
	GameState.current_card = null
#endregion


#region handles dice rolling and piece placement actions
func _on_dice_rolled(dice_results, move_options):
	# allow reroll if current player has used a card, otherwise the turn ends
	if (
		GameState.players[GameState.current_player]["used_card"] or 
		GameState.players[GameState.current_player]["used_leader"]
	):
		if GameState.current_phase != GameState.TurnPhase.REROLL:
			GameState.current_phase = GameState.TurnPhase.REROLL
		else:  # already rerolled
			GameState.current_phase = GameState.TurnPhase.PLACE
	else:
		GameState.current_phase = GameState.TurnPhase.PLACE
	process_turn_phase()


func _on_dice_selected(territory: int, deploy_count: int, has_leader: bool):
	GameState.update_game_state_on_deployed(
		GameState.current_player, territory, deploy_count, has_leader, true
	)
	
	# reset dice options
	GameState.update_dice([])
	
	# go to next phase
	GameState.current_phase = GameState.TurnPhase.END
	process_turn_phase()
#endregion 


func end_turn():
	print(GameState.players[GameState.current_player]["name"], "'s turn is over.")
	
	# Update player pieces and check if they are out
	if GameState.players[GameState.current_player]["leader"] + GameState.players[GameState.current_player]["soldier"] <= 0:
		print(GameState.players[GameState.current_player]["name"], " is out of pieces!")
		GameState.players[GameState.current_player]["active"] = false
		# log out-sequence, ie if player priority already has an entry, current play out sequence = 2 (ie 1 on 0-index)
		GameState.players[GameState.current_player]["priority"] = GameState.player_priority.size()
		# store player out sequence for tie-breaker
		GameState.player_priority.append(GameState.current_player)
		print("priority: ", GameState.player_priority)

	# Switch to the next player
	GameState.current_player = (GameState.current_player + 1) % GameState.num_players

	# Start the next player's turn
	start_turn()


func scoring_phase():
	print("entering scoring phase")
	
	var player_scores = resolve_game(GameState.player_priority)
	
	var placement = get_placements(player_scores, GameState.player_priority)
	
	# update game state
	GameState.placement = placement
	for i in range(placement.size()):
		var player = placement[i]
		GameState.players[player]["placement"] = i
	
	print("final placement: ", GameState.placement)
	
	# emit signal that scoring is done for ui
	game_scored.emit()


func resolve_game(player_priority: Array) -> Array:
	"""Return an array of player scores. GameState changes."""
	
	# get an array of territory indices by territory points ascending
	var territories_by_points = []
	for territory_points in range(2, 13):
		territories_by_points.append(GameState.board_state["territory_points"].find(territory_points))
	
	for territory: int in territories_by_points:
		
		var territory_points: int = territories_by_points.find(territory) + 2  # first one is 2 points
		print("Scoring %s: territory index %s" % [territory_points, territory])
		
		# check who wins
		var territory_tally = GameState.board_state["territory_tally"][territory]
		var territory_scores = []
		for player_tally in territory_tally:
			territory_scores.append(
				player_tally["soldier"] + player_tally["reinforcement"] + player_tally["leader"] * 2
			)
			
		var territory_placement = get_placements(territory_scores, player_priority)
		
		# update winner for each territory in game state
		if GameState.board_state["territory_winner"].size() != GameState.num_territories:
			GameState.board_state["territory_winner"].resize(GameState.num_territories)
		GameState.board_state["territory_winner"][territory] = territory_placement[0]
		
		# if no one wins the territory, continue
		if territory_placement.max() == -1:
			continue
		print(GameState.players[territory_placement[0]]["name"], " is first place")
		
		if territory_placement[1] != -1:
			print(GameState.players[territory_placement[1]]["name"], " is second place")
		
		# reinforce to adjacent territories
		reinforce(territory_placement[0], territory)
		
		# credit score to the player
		GameState.players[territory_placement[0]]["score"] += territory_points
		
		# add half score (round down) to 2nd place if more than 2 players
		if GameState.num_players > 2:
			if territory_placement[1] != -1:
				GameState.players[territory_placement[1]]["score"] += territory_points / 2
				print("credited ", territory_points / 2, " to ", GameState.players[territory_placement[1]]["name"])

	# annouce the winner
	var player_scores = []
	for player in GameState.players:
		player_scores.append(player["score"])

	return player_scores


func reset_game_state_post_adhoc_resolution():
	"""If it's an adhoc resolution for AI, reset those states."""
	GameState.board_state["territory_winner"] = []
	
	for player in GameState.players:
		player["score"] = 0
	
	for territory in range(GameState.num_territories):
		for player in range(GameState.num_players):
			GameState.update_board_tally(
				territory, player, {"reinforcement": 0}
			)
	

func get_placements(player_scores: Array, player_priority: Array) -> Array:
	"""Given scores, return an array of player_index ordered by win order.
	Eg, [1, 2, 0] means first place is player1, last place is player0
	"""
	# eg scores = [23, 45, 23, 30], priority = [2, 0, 1, 3] => placement = [1, 3, 2, 0]
	var placements = []
	
	# if no one wins (on an empty territory), return all -1s
	if player_scores.max() == 0:
		return [-1, -1, -1, -1].slice(0, player_scores.size())
	
	# first sort scores by priority, scores_sorted = [23 (2), 23 (0), 45, 30]
	# find max=45, index=2, priority[2]=1 => player 1 wins
	# example 2: scores [24, 19], priority [1, 0], sorted [19, 24], max=24, index=1, priority[1]=0
	var scores_sorted = []
	for i in range(player_scores.size()):
		scores_sorted.append(player_scores[player_priority[i]])
	
	while scores_sorted.max() > -1:
		var current_max = scores_sorted.max()
		var current_highest_player_priority_index = scores_sorted.find(current_max)
		var current_highest_player = player_priority[current_highest_player_priority_index]
		
		# if already all 0s (can happen on single territory scoring, eg only 1 player occupies)
		# fill the rest of the placements with -1
		if current_max == 0:
			current_highest_player = -1
		
		placements.append(current_highest_player)
		scores_sorted[current_highest_player_priority_index] = -1
	
	return placements


func reinforce(player, from_territory):
	"""Reinforce `player` pieces from `from_territory` to all eligible connected territories."""
	# get connected territories and how many pieces to reinforce
	var pieces_to_reinforce = 1
	if GameState.num_players > 2:
		pieces_to_reinforce = 2

	var connected_territories = TerritoryHelper.get_adjacent_by_connection_type(from_territory, "all")
	for connected_territory in connected_territories:
		# reinforce if the connected territory has higher points than current territory
		if (
			GameState.board_state["territory_points"][connected_territory] > 
			GameState.board_state["territory_points"][from_territory]
		):
			var tally = TerritoryHelper.get_player_territory_tally(player, connected_territory)
			
			# only reinforce if player has pieces
			if tally["soldier"] + tally["leader"] > 0:
				GameState.update_board_tally_by_delta(
					connected_territory, player, {"reinforcement": pieces_to_reinforce},
				)
				print(
					"territory %s with points %s received player %s's %s reinforcements" % 
					[
						str(connected_territory),
						str(GameState.board_state["territory_points"][connected_territory]),
						str(player),
						str(pieces_to_reinforce)
					]
				)
