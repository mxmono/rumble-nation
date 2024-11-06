extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "HitoJichi"
	card_name_jp = "人質"
	description = "Move one soldier from another player to a connected territory you occupy."
	effect = [
		{"deploy": -1, "territory": "occupied_other_adjacent_to_self", "player": "other"},
		{"deploy": 1, "territory": "adjacent_occupied", "player": "other"},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have pieces
		2. within connected territories of current player, there must be pieces from another player
	"""
	var current_player_territories =Settings.players[player]["territories"]
	
	# if no territories, return false
	if current_player_territories.size() == 0:
		return false
	
	# find which players have territories adjacent to current player 
	var valid_opponents = get_valid_targets(player)
	
	# if no valid opponents, return false
	if valid_opponents.size() == 0:
		return false
	
	return true

func get_valid_targets(player) -> Array:
	var current_player_territories = Settings.players[player]["territories"]
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	
	# find which players have territories adjacent to current player 
	var valid_opponents = []
	for player_index in range(Settings.players.size()):
		if player_index == player:  # skip self
			continue
		var opponent_territories = Settings.players[player]["territories"]
		
		# loop through all territories current player has and check connections
		for player_territory_index in current_player_territories:
			var connections = territory_connections[player_territory_index]["all"]
			
			# if anything in the connections has the opponent's pieces on, add to pool
			for connection in connections:
				if opponent_territories.has(connection):
					valid_opponents.append(player_index + 1)
					continue
	
	return valid_opponents
