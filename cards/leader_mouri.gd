extends Leader


func _ready() -> void:
	card_name = "Mouri Motonari"
	card_name_jp = "毛利元就"
	description = "Deploy 1 of your soldiers from hand to a territory adjacent to the territory your leader occupies up to 3 times."
	# effect is updated on selection
	effect = [
		{"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. player must have >=1 soldier left (redundant, player must not be out to play cards, and if
			last piece is leader, condition 1 is not met)
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false

	return true


func update_card_on_selection():
	"""Based on which player, reduce available number of steps if necessary."""
	super.update_card_on_selection()

	# can only click up to the times the player has soldier left
	var soldiers_left = GameState.players[GameState.current_player]["soldier"]
	if soldiers_left <= self.effect.size():
		self.effect = self.effect.slice(0, soldiers_left)


func get_card_step_territories(step: int) -> Array:
	# step 1: adjacent to leader
	if step == 0:
		return TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all")
	
	# step 2: adjacent to leader, but hasn't been selected
	if step == 1:
		var territories = TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all").duplicate()
		territories.erase(self.staged_moves[0][1])
		return territories
	
	# step 3: yet another adjacent
	if step == 2:
		var territories = TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all").duplicate()
		territories.erase(self.staged_moves[0][1])
		territories.erase(self.staged_moves[1][1])
		return territories
	
	return []
