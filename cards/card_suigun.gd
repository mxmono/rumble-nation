extends Card


func _ready() -> void:
	card_name = "SuiGun / Navy"
	card_name_jp = "水軍"
	description = "Move 2 of your soldiers from one territory to an adjacent territory by water."
	effect = [
		{"deploy": -2, "player": "current", "territory_selection_required": true},
		{"deploy": 2, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have at least 2 soldiers on a territory with water connection.
	"""
	
	if get_card_step_territories(0).size() == 0:
		return false
	
	return true


func get_card_step_territories(step: int) -> Array:
	# step 1: >=2 soldiers on territory, territory has water connection
	if step == 0:
		var player_territories = TerritoryHelper.get_player_occupied_with_min_tally(
			GameState.current_player, 2, 0
		)
		var water_territories = TerritoryHelper.get_all_with_connection_type("water")
		return Helper.get_array_overlap(player_territories, water_territories)
	
	# step 2:adjacent to previously selected by water
	if step == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "water")
	
	return []
