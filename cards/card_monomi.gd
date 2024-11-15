extends Card


func _ready() -> void:
	card_name = "MonoMi / Sightseeing"
	card_name_jp = "物見"
	description = "Move 1 of your soldiers to any adjacent territory."
	effect = [
		{"deploy": -1, "player": "current", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. Must have a soldier on map.
	"""

	if TerritoryHelper.get_player_soldier_occupied(player).size() == 0:
		return false
	
	return true


func get_card_step_territories(step: int) -> Array:
	# step 1: soldier occupied any
	if step == 0:
		return TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
	
	# step 2: adjancet to prev step
	if step == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "all")
	
	return []
