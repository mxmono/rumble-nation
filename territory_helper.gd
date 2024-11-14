extends Node


func get_player_territories(player: int) -> Array:
	return GameState.players[player]["territories"]


func get_player_territory_tally(player:int, territory: int) -> Dictionary:
	return GameState.board_state["territory_tally"][territory][player]


func get_player_territories_soldiers_only(player: int) -> Array:
	var player_territories = get_player_territories(player)
	var soldier_territories = []
	
	for territory in player_territories:
		if get_player_territory_tally(player, territory)["soldier"] > 0:
			soldier_territories.append(territory)
	
	return soldier_territories
