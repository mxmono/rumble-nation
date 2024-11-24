extends Card


func _ready() -> void:
	card_name = "Otori / Decoy"
	_card_name = "otori"
	card_name_jp = "囮"
	description = "Move 1 of your soldiers and 2 of an opponent's soldiers to any adjancent territory."
	effect = [
		{"deploy": -2, "player": "other", "territory_selection_required": true},  # the first one needs to be "other" player
		{"deploy": -1, "player": "current", "territory_selection_required": false},
		{"deploy": 2, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": false},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. there must be territories with one of self and two of the same others
	"""
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true


func get_valid_targets(player):
	"""Any opponent with >= 2 soldiers on player soldier occupied."""
	
	var player_territories = TerritoryHelper.get_player_soldier_occupied(player)
	var valid_targets = []
	
	for territory in player_territories:
		for opponent in TerritoryHelper.get_opponents(GameState.current_player):
			if TerritoryHelper.get_player_territory_tally(opponent, territory)["soldier"] >= 2:
				if not valid_targets.has(opponent):
					valid_targets.append(opponent)
	
	return valid_targets


func get_card_step_territories(step: int) -> Array:
	# step 1: territories with 1 self + >=2 others, soldiers only
	if step == 0:
		var player_territories = TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
		
		var opponent_territories = []
		# if opponent known
		if self.selected_opponent != -1:
			opponent_territories = TerritoryHelper.get_player_occupied_with_min_tally(self.selected_opponent, 2, 0)
		
		# if opponent not selected, get all opponents' valid territories
		else:
			for opponent in TerritoryHelper.get_opponents(GameState.current_player):
				opponent_territories = Helper.union_set(
					TerritoryHelper.get_player_occupied_with_min_tally(opponent, 2, 0),
					opponent_territories,
				)
				
		return Helper.get_array_overlap(player_territories, opponent_territories)
	
	# step 2:  same territory as before, just a different player
	if step == 1:
		return [self.staged_moves[0][1]]
	
	# step 3: any adjacent to previous selected
	if step == 2:
		return TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "all")
	
	# step 4: same as prev selected
	if step == 3:
		return [self.staged_moves[2][1]]
	
	return []
