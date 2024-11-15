extends Card


func _ready() -> void:
	card_name = "HitoJichi / Prisoner"
	card_name_jp = "人質"
	description = "Move 1 opponent's soldier to an adjacent territory your soldiers occupy."
	effect = [
		{"deploy": -1, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "other", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have soldier territories
		2. within connected territories of current player, there must be soldiers from another player
	"""
	var current_player_territories = GameState.players[player]["territories"]
	
	# if no territories, return false
	if TerritoryHelper.get_player_soldier_occupied(player).size() == 0:
		return false
	
	# find which players have territories adjacent to current player 
	var valid_opponents = get_valid_targets(player)
	
	# if no valid opponents, return false
	if valid_opponents.size() == 0:
		return false
	
	return true


func get_valid_targets(player) -> Array:
	"""Any opponent with soldiers in territories adjacent to player soldier occupied."""
	
	var player_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(player)
	var adjacents = []
	for territory in player_soldier_occupied:
		adjacents = Helper.union_set(
			TerritoryHelper.get_adjacent_by_connection_type(territory, "all"),
			adjacents,
		)
	
	# get all players (except self) that has soldiers in `adjacents`
	var valid_targets = []
	for opponent in TerritoryHelper.get_opponents(player):
		var opponent_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(opponent)
		# valid if the opponent soldier occupied territories overlap with valid adjacents
		if Helper.get_array_overlap(adjacents, opponent_soldier_occupied).size() > 0:
			valid_targets.append(opponent)
	
	return valid_targets


func get_card_step_territories(step) -> Array:
	# step 1: opponent soldier occupied, adjacent to self soldier occupied
	if step == 0:
		var opponent_soldier_territories = []
		if self.selected_opponent != -1:
			opponent_soldier_territories = TerritoryHelper.get_player_soldier_occupied(self.selected_opponent)
		else:
			opponent_soldier_territories = TerritoryHelper.get_players_soldier_occupied(
				TerritoryHelper.get_opponents(GameState.current_player)
			)
		
		var self_soldier_occupied_adjacents = TerritoryHelper.get_player_soldier_occupied_adjancents_by_connection_type(
			GameState.current_player, "all"
		)
		
		# return overlap of opponent soldier occupied and adjacents to self soldier occupied
		return Helper.get_array_overlap(self_soldier_occupied_adjacents, opponent_soldier_territories)
	
	# step 2: adjacent to step 1 selected territory that own soldiers occupy
	if step == 1:
		var adjacents = TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "all")
		var self_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
		return Helper.get_array_overlap(adjacents, self_soldier_occupied)
	
	return []
