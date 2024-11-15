extends Card


func _ready() -> void:
	card_name = "MuHon / Coup"
	card_name_jp = "謀反"
	description = "Bounce 1 opponent's soldier and replace it with 1 soldier from your hand."
	effect = [
		{"deploy": -1, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": false},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have soldiers left
		2. there must be other player soldiers on the board
	"""
	
	if GameState.players[player]["soldier"] <= 0:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true


func get_valid_targets(player) -> Array:
	"""All players with soldiers (except self) are valid."""
	
	var valid_targets = []
	
	for opponent in TerritoryHelper.get_opponents(player):
		if TerritoryHelper.get_player_soldier_occupied(opponent).size() > 0:
			valid_targets.append(opponent)
	
	return valid_targets


func get_card_step_territories(step: int) -> Array:
	# step 1: territories with opponent soldier
	if step == 0:
		# if opponent is selected, return specific territories
		if self.selected_opponent != -1:
			return TerritoryHelper.get_player_soldier_occupied(self.selected_opponent)
		
		# otherwise, highlight all valid opponents' valid territories
		return TerritoryHelper.get_players_soldier_occupied(
			TerritoryHelper.get_opponents(GameState.current_player)
		)
	
	# step 2: previously selected territory
	if step == 1:
		return self.staged_moves[0][1]
		
	return []
