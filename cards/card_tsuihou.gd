extends Card


func _ready() -> void:
	card_name = "TsuiHou / Expel"
	_card_name = "tsuihou"
	card_name_jp = "追放"
	description = "Move 1 opponent's soldier from a territory you occupy to an adjacent territory."
	effect = [
		{"deploy": -1, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "other", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have pieces on board
		2. there must be other players on territories the player occupies
	"""
	
	if GameState.players[player]["territories"].size() == 0:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true


func get_valid_targets(player):
	"""Opponent must occupy the same territory."""
	
	var player_territories = TerritoryHelper.get_player_soldier_occupied(player)
	var valid_targets = []
	
	for opponent in TerritoryHelper.get_opponents(player):
		var opponent_territories = TerritoryHelper.get_player_soldier_occupied(opponent)
		if Helper.get_array_overlap(player_territories, opponent_territories).size() > 0:
			valid_targets.append(opponent)
	
	return valid_targets


func get_card_step_territories(step: int) -> Array:
	# step 1: self soldier occupied, opponent soldier occupied
	if step == 0:
		var player_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
		var opponent_soldier_occupied = []
		
		# if opponent selected
		if self.selected_opponent != -1:
			opponent_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(self.selected_opponent)
		# if not selected, get all
		else:
			opponent_soldier_occupied = TerritoryHelper.get_players_soldier_occupied(
				TerritoryHelper.get_opponents(GameState.current_player)
			)
		return Helper.get_array_overlap(player_soldier_occupied, opponent_soldier_occupied)
	
	# step 2: adjacent to previously selected
	if step == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "all")
	
	return []
