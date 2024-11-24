extends Card


func _ready() -> void:
	card_name = "JouRaku / Capital March"
	_card_name = "jouraku"
	card_name_jp = "上洛"
	description = "Deploy any number of your own soldiers from any number of territories adjacent to Kyo to Kyo."
	
	# effect needs to be updated, this is a placeholder for territory highlight on first click
	effect = [
		{"deploy": -1, "player": "current", "territory_selection_required": true, "finish_allowed": false},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have territories adjacent to kyo (index = 4) with soldiers
	"""
	
	if get_card_step_territories(0).size() == 0:
		return false
	
	return true


func update_effect(player):
	# special to this card: max number of times is total number of pieces in adjacent territories.
	var max_deploy_times = get_max_deploy_times(player)
	if self.effect.size() == 1:  # reset the first time
		self.effect = []
	for i in range(max_deploy_times):
		effect += [
			{"deploy": -1,"player": "current", "territory_selection_required": true, "finish_allowed": false},
			{"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		]


func get_max_deploy_times(player) -> int:
	"""Number of total deployed soldiers in kyo-adjacent territories."""
	
	var max_deploy_times = 0
	var valid_territories = get_card_step_territories(0)
	
	for territory in valid_territories:
		max_deploy_times += TerritoryHelper.get_player_territory_tally(player, territory)["soldier"]
	
	return max_deploy_times


func get_card_step_territories(step: int) -> Array:
	# step 1,3,5...: territories around kyo (4) the player soldier occupies
	if step % 2 == 0:  # 0, 2, 4...
		var kyo_adjacents = TerritoryHelper.get_adjacent_by_connection_type(4, "all")
		var player_occupied = TerritoryHelper.get_player_soldier_occupied(GameState.current_player)
		return Helper.get_array_overlap(kyo_adjacents, player_occupied)
	
	# step 2,4,6...: kyo
	if step % 2 == 1:  # 1, 3, 5...
		return [4]
	
	return []
