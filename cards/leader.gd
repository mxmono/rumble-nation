extends "res://cards/card.gd"

@export var is_leader_optional_or_undecided: bool = false  # whether the card can act on soldiers only
@export var apply_to_leader: bool = true  # if leader is optional, whether applies to leader
@export var leader_territory: int = -1  # leader territory when effect triggered, need to store as leader can move

func _ready() -> void:
	self.card_type = "leader"
	self.territory_func_mapping.merge(
		{
			"leader_occupied": get_leader_territory,
			"leader_initial_occupied": get_initial_leader_territory,
			"leader_adjacent": get_leader_adjacent_territories,
			"leader_adjacent_not_already_selected": get_leader_adjacent_territories_not_already_selected,
			"leader_adjacent_water": get_leader_adjacent_territories_by_water,
			"leader_adjacent_land": get_leader_adjacent_territories_by_land,
			"leader_adjacent_opponent_occupied": get_leader_adjacent_territories_occupied_by_any_opponent,
		}
	)
	
	super._ready()

func reset_card():
	self.is_leader_optional_or_undecided = false
	self.apply_to_leader = true
	super.reset_card()

func update_card_on_selection():
	var current_player = get_node("/root/GameController").current_player
	
	# specific to leader, get initial leader territory and store it
	self.leader_territory = get_leader_territory(current_player, null)[0]

func get_leader_territory(player, territory_index=null):
	"""Get which territory index the leader occupies for the player.
	Returns -1 if no leader.
	"""
	# assume 1 leader only
	var board_state =Settings.board_state["territory_tally"]
	var territory_connections = Settings.board_state["territory_connections"]
	
	var leader_territory_index = -1
	for territory in range(board_state.size()):
		if board_state[territory][player]["leader"] > 0:
			leader_territory_index = territory
	
	return [leader_territory_index]
	
func get_initial_leader_territory(player, territory_index):
	"""Get initial leader territory. Given leader can move during effect."""
	return [self.leader_territory]

func get_leader_adjacent_territories(player, territory_index=null):
	"""Territories adjacent to the leader."""

	# if card has been selected and we know the leader territory
	if self.leader_territory != -1:
		return get_adjacent_territories(player, self.leader_territory)
	
	if get_leader_territory(player, null)[0] == -1:
		return []
	
	return get_adjacent_territories(player, get_leader_territory(player, null)[0])

func get_leader_adjacent_territories_not_already_selected(player, territory_index=null):
	"""Territories adjacent to leader but not already selected/staged."""
	
	# get all leader adjacent territories
	var adjacent_territories = get_leader_adjacent_territories(player, territory_index).duplicate()
	
	# remove territories already selected in staged moves
	for move in self.staged_moves:
		adjacent_territories.erase(move[1])
	
	return adjacent_territories

func get_leader_adjacent_territories_by_water(player, territory_index=null):
	"""Adjacent to leader territory by water."""
	
	if self.leader_territory != -1:
		return get_adjacent_selected_water(player, self.leader_territory)
	
	return get_adjacent_selected_water(player, get_leader_territory(player, null)[0])

func get_leader_adjacent_territories_by_land(player, territory_index=null):
	"""Adjacent to leader territory by water."""
	
	if self.leader_territory != -1:
		return get_adjacent_selected_land(player, self.leader_territory)
	
	return get_adjacent_selected_land(player, get_leader_territory(player, null)[0])

func get_leader_adjacent_territories_occupied_by_any_opponent(player, territory_index):
	"""Leader adjacent territories with other player pieces. **soldier only"""
	
	var leader_adjacent_territories = get_leader_adjacent_territories(player, null)
	
	var valid_territories = []
	for territory in leader_adjacent_territories:
		var territory_tally = Settings.board_state["territory_tally"][territory]
		for opponent in range(territory_tally.size()):
			if opponent == player:
				continue
			if territory_tally[opponent]["soldier"] > 0:
				if not valid_territories.has(territory):
					valid_territories.append(territory)
	
	return valid_territories
	
