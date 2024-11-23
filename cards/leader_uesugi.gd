extends Leader


func _ready() -> void:
	card_name = "Uesugi Kenshin"
	card_name_jp = "上杉謙信"
	description = "Move up to 3 of your soldiers from your leader territory to any number of adjacent territories by land."
	
	effect = []  # effect is updated on card selection
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. leader territory has land connection
		3. player has at least 1 soldier on leader territory
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	var leader_territory = TerritoryHelper.get_player_leader_occupied(player)
	
	if GameState.board_state["territory_connections"][leader_territory]["land"].size() == 0:
		return false
	
	if GameState.board_state["territory_tally"][leader_territory][player]["soldier"] <= 0:
		return false

	return true


func update_card_on_selection():
	
	super.update_card_on_selection()
	
	var current_player = GameState.current_player
	
	# update effects based on state when card is selected
	self.effect = []
	var soldiers_on_leader_territory = TerritoryHelper.get_player_territory_tally(
		GameState.current_player, self.leader_territory
	)["soldier"]
	for i in range(soldiers_on_leader_territory):
		self.effect += [
			{"deploy": -1, "player": "current", "territory_selection_required": true},
			{"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		]


func get_card_step_territories(step: int) -> Array:
	# step 1s: leader initial
	if step % 2 == 0:
		return [self.leader_territory]
	
	# step 2s: adjacent to leader
	if step % 2 == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "land")
	
	return []
