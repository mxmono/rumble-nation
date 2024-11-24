extends Card


func _ready() -> void:
	card_name = "BunTai / Squad Split"
	_card_name = "buntai"
	card_name_jp = "分隊"
	description = "Move half (round down) of your soldiers from one territory to any one adjacent territory."
	
	effect = [
		{"deploy": -1, "player": "current", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player) -> bool:
	"""Conditions:
		1. player must have >=2 soldiers on any territory.
	"""
	
	if get_card_step_territories(0).size() > 0:
		return true
	
	return false


func update_effect(player) -> void:

	# half of the player's soldiers on selected territory
	var board_state =GameState.board_state["territory_tally"]
	var deploy_count = 0
	if self.staged_moves.size() > 0:  # ie step 2, the first move is alredy staged
		deploy_count = board_state[self.staged_moves[0][1]][player]["soldier"] / 2
	else:  # step 1, use last clicked territory
		deploy_count = board_state[self.last_selected_territory][player]["soldier"] / 2
	
	# update the effect
	self.effect[0]["deploy"] = -deploy_count
	self.effect[1]["deploy"] = deploy_count


func get_card_step_territories(step) -> Array:
	# step 1: territories with at least 2 soldiers with connections
	if step == 0:
		var territory_pool = TerritoryHelper.get_all_with_connection_type("all")
		var territory_at_least_two_soldiers = TerritoryHelper.get_player_occupied_with_min_tally(
			GameState.current_player, 2, 0
		)
		return Helper.get_array_overlap(territory_pool, territory_at_least_two_soldiers)
	
	# step 2: any adjacent to previous selected
	return TerritoryHelper.get_adjacent_by_connection_type(self.staged_moves[0][1], "all")
