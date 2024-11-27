extends Node


func get_opponents(player: int) -> Array:
	var opponents = range(GameState.num_players)
	opponents.erase(player)
	return opponents


func get_player_occupied(player: int) -> Array:
	return GameState.players[player]["territories"]


func get_players_occupied(players: Array) -> Array:
	var territories = []
	
	for player in players:
		var player_territories = get_player_occupied(player)
		for player_territory in player_territories:
			if not territories.has(player_territory):
				territories.append(player_territory)
	
	return territories


func get_players_on_territory(territory: int) -> Array:
	"""Return array of players with pieces on territory."""
	var players = []
	
	for player in range(GameState.num_players):
		if GameState.players[player]["territories"].has(territory):
			players.append(player)
	
	return players


func is_territory_empty(territory: int) -> bool:
	"""If territroy has no pieces."""
	return get_players_on_territory(territory).is_empty()


func get_player_territory_tally(player:int, territory: int) -> Dictionary:
	return GameState.board_state["territory_tally"][territory][player]


func get_player_soldier_occupied(player: int) -> Array:
	"""Territories soldiers occupy (excl leader)."""
	var player_territories = get_player_occupied(player)
	var soldier_territories = []
	
	for territory in player_territories:
		if get_player_territory_tally(player, territory)["soldier"] > 0:
			soldier_territories.append(territory)
	
	return soldier_territories


func get_players_soldier_occupied(players: Array) -> Array:
	"""Soldier occupied territories for a collection of players."""
	var soldier_territories = []
	
	for player in players:
		var player_territories = get_player_soldier_occupied(player)
		for player_territory in player_territories:
			if not soldier_territories.has(player_territory):
				soldier_territories.append(player_territory)
	
	return soldier_territories


func get_adjacent_by_connection_type(territory: int, connection_type: String = "all") -> Array:
	"""Get adjacent territories by connection type (water, land, all)."""
	return GameState.board_state["territory_connections"][territory][connection_type]


func get_all_with_connection_type(connection_type: String = "all") -> Array:
	"""All territories with connection type `water` or `land` or `all`."""
	var territory_connections = GameState.board_state["territory_connections"]
	var territories = []
	
	for territory in range(GameState.num_territories):
		if territory_connections[territory][connection_type].size() > 0:
			territories.append(territory)
	
	return territories


func get_player_occupied_with_min_tally(player: int, min_soldier: int = 0, min_leader: int = 0) -> Array:
	"""Player territroies with at least x soldiers and y leaders."""
	
	var player_territories = get_player_occupied(player)
	var tallies = GameState.board_state["territory_tally"]
	var territories = []
	
	for territory in player_territories:
		if tallies[territory][player]["soldier"] >= min_soldier:
			if tallies[territory][player]["leader"] >= min_leader:
				territories.append(territory)
	
	return territories


func get_player_soldier_occupied_adjancents_by_connection_type(player: int, connection_type: String = "all") -> Array:
	"""All territories that are adjacent to soldier occupied territories."""
	var player_soldier_occupied_adjacents = []
	
	var player_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(player)
	for territory in player_soldier_occupied:
		player_soldier_occupied_adjacents = Helper.union_set(
			TerritoryHelper.get_adjacent_by_connection_type(territory, connection_type),
			player_soldier_occupied_adjacents,
		)
	
	return player_soldier_occupied_adjacents


func get_player_leader_occupied(player: int) -> int:
	"""Leader occupied territory."""
	return get_player_occupied_with_min_tally(player, 0, 1)[0]
