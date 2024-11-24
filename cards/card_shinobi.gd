extends Card


func _ready() -> void:
	card_name = "Shinobi / Ninja"
	_card_name = "shinobi"
	card_name_jp = "忍"
	description = "Move 1 of your soldiers from any territory to any other territory your soldiers occupy."
	effect = [
		{"deploy": -1, "player": "current", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player must have at least two territories with soldiers.
	"""
	
	if TerritoryHelper.get_player_soldier_occupied(player).size() >= 2:
		return true
	
	return false


func get_card_step_territories(step: int) -> Array:
	# step 1: territories with soldiers
	if step == 0:
		return TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
	
	# step 2: a different territory with soldiers
	if step == 1:
		var occupied_territories = TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
		occupied_territories.erase(self.staged_moves[0][1])
		return occupied_territories
	
	return []
