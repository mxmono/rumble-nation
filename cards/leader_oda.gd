extends Leader


func _ready() -> void:
	card_name = "Oda Nobunaga"
	_card_name = "oda"
	card_name_jp = "織田信長"
	description = "Move your leader to an adjacent territory. You can move up to 1 soldier with your leader."
	
	effect = [
		# leader move
		{"deploy": -1, "player": "current", "territory_selection_required": true, "has_leader": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true, "has_leader": true, "finish_allowed": true, "emit": true},
		# optional soldier move
		{"deploy": -1, "player": "current", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	return true


func update_card_on_selection():
	"""If no soldier on leader territory, remove the optional step."""
	
	super.update_card_on_selection()
		
	var current_player = GameState.current_player
	var soldiers_on_leader_territory = TerritoryHelper.get_player_territory_tally(
		GameState.current_player, self.leader_territory
	)["soldier"]
	
	# if no soldier on leader territory, remove the optional step
	if soldiers_on_leader_territory <= 0:
		self.effect = self.effect.slice(0, 2)


func get_card_step_territories(step: int) -> Array:
	# step 1: leader initial occupied
	if step == 0:
		return [self.leader_territory]
	
	# step 2: adjacent to leader
	if step == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all")
	
	# step 3: optional. but should be the same as step 1
	if step == 2:
		return [self.leader_territory]
	
	# step 4: optional, but should be same as step 2
	if step == 3:
		return [self.staged_moves[1][1]]
	
	return []
